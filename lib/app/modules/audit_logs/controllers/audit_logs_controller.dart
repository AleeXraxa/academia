import 'dart:async';

import 'package:academia/app/data/models/audit_log_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class AuditLogsController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RxList<AuditLogModel> logs = <AuditLogModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxString errorText = ''.obs;

  final RxInt rangeDays = 7.obs;
  final RxString entityType = ''.obs;
  final RxString action = ''.obs;
  final RxString actorRole = ''.obs;
  final RxString search = ''.obs;
  final RxInt pageSize = 50.obs;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  static const int _pageStep = 50;

  @override
  void onInit() {
    super.onInit();
    _listenLogs();
  }

  void _listenLogs() {
    _subscription?.cancel();
    isLoading.value = true;

    _subscription = _firestore
        .collection('audit_logs')
        .orderBy('at', descending: true)
        .limit(500)
        .snapshots()
        .listen(
          (QuerySnapshot<Map<String, dynamic>> snapshot) {
            final List<AuditLogModel> mapped = snapshot.docs
                .map(
                  (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                      AuditLogModel.fromMap(id: doc.id, map: doc.data()),
                )
                .toList();
            logs.assignAll(mapped);
            errorText.value = '';
            isLoading.value = false;
            if (pageSize.value < _pageStep) {
              resetPagination();
            }
          },
          onError: (_) {
            errorText.value = 'Failed to load audit logs.';
            isLoading.value = false;
          },
        );
  }

  void updateRangeDays(int value) {
    rangeDays.value = value;
    resetPagination();
  }

  void updateEntityType(String value) {
    entityType.value = value.trim().toLowerCase();
    resetPagination();
  }

  void updateAction(String value) {
    action.value = value.trim().toLowerCase();
    resetPagination();
  }

  void updateActorRole(String value) {
    actorRole.value = value.trim().toLowerCase();
    resetPagination();
  }

  void updateSearch(String value) {
    search.value = value.trim().toLowerCase();
    resetPagination();
  }

  void resetPagination() {
    pageSize.value = _pageStep;
  }

  void loadMore() {
    final int total = filteredLogs.length;
    if (pageSize.value >= total) {
      return;
    }
    pageSize.value = (pageSize.value + _pageStep).clamp(0, total);
  }

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

    return logs.where((AuditLogModel item) {
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

  bool get hasMoreLogs => filteredLogs.length > pagedLogs.length;

  int get totalLogs => logs.length;

  int get todayLogs {
    final DateTime now = DateTime.now();
    final DateTime start = DateTime(now.year, now.month, now.day);
    return logs.where((AuditLogModel item) {
      final DateTime date = item.at ?? DateTime(2000, 1, 1);
      return !date.isBefore(start);
    }).length;
  }

  int get userActions => logs
      .where((AuditLogModel item) => item.entityType.toLowerCase() == 'user')
      .length;

  int get attendanceActions => logs
      .where((AuditLogModel item) =>
          item.entityType.toLowerCase() == 'attendance' ||
          item.entityType.toLowerCase() == 'session')
      .length;

  @override
  void onClose() {
    _subscription?.cancel();
    super.onClose();
  }
}
