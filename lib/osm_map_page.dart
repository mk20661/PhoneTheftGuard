import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'global_data.dart';
import 'package:provider/provider.dart';
import 'src/settings_state.dart';

class OSMMapPage extends StatelessWidget {
  const OSMMapPage({Key? key}) : super(key: key);

  Future<Position> _getPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    LocationPermission permission = await Geolocator.checkPermission();

    if (!serviceEnabled) {
      throw Exception("Location services are disabled");
    }

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception("Location permission denied");
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception("Location permission permanently denied");
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<String> getLSOACode(double lat, double lon) async {
    final url = 'https://api.postcodes.io/postcodes?lon=$lon&lat=$lat';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body) as Map<String, dynamic>;
      if (data['result'] != null &&
          data['result'] is List &&
          data['result'].isNotEmpty) {
        final first = data['result'][0] as Map<String, dynamic>;
        final codes = first['codes'] as Map<String, dynamic>;
        final lsoaCode = codes['lsoa']?.toString() ?? 'Unknown';
        return lsoaCode;
      }
    }

    return 'Unknown';
  }

  Future<String> reverseGeocode(double lat, double lon) async {
    final url =
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lon&format=json';
    final response = await http.get(
      Uri.parse(url),
      headers: {
        'User-Agent': 'PhoneTheftGuardApp/1.0 (your_email@example.com)',
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['display_name'] ?? 'Unknown address';
    } else {
      return 'Unknown address';
    }
  }

  Color getColor(int thefts) {
    if (thefts > 25) return Colors.red[900]!;
    if (thefts > 15) return Colors.red[600]!;
    if (thefts > 10) return Colors.orange[600]!;
    if (thefts > 1) return Colors.yellow[700]!;
    return Colors.green[400]!;
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = Provider.of<SettingsState>(context);

    return FutureBuilder<Position>(
      future: _getPosition(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final position = snapshot.data!;
        final currentLocation = LatLng(position.latitude, position.longitude);
        final mapController = MapController();

        return FutureBuilder<String>(
          future: getLSOACode(position.latitude, position.longitude),
          builder: (context, lsoaSnapshot) {
            if (!lsoaSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final lsoaCode = lsoaSnapshot.data!;

            return FutureBuilder<Map<String, int>>(
              future: loadLSOATheftCounts(),
              builder: (context, theftSnapshot) {
                if (!theftSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final theftData = theftSnapshot.data!;
                final thefts = theftData[lsoaCode] ?? 0;
                final riskColor = getColor(thefts);

                if (settingsState.locationAlertEnabled &&
                    settingsState.notificationsEnabled &&
                    thefts > 15) {
                  Future.delayed(Duration.zero, () {
                    showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: const Text("⚠️ High Risk Area"),
                            content: const Text(
                              "You're in a high-risk phone theft area! Stay alert.",
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text("OK"),
                              ),
                            ],
                          ),
                    );
                  });
                }

                return FutureBuilder<String>(
                  future: reverseGeocode(position.latitude, position.longitude),
                  builder: (context, addressSnapshot) {
                    if (!addressSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final address = addressSnapshot.data!;
                    globalAddress = address;

                    return Scaffold(
                      backgroundColor: Colors.white,
                      appBar: AppBar(
                        title: const Text('Phone Theft Radar'),
                        centerTitle: true,
                      ),
                      body: SafeArea(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              SizedBox(
                                height: 500,
                                child: Stack(
                                  children: [
                                    FlutterMap(
                                      mapController: mapController,
                                      options: MapOptions(
                                        center: currentLocation,
                                        zoom: 16,
                                      ),
                                      children: [
                                        TileLayer(
                                          urlTemplate:
                                              "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                                        ),
                                        MarkerLayer(
                                          markers: [
                                            Marker(
                                              point: currentLocation,
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
                                    Positioned(
                                      bottom: 16,
                                      right: 16,
                                      child: FloatingActionButton(
                                        onPressed: () async {
                                          final newPosition =
                                              await Geolocator.getCurrentPosition();
                                          mapController.move(
                                            LatLng(
                                              newPosition.latitude,
                                              newPosition.longitude,
                                            ),
                                            16,
                                          );
                                        },
                                        child: const Icon(Icons.my_location),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                margin: const EdgeInsets.all(20),
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
                                      "📍 Current Location:",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      address,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "LSOA: $lsoaCode",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white70,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      "$thefts phone thefts reported",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      thefts > 15
                                          ? "⚠️ High risk area"
                                          : "✅ Low risk area",
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
