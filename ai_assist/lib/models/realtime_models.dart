/// Denormalized linked-user entry shown on the Caregiver dashboard.
///
/// SIMPLIFICATION: in a fuller build, a caregiver_link would reference a
/// real /users/{uid} record for the linked person, created only after that
/// person explicitly grants consent. This demo skips that consent-flow
/// pipeline (there's no fall-detection or invite system built) and instead
/// stores the display info directly under the caregiver's own node —
/// which also happens to make the security rules trivial: a caregiver can
/// only ever read/write their own subtree.
class CaregiverLinkedUser {
  final String id;
  final String name;
  final String relationship;
  final String status; // 'online' | 'offline' | 'recent'
  final String? lastActiveLabel;

  const CaregiverLinkedUser({
    required this.id,
    required this.name,
    required this.relationship,
    required this.status,
    this.lastActiveLabel,
  });

  factory CaregiverLinkedUser.fromMap(String id, Map<dynamic, dynamic> map) => CaregiverLinkedUser(
        id: id,
        name: map['name'] as String? ?? '',
        relationship: map['relationship'] as String? ?? '',
        status: map['status'] as String? ?? 'offline',
        lastActiveLabel: map['lastActiveLabel'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'name': name,
        'relationship': relationship,
        'status': status,
        if (lastActiveLabel != null) 'lastActiveLabel': lastActiveLabel,
      };
}

class CaregiverAlert {
  final String id;
  final String userName;
  final String type; // 'fallDetected' | 'lowBattery' | 'emergencyRequest' | 'deviceOffline'
  final String status; // 'Open' | 'Acknowledged' | 'Resolved'
  final DateTime createdAt;

  const CaregiverAlert({
    required this.id,
    required this.userName,
    required this.type,
    required this.status,
    required this.createdAt,
  });

  factory CaregiverAlert.fromMap(String id, Map<dynamic, dynamic> map) => CaregiverAlert(
        id: id,
        userName: map['userName'] as String? ?? '',
        type: map['type'] as String? ?? 'emergencyRequest',
        status: map['status'] as String? ?? 'Open',
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'userName': userName,
        'type': type,
        'status': status,
        'createdAt': createdAt.toIso8601String(),
      };
}

/// A single AI-operation history entry (spec §33) — scoped to one user's
/// own subtree in the database (`/ai_history/{uid}/...`), never readable by
/// anyone else's rules.
class HistoryEntry {
  final String id;
  final String taskType;
  final String summary;
  final DateTime createdAt;

  const HistoryEntry({
    required this.id,
    required this.taskType,
    required this.summary,
    required this.createdAt,
  });

  factory HistoryEntry.fromMap(String id, Map<dynamic, dynamic> map) => HistoryEntry(
        id: id,
        taskType: map['taskType'] as String? ?? '',
        summary: map['summary'] as String? ?? '',
        createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'taskType': taskType,
        'summary': summary,
        'createdAt': createdAt.toIso8601String(),
      };
}
