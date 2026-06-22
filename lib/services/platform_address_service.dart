import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/google_maps_config.dart';
import 'cors_proxy_service.dart';

/// Serviço de endereços que funciona em todas as plataformas
class PlatformAddressService {
  /// Detecta se está rodando na web
  static bool get isWeb => kIsWeb;

  /// Detecta se está rodando no Android
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  /// Detecta se está rodando no iOS
  static bool get isIOS => !kIsWeb && Platform.isIOS;

  /// Obtém sugestões de endereços baseado na plataforma
  static Future<List<String>> getAddressSuggestions(
    String partialAddress,
  ) async {
    print('DEBUG: Obtendo sugestões para: $partialAddress');
    print('DEBUG: Plataforma - Web: $isWeb, Android: $isAndroid, iOS: $isIOS');

    if (partialAddress.trim().isEmpty) return [];

    try {
      if (isWeb) {
        // Para web, usar apenas geocoding (mais confiável)
        return await _getWebSuggestions(partialAddress);
      } else {
        // Para mobile, tentar Google Places API primeiro
        return await _getMobileSuggestions(partialAddress);
      }
    } catch (e) {
      print('DEBUG: Erro ao obter sugestões: $e');
      return _getFallbackSuggestions(partialAddress);
    }
  }

  /// Valida endereço baseado na plataforma
  static Future<AddressValidationResult> validateAddress(String address) async {
    print('DEBUG: Validando endereço: $address');

    try {
      if (isWeb) {
        return await _validateWebAddress(address);
      } else {
        return await _validateMobileAddress(address);
      }
    } catch (e) {
      print('DEBUG: Erro na validação: $e');
      return AddressValidationResult(
        isValid: false,
        error: 'Erro na validação: $e',
        formattedAddress: address,
        latitude: 0.0,
        longitude: 0.0,
      );
    }
  }

  /// Sugestões para web (apenas geocoding)
  static Future<List<String>> _getWebSuggestions(String partialAddress) async {
    print('DEBUG: Usando método web (geocoding)');

    try {
      String searchAddress = partialAddress.trim();
      if (!searchAddress.toLowerCase().contains('são paulo') &&
          !searchAddress.toLowerCase().contains('sao paulo')) {
        searchAddress = '$searchAddress, São Paulo, SP, Brasil';
      }

      List<Location> locations = await locationFromAddress(searchAddress);
      List<String> suggestions = [];

      for (int i = 0; i < locations.length && i < 5; i++) {
        try {
          Location location = locations[i];

          if (location.latitude == 0.0 && location.longitude == 0.0) {
            continue;
          }

          List<Placemark> placemarks = await placemarkFromCoordinates(
            location.latitude,
            location.longitude,
          );

          if (placemarks.isNotEmpty) {
            String formattedAddress = _buildFormattedAddress(placemarks.first);
            if (formattedAddress.isNotEmpty &&
                !suggestions.contains(formattedAddress)) {
              suggestions.add(formattedAddress);
            }
          }
        } catch (e) {
          print('DEBUG: Erro ao processar sugestão $i: $e');
          continue;
        }
      }

      print('DEBUG: Web retornou ${suggestions.length} sugestões');
      return suggestions;
    } catch (e) {
      print('DEBUG: Erro no geocoding web: $e');
      return _getFallbackSuggestions(partialAddress);
    }
  }

  /// Sugestões para mobile (Google Places + geocoding)
  static Future<List<String>> _getMobileSuggestions(
    String partialAddress,
  ) async {
    print('DEBUG: Usando método mobile (Google Places + geocoding)');

    try {
      // Primeiro tentar Google Places API
      List<String> googleSuggestions = await _getGooglePlacesSuggestions(
        partialAddress,
      );

      if (googleSuggestions.isNotEmpty) {
        print(
          'DEBUG: Google Places retornou ${googleSuggestions.length} sugestões',
        );
        return googleSuggestions.take(5).toList();
      }

      // Se Google Places falhar, usar geocoding
      print('DEBUG: Google Places falhou, tentando geocoding...');
      return await _getWebSuggestions(partialAddress);
    } catch (e) {
      print('DEBUG: Erro no método mobile: $e');
      return _getFallbackSuggestions(partialAddress);
    }
  }

  /// Google Places API (com suporte a CORS para web)
  static Future<List<String>> _getGooglePlacesSuggestions(
    String partialAddress,
  ) async {
    try {
      String apiKey = GoogleMapsConfig.apiKey;
      if (apiKey.isEmpty) {
        print('DEBUG: Chave da API não configurada');
        return [];
      }

      String cleanAddress = partialAddress.trim();
      if (!cleanAddress.toLowerCase().contains('são paulo') &&
          !cleanAddress.toLowerCase().contains('sao paulo')) {
        cleanAddress = '$cleanAddress, São Paulo, SP, Brasil';
      }

      String encodedAddress = Uri.encodeComponent(cleanAddress);
      String url =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$encodedAddress&key=$apiKey&components=country:br&types=establishment|geocode';

      print('DEBUG: Buscando na Google Places API: $url');

      http.Response response;

      if (isWeb) {
        // Para web, usar proxy CORS
        try {
          response = await CORSProxyService.getWithCORS(url);
        } catch (e) {
          print('DEBUG: Proxy CORS falhou, tentando requisição direta: $e');
          response = await http
              .get(
                Uri.parse(url),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              )
              .timeout(const Duration(seconds: 10));
        }
      } else {
        // Para mobile, requisição direta
        response = await http
            .get(
              Uri.parse(url),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
            )
            .timeout(const Duration(seconds: 10));
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['predictions'] != null) {
          List<String> suggestions = [];

          for (var prediction in data['predictions']) {
            String description = prediction['description'] ?? '';
            if (description.isNotEmpty && !suggestions.contains(description)) {
              suggestions.add(description);
            }
          }

          print(
            'DEBUG: Google Places retornou ${suggestions.length} sugestões',
          );
          return suggestions.take(5).toList();
        } else {
          print('DEBUG: Google Places retornou status: ${data['status']}');
        }
      } else {
        print('DEBUG: Erro HTTP na Google Places API: ${response.statusCode}');
      }

      return [];
    } catch (e) {
      print('DEBUG: Erro na Google Places API: $e');
      return [];
    }
  }

  /// Validação para web
  static Future<AddressValidationResult> _validateWebAddress(
    String address,
  ) async {
    try {
      String searchAddress = address.trim();
      if (!searchAddress.toLowerCase().contains('são paulo') &&
          !searchAddress.toLowerCase().contains('sao paulo')) {
        searchAddress = '$searchAddress, São Paulo, SP, Brasil';
      }

      List<Location> locations = await locationFromAddress(searchAddress);

      if (locations.isNotEmpty) {
        Location location = locations.first;

        if (location.latitude == 0.0 && location.longitude == 0.0) {
          return AddressValidationResult(
            isValid: false,
            error: 'Coordenadas inválidas',
            formattedAddress: address,
            latitude: 0.0,
            longitude: 0.0,
          );
        }

        List<Placemark> placemarks = await placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        );

        String formattedAddress = address;
        String? city;
        String? state;
        String? country;

        if (placemarks.isNotEmpty) {
          formattedAddress = _buildFormattedAddress(placemarks.first);
          city = placemarks.first.locality;
          state = placemarks.first.administrativeArea;
          country = placemarks.first.country;
        }

        return AddressValidationResult(
          isValid: true,
          formattedAddress: formattedAddress,
          latitude: location.latitude,
          longitude: location.longitude,
          city: city,
          state: state,
          country: country,
        );
      }

      return AddressValidationResult(
        isValid: false,
        error: 'Endereço não encontrado',
        formattedAddress: address,
        latitude: 0.0,
        longitude: 0.0,
      );
    } catch (e) {
      return AddressValidationResult(
        isValid: false,
        error: 'Erro na validação: $e',
        formattedAddress: address,
        latitude: 0.0,
        longitude: 0.0,
      );
    }
  }

  /// Validação para mobile
  static Future<AddressValidationResult> _validateMobileAddress(
    String address,
  ) async {
    // Para mobile, usar o mesmo método da web por enquanto
    // Pode ser expandido para usar Google Places API se necessário
    return await _validateWebAddress(address);
  }

  /// Sugestões de fallback
  static List<String> _getFallbackSuggestions(String partialAddress) {
    print('DEBUG: Usando sugestões de fallback para: $partialAddress');

    final lowerPartial = partialAddress.toLowerCase().trim();
    List<String> suggestions = [];

    if (lowerPartial.isEmpty) return [];

    final commonAddresses = [
      'Rua Augusta, Consolação, São Paulo, SP, Brasil',
      'Avenida Paulista, Bela Vista, São Paulo, SP, Brasil',
      'Rua Oscar Freire, Jardins, São Paulo, SP, Brasil',
      'Avenida Faria Lima, Itaim Bibi, São Paulo, SP, Brasil',
      'Rua da Consolação, Consolação, São Paulo, SP, Brasil',
      'Avenida Rebouças, Pinheiros, São Paulo, SP, Brasil',
      'Rua Teodoro Sampaio, Pinheiros, São Paulo, SP, Brasil',
      'Avenida 9 de Julho, Bela Vista, São Paulo, SP, Brasil',
      'Rua Bela Cintra, Jardins, São Paulo, SP, Brasil',
      'Avenida Higienópolis, Higienópolis, São Paulo, SP, Brasil',
    ];

    for (String address in commonAddresses) {
      if (address.toLowerCase().contains(lowerPartial)) {
        suggestions.add(address);
      }
    }

    if (suggestions.isNotEmpty) {
      print(
        'DEBUG: Fallback retornou ${suggestions.length} sugestões específicas',
      );
      return suggestions.take(5).toList();
    }

    print('DEBUG: Nenhuma sugestão de fallback encontrada');
    return [];
  }

  /// Constrói endereço formatado
  static String _buildFormattedAddress(Placemark place) {
    List<String> parts = [];

    String? street = place.street;
    String? number = place.subThoroughfare;
    String? thoroughfare = place.thoroughfare;

    if (street != null && street.isNotEmpty) {
      if (number != null && number.isNotEmpty) {
        parts.add('$street, $number');
      } else {
        parts.add(street);
      }
    } else if (thoroughfare != null && thoroughfare.isNotEmpty) {
      if (number != null && number.isNotEmpty) {
        parts.add('$thoroughfare, $number');
      } else {
        parts.add(thoroughfare);
      }
    }

    if (place.subLocality != null && place.subLocality!.isNotEmpty) {
      parts.add(place.subLocality!);
    }

    if (place.locality != null && place.locality!.isNotEmpty) {
      parts.add(place.locality!);
    }

    if (place.administrativeArea != null &&
        place.administrativeArea!.isNotEmpty) {
      parts.add(place.administrativeArea!);
    }

    if (place.country != null && place.country!.isNotEmpty) {
      parts.add(place.country!);
    }

    if (parts.isEmpty) {
      if (place.locality != null && place.locality!.isNotEmpty) {
        parts.add(place.locality!);
      }
      if (place.administrativeArea != null &&
          place.administrativeArea!.isNotEmpty) {
        parts.add(place.administrativeArea!);
      }
      if (place.country != null && place.country!.isNotEmpty) {
        parts.add(place.country!);
      }
    }

    return parts.join(', ');
  }
}

/// Resultado da validação de endereço
class AddressValidationResult {
  final bool isValid;
  final String? error;
  final String formattedAddress;
  final double? latitude;
  final double? longitude;
  final String? city;
  final String? state;
  final String? country;

  AddressValidationResult({
    required this.isValid,
    this.error,
    required this.formattedAddress,
    this.latitude,
    this.longitude,
    this.city,
    this.state,
    this.country,
  });
}
