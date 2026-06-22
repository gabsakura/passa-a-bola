import 'package:flutter/material.dart';
import '../data/location_model.dart';
import '../services/direct_geocoding_service.dart';
import '../data/constants.dart';
import 'map_location_selector.dart';
import 'map_preview.dart';

/// Campo de endereço simples com geocodificação direta e mapa (como scout_marker)
class SimpleAddressField extends StatefulWidget {
  final TextEditingController controller;
  final Function(LocationData?) onLocationChanged;
  final String? hintText;
  final String? labelText;
  final bool isRequired;
  final LocationData? initialLocation;

  const SimpleAddressField({
    super.key,
    required this.controller,
    required this.onLocationChanged,
    this.hintText,
    this.labelText,
    this.isRequired = false,
    this.initialLocation,
  });

  @override
  State<SimpleAddressField> createState() => _SimpleAddressFieldState();
}

class _SimpleAddressFieldState extends State<SimpleAddressField> {
  bool _isLoading = false;
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
    // Apenas limpar resultados quando texto estiver vazio
    if (text.trim().isEmpty) {
      setState(() {
        _selectedLocation = null;
        _lastResult = null;
        _error = null;
        widget.onLocationChanged(null);
      });
      return;
    }

    // Limpar erros quando usuário está digitando
    if (_error != null) {
      setState(() {
        _error = null;
        _lastResult = null;
      });
    }
  }

  Future<void> _searchAddress() async {
    final text = widget.controller.text.trim();

    if (text.isEmpty) {
      setState(() {
        _selectedLocation = null;
        _lastResult = null;
        _error = null;
        widget.onLocationChanged(null);
      });
      return;
    }

    if (text.length < 3) {
      setState(() {
        _error = 'Digite pelo menos 3 caracteres';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Geocodificação direta (como scout_marker)
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
          });

          widget.onLocationChanged(locationData);
        } else {
          setState(() {
            _error = result.error ?? 'Endereço não encontrado';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erro ao buscar endereço: $e';
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
      });
      widget.onLocationChanged(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Campo de texto com botão de busca
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: widget.controller,
                decoration: InputDecoration(
                  hintText:
                      widget.hintText ??
                      'Digite o endereço (ex: Rua Saturno, 123)...',
                  labelText: widget.labelText,
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
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
                onFieldSubmitted: (_) => _searchAddress(),
                validator: widget.isRequired
                    ? (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Endereço é obrigatório';
                        }
                        if (_selectedLocation == null) {
                          return 'Busque um endereço válido';
                        }
                        return null;
                      }
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            // Botão de busca
            _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    onPressed: _searchAddress,
                    icon: const Icon(Icons.search),
                    tooltip: 'Buscar Endereço',
                    style: IconButton.styleFrom(
                      backgroundColor: KConstants.primaryColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
            // Botão do mapa
            IconButton(
              onPressed: _openMapSelector,
              icon: const Icon(Icons.map),
              tooltip: 'Selecionar no Mapa',
            ),
          ],
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
                    'Número: ${_lastResult!.streetNumber}',
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

        // Dica de uso
        if (widget.controller.text.isNotEmpty &&
            _selectedLocation == null &&
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
                    'Digite o endereço e clique no botão de busca (🔍) ou pressione Enter',
                    style: KTextStyle.smallText.copyWith(
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
          ),

        // Mapa com pin (quando localização encontrada)
        if (_selectedLocation != null)
          Container(
            margin: const EdgeInsets.only(top: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Localização no Mapa',
                  style: KTextStyle.bodyText.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                MapPreview(
                  location: _selectedLocation!,
                  height: 200,
                  onLocationChanged: (location) {
                    setState(() {
                      _selectedLocation = location;
                      widget.controller.text = location.address ?? '';
                    });
                    widget.onLocationChanged(location);
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }
}
