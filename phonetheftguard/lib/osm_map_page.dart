import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Position>(
      future: _getPosition(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final position = snapshot.data!;
        final currentLocation = LatLng(position.latitude, position.longitude);
        final mapController = MapController();

        return FutureBuilder<List<Placemark>>(
          future: placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          ),
          builder: (context, placemarkSnapshot) {
            if (!placemarkSnapshot.hasData) {
              return Center(child: CircularProgressIndicator());
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
                        options: MapOptions(center: currentLocation, zoom: 16),
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
                                child: Icon(
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
                            try {
                              bool serviceEnabled =
                                  await Geolocator.isLocationServiceEnabled();
                              if (!serviceEnabled) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Location service is disabled",
                                    ),
                                  ),
                                );
                                return;
                              }

                              LocationPermission permission =
                                  await Geolocator.checkPermission();
                              if (permission == LocationPermission.denied) {
                                permission =
                                    await Geolocator.requestPermission();
                                if (permission == LocationPermission.denied) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Location permission denied",
                                      ),
                                    ),
                                  );
                                  return;
                                }
                              }

                              if (permission ==
                                  LocationPermission.deniedForever) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Location permission permanently denied",
                                    ),
                                  ),
                                );
                                return;
                              }

                              final newPosition =
                                  await Geolocator.getCurrentPosition();
                              mapController.move(
                                LatLng(
                                  newPosition.latitude,
                                  newPosition.longitude,
                                ),
                                16,
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Failed to get location: $e"),
                                ),
                              );
                            }
                          },
                          child: Icon(Icons.my_location),
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
                          padding: EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.lightGreenAccent.shade100,
                                Colors.green.shade600,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Current Location:",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text(address),
                              SizedBox(height: 10),
                              Text(
                                "Here is:",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              Text("Low phone theft risk in this area"),
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
  }
}
