import 'dart:convert';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import '../config/google_maps_config.dart';

/// Serviço de endereços baseado no que funciona no scout_marker
class WorkingAddressService {
  /// Obtém sugestões de endereços (baseado no scout_marker)
  static Future<List<String>> getAddressSuggestions(
    String partialAddress,
  ) async {
    print('DEBUG: Obtendo sugestões para: $partialAddress');

    if (partialAddress.trim().isEmpty) return [];

    try {
      // Usar a mesma lógica do scout_marker
      String cleanAddress = _cleanAddress(partialAddress);
      List<String> variations = _generateAddressVariations(cleanAddress);

      List<String> suggestions = [];

      // Testar cada variação para obter sugestões
      for (String variation in variations.take(3)) {
        // Limitar a 3 para performance
        try {
          List<Location> locations = await locationFromAddress(
            variation,
            localeIdentifier: 'pt_BR',
          );

          if (locations.isNotEmpty) {
            Location location = locations.first;

            // Verificar se as coordenadas são válidas
            if (location.latitude != 0.0 && location.longitude != 0.0) {
              // Obter endereço formatado
              List<Placemark> placemarks = await placemarkFromCoordinates(
                location.latitude,
                location.longitude,
              );

              if (placemarks.isNotEmpty) {
                String formattedAddress = _buildFormattedAddress(
                  placemarks.first,
                );
                if (formattedAddress.isNotEmpty &&
                    !suggestions.contains(formattedAddress)) {
                  suggestions.add(formattedAddress);
                }
              }
            }
          }
        } catch (e) {
          print('DEBUG: Erro ao processar variação $variation: $e');
          continue;
        }
      }

      // Se não conseguiu sugestões suficientes, tentar Google Places API
      if (suggestions.length < 3) {
        List<String> googleSuggestions = await _getGooglePlacesSuggestions(
          partialAddress,
        );
        for (String suggestion in googleSuggestions) {
          if (!suggestions.contains(suggestion)) {
            suggestions.add(suggestion);
          }
        }
      }

      print('DEBUG: ${suggestions.length} sugestões encontradas');
      return suggestions.take(5).toList();
    } catch (e) {
      print('DEBUG: Erro ao obter sugestões: $e');
      return _getFallbackSuggestions(partialAddress);
    }
  }

  /// Valida endereço (baseado no scout_marker)
  static Future<AddressValidationResult> validateAddress(String address) async {
    print('DEBUG: Validando endereço: $address');

    try {
      if (address.trim().isEmpty) {
        return AddressValidationResult(
          isValid: false,
          error: 'Endereço não pode estar vazio',
          formattedAddress: address,
          latitude: 0.0,
          longitude: 0.0,
        );
      }

      // Usar a mesma lógica do scout_marker
      String cleanAddress = _cleanAddress(address);
      List<String> variations = _generateAddressVariations(cleanAddress);

      // Tentar cada variação
      for (String variation in variations) {
        try {
          List<Location> locations = await locationFromAddress(
            variation,
            localeIdentifier: 'pt_BR',
          );

          if (locations.isNotEmpty) {
            Location location = locations.first;

            // Verificar se as coordenadas são válidas
            if (location.latitude == 0.0 && location.longitude == 0.0) {
              continue; // Tentar próxima variação
            }

            // Obter detalhes do endereço
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

            print('DEBUG: Endereço válido encontrado: $formattedAddress');
            print(
              'DEBUG: Coordenadas: ${location.latitude}, ${location.longitude}',
            );

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
        } catch (e) {
          print('DEBUG: Erro na variação $variation: $e');
          continue;
        }
      }

      // Se geocoding falhou, tentar Google Places API
      Map<String, double>? googleResult = await _tryGooglePlacesAPI(
        cleanAddress,
      );
      if (googleResult != null) {
        return AddressValidationResult(
          isValid: true,
          formattedAddress: address,
          latitude: googleResult['latitude']!,
          longitude: googleResult['longitude']!,
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
      print('DEBUG: Erro ao validar endereço: $e');
      return AddressValidationResult(
        isValid: false,
        error: 'Erro na validação: $e',
        formattedAddress: address,
        latitude: 0.0,
        longitude: 0.0,
      );
    }
  }

  /// Limpa e normaliza o endereço (igual ao scout_marker)
  static String _cleanAddress(String address) {
    String cleaned = address.trim();

    // Adicionar "São Paulo, SP, Brasil" se não estiver presente
    if (!cleaned.toLowerCase().contains('são paulo') &&
        !cleaned.toLowerCase().contains('sao paulo')) {
      cleaned = '$cleaned, São Paulo, SP, Brasil';
    }

    return cleaned;
  }

  /// Gera variações do endereço (igual ao scout_marker)
  static List<String> _generateAddressVariations(String address) {
    List<String> variations = [address];

    // Variações comuns
    String lowerAddress = address.toLowerCase();

    if (lowerAddress.contains('rua ')) {
      variations.add(address.replaceAll('rua ', 'Rua '));
      variations.add(address.replaceAll('rua ', 'R. '));
    }

    if (lowerAddress.contains('avenida ')) {
      variations.add(address.replaceAll('avenida ', 'Avenida '));
      variations.add(address.replaceAll('avenida ', 'Av. '));
    }

    if (lowerAddress.contains('r. ')) {
      variations.add(address.replaceAll('r. ', 'Rua '));
    }

    if (lowerAddress.contains('av. ')) {
      variations.add(address.replaceAll('av. ', 'Avenida '));
    }

    return variations;
  }

  /// Google Places API (igual ao scout_marker)
  static Future<Map<String, double>?> _tryGooglePlacesAPI(
    String address,
  ) async {
    try {
      String apiKey = GoogleMapsConfig.apiKey;
      if (apiKey.isEmpty) {
        print('DEBUG: Chave da API não configurada');
        return null;
      }

      String encodedAddress = Uri.encodeComponent(address);
      String url =
          'https://maps.googleapis.com/maps/api/geocode/json?address=$encodedAddress&key=$apiKey&region=br';

      print('DEBUG: Tentando Google Places API: $url');

      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'OK' && data['results'].isNotEmpty) {
          final result = data['results'][0];
          final location = result['geometry']['location'];

          print(
            'DEBUG: Endereço encontrado via Google Places: ${result['formatted_address']}',
          );
          return {
            'latitude': location['lat'].toDouble(),
            'longitude': location['lng'].toDouble(),
          };
        } else {
          print('DEBUG: Google Places API retornou: ${data['status']}');
        }
      } else {
        print('DEBUG: Erro HTTP: ${response.statusCode}');
      }
      return null;
    } catch (e) {
      print('DEBUG: Erro na Google Places API: $e');
      return null;
    }
  }

  /// Google Places API para sugestões
  static Future<List<String>> _getGooglePlacesSuggestions(
    String partialAddress,
  ) async {
    try {
      String apiKey = GoogleMapsConfig.apiKey;
      if (apiKey.isEmpty) return [];

      String cleanAddress = partialAddress.trim();
      if (!cleanAddress.toLowerCase().contains('são paulo') &&
          !cleanAddress.toLowerCase().contains('sao paulo')) {
        cleanAddress = '$cleanAddress, São Paulo, SP, Brasil';
      }

      String encodedAddress = Uri.encodeComponent(cleanAddress);
      String url =
          'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$encodedAddress&key=$apiKey&components=country:br&types=establishment|geocode';

      print('DEBUG: Buscando sugestões na Google Places API: $url');

      final response = await http.get(Uri.parse(url));
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
