class Driver {
  final int id;
  final String fullName;
  final String phoneNumber;
  final String vehicleRegistration;
  final String route;
  final String status;
  final double? latitude;
  final double? longitude;

  Driver({
    required this.id,
    required this.fullName,
    required this.phoneNumber,
    required this.vehicleRegistration,
    required this.route,
    required this.status,
    this.latitude,
    this.longitude,
  });

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'] ?? 0,
      fullName: json['fullName'] ?? 'Unknown',
      phoneNumber: json['phoneNumber'] ?? '',
      vehicleRegistration: json['vehicleRegistration'] ?? 'N/A',
      route: json['route'] ?? 'N/A',
      status: json['status'] ?? 'UNKNOWN',
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }
}