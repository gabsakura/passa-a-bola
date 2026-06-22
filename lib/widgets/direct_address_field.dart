import 'package:flutter/material.dart';
import '../data/location_model.dart';
import '../services/direct_geocoding_service.dart';
import '../data/constants.dart';
import 'map_location_selector.dart';

/// Campo de endereço otimizado com geocodificação direta para CEP e posicionamento
class DirectAddressField extends StatefulWidget {
  final TextEditingController controller;
  final Function(LocationData?) onLocationChanged;
  final String? hintText;
  final String? labelText;
  final bool isRequired;
  final LocationData? initialLocation;

  const DirectAddressField({
    super.key,
    required this.controller,
    required this.onLocationChanged,
    this.hintText,
    this.labelText,
    this.isRequired = false,
    this.initialLocation,
  });

  @override
  State<DirectAddressField> createState() => _DirectAddressFieldState();
}

class _DirectAddressFieldState extends State<DirectAddressField> {
  List<String> _suggestions = [];
  bool _isLoading = false;
  bool _showSuggestions = false;
  LocationData? _selectedLocation;
  String? _error;
  DirectGeocodingResult? _lastResult;

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
        _lastResult = null;
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
      // Usar geocodificação direta para obter CEP e coordenadas
      final result = await DirectGeocodingService.validateAndGeocode(text);

      if (mounted) {
        setState(() {
          _lastResult = result;
          _isLoading = false;
        });

        if (result.isValid) {
          // Criar LocationData com as informações obtidas
          final locationData = LocationData(
            latitude: result.latitude ?? 0.0,
            longitude: result.longitude ?? 0.0,
            address: result.formattedAddress ?? text,
            city: result.city,
            state: result.state,
            country: result.country,
          );

          setState(() {
            _selectedLocation = locationData;
            _showSuggestions = false;
          });

          widget.onLocationChanged(locationData);
        } else {
          setState(() {
            _error = result.error ?? 'Endereço não encontrado';
            _showSuggestions = true; // Mostrar opção de mapa
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erro ao buscar endereço. Use o mapa para selecionar.';
          _isLoading = false;
          _showSuggestions = true;
        });
      }
    }
  }

  Future<void> _getSuggestions(String text) async {
    if (text.length < 3) return;

    try {
      // Usar geocoding direto para obter sugestões (como scout_marker)
      final suggestions = await DirectGeocodingService.getAddressSuggestions(
        text,
      );

      if (mounted) {
        setState(() {
          _suggestions = suggestions;
          _showSuggestions = true;
        });
      }
    } catch (e) {
      print('DEBUG: Erro ao obter sugestões: $e');
    }
  }

  Future<void> _selectSuggestion(String suggestion) async {
    setState(() {
      _isLoading = true;
      _showSuggestions = false;
    });

    try {
      // Validar o endereço selecionado
      final result = await DirectGeocodingService.validateAndGeocode(
        suggestion,
      );

      if (result.isValid) {
        final locationData = LocationData(
          latitude: result.latitude ?? 0.0,
          longitude: result.longitude ?? 0.0,
          address: result.formattedAddress ?? suggestion,
          city: result.city,
          state: result.state,
          country: result.country,
        );

        setState(() {
          _selectedLocation = locationData;
          _lastResult = result;
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
            hintText:
                widget.hintText ??
                'Digite o endereço (ex: Rua Saturno, 123)...',
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
          onTap: () {
            if (widget.controller.text.length >= 3) {
              _getSuggestions(widget.controller.text);
            }
          },
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

        // Resultado da geocodificação
        if (_lastResult != null && _lastResult!.isValid)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green[600],
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Endereço Encontrado',
                        style: KTextStyle.smallText.copyWith(
                          color: Colors.green[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Chip(
                      label: Text(
                        _lastResult!.method,
                        style: const TextStyle(fontSize: 10),
                      ),
                      backgroundColor: Colors.green[100],
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _lastResult!.displayAddress,
                  style: KTextStyle.smallText.copyWith(
                    color: Colors.green[600],
                  ),
                ),
                if (_lastResult!.hasPostalCode) ...[
                  const SizedBox(height: 2),
                  Text(
                    'CEP: ${_lastResult!.postalCode}',
                    style: KTextStyle.smallText.copyWith(
                      color: Colors.green[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                if (_lastResult!.hasNumber) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Número encontrado: ${_lastResult!.streetNumber}',
                    style: KTextStyle.smallText.copyWith(
                      color: Colors.green[600],
                    ),
                  ),
                ],
                Text(
                  'Coordenadas: ${_lastResult!.latitude?.toStringAsFixed(4)}, ${_lastResult!.longitude?.toStringAsFixed(4)}',
                  style: KTextStyle.smallText.copyWith(
                    color: Colors.green[600],
                  ),
                ),
                Text(
                  'Confiança: ${(_lastResult!.confidence * 100).toInt()}%',
                  style: KTextStyle.smallText.copyWith(
                    color: Colors.green[600],
                  ),
                ),
              ],
            ),
          ),

        // Mensagem de erro
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
                    _error!,
                    style: KTextStyle.smallText.copyWith(
                      color: Colors.orange[700],
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _openMapSelector,
                  child: const Text('Usar Mapa'),
                ),
              ],
            ),
          ),

        // Dica para o usuário
        if (widget.controller.text.isNotEmpty &&
            _lastResult == null &&
            !_isLoading)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.blue[600], size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Dica: Inclua o número da rua para maior precisão (ex: Rua Saturno, 123)',
                    style: KTextStyle.smallText.copyWith(
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
