class EmergencyAlert {
  final String id;
  final String profileId;
  final String profileName;
  final String roleLabel;
  final DateTime timestamp;
  bool resolved;

  EmergencyAlert({
    required this.id,
    required this.profileId,
    required this.profileName,
    required this.roleLabel,
    required this.timestamp,
    this.resolved = false,
  });

  factory EmergencyAlert.fromJson(Map<String, dynamic> json) => EmergencyAlert(
        id: json['id'] as String,
        profileId: json['profileId'] as String,
        profileName: json['profileName'] as String,
        roleLabel: json['roleLabel'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
        resolved: json['resolved'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'profileId': profileId,
        'profileName': profileName,
        'roleLabel': roleLabel,
        'timestamp': timestamp.toIso8601String(),
        'resolved': resolved,
      };
}
