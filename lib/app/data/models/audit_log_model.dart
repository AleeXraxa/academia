import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLogModel {
  const AuditLogModel({
    required this.id,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.entityName,
    required this.actorId,
    required this.actorEmail,
    required this.actorRole,
    required this.note,
    required this.meta,
    this.at,
  });

  final String id;
  final String action;
  final String entityType;
  final String entityId;
  final String entityName;
  final String actorId;
  final String actorEmail;
  final String actorRole;
  final String note;
  final Map<String, dynamic> meta;
  final DateTime? at;

  factory AuditLogModel.fromMap({
    required String id,
    required Map<String, dynamic> map,
  }) {
    final Map<String, dynamic> meta =
        Map<String, dynamic>.from(map['meta'] as Map? ?? <String, dynamic>{});
    return AuditLogModel(
      id: id,
      action: (map['action'] as String? ?? '').trim(),
      entityType: (map['entityType'] as String? ?? '').trim(),
      entityId: (map['entityId'] as String? ?? '').trim(),
      entityName: (map['entityName'] as String? ?? '').trim(),
      actorId: (map['actorId'] as String? ?? '').trim(),
      actorEmail: (map['actorEmail'] as String? ?? '').trim(),
      actorRole: (map['actorRole'] as String? ?? '').trim(),
      note: (map['note'] as String? ?? '').trim(),
      meta: meta,
      at: (map['at'] as Timestamp?)?.toDate(),
    );
  }
}
