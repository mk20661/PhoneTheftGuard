import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:csv/csv.dart';
import 'global_data.dart';

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

        print("📌 当前 LSOA Code: $lsoaCode");
        return lsoaCode;
      }
    }

    return 'Unknown';
  }

  Future<Map<String, int>> loadLSOATheftCounts() async {
    final csvString = await rootBundle.loadString(
      'assets/geojson/PhoneTheft_Total_Only.csv',
    );
    final rows = const CsvToListConverter().convert(csvString, eol: '\n');

    final header = rows.first;
    final lsoaIndex = header.indexOf('LSOA Code');
    final theftCountIndex = header.length - 1;

    if (lsoaIndex == -1 || theftCountIndex == -1) return {};

    final counts = <String, int>{};
    for (var row in rows.skip(1)) {
      final code = row[lsoaIndex].toString();
      final thefts = int.tryParse(row[theftCountIndex].toString()) ?? 0;
      counts[code] = thefts;
    }

    return counts;
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

                return FutureBuilder<List<Placemark>>(
                  future: placemarkFromCoordinates(
                    position.latitude,
                    position.longitude,
                  ),
                  builder: (context, placemarkSnapshot) {
                    if (!placemarkSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final placemark = placemarkSnapshot.data!.first;
                    final address =
                        "${placemark.street}, ${placemark.locality}, ${placemark.postalCode}, ${placemark.country}";
                    globalAddress = "${placemark.locality}";

                    return Column(
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
                        Expanded(
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              double cardWidth = constraints.maxWidth * 0.9;
                              if (cardWidth > 400) cardWidth = 400;
                              return Center(
                                child: Container(
                                  width: cardWidth,
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
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Current Location:",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        address,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
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
                                        "LSOA Code: $lsoaCode",
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        "$thefts phone thefts in this area",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Text(
                                        thefts > 15
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
                              );
                            },
                          ),
                        ),
                      ],
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
