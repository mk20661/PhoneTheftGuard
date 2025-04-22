import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'osm_map_page.dart'; 

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _loadEverything();
  }

  Future<void> _loadEverything() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      final lsoaCode = await _getLSOACode(position.latitude, position.longitude);
      final theftData = await loadLSOATheftCounts();
      final placemark = (await placemarkFromCoordinates(position.latitude, position.longitude)).first;

      if (!mounted) return;

      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => OSMMapPage(
          position: position,
          lsoaCode: lsoaCode,
          theftData: theftData,
          placemark: placemark,
        ),
      ));
    } catch (e) {
      debugPrint("Loading error: $e");
    }
  }

  Future<String> _getLSOACode(double lat, double lon) async {
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

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
