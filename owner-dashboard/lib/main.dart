import 'dart:convert';

import 'package:flutter/material.dart';

import 'config/api_config.dart';
import 'models/dashboard_stats.dart';
import 'map_screen.dart';
import 'screens/owner_login_screen.dart';
import 'services/owner_auth_service.dart';

void main() {
  ApiConfig.validate();
  runApp(OwnerDashboardApp());
}

class OwnerDashboardApp extends StatelessWidget {
  OwnerDashboardApp({super.key, OwnerAuthService? authService})
    : authService = authService ?? OwnerAuthService();

  final OwnerAuthService authService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Owner Dashboard',
      theme: ThemeData.dark().copyWith(
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[900],
      ),
      home: AnimatedBuilder(
        animation: authService,
        builder: (context, _) => authService.isAuthenticated
            ? DashboardScreen(authService: authService)
            : OwnerLoginScreen(authService: authService),
      ),
    );
  }
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, required this.authService});

  final OwnerAuthService authService;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  DashboardStats? stats;
  List<dynamic> alerts = [];
  bool loading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      final statsRes = await widget.authService.get(
        Uri.parse('${ApiConfig.baseUrl}/api/dashboard/stats'),
      );
      final alertsRes = await widget.authService.get(
        Uri.parse('${ApiConfig.baseUrl}/api/dashboard/alerts'),
      );

      if (!mounted) return;

      if (statsRes.statusCode != 200 || alertsRes.statusCode != 200) {
        setState(() {
          errorMessage =
              'Could not load dashboard data. Please try again.';
          loading = false;
        });
        return;
      }

      final decodedStats = json.decode(statsRes.body);
      final decodedAlerts = json.decode(alertsRes.body);

      if (decodedStats is! Map<String, dynamic> ||
          decodedAlerts is! List) {
        throw const FormatException('Unexpected dashboard response format.');
      }

      final parsedStats = DashboardStats.fromJson(decodedStats);

      setState(() {
        stats = parsedStats;
        alerts = decodedAlerts;
        loading = false;
        errorMessage = null;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        errorMessage =
            'Unable to load dashboard data. Check your connection and try again.';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fleet Overview'),
        backgroundColor: Colors.blue[800],
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: widget.authService.logout,
          ),
          IconButton(
            tooltip: 'Map',
            icon: const Icon(Icons.map),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      MapScreen(authService: widget.authService),
                ),
              );
            },
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : errorMessage != null || stats == null
          ? _buildErrorState()
          : _buildDashboard(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off,
              size: 48,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            const Text(
              'Dashboard unavailable',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage ?? 'Dashboard data is unavailable.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: fetchData,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboard() {
    final dashboardStats = stats!;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              _buildStatCard(
                'Vehicles',
                dashboardStats.totalVehicles,
                Icons.directions_bus,
              ),
              _buildStatCard(
                'Active',
                dashboardStats.activeVehicles,
                Icons.check_circle,
              ),
            ],
          ),
          Row(
            children: [
              _buildStatCard(
                'Available',
                dashboardStats.availableVehicles,
                Icons.radio_button_checked,
              ),
              _buildStatCard(
                'On Trip',
                dashboardStats.onTripVehicles,
                Icons.route,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            color: Colors.blueGrey[800],
            child: ListTile(
              leading: const Icon(
                Icons.today,
                color: Colors.orange,
              ),
              title: const Text(
                "Today's Trips",
                style: TextStyle(color: Colors.white),
              ),
              trailing: Text(
                '${dashboardStats.todayTrips}',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: Card(
              color: Colors.blueGrey[800],
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Alerts',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: alerts.isEmpty
                          ? const Center(
                              child: Text('No alerts available.'),
                            )
                          : ListView.builder(
                              itemCount: alerts.length,
                              itemBuilder: (context, index) {
                                final alert = alerts[index];

                                if (alert is! Map) {
                                  return const SizedBox.shrink();
                                }

                                final type = alert['type']?.toString();
                                final message =
                                    alert['message']?.toString() ??
                                    'No message provided';

                                final IconData alertIcon =
                                    type == 'error'
                                    ? Icons.error
                                    : type == 'warning'
                                    ? Icons.warning
                                    : Icons.info;

                                final Color alertColor =
                                    type == 'error'
                                    ? Colors.red
                                    : type == 'warning'
                                    ? Colors.orange
                                    : Colors.blue;

                                return ListTile(
                                  leading: Icon(
                                    alertIcon,
                                    color: alertColor,
                                  ),
                                  title: Text(message),
                                  dense: true,
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    int value,
    IconData icon,
  ) {
    return Expanded(
      child: Card(
        color: Colors.blueGrey[800],
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              Icon(icon, color: Colors.blueAccent),
              Text(
                value.toString(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
