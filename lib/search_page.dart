import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:phonetheftguard/global_data.dart'; // 你自己的 theft 数据加载

class SearchMapPage extends StatefulWidget {
  const SearchMapPage({Key? key}) : super(key: key);

  @override
  State<SearchMapPage> createState() => _SearchMapPageState();
}

class _SearchMapPageState extends State<SearchMapPage> {
  final MapController _mapController = MapController();
  final TextEditingController _searchController = TextEditingController();

  LatLng _currentCenter = LatLng(51.5074, -0.1278); // 默认伦敦
  String _address = '';
  String _lsoaCode = 'Unknown';
  int _thefts = 0;

  Future<void> _searchAndMove(String query) async {
    if (query.trim().isEmpty) {
      _showError("Please enter a search term");
      return;
    }

    try {
      final locationData = await getLocationDataFromQuery(query);
      if (locationData == null) {
        _showError("Location not found");
        return;
      }

      final lat = locationData['lat'];
      final lon = locationData['lon'];
      final address = locationData['address'];

      final lsoa = await getLSOACodeFromCoordinates(lat, lon);
      final theftData = await loadLSOATheftCounts();
      final thefts = theftData[lsoa] ?? 0;

      setState(() {
        _currentCenter = LatLng(lat, lon);
        _address = address;
        _lsoaCode = lsoa;
        _thefts = thefts;
      });

      _mapController.move(LatLng(lat, lon), 15.0);
    } catch (e) {
      _showError("Search error: $e");
    }
  }

  Future<Map<String, dynamic>?> getLocationDataFromQuery(String query) async {
    final url = 'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(query)}&format=json&limit=1&addressdetails=1';
    final response = await http.get(Uri.parse(url), headers: {
      'User-Agent': 'PhoneTheftGuardApp/1.0 (your_email@example.com)'
    });

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      if (data.isNotEmpty) {
        final lat = double.parse(data[0]['lat']);
        final lon = double.parse(data[0]['lon']);
        final displayName = data[0]['display_name'];
        return {
          'lat': lat,
          'lon': lon,
          'address': displayName,
        };
      }
    }
    return null;
  }

  Future<String> getLSOACodeFromCoordinates(double lat, double lon) async {
    final url = 'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json&addressdetails=1';
    final response = await http.get(Uri.parse(url), headers: {
      'User-Agent': 'PhoneTheftGuardApp/1.0 (your_email@example.com)'
    });

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final postcode = data['address']?['postcode'];
      if (postcode != null) {
        final postcodeUrl = 'https://api.postcodes.io/postcodes/${Uri.encodeComponent(postcode)}';
        final postcodeResponse = await http.get(Uri.parse(postcodeUrl));
        if (postcodeResponse.statusCode == 200) {
          final postcodeData = json.decode(postcodeResponse.body);
          if (postcodeData['status'] == 200 && postcodeData['result'] != null) {
            return postcodeData['result']['codes']['lsoa'] ?? 'Unknown';
          }
        }
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final riskColor = getColor(_thefts);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text("Search Location"),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                'Hi, where would you like to go?\nCheck if it’s safe for your phone',
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
                        urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
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
      ),
    );
  }
}
