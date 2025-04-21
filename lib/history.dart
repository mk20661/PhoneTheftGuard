import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Polygon> polygons = [];
  bool isDataLoaded = false;
  bool hasRequestedData = false;

  final List<String> years = ['2023', '2024', '2025'];
  final List<String> months = [
    '01', '02', '03', '04', '05', '06',
    '07', '08', '09', '10', '11', '12'
  ];

  String selectedYear = '2023';
  String selectedMonth = '02';

  List<String> availableMonths = [
    '202302', '202303', '202304', '202305', '202306',
    '202307', '202308', '202309', '202310', '202311',
    '202312', '202401', '202402', '202403', '202404',
    '202405', '202406', '202407', '202408', '202409',
    '202410', '202411', '202412', '202501',
  ];

  Future<void> loadGeoJson() async {
    setState(() {
      isDataLoaded = false;
      hasRequestedData = true;
    });

    final String combinedMonth = selectedYear + selectedMonth;
    if (!availableMonths.contains(combinedMonth)) {
      setState(() {
        polygons = [];
        isDataLoaded = true;
      });
      return;
    }

    try {
      final String geojsonStr = await rootBundle.loadString(
        'assets/geojson/PhoneTheft.geojson',
      );
      final Map<String, dynamic> geojson = json.decode(geojsonStr);

      List<Polygon> newPolygons = [];

      for (var feature in geojson['features']) {
        final geometry = feature['geometry'];
        final props = feature['properties'];
        final dynamic theftVal = props[combinedMonth];

        if (theftVal == null) continue;

        int thefts = 0;
        if (theftVal is int) {
          thefts = theftVal;
        } else if (theftVal is String) {
          thefts = int.tryParse(theftVal) ?? 0;
        } else if (theftVal is double) {
          thefts = theftVal.toInt();
        }

        final List<LatLng> points = parseGeometryPoints(geometry);
        final color = getColor(thefts).withOpacity(0.6);

        newPolygons.add(
          Polygon(
            points: points,
            color: color,
            borderColor: Colors.white,
            borderStrokeWidth: 0.3,
            isFilled: true,
          ),
        );
      }

      setState(() {
        polygons = newPolygons;
        isDataLoaded = true;
      });
    } catch (e) {
      print('Error loading GeoJSON: $e');
      setState(() {
        polygons = [];
        isDataLoaded = true;
      });
    }
  }

  List<LatLng> parseGeometryPoints(Map<String, dynamic> geometry) {
    final type = geometry['type'];
    final coordinates = geometry['coordinates'];
    List<LatLng> points = [];

    if (type == 'Polygon') {
      points = coordinates[0].map<LatLng>((c) => LatLng(c[1], c[0])).toList();
    } else if (type == 'MultiPolygon') {
      points = coordinates[0][0].map<LatLng>((c) => LatLng(c[1], c[0])).toList();
    }

    return points;
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
    final String combinedMonth = selectedYear + selectedMonth;

    return Scaffold(
      appBar: AppBar(title: const Text('Phone Theft Heatmap')),
      body: Column(
        children: [
          Expanded(
            child: FlutterMap(
              options: MapOptions(
                center: LatLng(51.5074, -0.1278),
                zoom: 10.0,
              ),
              children: [
                TileLayer(
                  urlTemplate: "https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png",
                  subdomains: ['a', 'b', 'c'],
                  retinaMode: MediaQuery.of(context).devicePixelRatio > 2.0,
                  userAgentPackageName: 'com.example.app',
                ),
                if (isDataLoaded && polygons.isNotEmpty)
                  PolygonLayer(polygons: polygons),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                const Text("Select Year and Month:"),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DropdownButton<String>(
                      value: selectedYear,
                      items: years.map((year) {
                        return DropdownMenuItem<String>(
                          value: year,
                          child: Text(year),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedYear = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(width: 20),
                    DropdownButton<String>(
                      value: selectedMonth,
                      items: months.map((month) {
                        return DropdownMenuItem<String>(
                          value: month,
                          child: Text(month),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedMonth = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    loadGeoJson();
                  },
                  child: Text("Load Heatmap for $combinedMonth"),
                ),
                if (hasRequestedData && !isDataLoaded)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: CircularProgressIndicator(),
                  ),
                if (hasRequestedData && isDataLoaded && polygons.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 8.0),
                    child: Text("No data available for the selected month."),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}