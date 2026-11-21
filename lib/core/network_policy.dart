import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

const maxContentBytes = 10 * 1024 * 1024;

bool isGovernmentUrl(String value) {
  final uri = Uri.tryParse(value.trim());
  return uri != null &&
      uri.scheme == 'https' &&
      uri.port == 443 &&
      uri.userInfo.isEmpty &&
      uri.host.endsWith('.go.id');
}

Uri supabaseOrigin(String value) {
  final uri = Uri.tryParse(value.trim());
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.port != 443 ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment ||
      (uri.path.isNotEmpty && uri.path != '/') ||
      !RegExp(r'^[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.supabase\.co$')
          .hasMatch(uri.host)) {
    throw const FormatException('Gunakan URL HTTPS utama proyek Supabase.');
  }
  return Uri(scheme: 'https', host: uri.host);
}

String publicSupabaseKey(String value) {
  final key = value.trim();
  if (key.length > 4096) throw const FormatException('Public key tidak valid.');
  if (RegExp(r'^sb_publishable_[A-Za-z0-9_-]+$').hasMatch(key)) return key;
  final parts = key.split('.');
  if (parts.length == 3) {
    try {
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (payload is Map<String, dynamic> && payload['role'] == 'anon') {
        return key;
      }
    } catch (_) {
      // Never include the submitted key or token in an error message.
    }
  }
  throw const FormatException(
    'Gunakan publishable/anon key, bukan secret key.',
  );
}

Uri publicContentUri(String value, Uri project) {
  final uri = Uri.tryParse(value);
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host != project.host ||
      uri.port != 443 ||
      uri.userInfo.isNotEmpty ||
      uri.hasFragment ||
      !uri.path.startsWith('/storage/v1/object/public/') ||
      uri.pathSegments.length < 6 ||
      uri.pathSegments.any(
        (s) =>
            s.isEmpty ||
            s == '.' ||
            s == '..' ||
            s.contains('/') ||
            s.contains('\\') ||
            s.contains('\x00'),
      )) {
    throw const FormatException(
      'Paket harus berasal dari storage publik proyek Supabase yang terhubung.',
    );
  }
  return uri;
}

/// Public content receives no Authorization header. Redirects are rejected so
/// an allowed URL cannot forward the request to another host or private LAN.
Future<List<int>> downloadPublicContent(http.Client client, Uri uri) async {
  Future<List<int>> read() async {
    final request = http.Request('GET', uri)..followRedirects = false;
    final response = await client.send(request);
    if (response.statusCode != 200) {
      throw StateError(
        'Paket belum dapat diunduh. Versi sebelumnya tetap tersedia.',
      );
    }
    if ((response.contentLength ?? 0) > maxContentBytes) {
      throw const FormatException('Paket melebihi batas 10 MB.');
    }
    final bytes = <int>[];
    await for (final chunk in response.stream) {
      if (bytes.length + chunk.length > maxContentBytes) {
        throw const FormatException('Paket melebihi batas 10 MB.');
      }
      bytes.addAll(chunk);
    }
    return bytes;
  }

  try {
    return await read().timeout(const Duration(seconds: 30));
  } finally {
    client.close();
  }
}
