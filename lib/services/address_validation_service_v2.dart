import 'platform_address_service.dart';

/// Serviço de validação de endereços versão 2 - baseado em plataforma
class AddressValidationServiceV2 {
  /// Valida se um endereço é real usando o serviço baseado em plataforma
  static Future<AddressValidationResult> validateAddress(String address) async {
    final result = await PlatformAddressService.validateAddress(address);
    return AddressValidationResult(
      isValid: result.isValid,
      error: result.error,
      formattedAddress: result.formattedAddress,
      latitude: result.latitude,
      longitude: result.longitude,
      city: result.city,
      state: result.state,
      country: result.country,
    );
  }

  /// Obtém sugestões de endereços baseado em uma busca parcial
  static Future<List<String>> getAddressSuggestions(
    String partialAddress,
  ) async {
    return await PlatformAddressService.getAddressSuggestions(partialAddress);
  }

  /// Valida múltiplos endereços
  static Future<List<AddressValidationResult>> validateAddresses(
    List<String> addresses,
  ) async {
    List<AddressValidationResult> results = [];

    for (String address in addresses) {
      final result = await validateAddress(address);
      results.add(result);

      // Pequena pausa para não sobrecarregar a API
      await Future.delayed(const Duration(milliseconds: 100));
    }

    return results;
  }
}

/// Resultado da validação de endereço (compatível com a versão anterior)
class AddressValidationResult {
  final bool isValid;
  final String? error;
  final String formattedAddress;
  final double? latitude;
  final double? longitude;
  final String? streetNumber;
  final String? route;
  final String? neighborhood;
  final String? city;
  final String? state;
  final String? country;
  final String? postalCode;
  final bool? isInSaoPaulo;
  final double? confidence;

  AddressValidationResult({
    required this.isValid,
    this.error,
    required this.formattedAddress,
    this.latitude,
    this.longitude,
    this.streetNumber,
    this.route,
    this.neighborhood,
    this.city,
    this.state,
    this.country,
    this.postalCode,
    this.isInSaoPaulo,
    this.confidence,
  });
}
