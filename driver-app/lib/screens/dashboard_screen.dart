import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService auth = AuthService();
  int driverId = 1;
  String driverName = '';
  String route = '';
  String status = '';
  String vehicle = '';

  bool isLoading = false;
  String? activeTripId;
  String message = '';
  bool isSendingLocation = false;

  // Stop insights
  Map<String, dynamic>? currentStopInfo;
  bool loadingStopInfo = false;

  @override
  void initState() {
    super.initState();

    if (auth.token == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      });
      return;
    }

    if (auth.user != null) {
      driverId = auth.user!['driverId'] ?? 1;
      driverName = auth.user!['fullName'] ?? 'Driver';
      route = auth.user!['route'] ?? 'N/A';
      status = auth.user!['status'] ?? 'AVAILABLE';
      vehicle = auth.user!['vehicleRegistration'] ?? 'N/A';
    } else {
      driverId = 1;
    }

    fetchDriverStatus();
    _startLocationUpdates();
  }

  Future<void> fetchDriverStatus() async {
    try {
      final response = await http.get(
        Uri.parse('${auth.baseUrl}/api/drivers/$driverId'),
        headers: auth.getAuthHeaders(),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          driverName = data['fullName'] ?? 'Unknown';
          status = data['status'] ?? 'UNKNOWN';
          route = data['route'] ?? 'N/A';
          vehicle = data['vehicleRegistration'] ?? 'N/A';
        });
      } else if (response.statusCode == 401) {
        auth.logout();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
        return;
      }
      await checkActiveTrip();
    } catch (e) {
      if (!mounted) return;
      setState(() => message = 'Error fetching status');
    }
  }

  Future<void> checkActiveTrip() async {
    try {
      final response = await http.get(
        Uri.parse('${auth.baseUrl}/api/trips/driver/$driverId/active'),
        headers: auth.getAuthHeaders(),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          activeTripId = data['id'].toString();
          status = 'ON_TRIP';
        });
        _startSendingLocation();
      } else {
        setState(() {
          activeTripId = null;
        });
        _stopSendingLocation();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        activeTripId = null;
      });
      _stopSendingLocation();
    }
  }

  Future<void> startShift() async {
    setState(() => isLoading = true);
    try {
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      final body = {
        'driverId': driverId,
        'route': route,
        'latitude': pos.latitude,
        'longitude': pos.longitude,
      };
      final response = await http.post(
        Uri.parse('${auth.baseUrl}/api/trips/start'),
        headers: auth.getAuthHeaders(),
        body: json.encode(body),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() {
          message = 'Shift started!';
          status = 'ON_TRIP';
          isLoading = false;
        });
        await checkActiveTrip();
        if (!mounted) return;
        _startSendingLocation();
      } else {
        setState(() {
          message = 'Failed to start shift';
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        message = 'Error: $e';
        isLoading = false;
      });
    }
  }

  Future<void> endShift() async {
    if (activeTripId == null) {
      setState(() => message = 'No active shift to end');
      return;
    }
    setState(() => isLoading = true);
    try {
      Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.best,
      );
      final body = {'latitude': pos.latitude, 'longitude': pos.longitude};
      final response = await http.put(
        Uri.parse('${auth.baseUrl}/api/trips/$activeTripId/end'),
        headers: auth.getAuthHeaders(),
        body: json.encode(body),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() {
          message = 'Shift ended!';
          status = 'AVAILABLE';
          activeTripId = null;
          isLoading = false;
        });
        _stopSendingLocation();
      } else {
        setState(() {
          message = 'Failed to end shift';
          isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        message = 'Error: $e';
        isLoading = false;
      });
    }
  }

  // ---- STOP INSIGHT ----
  Future<void> fetchStopInsight(double lat, double lng) async {
    setState(() => loadingStopInfo = true);
    try {
      final response = await http.get(
        Uri.parse('${auth.baseUrl}/api/stops/insight?lat=$lat&lng=$lng'),
        headers: auth.getAuthHeaders(),
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          currentStopInfo = data;
        });
      } else {
        // No stop found or error – clear
        setState(() {
          currentStopInfo = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        currentStopInfo = null;
      });
    }
    if (!mounted) return;
    setState(() => loadingStopInfo = false);
  }

  void _startLocationUpdates() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!mounted) return;
    if (!serviceEnabled) {
      setState(() => message = 'Please enable GPS');
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (!mounted) return;
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (!mounted) return;
      if (permission == LocationPermission.denied) {
        setState(() => message = 'Location permission denied');
        return;
      }
    }

    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 10,
    );

    Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((Position position) {
      if (activeTripId != null) {
        _sendLocation(position.latitude, position.longitude);
        // Also fetch stop insight
        fetchStopInsight(position.latitude, position.longitude);
      }
    });
  }

  void _startSendingLocation() {
    setState(() => isSendingLocation = true);
  }

  void _stopSendingLocation() {
    setState(() => isSendingLocation = false);
  }

  Future<void> _sendLocation(double lat, double lng) async {
    try {
      final body = {
        'driverId': driverId,
        'latitude': lat,
        'longitude': lng,
      };
      await http.post(
        Uri.parse('${auth.baseUrl}/api/locations'),
        headers: auth.getAuthHeaders(),
        body: json.encode(body),
      );
    } catch (e) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        backgroundColor: Colors.blue[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Driver Info Card
            Card(
              color: Colors.blueGrey[800],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text('Hello, $driverName', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                      Text(vehicle),
                      Text(route),
                    ]),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: status == 'ON_TRIP' ? Colors.green : Colors.orange,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('Status: $status', style: const TextStyle(color: Colors.black)),
                    ),
                    if (isSendingLocation) ...[
                      const SizedBox(height: 4),
                      const Text('GPS sending active', style: TextStyle(color: Colors.greenAccent, fontSize: 12)),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Stop Insight Card (if available)
            if (loadingStopInfo)
              const Center(child: CircularProgressIndicator())
            else if (currentStopInfo != null)
              Card(
                color: Colors.blueGrey[700],
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('📍 ${currentStopInfo!['stopName'] ?? 'Stop'}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.timer, size: 16),
                          const SizedBox(width: 4),
                          Text('Avg wait: ${currentStopInfo!['averageWaitSeconds'] ?? 0} sec'),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.people, size: 16),
                          const SizedBox(width: 4),
                          Text('Passengers: ${currentStopInfo!['passengerCountEstimate'] ?? '?'}'),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.directions_bus, size: 16),
                          const SizedBox(width: 4),
                          Text('Next kombi: ${currentStopInfo!['nextKombiDistance'] ?? '?'} km away'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // Action Buttons
            if (activeTripId == null) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : startShift,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('START SHIFT', style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ] else ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : endShift,
                  icon: const Icon(Icons.stop),
                  label: const Text('END SHIFT', style: TextStyle(fontSize: 18)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Text('Trip ID: $activeTripId (Active)', style: const TextStyle(color: Colors.green)),
              ),
            ],

            if (isLoading) ...[
              const SizedBox(height: 20),
              const Center(child: CircularProgressIndicator()),
            ],

            if (message.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                color: Colors.blueGrey[700],
                child: Text(message, style: const TextStyle(color: Colors.white)),
              ),
            ],

            const Spacer(),
            Text('Driver ID: $driverId (from login)', style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
