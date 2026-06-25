/// Standard geohash encoder (base32, no a/i/l/o). Precision 7 gives a cell
/// roughly 150m × 150m — enough for CHW catchment-area matching without
/// revealing a patient's exact household location. The app must never send
/// raw latitude/longitude to the server; only the encoded string leaves the
/// device.
const String _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

String encodeGeohash(double latitude, double longitude, {int precision = 7}) {
  double latMin = -90.0, latMax = 90.0;
  double lonMin = -180.0, lonMax = 180.0;
  final buffer = StringBuffer();
  bool evenBit = true;
  int bit = 0;
  int charBits = 0;

  while (buffer.length < precision) {
    if (evenBit) {
      final mid = (lonMin + lonMax) / 2;
      if (longitude >= mid) {
        charBits = (charBits << 1) | 1;
        lonMin = mid;
      } else {
        charBits = charBits << 1;
        lonMax = mid;
      }
    } else {
      final mid = (latMin + latMax) / 2;
      if (latitude >= mid) {
        charBits = (charBits << 1) | 1;
        latMin = mid;
      } else {
        charBits = charBits << 1;
        latMax = mid;
      }
    }
    evenBit = !evenBit;

    if (++bit == 5) {
      buffer.write(_base32[charBits]);
      bit = 0;
      charBits = 0;
    }
  }
  return buffer.toString();
}
