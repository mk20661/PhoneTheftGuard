import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:phonetheftguard/global_data.dart';

class SearchMapPage extends StatefulWidget {
  const SearchMapPage({Key? key}) : super(key: key);

  @override
  State<SearchMapPage> createState() => _SearchMapPageState();
}

class _SearchMapPageState extends State<SearchMapPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  LatLng _currentCenter = LatLng(51.5074, -0.1278);

  String _address = '';
  String _lsoaCode = 'Unknown';
  int _thefts = 0;

  Future<void> _searchAndMove(String query) async {
    try {
      List<Location> locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        final newCenter = LatLng(locations[0].latitude, locations[0].longitude);
        final lsoa = await getLSOACode(newCenter.latitude, newCenter.longitude);
        final theftData = await loadLSOATheftCounts();
        final thefts = theftData[lsoa] ?? 0;

        final placemarks = await placemarkFromCoordinates(
          newCenter.latitude,
          newCenter.longitude,
        );
        final placemark = placemarks.first;
        final address =
            "${placemark.street}, ${placemark.locality}, ${placemark.postalCode}, ${placemark.country}";

        setState(() {
          _currentCenter = newCenter;
          _lsoaCode = lsoa;
          _thefts = thefts;
          _address = address;
        });

        _mapController.move(newCenter, 15.0);
      } else {
        _showError("Location not found");
      }
    } catch (e) {
      _showError("Search error: $e");
    }
  }

  Future<String> getLSOACode(double lat, double lon) async {
    final url = 'https://api.postcodes.io/postcodes?lon=$lon&lat=$lat';
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['result'] != null &&
          data['result'] is List &&
          data['result'].isNotEmpty) {
        final codes = data['result'][0]['codes'];
        return codes['lsoa'] ?? 'Unknown';
      }
    }
    return 'Unknown';
  }

  Color getColor(int thefts) {
    if (thefts > 25) return Colors.red[900]!;
    if (thefts > 15) return Colors.red[600]!;
    if (thefts > 10) return Colors.orange[600]!;
    if (thefts > 1) return Colors.yellow[700]!;
    return Colors.green[400]!;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final riskColor = getColor(_thefts);
    return SafeArea(
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(
              'Hi, where would you like to go?\nCheck the area is safe for Phone',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.left,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onSubmitted: _searchAndMove,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(center: _currentCenter, zoom: 13),
                  children: [
                    TileLayer(
                      urlTemplate:
                          "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _currentCenter,
                          width: 60,
                          height: 60,
                          child: const Icon(
                            Icons.location_on,
                            size: 40,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                if (_address.isNotEmpty)
                  Positioned(
                    bottom: 20,
                    right: 20,
                    left: 20,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: riskColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Search Location:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            _address,
                            style: const TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            "Here is:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            "LSOA Code: $_lsoaCode",
                            style: const TextStyle(color: Colors.white),
                          ),
                          Text(
                            "$_thefts phone thefts in this area",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            _thefts > 15
                                ? "⚠️ High phone theft risk"
                                : "✅ Low phone theft risk",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
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
