import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../data/location_model.dart';

/// Widget de preview do mapa com pin (como scout_marker)
class MapPreview extends StatefulWidget {
  final LocationData location;
  final double height;
  final Function(LocationData)? onLocationChanged;

  const MapPreview({
    super.key,
    required this.location,
    this.height = 200,
    this.onLocationChanged,
  });

  @override
  State<MapPreview> createState() => _MapPreviewState();
}

class _MapPreviewState extends State<MapPreview> {
  Set<Marker> _markers = {};

  @override
  void initState() {
    super.initState();
    _createMarker();
  }

  void _createMarker() {
    _markers = {
      Marker(
        markerId: const MarkerId('selected_location'),
        position: LatLng(widget.location.latitude, widget.location.longitude),
        infoWindow: InfoWindow(
          title: widget.location.address ?? 'Localização',
          snippet:
              'Lat: ${widget.location.latitude.toStringAsFixed(4)}, Lng: ${widget.location.longitude.toStringAsFixed(4)}',
        ),
      ),
    };
  }

  @override
  void didUpdateWidget(MapPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location.latitude != widget.location.latitude ||
        oldWidget.location.longitude != widget.location.longitude) {
      _createMarker();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: GoogleMap(
          onMapCreated: (GoogleMapController controller) {
            // Controller não é necessário para este preview
          },
          initialCameraPosition: CameraPosition(
            target: LatLng(widget.location.latitude, widget.location.longitude),
            zoom: 16.0,
          ),
          markers: _markers,
          mapType: MapType.normal,
          myLocationButtonEnabled: false,
          zoomControlsEnabled: false,
          mapToolbarEnabled: false,
          onTap: (LatLng position) {
            // Permitir mudança de localização ao tocar no mapa
            if (widget.onLocationChanged != null) {
              final newLocation = LocationData(
                latitude: position.latitude,
                longitude: position.longitude,
                address: widget.location.address, // Manter endereço original
                city: widget.location.city,
                state: widget.location.state,
                country: widget.location.country,
              );
              widget.onLocationChanged!(newLocation);
            }
          },
        ),
      ),
    );
  }
}
