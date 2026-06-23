import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:app/features/customers/data/services/geocoding_service.dart';
import 'package:app/features/customers/data/services/routing_service.dart';

class AddressPickerMap extends ConsumerStatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;
  final String? initialSearchQuery;
  final Future<void> Function(LatLng)? onSave;

  const AddressPickerMap({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialSearchQuery,
    this.onSave,
  });

  @override
  ConsumerState<AddressPickerMap> createState() => _AddressPickerMapState();
}

class _AddressPickerMapState extends ConsumerState<AddressPickerMap> {
  LatLng? _selectedLatLng;
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();
  List<GeocodingResult> _searchResults = [];
  bool _isSearching = false;
  Timer? _debounceTimer;

  // Driver Location and Routing State Variables
  LatLng? _driverLatLng;
  StreamSubscription<Position>? _positionStreamSubscription;
  RoutingRoute? _estimatedRoute;
  bool _isLoadingRoute = false;
  DateTime? _lastRoutingRequestTime;
  Timer? _dragDebounceTimer;
  Timer? _delayedRoutingTimer;
  final GlobalKey _mapKey = GlobalKey();

  // Track if location is modified to distinguish "View Route" from "Save Location"
  bool _isLocationModified = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLatLng = LatLng(widget.initialLatitude!, widget.initialLongitude!);
    }
    
    if (widget.initialSearchQuery != null && widget.initialSearchQuery!.isNotEmpty) {
      _searchController.text = widget.initialSearchQuery!;
      // Trigger initial search after build only if there are no saved coordinates
      if (_selectedLatLng == null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _performSearch(widget.initialSearchQuery!);
        });
      }
    }

    _initDriverLocationTracking();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _dragDebounceTimer?.cancel();
    _delayedRoutingTimer?.cancel();
    _positionStreamSubscription?.cancel();
    _searchController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
    return '${meters.round()} m';
  }

  String _formatDuration(double seconds) {
    final minutes = (seconds / 60).round();
    if (minutes < 1) {
      return 'Menos de 1 min';
    }
    return '$minutes min';
  }

  Future<void> _initDriverLocationTracking() async {
    debugPrint('Initializing driver location tracking...');
    bool serviceEnabled;
    LocationPermission permission;

    try {
      debugPrint('Checking if location service is enabled...');
      serviceEnabled = await Geolocator.isLocationServiceEnabled()
          .timeout(const Duration(seconds: 3));
      debugPrint('Location service enabled status: $serviceEnabled');
      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
        return;
      }

      debugPrint('Checking location permission...');
      permission = await Geolocator.checkPermission();
      debugPrint('Location permission status: $permission');
      if (permission == LocationPermission.denied) {
        debugPrint('Requesting location permission...');
        permission = await Geolocator.requestPermission();
        debugPrint('Requested location permission status: $permission');
        if (permission == LocationPermission.denied) {
          debugPrint('Location permission denied.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permission denied forever.');
        return;
      }

      debugPrint('Getting last known position in background...');
      Geolocator.getLastKnownPosition().then((lastKnown) {
        debugPrint('Last known position resolved: $lastKnown');
        if (lastKnown != null && mounted && _driverLatLng == null) {
          setState(() {
            _driverLatLng = LatLng(lastKnown.latitude, lastKnown.longitude);
          });
          _recalculateRoute(force: true);
        }
      }).catchError((e) {
        debugPrint('Error getting last known position: $e');
      });

      debugPrint('Getting current position in background...');
      Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.high,
          forceLocationManager: true,
        ),
        timeLimit: const Duration(seconds: 4),
      ).then((position) {
        debugPrint('Current position resolved: $position');
        if (mounted) {
          setState(() {
            _driverLatLng = LatLng(position.latitude, position.longitude);
          });
          _recalculateRoute(force: true);
        }
      }).catchError((e) {
        debugPrint('Error getting current position in background: $e');
        
        // Low accuracy fallback in background
        debugPrint('Getting current position (low accuracy) in background...');
        Geolocator.getCurrentPosition(
          locationSettings: AndroidSettings(
            accuracy: LocationAccuracy.low,
            forceLocationManager: true,
          ),
          timeLimit: const Duration(seconds: 3),
        ).then((lowPos) {
          debugPrint('Current position (low accuracy) resolved: $lowPos');
          if (mounted) {
            setState(() {
              _driverLatLng = LatLng(lowPos.latitude, lowPos.longitude);
            });
            _recalculateRoute(force: true);
          }
        }).catchError((err) {
          debugPrint('Error getting low accuracy position in background: $err');
        });
      });

      debugPrint('Subscribing to position stream...');
      // Set up position stream
      final positionStream = Geolocator.getPositionStream(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 20,
          forceLocationManager: true,
        ),
      );

      _positionStreamSubscription = positionStream.listen((Position position) {
        debugPrint('Position stream update: $position');
        if (!mounted) return;
        setState(() {
          _driverLatLng = LatLng(position.latitude, position.longitude);
        });
        _recalculateRoute();
      }, onError: (e) {
        debugPrint('Driver location stream error: $e');
      });
      debugPrint('Driver location stream subscribed.');
    } catch (e) {
      debugPrint('Driver location initialization error: $e');
    }
  }

  Future<void> _recalculateRoute({bool force = false}) async {
    final driver = _driverLatLng;
    final customer = _selectedLatLng;

    if (driver == null || customer == null) {
      setState(() {
        _estimatedRoute = null;
      });
      return;
    }

    final now = DateTime.now();
    if (!force && _lastRoutingRequestTime != null) {
      final difference = now.difference(_lastRoutingRequestTime!);
      if (difference.inSeconds < 5) {
        _scheduleDelayedRouteRecalculation();
        return;
      }
    }

    _lastRoutingRequestTime = now;
    _cancelDelayedRouteRecalculation();

    setState(() {
      _isLoadingRoute = true;
    });

    try {
      final routingService = ref.read(routingServiceProvider);
      final route = await routingService.getRoute(driver, customer);
      if (mounted) {
        setState(() {
          _estimatedRoute = route;
          _isLoadingRoute = false;
        });
      }
    } catch (e) {
      debugPrint('Routing recalculation error: $e');
      if (mounted) {
        setState(() {
          _isLoadingRoute = false;
        });
      }
    }
  }

  void _scheduleDelayedRouteRecalculation() {
    if (_delayedRoutingTimer?.isActive ?? false) return;
    _delayedRoutingTimer = Timer(const Duration(seconds: 5), () {
      _recalculateRoute();
    });
  }

  void _cancelDelayedRouteRecalculation() {
    _delayedRoutingTimer?.cancel();
  }

  void _debouncedRecalculateRoute() {
    _dragDebounceTimer?.cancel();
    _dragDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _recalculateRoute(force: true);
    });
  }

  void _onSearchChanged(String query) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }
    setState(() {
      _isSearching = true;
    });
    try {
      final geocodingService = ref.read(geocodingServiceProvider);
      
      // Clean query and append local city context to ensure high geocoding accuracy
      String searchFor = query.trim();
      if (!searchFor.toLowerCase().contains('salta')) {
        searchFor = '$searchFor, Salta';
      }

      final results = await geocodingService.search(searchFor);
      setState(() {
        _searchResults = results;
        _isSearching = false;
      });

      // If we find results and we don't have an initial location, we move to the first result
      if (results.isNotEmpty && _selectedLatLng == null) {
        _selectResult(results.first);
      }
    } catch (e) {
      debugPrint('Geocoding search error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al buscar dirección: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
    }
  }

  void _selectResult(GeocodingResult result) {
    final point = LatLng(result.latitude, result.longitude);
    setState(() {
      _selectedLatLng = point;
      _searchResults = [];
      _searchController.text = result.formattedAddress;
      _isLocationModified = true;
    });
    _mapController.move(point, 16.0);
    _recalculateRoute(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final initialCenter = _selectedLatLng ?? const LatLng(-24.789124, -65.411624);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ubicar en el mapa'),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0D1B3E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            key: _mapKey,
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 15.0,
              onTap: (tapPosition, point) {
                setState(() {
                  _selectedLatLng = point;
                  _isLocationModified = true;
                });
                _recalculateRoute(force: true);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.marilin.app',
              ),
              if (_estimatedRoute != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _estimatedRoute!.points,
                      strokeWidth: 4.0,
                      color: _estimatedRoute!.isFallback ? Colors.grey : const Color(0xFF1565C0),
                      pattern: _estimatedRoute!.isFallback
                          ? StrokePattern.dashed(segments: const [10, 5])
                          : const StrokePattern.solid(),
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (_driverLatLng != null)
                    Marker(
                      point: _driverLatLng!,
                      width: 40.0,
                      height: 40.0,
                      alignment: Alignment.center,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.3),
                              shape: BoxShape.circle,
                            ),
                          ),
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_selectedLatLng != null)
                    Marker(
                      point: _selectedLatLng!,
                      width: 60.0,
                      height: 60.0,
                      alignment: Alignment.topCenter,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onPanUpdate: (details) {
                          final mapRenderBox = _mapKey.currentContext?.findRenderObject() as RenderBox?;
                          if (mapRenderBox == null) return;
                          final localPoint = mapRenderBox.globalToLocal(details.globalPosition);
                          final latLng = _mapController.camera.screenOffsetToLatLng(localPoint);
                          
                          setState(() {
                            _selectedLatLng = latLng;
                            _isLocationModified = true;
                          });
                          
                          _debouncedRecalculateRoute();
                        },
                        child: const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 40.0,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
          
          // Search floating card at the top
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Column(
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      children: [
                        const Icon(Icons.search, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Buscar dirección (ej: San Martín 100, Salta)',
                              border: InputBorder.none,
                            ),
                            onChanged: _onSearchChanged,
                          ),
                        ),
                        if (_searchController.text.isNotEmpty)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchResults = [];
                              });
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                if (_searchResults.isNotEmpty)
                  Card(
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Container(
                      constraints: const BoxConstraints(maxHeight: 250),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final result = _searchResults[index];
                          return ListTile(
                            leading: const Icon(Icons.location_on_outlined),
                            title: Text(result.name),
                            subtitle: Text(result.formattedAddress),
                            onTap: () => _selectResult(result),
                          );
                        },
                      ),
                    ),
                  ),
                if (_isSearching)
                  const Card(
                    margin: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Padding(
                      padding: EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Buscando ubicación...'),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Floating action buttons or confirmation bar at the bottom
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Show instructions to tap map
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Arrastrá el pin rojo o tocá el mapa para ubicar al cliente',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Confirm button card
                Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_selectedLatLng != null) ...[
                          Row(
                            children: [
                              Icon(
                                _isLocationModified ? Icons.edit_location_alt : Icons.my_location,
                                color: _isLocationModified ? Colors.green : const Color(0xFF1565C0),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Ubicación seleccionada',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _isLocationModified
                                          ? '⚠️ Se modificó la ubicación. Toca para guardar.'
                                          : 'ℹ️ Ubicación sin cambios. Mostrando ruta para el repartidor.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _isLocationModified ? Colors.green[800] : Colors.grey[600],
                                        fontWeight: _isLocationModified ? FontWeight.bold : FontWeight.normal,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (_driverLatLng == null) ...[
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE3F2FD),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFBBDEFB)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.gps_fixed, size: 16, color: Color(0xFF1565C0)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Esperando ubicación del GPS del repartidor...',
                                      style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else if (_estimatedRoute != null) ...[
                            const SizedBox(height: 12),
                            const Divider(),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _estimatedRoute!.isFallback ? Icons.linear_scale : Icons.local_shipping,
                                      color: _estimatedRoute!.isFallback ? Colors.amber : Colors.green,
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _formatDistance(_estimatedRoute!.distance),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        Text(
                                          _estimatedRoute!.isFallback ? 'Distancia lineal' : 'Distancia de ruta',
                                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.access_time, color: Colors.blue),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          _formatDuration(_estimatedRoute!.duration),
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                        ),
                                        Text(
                                          'Tiempo est. de viaje',
                                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            if (_estimatedRoute!.isFallback) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.amber.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.amber.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.warning_amber_rounded, size: 16, color: Colors.amber.shade800),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        'Ruta de red no disponible (cálculo alternativo).',
                                        style: TextStyle(fontSize: 11, color: Colors.amber.shade900),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                          if (_isLoadingRoute) ...[
                            const SizedBox(height: 12),
                            const LinearProgressIndicator(),
                          ],
                          const SizedBox(height: 16),
                        ] else ...[
                          const Row(
                            children: [
                              Icon(Icons.location_off, color: Colors.grey),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Ubicación no seleccionada. Por favor tocá el mapa o buscá una dirección.',
                                  style: TextStyle(fontSize: 14, color: Colors.grey),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                        ElevatedButton(
                          onPressed: _isSaving
                              ? null
                              : () async {
                                  if (_selectedLatLng != null) {
                                    if (_isLocationModified) {
                                      if (widget.onSave != null) {
                                        setState(() {
                                          _isSaving = true;
                                        });
                                        try {
                                          await widget.onSave!(_selectedLatLng!);
                                          if (mounted) {
                                            setState(() {
                                              _isLocationModified = false;
                                            });
                                          }
                                        } catch (e) {
                                          debugPrint('Error during onSave: $e');
                                        } finally {
                                          if (mounted) {
                                            setState(() {
                                              _isSaving = false;
                                            });
                                          }
                                        }
                                      } else {
                                        Navigator.of(context).pop(_selectedLatLng);
                                      }
                                    } else {
                                      Navigator.of(context).pop(); // Just go back without saving
                                    }
                                  }
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isLocationModified ? Colors.green[700] : const Color(0xFF1565C0),
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey[300],
                            disabledForegroundColor: Colors.grey[500],
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  _isLocationModified ? 'Guardar Nueva Ubicación del Cliente' : 'Cerrar / Volver',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                        ),
                      ],
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
}
