import 'dart:convert';
import 'dart:io';

/// Resolves a tunnel domain to the server's geographic coordinates
/// (DNS lookup + IP geolocation), cached per domain. The hero world map
/// uses this so the route points at the real server location instead of
/// a fixed demo city.
class ServerLocationService {
  static final Map<String, ({double lat, double lon})> _cache = {};
  static final Set<String> _pending = {};

  static Future<({double lat, double lon})?> locate(String domain) async {
    final cached = _cache[domain];
    if (cached != null) return cached;
    if (!_pending.add(domain)) return null;
    try {
      final addresses = await InternetAddress.lookup(domain)
          .timeout(const Duration(seconds: 6));
      if (addresses.isEmpty) return null;
      final ip = addresses.first.address;

      final client = HttpClient()
        ..connectionTimeout = const Duration(seconds: 6);
      try {
        final request = await client
            .getUrl(Uri.parse('https://ipwho.is/$ip'))
            .timeout(const Duration(seconds: 6));
        request.headers.set(HttpHeaders.acceptHeader, 'application/json');
        final response =
            await request.close().timeout(const Duration(seconds: 6));
        if (response.statusCode != 200) return null;
        final body = await response.transform(utf8.decoder).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        if (json['success'] != true) return null;
        final lat = (json['latitude'] as num?)?.toDouble();
        final lon = (json['longitude'] as num?)?.toDouble();
        if (lat == null || lon == null) return null;
        final result = (lat: lat, lon: lon);
        _cache[domain] = result;
        return result;
      } finally {
        client.close(force: true);
      }
    } catch (_) {
      return null;
    } finally {
      _pending.remove(domain);
    }
  }
}
