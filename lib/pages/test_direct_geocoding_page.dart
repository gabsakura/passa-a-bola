import 'package:flutter/material.dart';
import '../data/location_model.dart';
import '../services/direct_geocoding_service.dart';
import '../widgets/direct_address_field.dart';
import '../data/constants.dart';

/// Página de teste para o novo sistema de geocodificação direta
class TestDirectGeocodingPage extends StatefulWidget {
  const TestDirectGeocodingPage({super.key});

  @override
  State<TestDirectGeocodingPage> createState() =>
      _TestDirectGeocodingPageState();
}

class _TestDirectGeocodingPageState extends State<TestDirectGeocodingPage> {
  final TextEditingController _addressController = TextEditingController();
  LocationData? _selectedLocation;
  DirectGeocodingResult? _lastResult;
  List<DirectGeocodingResult> _testResults = [];

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _onLocationChanged(LocationData? location) {
    setState(() {
      _selectedLocation = location;
    });
  }

  Future<void> _testAddress(String address) async {
    if (address.trim().isEmpty) return;

    setState(() {
      _lastResult = null;
    });

    try {
      final result = await DirectGeocodingService.validateAndGeocode(address);

      setState(() {
        _lastResult = result;
        _testResults.insert(0, result);
        if (_testResults.length > 10) {
          _testResults = _testResults.take(10).toList();
        }
      });
    } catch (e) {
      setState(() {
        _lastResult = DirectGeocodingResult(
          isValid: false,
          error: 'Erro no teste: $e',
        );
      });
    }
  }

  Future<void> _runTestSuite() async {
    final testAddresses = [
      'rua saturno',
      'rua saturno, 123',
      'Rua Saturno, Aclimação',
      'Rua Saturno, 456, Aclimação',
      'Avenida Paulista, 1000',
      'Rua Augusta, 500',
      'Rua Oscar Freire, 200',
      'Avenida Faria Lima, 1500',
      'Rua da Consolação, 300',
      'Rua Teodoro Sampaio, 800',
    ];

    setState(() {
      _testResults.clear();
    });

    for (String address in testAddresses) {
      await _testAddress(address);
      await Future.delayed(
        const Duration(milliseconds: 500),
      ); // Pausa entre testes
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste - Geocodificação Direta'),
        backgroundColor: KConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Campo de teste
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Teste Individual', style: KTextStyle.heading3),
                    const SizedBox(height: 16),
                    DirectAddressField(
                      controller: _addressController,
                      onLocationChanged: _onLocationChanged,
                      hintText: 'Digite um endereço para testar...',
                      labelText: 'Endereço',
                      isRequired: false,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: () =>
                              _testAddress(_addressController.text),
                          child: const Text('Testar Endereço'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _runTestSuite,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                          child: const Text('Executar Suite de Testes'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Resultado do teste individual
            if (_lastResult != null)
              Card(
                color: _lastResult!.isValid ? Colors.green[50] : Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _lastResult!.isValid
                                ? Icons.check_circle
                                : Icons.error,
                            color: _lastResult!.isValid
                                ? Colors.green
                                : Colors.red,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _lastResult!.isValid
                                ? 'Resultado Válido'
                                : 'Resultado Inválido',
                            style: KTextStyle.heading3.copyWith(
                              color: _lastResult!.isValid
                                  ? Colors.green[700]
                                  : Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_lastResult!.isValid) ...[
                        Text('Endereço: ${_lastResult!.displayAddress}'),
                        if (_lastResult!.hasPostalCode)
                          Text('CEP: ${_lastResult!.postalCode}'),
                        if (_lastResult!.hasNumber)
                          Text('Número: ${_lastResult!.streetNumber}'),
                        Text(
                          'Coordenadas: ${_lastResult!.latitude?.toStringAsFixed(4)}, ${_lastResult!.longitude?.toStringAsFixed(4)}',
                        ),
                        Text(
                          'Confiança: ${(_lastResult!.confidence * 100).toInt()}%',
                        ),
                        Text('Método: ${_lastResult!.method}'),
                      ] else ...[
                        Text('Erro: ${_lastResult!.error}'),
                      ],
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Localização selecionada
            if (_selectedLocation != null)
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.blue[600]),
                          const SizedBox(width: 8),
                          Text(
                            'Localização Selecionada',
                            style: KTextStyle.heading3.copyWith(
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Endereço: ${_selectedLocation!.address}'),
                      Text('Cidade: ${_selectedLocation!.city}'),
                      Text('Estado: ${_selectedLocation!.state}'),
                      Text(
                        'Coordenadas: ${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}',
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Histórico de testes
            if (_testResults.isNotEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Histórico de Testes (${_testResults.length})',
                        style: KTextStyle.heading3,
                      ),
                      const SizedBox(height: 8),
                      ..._testResults.map((result) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: result.isValid
                                ? Colors.green[50]
                                : Colors.red[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: result.isValid
                                  ? Colors.green[200]!
                                  : Colors.red[200]!,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    result.isValid
                                        ? Icons.check_circle
                                        : Icons.error,
                                    size: 16,
                                    color: result.isValid
                                        ? Colors.green
                                        : Colors.red,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      result.displayAddress,
                                      style: KTextStyle.smallText.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Chip(
                                    label: Text(
                                      result.method,
                                      style: const TextStyle(fontSize: 10),
                                    ),
                                    backgroundColor: result.isValid
                                        ? Colors.green[100]
                                        : Colors.red[100],
                                  ),
                                ],
                              ),
                              if (result.isValid) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'CEP: ${result.postalCode ?? "N/A"} | Confiança: ${(result.confidence * 100).toInt()}%',
                                  style: KTextStyle.smallText,
                                ),
                              ] else ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Erro: ${result.error}',
                                  style: KTextStyle.smallText.copyWith(
                                    color: Colors.red[700],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Informações sobre o sistema
            Card(
              color: Colors.amber[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.amber[600]),
                        const SizedBox(width: 8),
                        Text(
                          'Sobre o Sistema de Geocodificação Direta',
                          style: KTextStyle.heading3.copyWith(
                            color: Colors.amber[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Este sistema foi otimizado para:',
                      style: KTextStyle.bodyText.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('• Encontrar CEP automaticamente'),
                    const Text('• Posicionar no mapa com precisão'),
                    const Text(
                      '• Detectar números de endereço para maior precisão',
                    ),
                    const Text(
                      '• Usar múltiplas fontes de dados (Geocoding + Google Places)',
                    ),
                    const Text(
                      '• Fornecer feedback visual sobre a confiança do resultado',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Dicas para melhor resultado:',
                      style: KTextStyle.bodyText.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('• Inclua o número da rua quando possível'),
                    const Text('• Use nomes completos de ruas e avenidas'),
                    const Text('• Adicione o bairro se souber'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
