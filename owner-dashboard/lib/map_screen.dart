import 'package:flutter/material.dart';
import 'config/api_config.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:convert';
import 'services/owner_auth_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key, required this.authService});

  final OwnerAuthService authService;

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<dynamic> vehicles = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchLocations();
  }

  Future<void> fetchLocations() async {
    try {
      final response = await widget.authService.get(
        Uri.parse('${ApiConfig.baseUrl}/api/locations/active'),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() {
          vehicles = json.decode(response.body);
          loading = false;
        });
      } else {
        setState(() => loading = false);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Live Fleet Map'),
        backgroundColor: Colors.blue[800],
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() => loading = true);
              fetchLocations();
            },
          ),
        ],
      ),
      body: loading
          ? Center(child: CircularProgressIndicator())
          : vehicles.isEmpty
          ? Center(child: Text('No active drivers'))
          : FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(
                  -24.6282,
                  25.9231,
                ), // ✅ Changed from center
                initialZoom: 12, // ✅ Changed from zoom
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),
                MarkerLayer(
                  markers: vehicles.map((v) {
                    return Marker(
                      width: 40,
                      height: 40,
                      point: LatLng(v['latitude'] ?? 0, v['longitude'] ?? 0),
                      child: Icon(
                        Icons.directions_bus,
                        color: Colors.blue,
                        size: 30,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
    );
  }
}
