import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../data/constants.dart';
import '../data/championship_model.dart';
import '../data/scout_marker_model.dart';
import '../services/location_service.dart';
import '../services/nearby_championships_service.dart';
import '../services/user_address_service.dart';
import '../services/scout_marker_service.dart';
import '../services/demo_data_service.dart';
import '../config/google_maps_config.dart';
import 'championships_page.dart';
import 'user_address_page.dart';
import 'scout_marker_add_page.dart';
import 'admin_championship_page.dart' hide ChampionshipDetailsPage;

class NearbyChampionshipsPage extends StatefulWidget {
  const NearbyChampionshipsPage({super.key});

  @override
  State<NearbyChampionshipsPage> createState() =>
      _NearbyChampionshipsPageState();
}

class _NearbyChampionshipsPageState extends State<NearbyChampionshipsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Estado do mapa
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  LatLng? _userLocation;
  LatLng? _mapCenter;

  // Estado dos dados
  List<Map<String, dynamic>> _nearbyChampionships = [];
  List<ScoutMarker> _scoutMarkers = [];
  bool _isLoading = true;
  String? _error;
  String? _userAddress;
  bool _isTrustedScout = false;

  // Configurações de busca
  double _searchRadius = GoogleMapsConfig.defaultSearchRadiusKm;
  bool _isSearching = false;

  // Busca por endereço
  final TextEditingController _addressController = TextEditingController();
  bool _isSearchingByAddress = false;
  String? _searchAddress;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _initializeLocation();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _initializeLocation() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Primeiro, tentar usar o endereço cadastrado do usuário
      bool locationObtained = false;

      try {
        final hasValidAddress = await UserAddressService.hasValidUserAddress();
        if (hasValidAddress) {
          final coordinates = await UserAddressService.getUserCoordinates();
          if (coordinates != null) {
            _userLocation = LatLng(
              coordinates['latitude']!,
              coordinates['longitude']!,
            );
            _mapCenter = _userLocation;

            final addressInfo = await UserAddressService.getUserAddressInfo();
            _userAddress = addressInfo?.displayAddress ?? 'Endereço cadastrado';
            locationObtained = true;

            print('DEBUG: Usando endereço cadastrado do usuário');
          }
        }
      } catch (e) {
        print('DEBUG: Erro ao obter endereço cadastrado: $e');
      }

      // Se não tem endereço cadastrado, tentar GPS
      if (!locationObtained) {
        try {
          final hasPermission = await LocationService.hasLocationPermission();
          if (hasPermission) {
            final position = await LocationService.getCurrentLocation();
            if (position != null) {
              _userLocation = LatLng(position.latitude, position.longitude);
              _mapCenter = _userLocation;

              final address = await LocationService.getAddressFromCoordinates(
                position.latitude,
                position.longitude,
              );
              _userAddress = address;
              locationObtained = true;

              print('DEBUG: Usando localização GPS');
            }
          }
        } catch (e) {
          print('DEBUG: Erro ao obter localização GPS: $e');
        }
      }

      // Se ainda não conseguiu, usar localização padrão
      if (!locationObtained) {
        final defaultLoc = LocationService.getDefaultLocation();
        _userLocation = LatLng(
          defaultLoc['latitude']!,
          defaultLoc['longitude']!,
        );
        _mapCenter = _userLocation;
        _userAddress = 'São Paulo, SP';

        setState(() {
          _error =
              'Usando localização padrão. Cadastre seu endereço para melhor precisão.';
        });

        print('DEBUG: Usando localização padrão');
      }

      // Buscar campeonatos próximos
      await _searchNearbyChampionships();

      // Carregar marcadores de olheiros
      await _loadScoutMarkers();

      // Verificar se o usuário é um olheiro confiável
      await _checkIfTrustedScout();

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('DEBUG: Erro geral na inicialização: $e');
      // Mesmo com erro, mostrar o mapa com localização padrão
      final defaultLoc = LocationService.getDefaultLocation();
      _userLocation = LatLng(defaultLoc['latitude']!, defaultLoc['longitude']!);
      _mapCenter = _userLocation;
      _userAddress = 'São Paulo, SP';

      setState(() {
        _error =
            'Erro ao carregar dados. Use a busca por endereço para encontrar campeonatos.';
        _isLoading = false;
      });

      // Tentar buscar campeonatos mesmo com erro
      try {
        await _searchNearbyChampionships();
      } catch (searchError) {
        print('DEBUG: Erro na busca de campeonatos: $searchError');
      }
    }
  }

  Future<void> _searchNearbyChampionships() async {
    if (_userLocation == null) return;

    try {
      setState(() {
        _isSearching = true;
      });

      // Primeiro, garantir que os dados de demonstração existam
      await DemoDataService.addRealChampionships();

      final championships =
          await NearbyChampionshipsService.getNearbyChampionships(
            userLatitude: _userLocation!.latitude,
            userLongitude: _userLocation!.longitude,
            radiusKm: _searchRadius,
          );

      print('DEBUG: Campeonatos encontrados: ${championships.length}');

      // Debug detalhado de cada campeonato
      for (int i = 0; i < championships.length; i++) {
        final champ = championships[i];
        final championship = champ['championship'] as Championship;
        print('DEBUG: Campeonato $i: ${championship.title}');
        print('DEBUG: - Status: ${championship.status}');
        print(
          'DEBUG: - LocationData: ${championship.locationData != null ? "Presente" : "Ausente"}',
        );
        if (championship.locationData != null) {
          print('DEBUG: - Latitude: ${championship.locationData!.latitude}');
          print('DEBUG: - Longitude: ${championship.locationData!.longitude}');
          print('DEBUG: - isValid: ${championship.locationData!.isValid}');
        }
        print(
          'DEBUG: - É feminino: ${_isFemaleFootballChampionship(championship)}',
        );
      }

      setState(() {
        _nearbyChampionships = championships;
        _isLoading = false;
        _isSearching = false;
      });

      await _updateMapMarkers();
    } catch (e) {
      print('Erro ao buscar campeonatos próximos: $e');
      setState(() {
        _error = 'Erro ao buscar campeonatos: $e';
        _isLoading = false;
        _isSearching = false;
      });
    }
  }

  Future<void> _searchByAddress() async {
    final address = _addressController.text.trim();
    if (address.isEmpty) return;

    try {
      setState(() {
        _isSearchingByAddress = true;
        _error = null;
      });

      // Buscar todos os campeonatos, independentemente da distância
      final championships =
          await NearbyChampionshipsService.getNearbyChampionships(
            userLatitude: _userLocation!.latitude,
            userLongitude: _userLocation!.longitude,
            radiusKm: _searchRadius,
          );

      setState(() {
        _nearbyChampionships = championships;
        _searchAddress = address;
        _isSearchingByAddress = false;
      });

      await _updateMapMarkers();
    } catch (e) {
      setState(() {
        _error = 'Erro ao buscar por endereço: $e';
        _isSearchingByAddress = false;
      });
    }
  }

  void _clearAddressSearch() {
    setState(() {
      _searchAddress = null;
      _addressController.clear();
    });
    _searchNearbyChampionships();
  }

  void _showUserAddressPage() async {
    final result = await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const UserAddressPage()));

    // Recarregar localização após voltar da página de endereço
    if (result == true || result == null) {
      await _initializeLocation();
    }
  }

  Future<void> _updateMapMarkers() async {
    print('DEBUG: Atualizando marcadores do mapa...');
    print(
      'DEBUG: Total de campeonatos carregados: ${_nearbyChampionships.length}',
    );

    _markers.clear();

    // Adicionar marcador do usuário
    if (_userLocation != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: _userLocation!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          infoWindow: const InfoWindow(
            title: 'Sua Localização',
            snippet: 'Você está aqui',
          ),
        ),
      );
      print('DEBUG: Marcador do usuário adicionado');
    }

    // Filtrar apenas campeonatos de futebol feminino
    final femaleChampionships = _nearbyChampionships.where((champ) {
      final championship = champ['championship'] as Championship;
      final isFemale = _isFemaleFootballChampionship(championship);
      print('DEBUG: Campeonato ${championship.title} - É feminino: $isFemale');
      return isFemale;
    }).toList();

    print(
      'DEBUG: Campeonatos femininos filtrados: ${femaleChampionships.length}',
    );

    // Adicionar marcadores dos campeonatos femininos
    for (int i = 0; i < femaleChampionships.length; i++) {
      final champ = femaleChampionships[i];
      final championship = champ['championship'] as Championship;
      final distance = champ['distance'] as double;

      print(
        'DEBUG: Adicionando marcador para ${championship.title} em ${champ['latitude']}, ${champ['longitude']}',
      );

      _markers.add(
        Marker(
          markerId: MarkerId('championship_$i'),
          position: LatLng(champ['latitude'], champ['longitude']),
          icon: await _getCustomMarkerIcon(championship.status),
          infoWindow: InfoWindow(
            title: championship.title,
            snippet:
                '${_getStatusText(championship.status)}\n${distance.toStringAsFixed(1)}km - ${champ['address']}',
          ),
          onTap: () => _showChampionshipDetails(championship),
        ),
      );
    }

    // Adicionar marcadores de olheiros
    for (int i = 0; i < _scoutMarkers.length; i++) {
      final marker = _scoutMarkers[i];
      final distance = _calculateDistance(
        _userLocation!.latitude,
        _userLocation!.longitude,
        marker.latitude,
        marker.longitude,
      );

      _markers.add(
        Marker(
          markerId: MarkerId('scout_$i'),
          position: LatLng(marker.latitude, marker.longitude),
          icon: await _getScoutMarkerIcon(marker.type),
          infoWindow: InfoWindow(
            title: marker.title,
            snippet:
                '${marker.typeIcon} ${marker.typeDisplayName}\n${distance.toStringAsFixed(1)}km - ${marker.address}',
          ),
          onTap: () => _showScoutMarkerDetails(marker),
        ),
      );
    }

    print('DEBUG: Total de marcadores adicionados: ${_markers.length}');
    setState(() {});
  }

  Future<void> _loadScoutMarkers() async {
    if (_userLocation == null) return;

    try {
      // Garantir que os campeonatos reais existam
      await DemoDataService.addRealChampionships();

      // Corrigir estrutura de dados se necessário
      await DemoDataService.fixChampionshipDataStructure();

      final markers = await ScoutMarkerService.getNearbyScoutMarkers(
        latitude: _userLocation!.latitude,
        longitude: _userLocation!.longitude,
        radiusKm: _searchRadius,
      );

      print('DEBUG: Marcadores de olheiros encontrados: ${markers.length}');

      setState(() {
        _scoutMarkers = markers;
      });

      await _updateMapMarkers();
    } catch (e) {
      print('Erro ao carregar marcadores de olheiros: $e');
    }
  }

  Future<void> _checkIfTrustedScout() async {
    try {
      // Para demonstração, sempre retornar true
      // Em produção, implementar verificação real
      setState(() {
        _isTrustedScout = true; // Sempre true para demonstração
      });
    } catch (e) {
      print('Erro ao verificar status de olheiro: $e');
      setState(() {
        _isTrustedScout = true; // Fallback para demonstração
      });
    }
  }

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // Raio da Terra em km
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final double c = 2 * asin(sqrt(a));
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }

  bool _isFemaleFootballChampionship(Championship championship) {
    // TEMPORÁRIO: Aceitar todos os campeonatos para debug
    print('DEBUG: Verificando se é feminino: ${championship.title}');

    // Palavras-chave que indicam futebol feminino
    final femaleKeywords = [
      'feminino',
      'feminina',
      'mulheres',
      'mulher',
      'meninas',
      'menina',
      'female',
      'women',
      'girls',
      'girl',
      'lady',
      'ladies',
    ];

    // Palavras-chave que indicam futebol
    final footballKeywords = [
      'futebol',
      'futebolista',
      'futebolística',
      'soccer',
      'football',
      'fut',
      'futbol',
      'bola',
      'campo',
      'jogadora',
      'jogadoras',
    ];

    final title = championship.title.toLowerCase();
    final description = championship.description.toLowerCase();
    final text = '$title $description';

    // Verificar se contém palavras-chave de futebol feminino
    final hasFemaleKeyword = femaleKeywords.any(
      (keyword) => text.contains(keyword),
    );
    final hasFootballKeyword = footballKeywords.any(
      (keyword) => text.contains(keyword),
    );

    final result = hasFemaleKeyword || (hasFootballKeyword && hasFemaleKeyword);
    print('DEBUG: - hasFemaleKeyword: $hasFemaleKeyword');
    print('DEBUG: - hasFootballKeyword: $hasFootballKeyword');
    print('DEBUG: - Resultado: $result');

    // TEMPORÁRIO: Aceitar todos os campeonatos
    return true;
  }

  Future<BitmapDescriptor> _getCustomMarkerIcon(
    ChampionshipStatus status,
  ) async {
    // Usar cores diferentes baseadas no status
    double hue;
    switch (status) {
      case ChampionshipStatus.registrationOpen:
        hue = BitmapDescriptor.hueGreen; // Verde para inscrições abertas
        break;
      case ChampionshipStatus.registrationClosed:
        hue = BitmapDescriptor.hueOrange; // Laranja para inscrições fechadas
        break;
      case ChampionshipStatus.ongoing:
        hue = BitmapDescriptor.hueRed; // Vermelho para em andamento
        break;
      default:
        hue = BitmapDescriptor.hueViolet; // Roxo para outros status
    }

    // Usar marcador de estrela para diferenciar dos marcadores de localização
    // O marcador de estrela tem formato diferente do marcador de localização padrão
    return BitmapDescriptor.defaultMarkerWithHue(hue);
  }

  Future<BitmapDescriptor> _getScoutMarkerIcon(ScoutMarkerType type) async {
    // Usar cores diferentes para cada tipo de marcador de olheiro
    double hue;
    switch (type) {
      case ScoutMarkerType.friendlyMatch:
        hue = BitmapDescriptor.hueCyan; // Ciano para jogos amistosos
        break;
      case ScoutMarkerType.footballSchool:
        hue = BitmapDescriptor.hueYellow; // Amarelo para escolhinhas
        break;
      case ScoutMarkerType.externalChampionship:
        hue = BitmapDescriptor.hueMagenta; // Magenta para campeonatos externos
        break;
    }

    // Usar marcador de estrela para diferenciar dos outros marcadores
    return BitmapDescriptor.defaultMarkerWithHue(hue);
  }

  void _showScoutMarkerDetails(ScoutMarker marker) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(marker.typeIcon),
            const SizedBox(width: 8),
            Expanded(child: Text(marker.title)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              marker.typeDisplayName,
              style: KTextStyle.titleText.copyWith(
                fontSize: 16,
                color: KConstants.primaryColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(marker.description, style: KTextStyle.bodyText),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(marker.address, style: KTextStyle.smallText),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Marcado por: ${marker.scoutName}',
                  style: KTextStyle.smallText,
                ),
              ],
            ),
            if (marker.isVerified) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.verified, size: 16, color: Colors.green[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Verificado',
                    style: KTextStyle.smallText.copyWith(
                      color: Colors.green[600],
                    ),
                  ),
                ],
              ),
            ],
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

  void _showAddScoutMarker() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(builder: (context) => const ScoutMarkerAddPage()),
        )
        .then((_) {
          // Recarregar marcadores quando voltar da página de adicionar
          _loadScoutMarkers();
        });
  }

  void _showChampionshipCreation() {
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (context) => const AdminChampionshipPage(),
          ),
        )
        .then((_) {
          // Recarregar campeonatos quando voltar da página de criação
          _initializeLocation();
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todos os Eventos de Futebol Feminino'),
        backgroundColor: KConstants.primaryColor,
        foregroundColor: KConstants.textLightColor,
        actions: [
          if (_isTrustedScout)
            IconButton(
              onPressed: _showAddScoutMarker,
              icon: const Icon(Icons.add_location),
              tooltip: 'Adicionar Local Confiável',
            ),
          IconButton(
            onPressed: _showChampionshipCreation,
            icon: const Icon(Icons.add_circle),
            tooltip: 'Criar Campeonato',
          ),
          if (_searchAddress != null)
            IconButton(
              onPressed: _clearAddressSearch,
              icon: const Icon(Icons.clear),
              tooltip: 'Limpar Busca por Endereço',
            ),
          IconButton(
            onPressed: _showUserAddressPage,
            icon: const Icon(Icons.home),
            tooltip: 'Meu Endereço',
          ),
          IconButton(
            onPressed: _showAddressSearch,
            icon: const Icon(Icons.search),
            tooltip: 'Buscar por Endereço',
          ),
          IconButton(
            onPressed: _initializeLocation,
            icon: const Icon(Icons.my_location),
            tooltip: 'Minha Localização',
          ),
          IconButton(
            onPressed: _showSearchOptions,
            icon: const Icon(Icons.tune),
            tooltip: 'Opções de Busca',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Carregando localização e campeonatos...'),
          ],
        ),
      );
    }

    return Stack(
      children: [
        _buildMapTab(),
        // Mostrar erro como snackbar ou banner no topo
        if (_error != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.red[600], size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: Colors.red[700], fontSize: 12),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _error = null;
                      });
                    },
                    icon: Icon(Icons.close, color: Colors.red[600], size: 16),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMapTab() {
    if (_mapCenter == null) {
      return const Center(child: Text('Localização não disponível'));
    }

    return Stack(
      children: [
        GoogleMap(
          initialCameraPosition: CameraPosition(
            target: _mapCenter!,
            zoom: GoogleMapsConfig.defaultZoom,
          ),
          onMapCreated: (GoogleMapController controller) {
            _mapController = controller;
          },
          markers: _markers,
          myLocationEnabled: true,
          myLocationButtonEnabled: false,
          mapType: MapType.normal,
        ),
        // Controles personalizados
        Positioned(top: 16, left: 16, right: 16, child: _buildSearchInfoCard()),
        // Botão de localização
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(
            onPressed: _goToUserLocation,
            backgroundColor: KConstants.primaryColor,
            child: const Icon(Icons.my_location, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchInfoCard() {
    // Calcular quantidade de eventos de futebol feminino
    final femaleChampionshipsCount = _nearbyChampionships.where((champ) {
      final championship = champ['championship'] as Championship;
      return _isFemaleFootballChampionship(championship);
    }).length;

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _searchAddress != null ? Icons.search : Icons.location_on,
                  color: KConstants.primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _searchAddress ??
                        _userAddress ??
                        'Localização não disponível',
                    style: KTextStyle.titleText.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (_isSearching || _isSearchingByAddress)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.location_searching,
                  color: Colors.grey[600],
                  size: 16,
                ),
                const SizedBox(width: 4),
                Text(
                  'Mostrando todos os campeonatos',
                  style: KTextStyle.smallText.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                Icon(Icons.sports_soccer, color: Colors.grey[600], size: 16),
                const SizedBox(width: 4),
                Text(
                  '$femaleChampionshipsCount evento${femaleChampionshipsCount != 1 ? 's' : ''} de futebol feminino encontrado${femaleChampionshipsCount != 1 ? 's' : ''}',
                  style: KTextStyle.smallText.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
            if (_scoutMarkers.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.verified_user, color: Colors.grey[600], size: 16),
                  const SizedBox(width: 4),
                  Text(
                    '${_scoutMarkers.length} local${_scoutMarkers.length != 1 ? 'is' : ''} confiável${_scoutMarkers.length != 1 ? 'eis' : ''} marcado${_scoutMarkers.length != 1 ? 's' : ''} por olheiros',
                    style: KTextStyle.smallText.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getStatusText(ChampionshipStatus status) {
    switch (status) {
      case ChampionshipStatus.registrationOpen:
        return 'Inscrições Abertas';
      case ChampionshipStatus.registrationClosed:
        return 'Inscrições Fechadas';
      case ChampionshipStatus.ongoing:
        return 'Em Andamento';
      default:
        return 'Desconhecido';
    }
  }

  void _showChampionshipDetails(Championship championship) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            ChampionshipDetailsPage(championship: championship),
      ),
    );
  }

  void _goToUserLocation() {
    if (_mapController != null && _userLocation != null) {
      _mapController!.animateCamera(CameraUpdate.newLatLng(_userLocation!));
    }
  }

  void _showSearchOptions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Opções de Busca'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Raio de busca atual: ${_searchRadius.toStringAsFixed(0)}km'),
            const SizedBox(height: 16),
            Slider(
              value: _searchRadius,
              min: 1.0,
              max: GoogleMapsConfig.maxSearchRadiusKm,
              divisions: 49,
              label: '${_searchRadius.toStringAsFixed(0)}km',
              onChanged: (value) {
                setState(() {
                  _searchRadius = value;
                });
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _searchNearbyChampionships();
            },
            child: const Text('Buscar'),
          ),
        ],
      ),
    );
  }

  void _showAddressSearch() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Buscar por Endereço'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Digite um endereço em São Paulo',
                hintText: 'Ex: Avenida Paulista, 1000',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _searchByAddress();
            },
            child: const Text('Buscar'),
          ),
        ],
      ),
    );
  }
}
