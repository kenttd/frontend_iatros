import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:iatros/src/utils/api_client.dart';

enum PlaceType {
  pharmacy('pharmacy', 'Pharmacies', Icons.local_pharmacy, Colors.green),
  hospital('hospital', 'Hospitals', Icons.local_hospital, Colors.red),
  doctor('doctor', 'Clinics', Icons.medical_services, Colors.blue);

  final String apiType;
  final String label;
  final IconData icon;
  final Color color;

  const PlaceType(this.apiType, this.label, this.icon, this.color);
}

class PlaceDetails {
  final String id;
  final String name;
  final String? address;
  final double lat;
  final double lng;
  final bool? isOpen;
  final double? rating;
  final int? totalRatings;
  final String? phoneNumber;
  final List<String>? openingHours;
  final double distance;
  final PlaceType type;

  PlaceDetails({
    required this.id,
    required this.name,
    this.address,
    required this.lat,
    required this.lng,
    this.isOpen,
    this.rating,
    this.totalRatings,
    this.phoneNumber,
    this.openingHours,
    required this.distance,
    required this.type,
  });
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const _defaultLocation = LatLng(-6.2088, 106.8456);

  GoogleMapController? _mapController;
  LatLng _currentLocation = _defaultLocation;
  Set<Marker> _markers = {};
  List<PlaceDetails> _places = [];
  bool _isLoading = true;
  String? _errorMessage;
  PlaceType _selectedType = PlaceType.pharmacy;
  bool _show24HourOnly = false;

  // API key for direct calls (mobile only)
  static const String _apiKey = 'AIzaSyBcnorr8Q8vlnTb9qoszxeAW3J_9J5OhuA';

  // Use backend proxy for web, direct API for mobile
  final ApiClient _apiClient = ApiClient();

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    await _getCurrentLocation();
    await _searchNearbyPlaces();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _errorMessage = 'Location services are disabled';
          _isLoading = false;
        });
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'Location permissions denied';
            _isLoading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'Location permissions permanently denied';
          _isLoading = false;
        });
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      setState(() {
        _currentLocation = LatLng(position.latitude, position.longitude);
      });

      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(_currentLocation, 14),
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to get location: $e';
      });
    }
  }

  double _calculateDistance(double lat, double lng) {
    const R = 6371.0; // Earth's radius in km
    final dLat = _toRadians(lat - _currentLocation.latitude);
    final dLon = _toRadians(lng - _currentLocation.longitude);
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(_currentLocation.latitude)) *
            cos(_toRadians(lat)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degree) => degree * pi / 180;

  Future<void> _searchNearbyPlaces() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? keyword;
      if (_show24HourOnly && _selectedType == PlaceType.pharmacy) {
        keyword = '24 hour';
      }

      Map<String, dynamic> data;

      if (kIsWeb) {
        // Use backend proxy for web to avoid CORS
        final queryParams = {
          'location':
              '${_currentLocation.latitude},${_currentLocation.longitude}',
          'radius': '5000',
          'type': _selectedType.apiType,
          if (keyword != null) 'keyword': keyword,
        };

        final response = await _apiClient.get(
          '/places/nearby',
          queryParameters: queryParams,
        );

        if (response.statusCode == 200) {
          data = json.decode(response.body);
        } else {
          throw Exception('Failed to search places: ${response.statusCode}');
        }
      } else {
        // Direct API call for mobile (no CORS issues)
        final keywordParam = keyword != null
            ? '&keyword=${Uri.encodeComponent(keyword)}'
            : '';
        final url = Uri.parse(
          'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
          '?location=${_currentLocation.latitude},${_currentLocation.longitude}'
          '&radius=5000'
          '&type=${_selectedType.apiType}'
          '$keywordParam'
          '&key=$_apiKey',
        );

        final response = await http.get(url);

        if (response.statusCode == 200) {
          data = json.decode(response.body);
        } else {
          throw Exception('Failed to search places: ${response.statusCode}');
        }
      }

      // Process results (same for both web and mobile)
      final results = data['results'] as List;

      final List<PlaceDetails> places = [];
      final Set<Marker> markers = {};

      // Add current location marker
      markers.add(
        Marker(
          markerId: const MarkerId('current_location'),
          position: _currentLocation,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );

      for (int i = 0; i < results.length; i++) {
        final place = results[i];
        final lat = place['geometry']['location']['lat'] as double;
        final lng = place['geometry']['location']['lng'] as double;
        final name = place['name'] ?? 'Unknown';
        final address = place['vicinity'];
        final isOpen = place['opening_hours']?['open_now'];
        final rating = place['rating']?.toDouble();
        final totalRatings = place['user_ratings_total'];
        final distance = _calculateDistance(lat, lng);

        final placeDetails = PlaceDetails(
          id: place['place_id'] ?? 'place_$i',
          name: name,
          address: address,
          lat: lat,
          lng: lng,
          isOpen: isOpen,
          rating: rating,
          totalRatings: totalRatings,
          distance: distance,
          type: _selectedType,
        );

        places.add(placeDetails);

        // Determine marker color
        double hue;
        switch (_selectedType) {
          case PlaceType.pharmacy:
            hue = isOpen == true
                ? BitmapDescriptor.hueGreen
                : BitmapDescriptor.hueRed;
            break;
          case PlaceType.hospital:
            hue = BitmapDescriptor.hueRed;
            break;
          case PlaceType.doctor:
            hue = BitmapDescriptor.hueBlue;
            break;
        }

        markers.add(
          Marker(
            markerId: MarkerId('place_$i'),
            position: LatLng(lat, lng),
            icon: BitmapDescriptor.defaultMarkerWithHue(hue),
            onTap: () => _showPlaceDetails(placeDetails),
          ),
        );
      }

      // Sort by distance
      places.sort((a, b) => a.distance.compareTo(b.distance));

      setState(() {
        _places = places;
        _markers = markers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: $e';
        _isLoading = false;
      });
    }
  }

  void _showPlaceDetails(PlaceDetails place) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          _PlaceDetailsSheet(place: place, currentLocation: _currentLocation),
    );
  }

  Future<void> _openDirections(PlaceDetails place) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${_currentLocation.latitude},${_currentLocation.longitude}'
      '&destination=${place.lat},${place.lng}'
      '&travelmode=driving',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentLocation,
              zoom: 14,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: _markers,
            onMapCreated: (controller) => _mapController = controller,
          ),

          // Top controls
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                // Place type selector
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: PlaceType.values.map((type) {
                        final isSelected = type == _selectedType;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedType = type);
                              _searchNearbyPlaces();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? type.color.withOpacity(0.2)
                                    : null,
                                borderRadius: BorderRadius.circular(8),
                                border: isSelected
                                    ? Border.all(color: type.color, width: 2)
                                    : null,
                              ),
                              child: Row(
                                children: [
                                  Icon(type.icon, color: type.color, size: 20),
                                  const SizedBox(width: 4),
                                  Text(
                                    type.label,
                                    style: TextStyle(
                                      color: isSelected
                                          ? type.color
                                          : Colors.grey,
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : null,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // 24-hour filter (only for pharmacies)
                if (_selectedType == PlaceType.pharmacy)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, color: Colors.orange),
                        const SizedBox(width: 8),
                        const Expanded(child: Text('24-Hour Only')),
                        Switch(
                          value: _show24HourOnly,
                          onChanged: (value) {
                            setState(() => _show24HourOnly = value);
                            _searchNearbyPlaces();
                          },
                          activeColor: Colors.orange,
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 8),

                // Results count
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(_selectedType.icon, color: _selectedType.color),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _isLoading
                              ? 'Searching...'
                              : '${_places.length} ${_selectedType.label.toLowerCase()} found',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Error message
          if (_errorMessage != null)
            Positioned(
              bottom: 100,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade900),
                ),
              ),
            ),

          // Loading
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'refresh',
            onPressed: () => _searchNearbyPlaces(),
            child: const Icon(Icons.refresh),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'my_location',
            onPressed: () {
              _mapController?.animateCamera(
                CameraUpdate.newLatLngZoom(_currentLocation, 14),
              );
            },
            child: const Icon(Icons.my_location),
          ),
        ],
      ),
    );
  }
}

// Bottom sheet for place details
class _PlaceDetailsSheet extends StatelessWidget {
  final PlaceDetails place;
  final LatLng currentLocation;

  const _PlaceDetailsSheet({
    required this.place,
    required this.currentLocation,
  });

  Future<void> _openDirections() async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${currentLocation.latitude},${currentLocation.longitude}'
      '&destination=${place.lat},${place.lng}'
      '&travelmode=driving',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callPhone(String phone) async {
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: place.type.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        place.type.icon,
                        color: place.type.color,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            place.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: place.isOpen == true
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  place.isOpen == true ? 'Open' : 'Closed',
                                  style: TextStyle(
                                    color: place.isOpen == true
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${place.distance.toStringAsFixed(1)} km',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Rating
                if (place.rating != null)
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      const SizedBox(width: 4),
                      Text(
                        place.rating!.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${place.totalRatings ?? 0} reviews)',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),

                const SizedBox(height: 12),

                // Address
                if (place.address != null)
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.grey[600],
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          place.address!,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _openDirections,
                        icon: const Icon(Icons.directions),
                        label: const Text('Directions'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: place.type.color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          // Share functionality could be added
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.share),
                        label: const Text('Share'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: place.type.color,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          side: BorderSide(color: place.type.color),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}
