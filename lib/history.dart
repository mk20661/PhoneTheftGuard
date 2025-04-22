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

  DateTime selectedDate = DateTime(2023, 2);

  final List<String> availableMonths = [
    '202302','202303','202304','202305','202306','202307','202308','202309','202310','202311','202312','202401','202402','202403','202404','202405','202406','202407','202408','202409','202410','202411','202412','202501',
  ];

  Future<void> loadGeoJson() async {
    setState(() {
      isDataLoaded = false;
      hasRequestedData = true;
    });

    final String selectedMonth = "${selectedDate.year}${selectedDate.month.toString().padLeft(2, '0')}";

    if (!availableMonths.contains(selectedMonth)) {
      setState(() {
        polygons = [];
        isDataLoaded = true;
      });
      _showNoDataDialog();
      return;
    }

    try {
      final String geojsonStr = await rootBundle.loadString('assets/geojson/PhoneTheft.geojson');
      final Map<String, dynamic> geojson = json.decode(geojsonStr);

      List<Polygon> newPolygons = [];

      for (var feature in geojson['features']) {
        final geometry = feature['geometry'];
        final props = feature['properties'];
        final dynamic theftVal = props[selectedMonth];

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

      if (newPolygons.isEmpty) {
        _showNoDataDialog();
      }
    } catch (e) {
      print('Error loading GeoJSON: $e');
      setState(() {
        polygons = [];
        isDataLoaded = true;
      });
      _showNoDataDialog();
    }
  }

  void _showNoDataDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          Future.delayed(const Duration(seconds: 2), () {
            if (Navigator.canPop(context)) {
              Navigator.of(context).pop();
            }
          });

          return Center(
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              backgroundColor: Colors.grey[100],
              title: Row(
                children: const [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange),
                  SizedBox(width: 8),
                  Text("No Data"),
                ],
              ),
              content: const Text(
                "No data available for the selected month.",
                style: TextStyle(fontSize: 15),
              ),
            ),
          );
        },
      );
    });
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
    final selectedMonthStr = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}";

    return Scaffold(
      appBar: AppBar(title: const Text('History Heatmap')),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
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
                    PolygonLayer(polygons: polygons),
                  ],
                ),
                if (hasRequestedData && !isDataLoaded)
                  const Center(child: CircularProgressIndicator()),
              ],
            ),
          ),
          SizedBox(
            height: 130,
            child: Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Text("Selected Month: $selectedMonthStr"),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      DropdownButton<int>(
                        value: selectedDate.year,
                        alignment: Alignment.center,
                        items: [2023, 2024, 2025].map((year) {
                          return DropdownMenuItem(
                            value: year,
                            child: Text(year.toString()),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedDate = DateTime(value, selectedDate.month);
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 16),
                      DropdownButton<int>(
                        value: selectedDate.month,
                        alignment: Alignment.center,
                        items: List.generate(12, (index) => index + 1).map((month) {
                          return DropdownMenuItem(
                            value: month,
                            child: Text(month.toString().padLeft(2, '0')),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              selectedDate = DateTime(selectedDate.year, value);
                            });
                          }
                        },
                      ),
                      const SizedBox(width: 16),
                      Align(
                        alignment: Alignment.center,
                        child: ElevatedButton(
                          onPressed: loadGeoJson,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text("Load"),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}