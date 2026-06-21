import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class KeyStorageService {
  final _storage = const FlutterSecureStorage();

  Future<void> savePrivateKey(String publicKey, String privateKey) async {
    await _storage.write(key: 'priv_$publicKey', value: privateKey);
  }

  Future<String?> getPrivateKey(String publicKey) async {
    return await _storage.read(key: 'priv_$publicKey');
  }

  Future<void> deletePrivateKey(String publicKey) async {
    await _storage.delete(key: 'priv_$publicKey');
  }
}
