import 'dart:convert';
import 'dart:typed_data';

import 'package:dart_pg/dart_pg.dart';
// not publicly exposed
// ignore: implementation_imports
import 'package:dart_pg/src/enum/revocation_reason_tag.dart';
import 'package:shared/shared.dart';

import 'l10n/app_localizations.dart';

/// Human readable name of the source a key was fetched from.
///
/// Returns the title plus whether the source is a keyserver that verifies
/// key identities.
({String title, bool keyIdentitiesVerifies}) keyFetchSourceTitle(
  AppLocalizations appLocalizations, {
  required UserIdKeyFetchOrigin? origin,
  required String? originHost,
}) {
  var title = switch (origin) {
    .webKeyDirectoryAdvanced =>
      appLocalizations.keyFetchOriginWebKeyDirectoryAdvanced,
    .webKeyDirectoryDirect =>
      appLocalizations.keyFetchOriginWebKeyDirectoryDirect,
    .hkpKeyServer => appLocalizations.keyFetchOriginHkpKeyServer,
    null => originHost ?? "",
  };
  var keyIdentitiesVerifies = false;
  final hostParts = originHost?.split("|");
  if (hostParts != null && hostParts.length == 3) {
    title = appLocalizations.keyFetchKeyserverTitle(hostParts[1]);
    keyIdentitiesVerifies = hostParts[2] == "true";
  }
  return (title: title, keyIdentitiesVerifies: keyIdentitiesVerifies);
}

/// Expiration of [key], or null if it never expires.
///
/// dart_pg only looks at self-signatures of user IDs flagged as primary, so
/// keys without that flag (e.g. from `gpg --quick-generate-key`) would
/// otherwise be reported as non-expiring.
DateTime? keyExpirationTime(PublicKey key) {
  var candidates = key.directSignatures.toList();
  if (candidates.isEmpty) {
    final primaryUsers = key.users.where((u) => u.isPrimary).toList();
    candidates = [
      for (final user in primaryUsers.isEmpty ? key.users : primaryUsers)
        ...user.selfSignatures,
    ];
  }
  if (candidates.isEmpty) return null;
  candidates.sort((a, b) => b.creationTime.compareTo(a.creationTime));
  final newest = candidates.first;
  if (newest.keyExpirationTime <= 0) return null;
  return newest.creationTime.add(Duration(seconds: newest.keyExpirationTime));
}

/// Verified key revocation signatures for [key] found in [sources].
///
/// dart_pg drops key revocation signatures (type 0x20) when parsing a key, so
/// they have to be read from the raw packets.
List<SignaturePacket> keyRevocations(
  BaseKey key,
  Iterable<PacketList> sources,
) {
  final keyPacket = key.publicKey.keyPacket;
  final seen = <String>{};
  final result = <SignaturePacket>[];
  for (final source in sources) {
    for (final packet in source.packets.whereType<SignaturePacket>()) {
      if (!packet.isKeyRevocation) continue;
      try {
        if (!packet.verify(keyPacket, keyPacket.signBytes)) continue;
      } catch (_) {
        continue;
      }
      if (seen.add(base64Encode(packet.encode()))) result.add(packet);
    }
  }
  return result;
}

/// Reason given in the newest valid key revocation of the framed public key
/// [data], or null if the key is not revoked.
///
/// [RevocationReasonTag] is null for codes dart_pg doesn't know and
/// [String] is empty when no description was given.
({RevocationReasonTag? tag, String description})? publicKeyRevocationReason(
  Uint8List data,
) {
  final packets = PacketList.decode(data);
  final revocations = keyRevocations(PublicKey(packets), [packets]).toList()
    ..sort((a, b) => b.creationTime.compareTo(a.creationTime));
  if (revocations.isEmpty) return null;

  final bytes = revocations.first.getSubpacket<RevocationReason>()?.data;
  if (bytes == null || bytes.isEmpty) {
    return (tag: RevocationReasonTag.noReason, description: "");
  }
  final tag = RevocationReasonTag.values
      .where((t) => t.value == bytes[0])
      .firstOrNull;
  return (
    tag: tag,
    description: utf8.decode(bytes.sublist(1), allowMalformed: true),
  );
}

/// Encodes the public or private [key] without losing key revocation
/// signatures found in [sources].
Uint8List encodeKey(BaseKey key, Iterable<PacketList> sources) {
  final packets = key.packetList.packets.toList()
    ..insertAll(1, keyRevocations(key, sources));
  return PacketList(packets).encode();
}

/// Whether the framed public key [data] carries a valid key revocation.
bool isPublicKeyDataRevoked(Uint8List data) {
  final packets = PacketList.decode(data);
  return keyRevocations(PublicKey(packets), [packets]).isNotEmpty;
}

/// Corrects the revoked/expired state of a fetched key.
///
/// The fetch result is computed from the dart_pg parse, which misses key
/// revocations and expirations set on non-primary user IDs.
UserIdKeyFetchKey correctFetchedKeyState(UserIdKeyFetchKey fetched) {
  try {
    final packets = PacketList.decode(fetched.bytes);
    final key = PublicKey(packets);
    final isRevoked =
        fetched.isRevoked || keyRevocations(key, [packets]).isNotEmpty;
    final expiration = keyExpirationTime(key);
    final isExpired =
        fetched.isExpired ||
        (expiration != null && expiration.isBefore(DateTime.now()));
    return (
      bytes: fetched.bytes,
      fingerprint: fetched.fingerprint,
      isValid: fetched.isValid && !isRevoked && !isExpired,
      isExpired: isExpired,
      isRevoked: isRevoked,
      isUnreadable: fetched.isUnreadable,
    );
  } catch (_) {
    return fetched;
  }
}

/// Concatenates the framed [keys] into a single binary stream.
Uint8List chainKeys(List<Uint8List> keys) {
  final builder = BytesBuilder(copy: false);
  keys.forEach(builder.add);
  return builder.takeBytes();
}
