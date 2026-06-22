import 'package:flutter/material.dart';
import '../data/location_model.dart';
import '../services/direct_geocoding_service.dart';
import '../widgets/direct_address_field.dart';
import '../data/constants.dart';

/// Página de demonstração do novo sistema de geocodificação direta
class DemoDirectGeocodingPage extends StatefulWidget {
  const DemoDirectGeocodingPage({super.key});

  @override
  State<DemoDirectGeocodingPage> createState() =>
      _DemoDirectGeocodingPageState();
}

class _DemoDirectGeocodingPageState extends State<DemoDirectGeocodingPage> {
  final TextEditingController _addressController = TextEditingController();
  LocationData? _selectedLocation;

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _onLocationChanged(LocationData? location) {
    // Location changed - could be used for additional processing
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demo - Geocodificação Direta'),
        backgroundColor: KConstants.primaryColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const TestDirectGeocodingPage(),
                ),
              );
            },
            icon: const Icon(Icons.science),
            tooltip: 'Página de Testes',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Explicação do sistema
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb, color: Colors.blue[600]),
                        const SizedBox(width: 8),
                        Text(
                          'Sistema de Geocodificação Direta',
                          style: KTextStyle.heading3.copyWith(
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Este novo sistema foi desenvolvido para resolver os problemas de sugestões limitadas e erros de CORS. Ele:',
                      style: KTextStyle.bodyText,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '✅ Vai direto para a geocodificação (não depende de sugestões)',
                    ),
                    const Text('✅ Encontra o CEP automaticamente'),
                    const Text('✅ Posiciona no mapa com precisão'),
                    const Text(
                      '✅ Detecta números de endereço para maior precisão',
                    ),
                    const Text('✅ Usa múltiplas fontes de dados'),
                    const Text('✅ Fornece feedback visual sobre a confiança'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Exemplo de uso
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Exemplo de Uso', style: KTextStyle.heading3),
                    const SizedBox(height: 16),
                    Text(
                      'Digite um endereço para ver o sistema em ação:',
                      style: KTextStyle.bodyText,
                    ),
                    const SizedBox(height: 16),
                    DirectAddressField(
                      controller: _addressController,
                      onLocationChanged: _onLocationChanged,
                      hintText: 'Ex: Rua Saturno, 123, Aclimação',
                      labelText: 'Endereço',
                      isRequired: false,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Resultado
            if (_selectedLocation != null)
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[600]),
                          const SizedBox(width: 8),
                          Text(
                            'Localização Encontrada!',
                            style: KTextStyle.heading3.copyWith(
                              color: Colors.green[700],
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

            // Comparação com o sistema antigo
            Card(
              color: Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.compare, color: Colors.orange[600]),
                        const SizedBox(width: 8),
                        Text(
                          'Comparação com Sistema Anterior',
                          style: KTextStyle.heading3.copyWith(
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('❌ Sistema Anterior:'),
                    const Text('  • Dependia de sugestões (que falhavam)'),
                    const Text('  • Erros de CORS frequentes'),
                    const Text('  • Poucas sugestões retornadas'),
                    const Text('  • Não encontrava CEP automaticamente'),
                    const SizedBox(height: 8),
                    const Text('✅ Sistema Novo:'),
                    const Text('  • Geocodificação direta (mais confiável)'),
                    const Text('  • Encontra CEP automaticamente'),
                    const Text('  • Detecção inteligente de números'),
                    const Text('  • Múltiplas fontes de dados'),
                    const Text('  • Feedback visual de confiança'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Como integrar
            Card(
              color: Colors.purple[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.code, color: Colors.purple[600]),
                        const SizedBox(width: 8),
                        Text(
                          'Como Integrar',
                          style: KTextStyle.heading3.copyWith(
                            color: Colors.purple[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('Para usar o novo sistema, substitua:'),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        '// Antigo\nAddressPickerWidget(\n  onAddressSelected: (result) {\n    // ...\n  },\n)\n\n// Novo\nDirectAddressField(\n  controller: controller,\n  onLocationChanged: (location) {\n    // ...\n  },\n)',
                        style: TextStyle(fontFamily: 'monospace'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Botão para testar
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const TestDirectGeocodingPage(),
                    ),
                  );
                },
                icon: const Icon(Icons.science),
                label: const Text('Abrir Página de Testes'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: KConstants.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Página de teste (importada do arquivo anterior)
class TestDirectGeocodingPage extends StatefulWidget {
  const TestDirectGeocodingPage({super.key});

  @override
  State<TestDirectGeocodingPage> createState() =>
      _TestDirectGeocodingPageState();
}

class _TestDirectGeocodingPageState extends State<TestDirectGeocodingPage> {
  final TextEditingController _addressController = TextEditingController();
  DirectGeocodingResult? _lastResult;
  List<DirectGeocodingResult> _testResults = [];

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  void _onLocationChanged(LocationData? location) {
    // Location changed - could be used for additional processing
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
      await Future.delayed(const Duration(milliseconds: 500));
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
          ],
        ),
      ),
    );
  }
}
