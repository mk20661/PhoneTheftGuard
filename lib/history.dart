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
  int currentMonthIndex = 0;

  final List<String> availableMonths = [
    '202302', '202303', '202304', '202305', '202306',
    '202307', '202308', '202309', '202310', '202311',
    '202312', '202401', '202402', '202403', '202404',
    '202405', '202406', '202407', '202408', '202409',
    '202410', '202411', '202412', '202501',
  ];

  @override
  void initState() {
    super.initState();
    loadGeoJson();
  }

  Future<void> loadGeoJson() async {
    final String geojsonStr = await rootBundle.loadString(
      'assets/geojson/PhoneTheft.geojson',
    );
    final Map<String, dynamic> geojson = json.decode(geojsonStr);

    final String selectedMonth = availableMonths[currentMonthIndex];
    List<Polygon> newPolygons = [];

    for (var feature in geojson['features']) {
      final geometry = feature['geometry'];
      final props = feature['properties'];
      final name = props['name'] ?? 'Unknown';
      final thefts = props[selectedMonth]?.toInt() ?? 0;

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
                    urlTemplate:"https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png",
                    subdomains: ['a', 'b', 'c'],
                    retinaMode: MediaQuery.of(context).devicePixelRatio > 2.0,
                    userAgentPackageName: 'com.example.app',
                    ),
                PolygonLayer(polygons: polygons),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text("Month: ${availableMonths[currentMonthIndex]}"),
                Slider(
                  value: currentMonthIndex.toDouble(),
                  min: 0,
                  max: (availableMonths.length - 1).toDouble(),
                  divisions: availableMonths.length - 1,
                  label: availableMonths[currentMonthIndex],
                  onChanged: (value) {
                    setState(() {
                      currentMonthIndex = value.toInt();
                    });
                    loadGeoJson();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}