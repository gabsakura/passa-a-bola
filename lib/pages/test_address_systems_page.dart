import 'package:flutter/material.dart';
import '../data/location_model.dart';
import '../data/constants.dart';
import '../widgets/smart_address_field.dart';
import '../widgets/simple_address_field.dart';

/// Página de teste para comparar os sistemas de endereço
class TestAddressSystemsPage extends StatefulWidget {
  const TestAddressSystemsPage({super.key});

  @override
  State<TestAddressSystemsPage> createState() => _TestAddressSystemsPageState();
}

class _TestAddressSystemsPageState extends State<TestAddressSystemsPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers para o sistema inteligente
  final _smartAddressController = TextEditingController();
  LocationData? _smartLocation;

  // Controllers para o sistema simplificado
  final _simpleAddressController = TextEditingController();
  LocationData? _simpleLocation;

  @override
  void dispose() {
    _smartAddressController.dispose();
    _simpleAddressController.dispose();
    super.dispose();
  }

  void _onSmartLocationChanged(LocationData? location) {
    setState(() {
      _smartLocation = location;
    });
  }

  void _onSimpleLocationChanged(LocationData? location) {
    setState(() {
      _simpleLocation = location;
    });
  }

  void _showComparison() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Comparação dos Sistemas'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sistema Inteligente
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sistema Inteligente',
                      style: KTextStyle.titleText.copyWith(
                        color: Colors.blue[700],
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Status: ${_smartLocation != null ? "✅ Selecionado" : "❌ Não selecionado"}',
                      style: KTextStyle.bodyText,
                    ),
                    if (_smartLocation != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Endereço: ${_smartLocation!.address ?? "N/A"}',
                        style: KTextStyle.smallText,
                      ),
                      Text(
                        'Coordenadas: ${_smartLocation!.latitude.toStringAsFixed(4)}, ${_smartLocation!.longitude.toStringAsFixed(4)}',
                        style: KTextStyle.smallText,
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Sistema Simplificado
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sistema Simplificado',
                      style: KTextStyle.titleText.copyWith(
                        color: Colors.green[700],
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Status: ${_simpleLocation != null ? "✅ Selecionado" : "❌ Não selecionado"}',
                      style: KTextStyle.bodyText,
                    ),
                    if (_simpleLocation != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Endereço: ${_simpleLocation!.address ?? "N/A"}',
                        style: KTextStyle.smallText,
                      ),
                      Text(
                        'Coordenadas: ${_simpleLocation!.latitude.toStringAsFixed(4)}, ${_simpleLocation!.longitude.toStringAsFixed(4)}',
                        style: KTextStyle.smallText,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Teste - Sistemas de Endereço'),
        backgroundColor: KConstants.primaryColor,
        foregroundColor: KConstants.textLightColor,
        actions: [
          IconButton(
            onPressed: _showComparison,
            icon: const Icon(Icons.compare),
            tooltip: 'Comparar Sistemas',
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              Text(
                'Comparação de Sistemas de Endereço',
                style: KTextStyle.titleText.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Teste ambos os sistemas e compare os resultados',
                style: KTextStyle.bodyText.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // Sistema Inteligente
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
                          'Sistema Inteligente',
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
                      'Tenta sugestões de texto primeiro, fallback para mapa',
                      style: KTextStyle.smallText.copyWith(
                        color: Colors.blue[600],
                      ),
                    ),
                    const SizedBox(height: 16),

                    SmartAddressField(
                      controller: _smartAddressController,
                      onLocationChanged: _onSmartLocationChanged,
                      hintText: 'Ex: Rua Augusta, 100',
                      labelText: 'Endereço (Inteligente)',
                      isRequired: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Sistema Simplificado
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
                          'Sistema Simplificado',
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
                      'Prioriza o mapa GPS confiável, validação opcional de texto',
                      style: KTextStyle.smallText.copyWith(
                        color: Colors.green[600],
                      ),
                    ),
                    const SizedBox(height: 16),

                    SimpleAddressField(
                      controller: _simpleAddressController,
                      onLocationChanged: _onSimpleLocationChanged,
                      hintText: 'Ex: Rua Augusta, 100',
                      labelText: 'Endereço (Simplificado)',
                      isRequired: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Botões de ação
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _showComparison,
                      icon: const Icon(Icons.compare),
                      label: const Text('Comparar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Sistemas validados! Smart: ${_smartLocation != null ? "OK" : "Falha"}, Simple: ${_simpleLocation != null ? "OK" : "Falha"}',
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.check),
                      label: const Text('Validar'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KConstants.primaryColor,
                        foregroundColor: KConstants.textLightColor,
                      ),
                    ),
                  ),
                ],
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
                      'Como testar:',
                      style: KTextStyle.titleText.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Digite "rua saturno" ou "ana rosa" em ambos os campos',
                    ),
                    const Text(
                      '2. Observe como cada sistema lida com as sugestões',
                    ),
                    const Text('3. Use o mapa quando as sugestões falharem'),
                    const Text('4. Compare a precisão e facilidade de uso'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
