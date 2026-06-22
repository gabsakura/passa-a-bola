import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../data/constants.dart';
import '../data/scout_marker_model.dart';
import '../services/scout_marker_request_service.dart';
import '../services/location_service.dart';

class ScoutMarkerAddPage extends StatefulWidget {
  const ScoutMarkerAddPage({super.key});

  @override
  State<ScoutMarkerAddPage> createState() => _ScoutMarkerAddPageState();
}

class _ScoutMarkerAddPageState extends State<ScoutMarkerAddPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();

  ScoutMarkerType _selectedType = ScoutMarkerType.friendlyMatch;
  LatLng? _selectedLocation;
  bool _isLoading = false;
  String? _error;
  bool _isSearchingAddress = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _searchAddress() async {
    if (_addressController.text.trim().isEmpty) return;

    setState(() {
      _isSearchingAddress = true;
      _error = null;
    });

    try {
      final location = await LocationService.getCoordinatesFromAddress(
        _addressController.text.trim(),
      );
      if (location != null) {
        setState(() {
          _selectedLocation = LatLng(
            location['latitude']!,
            location['longitude']!,
          );
        });
      } else {
        setState(() {
          _error =
              'Endereço não encontrado. Tente um endereço mais específico.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erro ao buscar endereço: $e';
      });
    } finally {
      setState(() {
        _isSearchingAddress = false;
      });
    }
  }

  Future<void> _testLocationSearch() async {
    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Digite um endereço para testar'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Testando busca... Verifique o console para detalhes'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 3),
      ),
    );

    await LocationService.testLocationSearch(_addressController.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adicionar Local Confiável'),
        backgroundColor: KConstants.primaryColor,
        foregroundColor: KConstants.textLightColor,
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveMarker,
            child: Text(
              'Salvar',
              style: KTextStyle.buttonText.copyWith(
                color: KConstants.textLightColor,
              ),
            ),
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
              // Tipo de marcador
              _buildSectionTitle('Tipo de Local'),
              const SizedBox(height: 8),
              _buildTypeSelector(),
              const SizedBox(height: 24),

              // Título
              _buildSectionTitle('Título'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                decoration: KInputDecoration.textFieldDecoration(
                  hintText: 'Ex: Jogo Amistoso - Vila Olímpia',
                  prefixIcon: Icons.title,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Título é obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Descrição
              _buildSectionTitle('Descrição'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: KInputDecoration.textFieldDecoration(
                  hintText: 'Descreva o local e as atividades...',
                  prefixIcon: Icons.description,
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Descrição é obrigatória';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Endereço
              _buildSectionTitle('Endereço'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _addressController,
                      decoration: KInputDecoration.textFieldDecoration(
                        hintText: 'Ex: Rua das Flores, 123 - Vila Olímpia',
                        prefixIcon: Icons.location_on,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Endereço é obrigatório';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: _isSearchingAddress ? null : _searchAddress,
                    icon: _isSearchingAddress
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search, size: 18),
                    label: const Text('Buscar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KConstants.primaryColor,
                      foregroundColor: KConstants.textLightColor,
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    onPressed: _testLocationSearch,
                    icon: const Icon(Icons.bug_report, size: 18),
                    tooltip: 'Testar Busca',
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.orange[100],
                      foregroundColor: Colors.orange[700],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Mapa para seleção de localização
              _buildSectionTitle('Localização no Mapa'),
              const SizedBox(height: 8),
              _buildMapSelector(),
              const SizedBox(height: 24),

              // Botão de salvar
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error, color: Colors.red[600], size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Colors.red[700],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveMarker,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: KConstants.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text('Salvar Local Confiável'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: KTextStyle.titleText.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: KConstants.primaryColor,
      ),
    );
  }

  Widget _buildTypeSelector() {
    return Column(
      children: ScoutMarkerType.values.map((type) {
        return RadioListTile<ScoutMarkerType>(
          title: Text(_getTypeDisplayName(type)),
          subtitle: Text(_getTypeDescription(type)),
          value: type,
          groupValue: _selectedType,
          onChanged: (value) {
            setState(() {
              _selectedType = value!;
            });
          },
          activeColor: KConstants.primaryColor,
        );
      }).toList(),
    );
  }

  String _getTypeDisplayName(ScoutMarkerType type) {
    switch (type) {
      case ScoutMarkerType.friendlyMatch:
        return 'Jogo Amistoso Feminino';
      case ScoutMarkerType.footballSchool:
        return 'Escolhinha de Futebol';
      case ScoutMarkerType.externalChampionship:
        return 'Campeonato Externo';
    }
  }

  String _getTypeDescription(ScoutMarkerType type) {
    switch (type) {
      case ScoutMarkerType.friendlyMatch:
        return 'Jogos amistosos de futebol feminino';
      case ScoutMarkerType.footballSchool:
        return 'Escolhinhas e academias de futebol';
      case ScoutMarkerType.externalChampionship:
        return 'Campeonatos não organizados pelo Passa a Bola';
    }
  }

  Widget _buildMapSelector() {
    if (_selectedLocation != null) {
      return Column(
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _selectedLocation!,
                  zoom: 15.0,
                ),
                markers: {
                  Marker(
                    markerId: const MarkerId('selected_location'),
                    position: _selectedLocation!,
                    infoWindow: const InfoWindow(
                      title: 'Localização Encontrada',
                      snippet: 'Verifique se está correto',
                    ),
                  ),
                },
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: true,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              border: Border.all(color: Colors.green[200]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Localização encontrada! Verifique se está correto.',
                    style: KTextStyle.smallText.copyWith(
                      color: Colors.green[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange[50],
          border: Border.all(color: Colors.orange[200]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.info, color: Colors.orange[600], size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Digite um endereço e clique em "Buscar" para encontrar a localização.',
                style: KTextStyle.smallText.copyWith(color: Colors.orange[700]),
              ),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _saveMarker() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedLocation == null) {
      setState(() {
        _error = 'Selecione uma localização no mapa';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Criar solicitação de marcador para aprovação do admin
      await ScoutMarkerRequestService.createRequestWithUserData(
        type: _selectedType,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        address: _addressController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Solicitação enviada! Aguarde aprovação do administrador.',
            ),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _error = 'Erro ao salvar local: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
