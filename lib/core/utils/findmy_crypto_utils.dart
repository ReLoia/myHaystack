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
 * Heavily refactored and optimized using an LLM to reduce space and execution time.
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

  /// Helper: Decodes a Base64 private key into an ECPrivateKey
  static ECPrivateKey _decodePrivateKey(String privateKeyBase64) =>
      ECPrivateKey(
        pc_utils.decodeBigIntWithSign(1, base64Decode(privateKeyBase64)),
        _curveParams,
      );

  static ECPublicKey _derivePublicKey(ECPrivateKey privateKey) =>
      ECPublicKey(_curveParams.G * privateKey.d, _curveParams);

  static ECPublicKey _getPublicKeyFromBase64(String privateKeyBase64) =>
      _derivePublicKey(_decodePrivateKey(privateKeyBase64));

  static String getHashedPublicKey({
    Uint8List? publicKeyBytes,
    ECPublicKey? publicKey,
  }) {
    final pkBytes = publicKeyBytes ?? publicKey!.Q!.getEncoded(false);
    return base64Encode(SHA256Digest().process(pkBytes));
  }

  /// Derives the hex encoded public key from a base64 private key
  static String getHexPublicKeyFromPrivateKey(String privateKeyBase64) {
    final pkBytes = _getPublicKeyFromBase64(
      privateKeyBase64,
    ).Q!.getEncoded(false);
    return pkBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join('');
  }

  /// Derives the base64 hashed key from a base64 private key
  static String getHashedPublicKeyFromPrivateKey(String privateKeyBase64) {
    return getHashedPublicKey(
      publicKey: _getPublicKeyFromBase64(privateKeyBase64),
    );
  }

  /// Derives the base64 hashed advertisement key from a base64 private key
  static String getHashedAdvKeyFromPrivateKey(String privateKeyBase64) {
    final pkBytes = _getPublicKeyFromBase64(
      privateKeyBase64,
    ).Q!.getEncoded(true);
    return getHashedPublicKey(publicKeyBytes: pkBytes.sublist(1));
  }

  static DecryptedLocationModel? decryptReport(
    LocationReportModel encryptedReport,
    String privateKeyBase64,
  ) {
    try {
      var payloadData = base64Decode(encryptedReport.payload);

      if (payloadData.length > 88) {
        payloadData = Uint8List.fromList([
          ...payloadData.take(4),
          ...payloadData.skip(5),
        ]);
      }

      if (payloadData.length < 88) return null;

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

      // Derive Keys
      final privateKey = _decodePrivateKey(privateKeyBase64);
      final decodePoint = _curveParams.curve.decodePoint(ephemeralKeyBytes);
      final ephemeralPublicKey = ECPublicKey(decodePoint, _curveParams);

      // Perform ECDH & derive symmetric keys
      final derivedKey = _kdf(
        _ecdh(ephemeralPublicKey, privateKey),
        ephemeralKeyBytes,
      );

      // Decrypt using AES-GCM (throws if MAC fails)
      final decryptedPayload = _decryptPayload(encData, derivedKey, tag);

      // Decode resulting location payload safely
      final decView = ByteData.sublistView(decryptedPayload);
      final status = decView.getUint8(9);

      final batteryStatus = (status >> 6) & 0x03;

      return DecryptedLocationModel(
        latitude: decView.getUint32(0, Endian.big) / 10000000.0,
        longitude: decView.getUint32(4, Endian.big) / 10000000.0,
        timestamp: timestamp,
        confidence: confidence,
        accuracy: decView.getUint8(8),
        // 0 - FULL, 1 - MEDIUM, 2 - LOW, 3 - CRITICAL
        batteryStatus: batteryStatus,
      );
    } catch (_) {
      return null;
    }
  }

  /// Performs ECDH. Optimized to skip heavy string parsing conversions.
  static Uint8List _ecdh(
    ECPublicKey ephemeralPublicKey,
    ECPrivateKey privateKey,
  ) {
    final sharedKey = ephemeralPublicKey.Q! * privateKey.d;
    final xBytes = pc_utils.encodeBigInt(sharedKey!.x!.toBigInteger()!);

    // Ensure exactly 28 bytes (224 bits) via native byte manipulation
    final result = Uint8List(28);
    if (xBytes.length > 28) {
      result.setAll(0, xBytes.skip(xBytes.length - 28));
    } else {
      result.setAll(28 - xBytes.length, xBytes);
    }
    return result;
  }

  /// ANSI X.963 key derivation to calculate the actual advertisement key
  static Uint8List _kdf(Uint8List secret, Uint8List ephemeralKey) {
    final counterBytes = (ByteData(4)..setUint32(0, 1)).buffer.asUint8List();
    final input = Uint8List.fromList([
      ...secret,
      ...counterBytes,
      ...ephemeralKey,
    ]);

    return SHA256Digest().process(input);
  }

  /// Decrypts the cipher text using AES-GCM
  static Uint8List _decryptPayload(
    Uint8List cipherText,
    Uint8List symmetricKey,
    Uint8List tag,
  ) {
    final cipher = GCMBlockCipher(AESEngine())
      ..init(
        false,
        AEADParameters(
          KeyParameter(symmetricKey.sublist(0, 16)),
          tag.length * 8,
          symmetricKey.sublist(16),
          Uint8List(0),
        ),
      );

    return cipher.process(Uint8List.fromList([...cipherText, ...tag]));
  }
}
