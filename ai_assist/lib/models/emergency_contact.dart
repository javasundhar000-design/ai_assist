class EmergencyContact {
  final String name;
  final String phone;
  final String relation;

  const EmergencyContact({
    required this.name,
    required this.phone,
    this.relation = 'Caregiver',
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) =>
      EmergencyContact(
        name: json['name'] as String,
        phone: json['phone'] as String,
        relation: json['relation'] as String? ?? 'Caregiver',
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'relation': relation,
      };
}
