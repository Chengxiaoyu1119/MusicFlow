import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';

/// AES-256-GCM encryption for plugin files.
///
/// Encrypts external JS plugin files when stored on disk,
/// protecting user-provided plugin configurations.
class PluginEncryption {
  static const int _keyLength = 32; // AES-256
  static const String _appKeyTag = 'musicflow_plugin_key_v1';

  encrypt.Key? _key;
  bool _initialized = false;

  /// Initialize or load the encryption key.
  Future<void> init() async {
    if (_initialized) return;

    // Generate a device-specific key based on a stable identifier
    // In production, derive from platform-specific secure storage
    final seed = await _getDeviceSeed();
    _key = _deriveKey(seed);
    _initialized = true;
  }

  /// Encrypt a plugin JS file.
  Future<bool> encryptFile(String filePath) async {
    if (!_initialized) await init();

    try {
      final file = File(filePath);
      if (!await file.exists()) return false;

      final content = await file.readAsString();
      final encrypted = encryptContent(content);

      // Save encrypted content with a marker header
      await file.writeAsString('__MELODYFLOW_ENC_V1__$encrypted');
      return true;
    } catch (e) {
      debugPrint('Failed to encrypt plugin file: $e');
      return false;
    }
  }

  /// Decrypt a plugin JS file.
  Future<String?> decryptFile(String filePath) async {
    if (!_initialized) await init();

    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final content = await file.readAsString();

      // Check if file is encrypted
      if (!content.startsWith('__MELODYFLOW_ENC_V1__')) {
        return content; // Not encrypted, return as-is
      }

      final encrypted = content.substring('__MELODYFLOW_ENC_V1__'.length);
      return decryptContent(encrypted);
    } catch (e) {
      debugPrint('Failed to decrypt plugin file: $e');
      return null;
    }
  }

  /// Encrypt a plain text string.
  String encryptContent(String plainText) {
    if (_key == null) return plainText;

    try {
      final iv = encrypt.IV.fromLength(12); // 96-bit IV for GCM
      final encrypter = encrypt.Encrypter(
        encrypt.AES(_key!, mode: encrypt.AESMode.gcm, padding: null),
      );
      final encrypted = encrypter.encrypt(plainText, iv: iv);
      return '${base64Url.encode(iv.bytes)}:${base64Url.encode(encrypted.bytes)}';
    } catch (e) {
      debugPrint('Encryption error: $e');
      return plainText;
    }
  }

  /// Decrypt an encrypted string (format: "base64iv:base64data").
  String? decryptContent(String encryptedText) {
    if (_key == null) return null;

    try {
      final parts = encryptedText.split(':');
      if (parts.length != 2) return null;

      final ivBytes = base64Url.decode(parts[0]);
      final encryptedBytes = base64Url.decode(parts[1]);

      final encrypter = encrypt.Encrypter(
        encrypt.AES(_key!, mode: encrypt.AESMode.gcm, padding: null),
      );
      final decrypted = encrypter.decrypt(
        encrypt.Encrypted(encryptedBytes),
        iv: encrypt.IV(Uint8List.fromList(ivBytes)),
      );
      return decrypted;
    } catch (e) {
      debugPrint('Decryption error: $e');
      return null;
    }
  }

  /// Generate a stable device-specific seed.
  Future<String> _getDeviceSeed() async {
    // Combine platform-specific identifiers
    final parts = <String>[
      _appKeyTag,
      Platform.operatingSystem,
      Platform.localHostname,
    ];
    return parts.join('|');
  }

  /// Derive a 256-bit key from a seed string using SHA-256.
  encrypt.Key _deriveKey(String seed) {
    final bytes = utf8.encode(seed);
    final hash = crypto.sha256.convert(bytes);
    return encrypt.Key(Uint8List.fromList(hash.bytes.sublist(0, _keyLength)));
  }
}
