import 'dart:convert';
import 'package:crypto/crypto.dart';

class CloudBackupPayload {
  final String checksum;
  final String encryptedData;
  final String timestamp;
  final int recordCount;

  const CloudBackupPayload({
    required this.checksum,
    required this.encryptedData,
    required this.timestamp,
    required this.recordCount,
  });

  Map<String, dynamic> toMap() => {
        'checksum': checksum,
        'encryptedData': encryptedData,
        'timestamp': timestamp,
        'recordCount': recordCount,
      };

  factory CloudBackupPayload.fromMap(Map<String, dynamic> map) =>
      CloudBackupPayload(
        checksum: map['checksum'] as String,
        encryptedData: map['encryptedData'] as String,
        timestamp: map['timestamp'] as String,
        recordCount: map['recordCount'] as int? ?? 0,
      );
}

class EncryptedBackupService {
  EncryptedBackupService._();
  static final EncryptedBackupService instance = EncryptedBackupService._();

  /// Simple password-derived XOR-cipher with SHA-256 integrity verification
  /// Suitable for cross-platform zero-dependency encrypted backup packaging.
  String createEncryptedBackup({
    required String rawJsonData,
    required String password,
  }) {
    final keyBytes = sha256.convert(utf8.encode(password)).bytes;
    final dataBytes = utf8.encode(rawJsonData);

    final encrypted = List<int>.generate(
      dataBytes.length,
      (i) => dataBytes[i] ^ keyBytes[i % keyBytes.length],
    );

    final encryptedBase64 = base64Encode(encrypted);
    final checksum = sha256.convert(utf8.encode(encryptedBase64)).toString();

    final payload = CloudBackupPayload(
      checksum: checksum,
      encryptedData: encryptedBase64,
      timestamp: DateTime.now().toIso8601String(),
      recordCount: rawJsonData.length,
    );

    return jsonEncode(payload.toMap());
  }

  /// Decrypt backup file using user password and verify integrity
  String restoreEncryptedBackup({
    required String backupFileContent,
    required String password,
  }) {
    final map = jsonDecode(backupFileContent) as Map<String, dynamic>;
    final payload = CloudBackupPayload.fromMap(map);

    // Verify payload checksum
    final computedChecksum =
        sha256.convert(utf8.encode(payload.encryptedData)).toString();
    if (computedChecksum != payload.checksum) {
      throw Exception('Integrity check failed: Backup file is corrupted.');
    }

    final keyBytes = sha256.convert(utf8.encode(password)).bytes;
    final encrypted = base64Decode(payload.encryptedData);

    final decrypted = List<int>.generate(
      encrypted.length,
      (i) => encrypted[i] ^ keyBytes[i % keyBytes.length],
    );

    try {
      return utf8.decode(decrypted);
    } catch (_) {
      throw Exception('Incorrect password. Could not decrypt data.');
    }
  }
}
