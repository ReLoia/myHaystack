class DecryptedLocationModel {
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final int confidence;
  final int accuracy;
  final int? batteryStatus;

  DecryptedLocationModel({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    required this.confidence,
    required this.accuracy,
    this.batteryStatus,
  });
}
