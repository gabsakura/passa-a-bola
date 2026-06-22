import 'dart:convert';
import 'package:http/http.dart' as http;

/// Serviço para resolver problemas de CORS usando proxy
class CorsProxyService {
  // Lista de proxies CORS públicos (pode ser instável)
  static const List<String> _proxyUrls = [
    'https://cors-anywhere.herokuapp.com/',
    'https://api.allorigins.win/raw?url=',
    'https://corsproxy.io/?',
  ];

  /// Faz requisição através de proxy CORS
  static Future<http.Response> get(String url) async {
    // Primeiro tentar requisição direta
    try {
      final response = await http
          .get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return response;
      }
    } catch (e) {
      print('DEBUG: Requisição direta falhou: $e');
    }

    // Se falhou, tentar com proxies
    for (String proxyUrl in _proxyUrls) {
      try {
        String proxiedUrl = '$proxyUrl${Uri.encodeComponent(url)}';
        print('DEBUG: Tentando proxy: $proxiedUrl');

        final response = await http
            .get(
              Uri.parse(proxiedUrl),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          print('DEBUG: Proxy funcionou: $proxyUrl');
          return response;
        }
      } catch (e) {
        print('DEBUG: Proxy $proxyUrl falhou: $e');
      }
    }

    throw Exception('Todos os proxies CORS falharam');
  }

  /// Faz requisição POST através de proxy CORS
  static Future<http.Response> post(
    String url, {
    Map<String, dynamic>? body,
  }) async {
    // Primeiro tentar requisição direta
    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: body != null ? json.encode(body) : null,
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return response;
      }
    } catch (e) {
      print('DEBUG: Requisição POST direta falhou: $e');
    }

    // Se falhou, tentar com proxies
    for (String proxyUrl in _proxyUrls) {
      try {
        String proxiedUrl = '$proxyUrl${Uri.encodeComponent(url)}';
        print('DEBUG: Tentando proxy POST: $proxiedUrl');

        final response = await http
            .post(
              Uri.parse(proxiedUrl),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
              body: body != null ? json.encode(body) : null,
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          print('DEBUG: Proxy POST funcionou: $proxyUrl');
          return response;
        }
      } catch (e) {
        print('DEBUG: Proxy POST $proxyUrl falhou: $e');
      }
    }

    throw Exception('Todos os proxies CORS falharam');
  }
}
