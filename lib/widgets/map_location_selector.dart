import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../data/location_model.dart';
import '../services/location_service.dart';
import '../data/constants.dart';

/// Widget para seleção de localização no mapa (baseado no sistema scout_marker)
class MapLocationSelector extends StatefulWidget {
  final Function(LocationData) onLocationSelected;
  final LocationData? initialLocation;
  final String? title;

  const MapLocationSelector({
    super.key,
    required this.onLocationSelected,
    this.initialLocation,
    this.title,
  });

  @override
  State<MapLocationSelector> createState() => _MapLocationSelectorState();
}

class _MapLocationSelectorState extends State<MapLocationSelector> {
  GoogleMapController? _mapController;
  LatLng? _selectedLocation;
  LatLng? _currentLocation;
  bool _isLoading = true;
  String? _error;
  String? _addressText;

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Primeiro, tentar obter localização atual via GPS
      final position = await LocationService.getCurrentLocation();

      if (position != null) {
        _currentLocation = LatLng(position.latitude, position.longitude);
        _selectedLocation = _currentLocation;

        // Obter endereço da localização atual
        final address = await LocationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (mounted) {
          setState(() {
            _addressText = address;
            _isLoading = false;
          });
        }
      } else {
        // Se não conseguir GPS, usar localização inicial ou padrão
        if (widget.initialLocation != null) {
          _selectedLocation = LatLng(
            widget.initialLocation!.latitude,
            widget.initialLocation!.longitude,
          );
          _addressText = widget.initialLocation!.address;
        } else {
          // Usar São Paulo como padrão
          _selectedLocation = const LatLng(-23.5505, -46.6333);
          _addressText = 'São Paulo, SP, Brasil';
        }

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erro ao obter localização: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title ?? 'Selecionar Localização'),
        backgroundColor: KConstants.primaryColor,
        foregroundColor: KConstants.textLightColor,
        actions: [
          if (_selectedLocation != null)
            IconButton(
              onPressed: _confirmSelection,
              icon: const Icon(Icons.check),
              tooltip: 'Confirmar Localização',
            ),
        ],
      ),
      body: Column(
        children: [
          // Barra de endereço atual
          Container(
            padding: const EdgeInsets.all(16),
            color: KConstants.backgroundColor,
            child: Row(
              children: [
                Icon(Icons.location_on, color: KConstants.primaryColor),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _addressText ?? 'Obtendo localização...',
                    style: KTextStyle.bodyText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_currentLocation != null)
                  IconButton(
                    onPressed: _goToCurrentLocation,
                    icon: const Icon(Icons.my_location),
                    tooltip: 'Minha Localização',
                  ),
              ],
            ),
          ),

          // Mapa
          Expanded(child: _buildMap()),

          // Botões de ação
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _goToCurrentLocation,
                    icon: const Icon(Icons.my_location),
                    label: const Text('Minha Localização'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: KConstants.primaryColor,
                      foregroundColor: KConstants.textLightColor,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _selectedLocation != null
                        ? _confirmSelection
                        : null,
                    icon: const Icon(Icons.check),
                    label: const Text('Confirmar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMap() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Obtendo sua localização...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 48, color: Colors.red[400]),
            const SizedBox(height: 16),
            Text(
              _error!,
              style: KTextStyle.bodyText.copyWith(color: Colors.red[700]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _initializeLocation,
              child: const Text('Tentar Novamente'),
            ),
          ],
        ),
      );
    }

    return GoogleMap(
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
      },
      initialCameraPosition: CameraPosition(
        target: _selectedLocation ?? const LatLng(-23.5505, -46.6333),
        zoom: 15.0,
      ),
      markers: _selectedLocation != null
          ? {
              Marker(
                markerId: const MarkerId('selected_location'),
                position: _selectedLocation!,
                infoWindow: const InfoWindow(
                  title: 'Localização Selecionada',
                  snippet: 'Toque no mapa para alterar',
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueRed,
                ),
              ),
            }
          : {},
      onTap: _onMapTapped,
      myLocationEnabled: true,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: true,
      mapType: MapType.normal,
    );
  }

  void _onMapTapped(LatLng location) async {
    setState(() {
      _selectedLocation = location;
      _isLoading = true;
    });

    try {
      // Obter endereço da nova localização
      final address = await LocationService.getAddressFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (mounted) {
        setState(() {
          _addressText = address ?? 'Endereço não encontrado';
          _isLoading = false;
        });
      }

      // Mover câmera para a nova localização
      _mapController?.animateCamera(CameraUpdate.newLatLng(location));
    } catch (e) {
      if (mounted) {
        setState(() {
          _addressText = 'Erro ao obter endereço';
          _isLoading = false;
        });
      }
    }
  }

  void _goToCurrentLocation() async {
    if (_currentLocation == null) {
      await _initializeLocation();
      return;
    }

    setState(() {
      _selectedLocation = _currentLocation;
    });

    _mapController?.animateCamera(CameraUpdate.newLatLng(_currentLocation!));

    // Obter endereço da localização atual
    try {
      final address = await LocationService.getAddressFromCoordinates(
        _currentLocation!.latitude,
        _currentLocation!.longitude,
      );

      if (mounted) {
        setState(() {
          _addressText = address ?? 'Endereço não encontrado';
        });
      }
    } catch (e) {
      print('Erro ao obter endereço: $e');
    }
  }

  void _confirmSelection() {
    if (_selectedLocation != null) {
      final locationData = LocationData(
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        address: _addressText,
      );
      widget.onLocationSelected(locationData);
      Navigator.of(context).pop();
    }
  }
}
