import 'services/address_validation_service.dart';
import 'data/location_service.dart';

/// Classe para testar problemas de validação de endereços
class AddressDebugTest {
  static Future<void> testAddressValidation() async {
    print('=== TESTE DE VALIDAÇÃO DE ENDEREÇOS ===');

    // Lista de endereços para testar
    List<String> testAddresses = [
      'Avenida Paulista, 1000',
      'Rua Augusta, 100',
      'Parque do Ibirapuera',
      'Vila Olímpia',
      'Rua das Flores, 123',
    ];

    for (String address in testAddresses) {
      print('\n--- Testando: $address ---');

      try {
        final result = await AddressValidationService.validateAddress(address);

        print('Válido: ${result.isValid}');
        print('Erro: ${result.error}');
        print('Endereço formatado: ${result.formattedAddress}');
        print('Cidade: ${result.city}');
        print('Estado: ${result.state}');
        print('País: ${result.country}');
        print('Coordenadas: ${result.latitude}, ${result.longitude}');

        if (result.isValid) {
          print('✅ SUCESSO');
        } else {
          print('❌ FALHOU: ${result.error}');
        }
      } catch (e) {
        print('❌ ERRO: $e');
      }
    }

    print('\n=== FIM DO TESTE ===');
  }

  static Future<void> testGoogleMapsAPI() async {
    print('=== TESTE DA API DO GOOGLE MAPS ===');

    try {
      // Testar se a API está funcionando
      final result = await AddressValidationService.validateAddress(
        'Avenida Paulista, 1000',
      );

      if (result.isValid) {
        print('✅ API do Google Maps funcionando corretamente');
        print('Endereço: ${result.formattedAddress}');
        print('Coordenadas: ${result.latitude}, ${result.longitude}');
      } else {
        print('❌ API do Google Maps com problemas: ${result.error}');
      }
    } catch (e) {
      print('❌ Erro na API do Google Maps: $e');
    }
  }

  static Future<void> testAddressSuggestions() async {
    print('=== TESTE DE SUGESTÕES DE ENDEREÇOS ===');

    List<String> testQueries = [
      'rua saturno',
      'avenida paulista',
      'vila olímpia',
      'parque',
      'shopping',
      'rua augusta',
      'faria lima',
    ];

    for (String query in testQueries) {
      print('\n--- Testando sugestões para: $query ---');

      try {
        final suggestions =
            await AddressValidationService.getAddressSuggestions(query);

        if (suggestions.isNotEmpty) {
          print('✅ ${suggestions.length} sugestões encontradas:');
          for (int i = 0; i < suggestions.length; i++) {
            print('  ${i + 1}. ${suggestions[i]}');
          }
        } else {
          print('❌ Nenhuma sugestão encontrada');
        }
      } catch (e) {
        print('❌ ERRO: $e');
      }
    }

    print('\n=== FIM DO TESTE DE SUGESTÕES ===');
  }

  static Future<void> testSpecificAddress() async {
    print('=== TESTE ESPECÍFICO: RUA SATURNO ===');

    try {
      final suggestions = await AddressValidationService.getAddressSuggestions(
        'rua saturno',
      );

      print('Resultado:');
      if (suggestions.isNotEmpty) {
        print('✅ ${suggestions.length} sugestões encontradas:');
        for (int i = 0; i < suggestions.length; i++) {
          print('  ${i + 1}. ${suggestions[i]}');
        }
      } else {
        print('❌ Nenhuma sugestão encontrada para "rua saturno"');
      }
    } catch (e) {
      print('❌ ERRO: $e');
    }

    print('\n=== FIM DO TESTE ESPECÍFICO ===');
  }

  static Future<void> testCoordinateAccuracy() async {
    print('=== TESTE DE PRECISÃO DAS COORDENADAS ===');

    List<String> testAddresses = [
      'Rua Augusta, Consolação',
      'Avenida Paulista, Bela Vista',
      'Rua Oscar Freire, Jardins',
      'rua saturno',
    ];

    for (String address in testAddresses) {
      print('\n--- Testando coordenadas para: $address ---');

      try {
        // Usar a função searchAddresses diretamente
        final results = await LocationService.searchAddresses(address);

        if (results.isNotEmpty) {
          final result = results.first;
          print('✅ Endereço: ${result.address}');
          print('   Coordenadas: ${result.latitude}, ${result.longitude}');
          print('   Cidade: ${result.city}');
          print('   Estado: ${result.state}');

          // Verificar se as coordenadas estão em São Paulo (aproximadamente)
          if (result.latitude >= -24.0 &&
              result.latitude <= -23.0 &&
              result.longitude >= -47.0 &&
              result.longitude <= -46.0) {
            print('   ✅ Coordenadas parecem estar em São Paulo');
          } else {
            print('   ❌ Coordenadas podem estar fora de São Paulo');
          }
        } else {
          print('❌ Nenhum resultado encontrado');
        }
      } catch (e) {
        print('❌ ERRO: $e');
      }
    }

    print('\n=== FIM DO TESTE DE PRECISÃO ===');
  }
}
