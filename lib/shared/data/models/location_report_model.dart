class LocationReportModel {
  final String id;
  final String payload;
  final int statusCode;

  LocationReportModel({
    required this.id,
    required this.payload,
    required this.statusCode,
  });

  factory LocationReportModel.fromJson(Map<String, dynamic> json) {
    return LocationReportModel(
      id: json['id'] as String? ?? '',
      payload: json['payload'] as String? ?? '',
      statusCode: json['statusCode'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'payload': payload,
      'statusCode': statusCode,
    };
  }
}
