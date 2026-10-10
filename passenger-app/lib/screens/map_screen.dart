import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/driver.dart';
import '../services/api_service.dart';

class MapScreen extends StatefulWidget {
  final String route;
  final String token;
  const MapScreen({super.key, required this.route, required this.token});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late final ApiService _api;
  List<Driver> _activeDrivers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _api = ApiService(token: widget.token);
    _loadActiveDrivers();
  }

  Future<void> _loadActiveDrivers() async {
    setState(() => _loading = true);
    final drivers = await _api.fetchActiveDrivers();
    setState(() {
      // Filter by selected route (if the driver has route info, otherwise fallback)
      // For now, we filter by vehicleRegistration as a proxy, or we can just show all.
      // Since the backend returns drivers with route = 'N/A' for locations,
      // we'll show all active drivers and let the user see them.
      _activeDrivers = drivers;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kombis on ${widget.route}'),
        backgroundColor: Colors.blue[800],
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadActiveDrivers),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _activeDrivers.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_bus, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No active kombis on this route'),
                  Text(
                    'Check back later',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(-24.6282, 25.9231),
                initialZoom: 13,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.app',
                ),
                MarkerLayer(
                  markers: _activeDrivers.map((driver) {
                    return Marker(
                      width: 60,
                      height: 60,
                      point: LatLng(
                        driver.latitude ?? 0,
                        driver.longitude ?? 0,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.directions_bus,
                            color: Colors.blue,
                            size: 40,
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 2,
                            ),
                            color: Colors.black54,
                            child: Text(
                              driver.vehicleRegistration,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
    );
  }
}
