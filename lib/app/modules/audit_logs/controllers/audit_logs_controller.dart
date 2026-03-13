import 'dart:async';

import 'package:academia/app/data/models/audit_log_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class AuditLogsController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RxList<AuditLogModel> logs = <AuditLogModel>[].obs;
  final RxList<AuditLogModel> sessionLogs = <AuditLogModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxBool isPaging = false.obs;
  final RxString errorText = ''.obs;

  final RxInt rangeDays = 7.obs;
  final RxString entityType = ''.obs;
  final RxString action = ''.obs;
  final RxString actorRole = ''.obs;
  final RxString search = ''.obs;
  final RxInt pageSize = 50.obs;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sessionSubscription;

  DocumentSnapshot<Map<String, dynamic>>? _lastDoc;
  bool _hasMore = true;
  static const int _pageStep = 50;

  @override
  void onInit() {
    super.onInit();
    _listenSessionAuditLogs();
    _loadInitialLogs();
  }

  Future<void> _loadInitialLogs() async {
    isLoading.value = true;
    errorText.value = '';
    logs.clear();
    _lastDoc = null;
    _hasMore = true;
    await _loadMoreInternal();
    isLoading.value = false;
  }

  Future<void> loadMore() async {
    if (isPaging.value || !_hasMore) {
      return;
    }
    isPaging.value = true;
    await _loadMoreInternal();
    isPaging.value = false;
  }

  Future<void> _loadMoreInternal() async {
    try {
      Query<Map<String, dynamic>> query = _firestore
          .collection('audit_logs')
          .orderBy('at', descending: true)
          .limit(_pageStep);
      if (_lastDoc != null) {
        query = query.startAfterDocument(_lastDoc!);
      }
      final QuerySnapshot<Map<String, dynamic>> snapshot = await query.get();
      if (snapshot.docs.isNotEmpty) {
        _lastDoc = snapshot.docs.last;
        final List<AuditLogModel> mapped = snapshot.docs
            .map(
              (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                  AuditLogModel.fromMap(id: doc.id, map: doc.data()),
            )
            .toList();
        logs.addAll(mapped);
      }
      if (snapshot.docs.length < _pageStep) {
        _hasMore = false;
      }
    } catch (_) {
      errorText.value = 'Failed to load audit logs.';
    }
  }

  void updateRangeDays(int value) {
    rangeDays.value = value;
  }

  void updateEntityType(String value) {
    entityType.value = value.trim().toLowerCase();
  }

  void updateAction(String value) {
    action.value = value.trim().toLowerCase();
  }

  void updateActorRole(String value) {
    actorRole.value = value.trim().toLowerCase();
  }

  void updateSearch(String value) {
    search.value = value.trim().toLowerCase();
  }

  void _listenSessionAuditLogs() {
    _sessionSubscription?.cancel();
    _sessionSubscription = _firestore
        .collection('attendance_sessions')
        .orderBy('updatedAt', descending: true)
        .limit(300)
        .snapshots()
        .listen(
          (QuerySnapshot<Map<String, dynamic>> snapshot) {
            final List<AuditLogModel> mapped = <AuditLogModel>[];
            for (final QueryDocumentSnapshot<Map<String, dynamic>> doc
                in snapshot.docs) {
              final Map<String, dynamic> data = doc.data();
              final List<dynamic> rawLogs =
                  (data['auditLogs'] as List<dynamic>?) ?? <dynamic>[];
              final String batchName = (data['batchName'] as String? ?? '').trim();
              for (int i = 0; i < rawLogs.length; i += 1) {
                final Object? raw = rawLogs[i];
                if (raw is! Map) {
                  continue;
                }
                final Map<String, dynamic> entry =
                    Map<String, dynamic>.from(raw as Map);
                final Map<String, dynamic> normalized = <String, dynamic>{
                  'action': (entry['action'] ?? 'submit').toString(),
                  'entityType': (entry['entityType'] ?? 'attendance').toString(),
                  'entityId': (entry['entityId'] ?? doc.id).toString(),
                  'entityName': (entry['entityName'] ?? batchName).toString(),
                  'actorId': (entry['actorId'] ?? '').toString(),
                  'actorEmail': (entry['actorEmail'] ?? '').toString(),
                  'actorRole': (entry['actorRole'] ?? '').toString(),
                  'note': (entry['note'] ?? '').toString(),
                  'meta': entry['meta'] is Map
                      ? Map<String, dynamic>.from(entry['meta'] as Map)
                      : <String, dynamic>{},
                  'at': entry['at'] ?? Timestamp.now(),
                };
                mapped.add(
                  AuditLogModel.fromMap(
                    id: 'session_${doc.id}_$i',
                    map: normalized,
                  ),
                );
              }
            }
            sessionLogs.assignAll(mapped);
          },
          onError: (_) {
            sessionLogs.clear();
          },
        );
  }

  List<AuditLogModel> get allLogs => <AuditLogModel>[...logs, ...sessionLogs];

  List<AuditLogModel> get filteredLogs {
    final int days = rangeDays.value;
    final String type = entityType.value.trim().toLowerCase();
    final String act = action.value.trim().toLowerCase();
    final String role = actorRole.value.trim().toLowerCase();
    final String q = search.value.trim().toLowerCase();

    final DateTime now = DateTime.now();
    final DateTime startDate = days <= 0
        ? DateTime(2000, 1, 1)
        : DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: days - 1));

    return allLogs.where((AuditLogModel item) {
      final String itemType = item.entityType.trim().toLowerCase();
      final String itemAction = item.action.trim().toLowerCase();
      final String itemRole = item.actorRole.trim().toLowerCase();
      final String label = item.entityName.trim().toLowerCase();
      final String id = item.entityId.trim().toLowerCase();
      final String actorEmail = item.actorEmail.trim().toLowerCase();
      final String note = item.note.trim().toLowerCase();
      final DateTime date = item.at ?? DateTime(2000, 1, 1);

      final bool dateMatch = days <= 0 || !date.isBefore(startDate);
      final bool typeMatch = type.isEmpty || itemType == type;
      final bool actionMatch = act.isEmpty || itemAction == act;
      final bool roleMatch = role.isEmpty || itemRole == role;
      final bool searchMatch = q.isEmpty ||
          label.contains(q) ||
          id.contains(q) ||
          actorEmail.contains(q) ||
          note.contains(q);

      return dateMatch && typeMatch && actionMatch && roleMatch && searchMatch;
    }).toList();
  }

  List<AuditLogModel> get pagedLogs {
    final List<AuditLogModel> filtered = filteredLogs;
    if (filtered.length <= pageSize.value) {
      return filtered;
    }
    return filtered.take(pageSize.value).toList();
  }

  bool get hasMoreLogs => _hasMore;

  int get totalLogs => allLogs.length;

  int get todayLogs {
    final DateTime now = DateTime.now();
    final DateTime start = DateTime(now.year, now.month, now.day);
    return allLogs.where((AuditLogModel item) {
      final DateTime date = item.at ?? DateTime(2000, 1, 1);
      return !date.isBefore(start);
    }).length;
  }

  int get userActions => allLogs
      .where((AuditLogModel item) => item.entityType.toLowerCase() == 'user')
      .length;

  int get attendanceActions => allLogs
      .where((AuditLogModel item) =>
          item.entityType.toLowerCase() == 'attendance' ||
          item.entityType.toLowerCase() == 'session')
      .length;

  @override
  void onClose() {
    _sessionSubscription?.cancel();
    super.onClose();
  }
}
