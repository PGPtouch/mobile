import 'package:dart_pg/dart_pg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/key_utils.dart';

void main() {
  test("chains public and private keys into one readable stream", () {
    final first = PrivateKey.generate(
      ["A <a@example.net>"],
      "pass",
      type: KeyType.ecc,
      curve: Ecc.secp256r1,
    );
    final second = PrivateKey.generate(
      ["B <b@example.net>"],
      "pass",
      type: KeyType.ecc,
      curve: Ecc.secp256r1,
    );

    final chained = chainKeys([
      first.packetList.encode(),
      second.publicKey.packetList.encode(),
    ]);

    final packets = PacketList.decode(chained).packets.toList();
    expect(
      packets.whereType<SecretKeyPacket>().first.fingerprint,
      first.fingerprint,
    );
    expect(
      packets.where((p) => p.runtimeType == PublicKeyPacket).single,
      isA<PublicKeyPacket>().having(
        (p) => p.fingerprint,
        "fingerprint",
        second.fingerprint,
      ),
    );
    expect(chainKeys([]), isEmpty);
  });
}
