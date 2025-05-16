import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RunMapScreen extends StatelessWidget {
  final String routeJson;

  const RunMapScreen({super.key, required this.routeJson});

  @override
  Widget build(BuildContext context) {
    final List<dynamic> rawCoords = jsonDecode(routeJson);
    final List<LatLng> coordinates = rawCoords
        .map((point) => LatLng(point['lat'], point['lng']))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Route Map')),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: coordinates.isNotEmpty ? coordinates.first : const LatLng(0, 0),
          zoom: 16,
        ),
        polylines: {
          Polyline(
            polylineId: const PolylineId("route"),
            points: coordinates,
            color: Colors.blue,
            width: 5,
          ),
        },
        markers: {
          if (coordinates.isNotEmpty)
            Marker(
              markerId: const MarkerId('start'),
              position: coordinates.first,
              infoWindow: const InfoWindow(title: 'Start'),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
            ),
          if (coordinates.length > 1)
            Marker(
              markerId: const MarkerId('end'),
              position: coordinates.last,
              infoWindow: const InfoWindow(title: 'End'),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
            ),
        },
        myLocationEnabled: false,
        myLocationButtonEnabled: false,
      ),
    );
  }
}
