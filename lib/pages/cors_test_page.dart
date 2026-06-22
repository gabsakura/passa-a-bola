import 'package:flutter/material.dart';
import '../data/location_model.dart';
import '../data/constants.dart';
import '../services/address_validation_service_v2.dart';
import '../widgets/simple_address_field.dart';

/// Página de teste para verificar se CORS foi resolvido
class CORSTestPage extends StatefulWidget {
  const CORSTestPage({super.key});

  @override
  State<CORSTestPage> createState() => _CORSTestPageState();
}

class _CORSTestPageState extends State<CORSTestPage> {
  final _addressController = TextEditingController();
  LocationData? _selectedLocation;
  bool _isTesting = false;
  String _testResult = '';

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

  Future<void> _testCORS() async {
    setState(() {
      _isTesting = true;
      _testResult = 'Testando...';
    });

    try {
      // Testar sugestões
      final suggestions =
          await AddressValidationServiceV2.getAddressSuggestions('rua saturno');

      // Testar validação
      final validation = await AddressValidationServiceV2.validateAddress(
        'rua saturno, 100',
      );

      setState(() {
        _testResult =
            '''
✅ TESTE CORS CONCLUÍDO

Sugestões encontradas: ${suggestions.length}
- ${suggestions.take(3).join('\n- ')}

Validação: ${validation.isValid ? '✅ Válida' : '❌ Inválida'}
${validation.isValid ? 'Coordenadas: ${validation.latitude?.toStringAsFixed(4)}, ${validation.longitude?.toStringAsFixed(4)}' : 'Erro: ${validation.error}'}

Status: ${suggestions.isNotEmpty || validation.isValid ? '✅ CORS RESOLVIDO' : '❌ Ainda há problemas CORS'}
        ''';
      });
    } catch (e) {
      setState(() {
        _testResult =
            '''
❌ ERRO NO TESTE CORS

Erro: $e

Solução: Use o SimpleAddressField abaixo que sempre funciona.
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
        title: const Text('Teste CORS'),
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
              'Teste de CORS - Web/Mobile',
              style: KTextStyle.titleText.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Teste se os problemas de CORS foram resolvidos',
              style: KTextStyle.bodyText.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // Botão de teste
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isTesting ? null : _testCORS,
                icon: _isTesting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.bug_report),
                label: Text(_isTesting ? 'Testando...' : 'Testar CORS'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
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

            // Campo de endereço que sempre funciona
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
                      Icon(Icons.check_circle, color: Colors.green[600]),
                      const SizedBox(width: 8),
                      Text(
                        'Solução Garantida',
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
                    'Este campo sempre funciona, mesmo com problemas de CORS',
                    style: KTextStyle.smallText.copyWith(
                      color: Colors.green[600],
                    ),
                  ),
                  const SizedBox(height: 16),

                  SimpleAddressField(
                    controller: _addressController,
                    onLocationChanged: _onLocationChanged,
                    hintText: 'Ex: Rua Saturno, 100',
                    labelText: 'Endereço (Sempre Funciona)',
                    isRequired: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Informações da localização selecionada
            if (_selectedLocation != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Localização Selecionada',
                      style: KTextStyle.titleText.copyWith(
                        color: Colors.blue[700],
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Endereço: ${_selectedLocation!.address ?? 'N/A'}',
                      style: KTextStyle.bodyText,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Coordenadas: ${_selectedLocation!.latitude.toStringAsFixed(4)}, ${_selectedLocation!.longitude.toStringAsFixed(4)}',
                      style: KTextStyle.smallText.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
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
                  const Text('1. Clique em "Testar CORS" para verificar APIs'),
                  const Text('2. Se falhar, use o campo "Sempre Funciona"'),
                  const Text('3. O campo usa GPS confiável do scout_marker'),
                  const Text('4. Funciona em Web, Android e iOS'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
