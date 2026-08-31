// Numeric fields cross the wire as JSON `num` (Dart's json decoder produces
// `double` for any value with a decimal point) — coerce explicitly rather
// than assuming the backend never sends e.g. 2099.954 for a seconds count.
int _asInt(dynamic v) => (v as num).round();

class TaskItem {
  final String taskId;
  final String title;
  final String type; // "digital" | "external"
  final int rewardMinutes;
  final bool proofAllowed;
  final String status; // "pending" | "completed"
  final String? verifiedBy;

  TaskItem({
    required this.taskId,
    required this.title,
    required this.type,
    required this.rewardMinutes,
    required this.proofAllowed,
    required this.status,
    required this.verifiedBy,
  });

  bool get isDigital => type == 'digital';
  bool get isDone => status == 'completed';

  factory TaskItem.fromJson(Map<String, dynamic> json) => TaskItem(
        taskId: json['taskId'],
        title: json['title'],
        type: json['type'],
        rewardMinutes: _asInt(json['rewardMinutes']),
        proofAllowed: json['proofAllowed'] ?? false,
        status: json['status'],
        verifiedBy: json['verifiedBy'],
      );
}

class SessionState {
  final String id;
  final DateTime startedAt;
  final int durationSec;
  final int remainingSec;
  final bool frozen;
  final bool ended;

  SessionState({
    required this.id,
    required this.startedAt,
    required this.durationSec,
    required this.remainingSec,
    required this.frozen,
    required this.ended,
  });

  factory SessionState.fromJson(Map<String, dynamic> json) => SessionState(
        id: json['id'],
        startedAt: DateTime.parse(json['startedAt']),
        durationSec: _asInt(json['durationSec']),
        remainingSec: _asInt(json['remainingSec']),
        frozen: json['frozen'] ?? false,
        ended: json['ended'] ?? false,
      );
}

class ChildState {
  final String childId;
  final String childName;
  final String date;
  final List<TaskItem> tasks;
  final int earnedMinutesToday;
  final int availableSeconds;
  final SessionState? activeSession;

  ChildState({
    required this.childId,
    required this.childName,
    required this.date,
    required this.tasks,
    required this.earnedMinutesToday,
    required this.availableSeconds,
    required this.activeSession,
  });

  factory ChildState.fromJson(Map<String, dynamic> json) => ChildState(
        childId: json['childId'],
        childName: json['childName'] ?? '',
        date: json['date'],
        tasks: (json['tasks'] as List).map((t) => TaskItem.fromJson(t)).toList(),
        earnedMinutesToday: _asInt(json['earnedMinutesToday']),
        availableSeconds: _asInt(json['availableSeconds']),
        activeSession: json['activeSession'] == null ? null : SessionState.fromJson(json['activeSession']),
      );
}
