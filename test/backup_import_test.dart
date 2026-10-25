import 'package:dart_pg/dart_pg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/components/backup_code_input.dart';

void main() {
  const code = "TWNK-KD5Y-MT3T-E1GS-DRDB-KVTW";

  late String backup;
  late PrivateKey key;

  setUpAll(() async {
    key = PrivateKey.generate(
      ["Test <test@example.net>"],
      "pass",
      type: KeyType.ecc,
      curve: Ecc.secp256r1,
    );
    backup = OpenPGP.encryptCleartext(
      key.armor(),
      passwords: [code],
    ).armor().replaceFirst("\n\n", "\nBackupVersion: 2\n\n");
  });

  test("detects backup files", () {
    expect(isBackupText(backup), isTrue);
    expect(isBackupText(backup.replaceAll("\n", "\r\n")), isTrue);
    expect(isBackupText(key.armor()), isFalse);
    expect(
      isBackupText(backup.replaceFirst("BackupVersion: 2", "Comment: x")),
      isFalse,
    );
  });

  test("decrypts with the right code only", () async {
    final data = await decryptBackup(backup, code);
    expect(data, isNotNull);
    expect(String.fromCharCodes(data!), contains("BEGIN PGP PRIVATE KEY"));
    expect(
      await decryptBackup(backup, "AAAA-AAAA-AAAA-AAAA-AAAA-AAAA"),
      isNull,
    );
  });

  test("decrypts binary key packets like OpenKeychain produces", () async {
    final binary = OpenPGP.encryptBinaryData(
      key.packetList.encode(),
      passwords: [code],
    ).armor().replaceFirst("\n\n", "\nBackupVersion: 2\n\n");
    final data = await decryptBackup(binary, code);
    expect(data, key.packetList.encode());
  });
}
