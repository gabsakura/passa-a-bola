import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'address_validation_service.dart';

class UserAddressService {
  static const String _addressKey = 'user_address';
  static const String _validationKey = 'user_address_validation';

  /// Salva o endereço do usuário
  static Future<bool> saveUserAddress(String address) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return await prefs.setString(_addressKey, address);
    } catch (e) {
      print('DEBUG: Erro ao salvar endereço do usuário: $e');
      return false;
    }
  }

  /// Obtém o endereço do usuário
  static Future<String?> getUserAddress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_addressKey);
    } catch (e) {
      print('DEBUG: Erro ao obter endereço do usuário: $e');
      return null;
    }
  }

  /// Salva a validação do endereço do usuário
  static Future<bool> saveAddressValidation(
    AddressValidationResult validation,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final validationJson = json.encode({
        'isValid': validation.isValid,
        'latitude': validation.latitude,
        'longitude': validation.longitude,
        'formattedAddress': validation.formattedAddress,
        'streetNumber': validation.streetNumber,
        'route': validation.route,
        'neighborhood': validation.neighborhood,
        'city': validation.city,
        'state': validation.state,
        'country': validation.country,
        'postalCode': validation.postalCode,
        'isInSaoPaulo': validation.isInSaoPaulo,
        'confidence': validation.confidence,
        'error': validation.error,
      });
      return await prefs.setString(_validationKey, validationJson);
    } catch (e) {
      print('DEBUG: Erro ao salvar validação do endereço: $e');
      return false;
    }
  }

  /// Obtém a validação do endereço do usuário
  static Future<AddressValidationResult?> getAddressValidation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final validationJson = prefs.getString(_validationKey);

      if (validationJson != null) {
        final data = json.decode(validationJson) as Map<String, dynamic>;
        return AddressValidationResult(
          isValid: data['isValid'] as bool,
          latitude: data['latitude'] as double?,
          longitude: data['longitude'] as double?,
          formattedAddress: data['formattedAddress'] as String?,
          streetNumber: data['streetNumber'] as String?,
          route: data['route'] as String?,
          neighborhood: data['neighborhood'] as String?,
          city: data['city'] as String?,
          state: data['state'] as String?,
          country: data['country'] as String?,
          postalCode: data['postalCode'] as String?,
          isInSaoPaulo: data['isInSaoPaulo'] as bool? ?? false,
          confidence: (data['confidence'] as num?)?.toDouble() ?? 0.0,
          error: data['error'] as String?,
        );
      }
    } catch (e) {
      print('DEBUG: Erro ao obter validação do endereço: $e');
    }

    return null;
  }

  /// Valida e salva o endereço do usuário
  static Future<AddressValidationResult> validateAndSaveUserAddress(
    String address,
  ) async {
    try {
      // Validar o endereço
      final validation = await AddressValidationService.validateAddress(
        address,
      );

      if (validation.isValid) {
        // Salvar o endereço e a validação
        await saveUserAddress(address);
        await saveAddressValidation(validation);
        print(
          'DEBUG: Endereço do usuário validado e salvo: ${validation.displayAddress}',
        );
      } else {
        print('DEBUG: Endereço do usuário inválido: ${validation.error}');
      }

      return validation;
    } catch (e) {
      print('DEBUG: Erro ao validar e salvar endereço: $e');
      return AddressValidationResult(isValid: false, error: 'Erro interno: $e');
    }
  }

  /// Obtém as coordenadas do endereço do usuário
  static Future<Map<String, double>?> getUserCoordinates() async {
    try {
      final validation = await getAddressValidation();

      if (validation != null && validation.hasValidCoordinates) {
        return {
          'latitude': validation.latitude!,
          'longitude': validation.longitude!,
        };
      }
    } catch (e) {
      print('DEBUG: Erro ao obter coordenadas do usuário: $e');
    }

    return null;
  }

  /// Verifica se o usuário tem um endereço válido
  static Future<bool> hasValidUserAddress() async {
    try {
      final validation = await getAddressValidation();
      return validation?.isValid == true &&
          validation?.hasValidCoordinates == true;
    } catch (e) {
      print('DEBUG: Erro ao verificar endereço válido: $e');
      return false;
    }
  }

  /// Obtém informações do endereço do usuário para exibição
  static Future<UserAddressInfo?> getUserAddressInfo() async {
    try {
      final address = await getUserAddress();
      final validation = await getAddressValidation();

      if (address != null && validation != null) {
        return UserAddressInfo(
          originalAddress: address,
          validation: validation,
        );
      }
    } catch (e) {
      print('DEBUG: Erro ao obter informações do endereço: $e');
    }

    return null;
  }

  /// Limpa o endereço do usuário
  static Future<bool> clearUserAddress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_addressKey);
      await prefs.remove(_validationKey);
      return true;
    } catch (e) {
      print('DEBUG: Erro ao limpar endereço do usuário: $e');
      return false;
    }
  }

  /// Atualiza o endereço do usuário se necessário
  static Future<bool> updateUserAddressIfNeeded(String newAddress) async {
    try {
      final currentAddress = await getUserAddress();

      if (currentAddress != newAddress) {
        return (await validateAndSaveUserAddress(newAddress)).isValid;
      }

      return true; // Endereço já é o mesmo
    } catch (e) {
      print('DEBUG: Erro ao atualizar endereço: $e');
      return false;
    }
  }
}

class UserAddressInfo {
  final String originalAddress;
  final AddressValidationResult validation;

  UserAddressInfo({required this.originalAddress, required this.validation});

  /// Retorna o endereço formatado para exibição
  String get displayAddress => validation.displayAddress;

  /// Retorna o endereço resumido
  String get shortAddress => validation.shortAddress;

  /// Verifica se está em São Paulo
  bool get isInSaoPaulo => validation.isInSaoPaulo;

  /// Retorna as coordenadas
  Map<String, double>? get coordinates {
    if (validation.hasValidCoordinates) {
      return {
        'latitude': validation.latitude!,
        'longitude': validation.longitude!,
      };
    }
    return null;
  }

  /// Retorna a confiança da validação
  double get confidence => validation.confidence;

  @override
  String toString() {
    return 'UserAddressInfo(original: $originalAddress, formatted: $displayAddress, valid: ${validation.isValid})';
  }
}
