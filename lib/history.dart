import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<Polygon> polygons = [];

  final Map<String, int> theftData = {
    "E02000001": 80,
    "E02000002": 180,
    "E02000003": 320,
    "E02000004": 20,
  };

  Color getColor(int thefts) {
    if (thefts > 250) return Colors.red[900]!;
    if (thefts > 150) return Colors.red[600]!;
    if (thefts > 100) return Colors.orange[600]!;
    if (thefts > 50) return Colors.yellow[700]!;
    return Colors.green[400]!;
  }

  @override
  void initState() {
    super.initState();
    loadGeoJson();
  }

  Future<void> loadGeoJson() async {
    final String geojsonStr = await rootBundle.loadString(
      'assets/geojson/London.geojson',
    );
    final geojson = json.decode(geojsonStr);

    List<Polygon> loadedPolygons = [];

    for (var feature in geojson['features']) {
      final id = feature['properties']['MSOA11CD'];
      final name = feature['properties']['MSOA11NM'];
      final thefts = theftData[id] ?? 0;

      final coordinates = feature['geometry']['coordinates'][0];
      final List<LatLng> points =
          coordinates.map<LatLng>((c) {
            return LatLng(c[1], c[0]);
          }).toList();

      loadedPolygons.add(
        Polygon(
          points: points,
          color: getColor(thefts).withOpacity(0.5),
          borderColor: Colors.black,
          borderStrokeWidth: 0.5,
          isFilled: true,
          label: name,
        ),
      );
    }

    setState(() {
      polygons = loadedPolygons;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Theft History Map')),
      body: FlutterMap(
        options: MapOptions(center: LatLng(51.5074, -0.1278), zoom: 10.0),
        children: [
          TileLayer(
            urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
            subdomains: ['a', 'b', 'c'],
          ),
          PolygonLayer(polygons: polygons),
        ],
      ),
    );
  }
}
