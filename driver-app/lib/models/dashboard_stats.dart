class DashboardStats {
  final int totalVehicles;
  final int activeVehicles;
  final int availableVehicles;
  final int onTripVehicles;
  final int todayTrips;

  DashboardStats({
    required this.totalVehicles,
    required this.activeVehicles,
    required this.availableVehicles,
    required this.onTripVehicles,
    required this.todayTrips,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalVehicles: json['totalVehicles'] ?? 0,
      activeVehicles: json['activeVehicles'] ?? 0,
      availableVehicles: json['availableVehicles'] ?? 0,
      onTripVehicles: json['onTripVehicles'] ?? 0,
      todayTrips: json['todayTrips'] ?? 0,
    );
  }
}