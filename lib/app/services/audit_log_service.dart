import 'package:academia/app/core/session/app_session.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';

class AuditLogService {
  AuditLogService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<void> log({
    required String action,
    required String entityType,
    String entityId = '',
    String entityName = '',
    String note = '',
    Map<String, dynamic> meta = const <String, dynamic>{},
    String? actorEmail,
    String? actorName,
  }) async {
    final Map<String, dynamic> payload = _buildPayload(
      action: action,
      entityType: entityType,
      entityId: entityId,
      entityName: entityName,
      note: note,
      meta: meta,
      actorEmail: actorEmail,
      actorName: actorName,
    );
    await _firestore.collection('audit_logs').add(payload);
  }

  void addToBatch(
    WriteBatch batch, {
    required String action,
    required String entityType,
    String entityId = '',
    String entityName = '',
    String note = '',
    Map<String, dynamic> meta = const <String, dynamic>{},
    String? actorEmail,
    String? actorName,
  }) {
    final DocumentReference<Map<String, dynamic>> doc =
        _firestore.collection('audit_logs').doc();
    batch.set(
      doc,
      _buildPayload(
        action: action,
        entityType: entityType,
        entityId: entityId,
        entityName: entityName,
        note: note,
        meta: meta,
        actorEmail: actorEmail,
        actorName: actorName,
      ),
    );
  }

  Map<String, dynamic> _buildPayload({
    required String action,
    required String entityType,
    required String entityId,
    required String entityName,
    required String note,
    required Map<String, dynamic> meta,
    String? actorEmail,
    String? actorName,
  }) {
    final String uid = (_auth.currentUser?.uid ?? '').trim();
    final String email = (actorEmail ?? _auth.currentUser?.email ?? '').trim();
    final String role = Get.find<AppSession>().roleOrStaff.name;

    return <String, dynamic>{
      'action': action.trim(),
      'entityType': entityType.trim(),
      'entityId': entityId.trim(),
      'entityName': entityName.trim(),
      'note': note.trim(),
      'meta': meta,
      'actorId': uid,
      'actorEmail': email,
      'actorName': (actorName ?? '').trim(),
      'actorRole': role,
      'at': FieldValue.serverTimestamp(),
    };
  }
}
