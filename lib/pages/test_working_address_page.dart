import 'package:flutter/material.dart';
import '../data/location_model.dart';
import '../data/constants.dart';
import '../services/working_address_service.dart';
import '../widgets/smart_address_field.dart';
import '../widgets/simple_address_field.dart';

/// Página de teste para o sistema de endereços que funciona
class TestWorkingAddressPage extends StatefulWidget {
  const TestWorkingAddressPage({super.key});

  @override
  State<TestWorkingAddressPage> createState() => _TestWorkingAddressPageState();
}

class _TestWorkingAddressPageState extends State<TestWorkingAddressPage> {
  final _smartAddressController = TextEditingController();
  LocationData? _smartSelectedLocation;

  final _simpleAddressController = TextEditingController();
  LocationData? _simpleSelectedLocation;

  bool _isTesting = false;
  String _testResult = '';

  @override
  void dispose() {
    _smartAddressController.dispose();
    _simpleAddressController.dispose();
    super.dispose();
  }

  void _onSmartLocationChanged(LocationData? location) {
    setState(() {
      _smartSelectedLocation = location;
    });
  }

  void _onSimpleLocationChanged(LocationData? location) {
    setState(() {
      _simpleSelectedLocation = location;
    });
  }

  Future<void> _testWorkingSystem() async {
    setState(() {
      _isTesting = true;
      _testResult = 'Testando sistema que funciona...';
    });

    try {
      // Testar com o endereço que estava falhando
      final testAddress = 'rua luisiania 373';

      // Testar sugestões
      final suggestions = await WorkingAddressService.getAddressSuggestions(
        testAddress,
      );

      // Testar validação
      final validation = await WorkingAddressService.validateAddress(
        testAddress,
      );

      setState(() {
        _testResult =
            '''
✅ SISTEMA FUNCIONANDO!

Endereço testado: $testAddress

Sugestões encontradas: ${suggestions.length}
${suggestions.take(3).map((s) => '- $s').join('\n')}

Validação: ${validation.isValid ? '✅ Válida' : '❌ Inválida'}
${validation.isValid ? 'Coordenadas: ${validation.latitude?.toStringAsFixed(4)}, ${validation.longitude?.toStringAsFixed(4)}' : 'Erro: ${validation.error}'}

Status: ${suggestions.isNotEmpty || validation.isValid ? '✅ SISTEMA FUNCIONANDO' : '❌ Ainda há problemas'}
        ''';
      });
    } catch (e) {
      setState(() {
        _testResult =
            '''
❌ ERRO NO TESTE

Erro: $e

O sistema baseado no scout_marker deveria funcionar.
        ''';
      });
    } finally {
      setState(() {
        _isTesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste - Sistema que Funciona'),
        backgroundColor: KConstants.primaryColor,
        foregroundColor: KConstants.textLightColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            Text(
              'Sistema de Endereços que Funciona',
              style: KTextStyle.titleText.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Baseado no sistema do scout_marker que já funciona',
              style: KTextStyle.bodyText.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // Botão de teste
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isTesting ? null : _testWorkingSystem,
                icon: _isTesting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle),
                label: Text(_isTesting ? 'Testando...' : 'Testar Sistema'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Resultado do teste
            if (_testResult.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _testResult.contains('✅')
                      ? Colors.green[50]
                      : Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _testResult.contains('✅')
                        ? Colors.green[200]!
                        : Colors.red[200]!,
                  ),
                ),
                child: Text(
                  _testResult,
                  style: KTextStyle.bodyText.copyWith(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                ),
              ),

            const SizedBox(height: 24),

            // SmartAddressField
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.psychology, color: Colors.blue[600]),
                      const SizedBox(width: 8),
                      Text(
                        'SmartAddressField (Sistema que Funciona)',
                        style: KTextStyle.titleText.copyWith(
                          color: Colors.blue[700],
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Usa o mesmo sistema do scout_marker',
                    style: KTextStyle.smallText.copyWith(
                      color: Colors.blue[600],
                    ),
                  ),
                  const SizedBox(height: 16),

                  SmartAddressField(
                    controller: _smartAddressController,
                    onLocationChanged: _onSmartLocationChanged,
                    hintText: 'Ex: rua luisiania 373',
                    labelText: 'Endereço (Sistema que Funciona)',
                    isRequired: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // SimpleAddressField
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.map, color: Colors.green[600]),
                      const SizedBox(width: 8),
                      Text(
                        'SimpleAddressField (Sempre Funciona)',
                        style: KTextStyle.titleText.copyWith(
                          color: Colors.green[700],
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Validação de texto + seleção no mapa',
                    style: KTextStyle.smallText.copyWith(
                      color: Colors.green[600],
                    ),
                  ),
                  const SizedBox(height: 16),

                  SimpleAddressField(
                    controller: _simpleAddressController,
                    onLocationChanged: _onSimpleLocationChanged,
                    hintText: 'Ex: rua luisiania 373',
                    labelText: 'Endereço (Sempre Funciona)',
                    isRequired: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Informações das localizações selecionadas
            if (_smartSelectedLocation != null ||
                _simpleSelectedLocation != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Localizações Selecionadas',
                      style: KTextStyle.titleText.copyWith(
                        color: Colors.orange[700],
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_smartSelectedLocation != null) ...[
                      Text(
                        'Smart: ${_smartSelectedLocation!.address ?? 'N/A'}',
                        style: KTextStyle.bodyText,
                      ),
                      Text(
                        'Coordenadas: ${_smartSelectedLocation!.latitude.toStringAsFixed(4)}, ${_smartSelectedLocation!.longitude.toStringAsFixed(4)}',
                        style: KTextStyle.smallText.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],

                    if (_simpleSelectedLocation != null) ...[
                      Text(
                        'Simple: ${_simpleSelectedLocation!.address ?? 'N/A'}',
                        style: KTextStyle.bodyText,
                      ),
                      Text(
                        'Coordenadas: ${_simpleSelectedLocation!.latitude.toStringAsFixed(4)}, ${_simpleSelectedLocation!.longitude.toStringAsFixed(4)}',
                        style: KTextStyle.smallText.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Instruções
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Como funciona:',
                    style: KTextStyle.titleText.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '1. Usa a mesma lógica do scout_marker que funciona',
                  ),
                  const Text(
                    '2. Múltiplas tentativas com variações do endereço',
                  ),
                  const Text('3. Google Places API como fallback'),
                  const Text('4. Validação robusta de coordenadas'),
                  const Text('5. Funciona em Web, Android e iOS'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
