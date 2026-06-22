import 'package:flutter/material.dart';
import '../data/location_model.dart';
import '../widgets/simple_address_field.dart';
import '../data/constants.dart';

/// Página de demonstração do campo de endereço simples (como scout_marker)
class DemoSimpleAddressPage extends StatefulWidget {
  const DemoSimpleAddressPage({super.key});

  @override
  State<DemoSimpleAddressPage> createState() => _DemoSimpleAddressPageState();
}

class _DemoSimpleAddressPageState extends State<DemoSimpleAddressPage> {
  final TextEditingController _addressController = TextEditingController();
  LocationData? _selectedLocation;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Demo - Campo de Endereço Simples'),
        backgroundColor: KConstants.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Explicação
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
                          'Sistema Simples (como scout_marker)',
                          style: KTextStyle.heading3.copyWith(
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Este sistema funciona exatamente como o scout_marker:',
                    ),
                    const SizedBox(height: 8),
                    const Text('✅ Digite o endereço'),
                    const Text(
                      '✅ Sistema encontra coordenadas e CEP automaticamente',
                    ),
                    const Text('✅ Mostra mapa com pin na localização'),
                    const Text('✅ Sem sugestões, sem complicações'),
                    const Text('✅ Funciona offline com geocoding'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Campo de endereço
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Teste o Sistema', style: KTextStyle.heading3),
                    const SizedBox(height: 16),
                    Text(
                      'Digite um endereço para ver a magia acontecer:',
                      style: KTextStyle.bodyText,
                    ),
                    const SizedBox(height: 16),
                    SimpleAddressField(
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

            // Informações da localização selecionada
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
                            'Localização Confirmada!',
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

            // Instruções de uso
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
                          'Como Usar',
                          style: KTextStyle.heading3.copyWith(
                            color: Colors.amber[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('1. Digite o endereço no campo acima'),
                    const Text('2. O sistema automaticamente:'),
                    const Text('   • Encontra as coordenadas'),
                    const Text('   • Extrai o CEP'),
                    const Text('   • Mostra o mapa com pin'),
                    const Text(
                      '3. Você pode ajustar a posição tocando no mapa',
                    ),
                    const Text(
                      '4. Ou usar o botão do mapa para seleção manual',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Exemplos de endereços para testar
            Card(
              color: Colors.purple[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Colors.purple[600]),
                        const SizedBox(width: 8),
                        Text(
                          'Exemplos para Testar',
                          style: KTextStyle.heading3.copyWith(
                            color: Colors.purple[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text('Teste com estes endereços:'),
                    const SizedBox(height: 8),
                    ...[
                          'Rua Saturno, Aclimação',
                          'Avenida Paulista, 1000',
                          'Rua Augusta, 500',
                          'Rua Oscar Freire, 200',
                        ]
                        .map(
                          (address) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: InkWell(
                              onTap: () {
                                _addressController.text = address;
                                _onLocationChanged(
                                  null,
                                ); // Reset para forçar nova busca
                              },
                              child: Text(
                                '• $address',
                                style: KTextStyle.bodyText.copyWith(
                                  color: Colors.blue[700],
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        )
                        ,
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
