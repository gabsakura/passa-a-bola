import 'package:flutter/material.dart';
import '../data/location_model.dart';
import '../services/working_address_service.dart';
import '../data/constants.dart';
import 'map_location_selector.dart';

/// Campo de endereço inteligente com sugestões e seleção no mapa
class SmartAddressField extends StatefulWidget {
  final TextEditingController controller;
  final Function(LocationData?) onLocationChanged;
  final String? hintText;
  final String? labelText;
  final bool isRequired;
  final LocationData? initialLocation;

  const SmartAddressField({
    super.key,
    required this.controller,
    required this.onLocationChanged,
    this.hintText,
    this.labelText,
    this.isRequired = false,
    this.initialLocation,
  });

  @override
  State<SmartAddressField> createState() => _SmartAddressFieldState();
}

class _SmartAddressFieldState extends State<SmartAddressField> {
  List<String> _suggestions = [];
  bool _isLoading = false;
  bool _showSuggestions = false;
  LocationData? _selectedLocation;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation;
    if (_selectedLocation != null) {
      widget.controller.text = _selectedLocation!.address ?? '';
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _onTextChanged(String text) async {
    if (text.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
        _selectedLocation = null;
        widget.onLocationChanged(null);
      });
      return;
    }

    if (text.length < 3) {
      setState(() {
        _suggestions = [];
        _showSuggestions = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final suggestions = await WorkingAddressService.getAddressSuggestions(
        text,
      );

      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          // Sempre mostrar opção de mapa, mesmo quando há sugestões
          _showSuggestions = true;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erro ao buscar sugestões. Use o mapa para selecionar.';
          _isLoading = false;
          // Mesmo com erro, mostrar opção de mapa
          _showSuggestions = true;
        });
      }
    }
  }

  Future<void> _selectSuggestion(String suggestion) async {
    setState(() {
      _isLoading = true;
      _showSuggestions = false;
    });

    try {
      // Validar o endereço selecionado
      final result = await WorkingAddressService.validateAddress(suggestion);

      if (result.isValid) {
        final locationData = LocationData(
          latitude: result.latitude ?? 0.0,
          longitude: result.longitude ?? 0.0,
          address: result.formattedAddress,
          city: result.city,
          state: result.state,
          country: result.country,
        );

        setState(() {
          _selectedLocation = locationData;
          widget.controller.text = suggestion;
        });

        widget.onLocationChanged(locationData);
      } else {
        setState(() {
          _error = 'Endereço inválido: ${result.error}';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Erro ao validar endereço: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _openMapSelector() async {
    final result = await Navigator.of(context).push<LocationData>(
      MaterialPageRoute(
        builder: (context) => MapLocationSelector(
          title: 'Selecionar Localização',
          initialLocation: _selectedLocation,
          onLocationSelected: (location) {
            Navigator.of(context).pop(location);
          },
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedLocation = result;
        widget.controller.text = result.address ?? '';
        _showSuggestions = false;
      });
      widget.onLocationChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Campo de texto
        TextFormField(
          controller: widget.controller,
          decoration: InputDecoration(
            hintText: widget.hintText ?? 'Digite o endereço...',
            labelText: widget.labelText,
            prefixIcon: const Icon(Icons.location_on),
            suffixIcon: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    onPressed: _openMapSelector,
                    icon: const Icon(Icons.map),
                    tooltip: 'Selecionar no Mapa',
                  ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: KConstants.primaryColor),
            ),
          ),
          onChanged: _onTextChanged,
          validator: widget.isRequired
              ? (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Endereço é obrigatório';
                  }
                  if (_selectedLocation == null) {
                    return 'Selecione um endereço válido';
                  }
                  return null;
                }
              : null,
        ),

        // Lista de sugestões
        if (_showSuggestions)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Opção de selecionar no mapa (sempre no topo)
                ListTile(
                  leading: const Icon(Icons.map, color: Colors.blue),
                  title: const Text('Selecionar no Mapa'),
                  subtitle: const Text('Toque para abrir o mapa'),
                  onTap: _openMapSelector,
                ),

                // Mostrar sugestões de texto apenas se existirem
                if (_suggestions.isNotEmpty) ...[
                  const Divider(height: 1),
                  ..._suggestions.take(5).map((suggestion) {
                    return ListTile(
                      leading: const Icon(
                        Icons.location_on,
                        color: Colors.green,
                      ),
                      title: Text(
                        suggestion,
                        style: KTextStyle.bodyText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _selectSuggestion(suggestion),
                    );
                  }),
                ],
              ],
            ),
          ),

        // Mensagem de erro ou informação
        if (_error != null)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.orange[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sugestões de texto não disponíveis. Use o mapa para selecionar a localização.',
                    style: KTextStyle.smallText.copyWith(
                      color: Colors.orange[700],
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _openMapSelector,
                  child: const Text('Abrir Mapa'),
                ),
              ],
            ),
          ),

        // Informação da localização selecionada
        if (_selectedLocation != null)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Localização Confirmada',
                        style: KTextStyle.smallText.copyWith(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Lat: ${_selectedLocation!.latitude.toStringAsFixed(4)}, Lng: ${_selectedLocation!.longitude.toStringAsFixed(4)}',
                        style: KTextStyle.smallText.copyWith(
                          color: Colors.green[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _openMapSelector,
                  icon: const Icon(Icons.edit_location),
                  tooltip: 'Alterar Localização',
                ),
              ],
            ),
          ),
      ],
    );
  }
}
