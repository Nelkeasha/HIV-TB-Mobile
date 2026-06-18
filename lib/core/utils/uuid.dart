import 'dart:math';

/// Generates a random UUID v4 string without pulling in the `uuid` package —
/// used to mint client_request_id values for the offline outbox.
String generateUuidV4() {
  final rand = Random.secure();
  final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
  bytes[6] = (bytes[6] & 0x0F) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3F) | 0x80; // variant 10

  String hex(int start, int end) =>
      bytes.sublist(start, end).map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
}
