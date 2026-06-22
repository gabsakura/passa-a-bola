import 'package:flutter/material.dart';
import '../data/location_model.dart';
import '../data/constants.dart';
import '../widgets/smart_address_field.dart';

/// Página de teste para o novo sistema de endereço inteligente
class TestSmartAddressPage extends StatefulWidget {
  const TestSmartAddressPage({super.key});

  @override
  State<TestSmartAddressPage> createState() => _TestSmartAddressPageState();
}

class _TestSmartAddressPageState extends State<TestSmartAddressPage> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
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

  void _showLocationInfo() {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhuma localização selecionada'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Informações da Localização'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Endereço: ${_selectedLocation!.address ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Cidade: ${_selectedLocation!.city ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Estado: ${_selectedLocation!.state ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('País: ${_selectedLocation!.country ?? 'N/A'}'),
            const SizedBox(height: 8),
            Text('Latitude: ${_selectedLocation!.latitude.toStringAsFixed(6)}'),
            const SizedBox(height: 8),
            Text(
              'Longitude: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
            ),
          ],
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
        title: const Text('Teste - Endereço Inteligente'),
        backgroundColor: KConstants.primaryColor,
        foregroundColor: KConstants.textLightColor,
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
                'Sistema de Endereço Inteligente',
                style: KTextStyle.titleText.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Digite um endereço ou use o mapa para selecionar a localização',
                style: KTextStyle.bodyText.copyWith(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // Campo de endereço inteligente
              SmartAddressField(
                controller: _addressController,
                onLocationChanged: _onLocationChanged,
                hintText: 'Ex: Rua Augusta, 100 - Consolação',
                labelText: 'Endereço',
                isRequired: true,
              ),

              const SizedBox(height: 24),

              // Informações da localização
              if (_selectedLocation != null) ...[
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
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.blue[600]),
                          const SizedBox(width: 8),
                          Text(
                            'Localização Selecionada',
                            style: KTextStyle.titleText.copyWith(
                              color: Colors.blue[700],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
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
                      if (_selectedLocation!.city != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Cidade: ${_selectedLocation!.city}',
                          style: KTextStyle.smallText.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Botões de ação
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _selectedLocation != null
                          ? _showLocationInfo
                          : null,
                      icon: const Icon(Icons.info),
                      label: const Text('Ver Detalhes'),
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
                                _selectedLocation != null
                                    ? 'Localização válida!'
                                    : 'Selecione uma localização',
                              ),
                              backgroundColor: _selectedLocation != null
                                  ? Colors.green
                                  : Colors.orange,
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
                      'Como usar:',
                      style: KTextStyle.titleText.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '1. Digite parte do endereço para ver sugestões',
                    ),
                    const Text('2. Toque em uma sugestão para selecionar'),
                    const Text(
                      '3. Ou toque no ícone do mapa para selecionar visualmente',
                    ),
                    const Text(
                      '4. O sistema validará automaticamente a localização',
                    ),
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
