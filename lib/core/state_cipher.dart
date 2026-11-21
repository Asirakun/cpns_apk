import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Authenticated encryption for persisted progress. The account namespace is
/// authenticated too, so a database row cannot be moved to another account.
class StateCipher {
  StateCipher({required this.keyProvider});
  StateCipher.forDevice() : keyProvider = _deviceKey;

  static const prefix = 'cpns.enc.v1:';
  static final device = StateCipher.forDevice();
  static final _algorithm = AesGcm.with256bits();
  static const _storage = FlutterSecureStorage();
  static const _keyName = 'cpns-state-key-v1';

  final Future<SecretKey> Function(bool create) keyProvider;
  Future<SecretKey>? _cachedKey;

  static Future<SecretKey> _deviceKey(bool create) async {
    final saved = await _storage.read(key: _keyName);
    if (saved != null) {
      final bytes = base64Decode(saved);
      if (bytes.length != 32) {
        throw StateError('Kunci penyimpanan tidak valid.');
      }
      return SecretKey(bytes);
    }
    if (!create) {
      throw StateError('Kunci penyimpanan tidak tersedia. Data tidak dihapus.');
    }
    final key = await _algorithm.newSecretKey();
    await _storage.write(
      key: _keyName,
      value: base64Encode(await key.extractBytes()),
    );
    return key;
  }

  Future<String> encrypt(String namespace, String plaintext) async {
    final key = await (_cachedKey ??= keyProvider(true));
    final box = await _algorithm.encrypt(
      utf8.encode(plaintext),
      secretKey: key,
      aad: utf8.encode(namespace),
    );
    return '$prefix${base64Encode(box.concatenation())}';
  }

  Future<String> decrypt(String namespace, String payload) async {
    if (!payload.startsWith(prefix)) {
      throw const FormatException('Format enkripsi tidak didukung.');
    }
    final box = SecretBox.fromConcatenation(
      base64Decode(payload.substring(prefix.length)),
      nonceLength: 12,
      macLength: 16,
    );
    final key = await (_cachedKey ??= keyProvider(false));
    return utf8.decode(
      await _algorithm.decrypt(
        box,
        secretKey: key,
        aad: utf8.encode(namespace),
      ),
    );
  }
}
