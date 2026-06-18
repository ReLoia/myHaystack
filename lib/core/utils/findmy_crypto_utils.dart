/*
 * Copyright (C) 2021 seemoo-lab/openhaystack contributors
 * Copyright (C) 2023 dchristl/macless-haystack contributors
 * Copyright (C) 2026 reloia
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * ---
 * MODIFICATION NOTICE:
 * Part of this code was taken and edited from dchristl/macless-haystack,
 * which was originally built upon the work of seemoo-lab/openhaystack.
 * Modified by reloia in June 2026.
 * ---
 */

import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';
import 'package:pointycastle/src/utils.dart' as pc_utils;

import '../../shared/data/models/decrypted_location_model.dart';
import '../../shared/data/models/location_report_model.dart';

class FindMyCryptoUtils {
  static final ECCurve_secp224r1 _curveParams = ECCurve_secp224r1();

  static ECPublicKey _derivePublicKey(ECPrivateKey privateKey) {
    final pk = _curveParams.G * privateKey.d;
    final publicKey = ECPublicKey(pk, _curveParams);
    return publicKey;
  }

  static String getHashedPublicKey({
    Uint8List? publicKeyBytes,
    ECPublicKey? publicKey,
  }) {
    var pkBytes = publicKeyBytes ?? publicKey!.Q!.getEncoded(false);
    final shaDigest = SHA256Digest();
    shaDigest.update(pkBytes, 0, pkBytes.lengthInBytes);
    Uint8List out = Uint8List(shaDigest.digestSize);
    shaDigest.doFinal(out, 0);
    return base64Encode(out);
  }

  /// Derives the base64 hashed key from a base64 private key
  static String getHashedPublicKeyFromPrivateKey(String privateKeyBase64) {
    final privateKeyBytes = base64Decode(privateKeyBase64);
    final ECPrivateKey privateKey = ECPrivateKey(
      pc_utils.decodeBigIntWithSign(1, privateKeyBytes),
      _curveParams,
    );

    final ECPublicKey publicKey = _derivePublicKey(privateKey);
    return getHashedPublicKey(publicKey: publicKey);
  }

  static String getHashedAdvKeyFromPrivateKey(String privateKeyBase64) {
    final privateKeyBytes = base64Decode(privateKeyBase64);
    final ECPrivateKey privateKey = ECPrivateKey(
      pc_utils.decodeBigIntWithSign(1, privateKeyBytes),
      _curveParams,
    );

    final ECPublicKey publicKey = _derivePublicKey(privateKey);

    var pkBytes = publicKey.Q!.getEncoded(true);
    var key = pkBytes.sublist(1, pkBytes.length);
    return getHashedPublicKey(publicKeyBytes: key);
  }

  static DecryptedLocationModel? decryptReport(
    LocationReportModel encryptedReport,
    String privateKeyBase64,
  ) {
    try {
      // 1. Decode the Base64 payload
      var payloadData = base64Decode(encryptedReport.payload);

      // Handle Macless Haystack extra byte padding if applicable
      if (payloadData.length > 88) {
        final modifiedData = Uint8List(payloadData.length - 1);
        modifiedData.setRange(0, 4, payloadData);
        modifiedData.setRange(4, modifiedData.length, payloadData, 5);
        payloadData = modifiedData;
      }

      if (payloadData.length < 88)
        return null; // Invalid/Corrupted payload length

      final ephemeralKeyBytes = payloadData.sublist(5, 62);
      final encData = payloadData.sublist(62, 72);
      final tag = payloadData.sublist(72, payloadData.length);

      // Extract unencrypted timestamp & confidence safely
      final payloadView = ByteData.sublistView(payloadData);
      final seenTimeStamp = payloadView.getInt32(0, Endian.big);
      final timestamp = DateTime.utc(
        2001,
      ).add(Duration(seconds: seenTimeStamp)).toLocal();
      final confidence = payloadData.elementAt(4);

      // 2. Decode user's Private Key
      final privateKeyBytes = base64Decode(privateKeyBase64);
      final privateKey = ECPrivateKey(
        pc_utils.decodeBigIntWithSign(1, privateKeyBytes),
        _curveParams,
      );

      // 3. Derive Ephemeral Public Key
      final decodePoint = _curveParams.curve.decodePoint(ephemeralKeyBytes);
      final ephemeralPublicKey = ECPublicKey(decodePoint, _curveParams);

      // 4. Perform ECDH & derive symmetric keys
      final Uint8List sharedKeyBytes = _ecdh(ephemeralPublicKey, privateKey);
      final Uint8List derivedKey = _kdf(sharedKeyBytes, ephemeralKeyBytes);

      // 5. Decrypt using AES-GCM (this will throw if MAC check fails/key is wrong)
      final decryptedPayload = _decryptPayload(encData, derivedKey, tag);

      // 6. Decode resulting location payload safely
      final decView = ByteData.sublistView(decryptedPayload);
      final latitude = decView.getUint32(0, Endian.big);
      final longitude = decView.getUint32(4, Endian.big);
      final accuracy = decView.getUint8(8); // Radius in meters!
      final status = decView.getUint8(9);

      int? batteryStatus;
      // STATUS_FLAG_BATTERY_UPDATES_SUPPORT
      if (status & 00100000 != 0 || status > 0) {
        batteryStatus = status >> 6; // 0=OK, 1=Medium, 2=Low, 3=Critical
      } else if (status == 0) {
        batteryStatus = 0; // FindMyFlipper firmware default OK
      }

      final latitudeDec = latitude / 10000000.0;
      final longitudeDec = longitude / 10000000.0;

      return DecryptedLocationModel(
        latitude: latitudeDec,
        longitude: longitudeDec,
        timestamp: timestamp,
        confidence: confidence,
        accuracy: accuracy,
        batteryStatus: batteryStatus,
      );
    } catch (e) {
      // Return null if decryption fails (e.g., wrong key or corrupted packet)
      return null;
    }
  }

  /// Performs an Elliptic Curve Diffie-Hellman with the given keys.
  static Uint8List _ecdh(
    ECPublicKey ephemeralPublicKey,
    ECPrivateKey privateKey,
  ) {
    final sharedKey = ephemeralPublicKey.Q! * privateKey.d;

    final bytes = sharedKey!.x!
        .toBigInteger()!
        .toUnsigned(28 * 8) // Ensure exactly 224 bits
        .toRadixString(16)
        .padLeft(28 * 2, '0');

    return Uint8List.fromList(
      List.generate(
        28,
        (i) => int.parse(bytes.substring(i * 2, i * 2 + 2), radix: 16),
      ),
    );
  }

  /// ANSI X.963 key derivation to calculate the actual advertisement key
  static Uint8List _kdf(Uint8List secret, Uint8List ephemeralKey) {
    var shaDigest = SHA256Digest();
    shaDigest.update(secret, 0, secret.length);

    var counterData = ByteData(4)..setUint32(0, 1);
    var counterDataBytes = counterData.buffer.asUint8List();
    shaDigest.update(counterDataBytes, 0, counterDataBytes.lengthInBytes);

    shaDigest.update(ephemeralKey, 0, ephemeralKey.lengthInBytes);

    Uint8List out = Uint8List(shaDigest.digestSize);
    shaDigest.doFinal(out, 0);

    return out;
  }

  /// Decrypts the cipher text using AES-GCM
  static Uint8List _decryptPayload(
    Uint8List cipherText,
    Uint8List symmetricKey,
    Uint8List tag,
  ) {
    final decryptionKey = symmetricKey.sublist(0, 16);
    final iv = symmetricKey.sublist(16, symmetricKey.length);

    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        false, // false = decryption
        AEADParameters(
          KeyParameter(decryptionKey),
          tag.length * 8,
          iv,
          Uint8List(0),
        ),
      );

    // Provide ciphertext concatenated with the tag to process it correctly in standard GCM block cipher
    final input = Uint8List.fromList([...cipherText, ...tag]);
    return cipher.process(input);
  }
}
