import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:academia/app/services/network_guard.dart';
import 'package:get/get.dart';

class SettingsController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final RxBool isLoading = true.obs;
  final RxBool isSaving = false.obs;
  final RxString errorText = ''.obs;

  final RxString instituteName = 'AttendX'.obs;
  final RxString supportEmail = ''.obs;
  final RxInt defaultHistoryDays = 30.obs;
  final RxBool lockSubmittedSessions = true.obs;
  final RxBool requireCorrectionNote = true.obs;
  final RxBool includeLeaveInAttendance = true.obs;
  final RxString appVersion = 'v1.0.0'.obs;

  final RxInt totalUsers = 0.obs;
  final RxInt totalTeachers = 0.obs;
  final RxInt totalStudents = 0.obs;
  final RxInt totalBatches = 0.obs;

  @override
  void onInit() {
    super.onInit();
    _load();
  }

  Future<void> _load() async {
    isLoading.value = true;
    errorText.value = '';
    try {
      final DocumentSnapshot<Map<String, dynamic>> settingsDoc = await _firestore
          .collection('app_settings')
          .doc('general')
          .get();
      final Map<String, dynamic> map = settingsDoc.data() ?? <String, dynamic>{};
      instituteName.value =
          (map['instituteName'] as String?)?.trim().isNotEmpty == true
          ? (map['instituteName'] as String).trim()
          : 'AttendX';
      supportEmail.value = (map['supportEmail'] as String?)?.trim() ?? '';
      defaultHistoryDays.value = _toInt(map['defaultHistoryDays'], fallback: 30);
      lockSubmittedSessions.value =
          (map['lockSubmittedSessions'] as bool?) ?? true;
      requireCorrectionNote.value =
          (map['requireCorrectionNote'] as bool?) ?? true;
      includeLeaveInAttendance.value =
          (map['includeLeaveInAttendance'] as bool?) ?? true;
      appVersion.value = (map['appVersion'] as String?)?.trim() ?? 'v1.0.0';

      final Future<QuerySnapshot<Map<String, dynamic>>> usersFuture =
          _firestore.collection('users').get();
      final Future<QuerySnapshot<Map<String, dynamic>>> teachersFuture =
          _firestore.collection('teachers').get();
      final Future<QuerySnapshot<Map<String, dynamic>>> studentsFuture =
          _firestore.collection('students').get();
      final Future<QuerySnapshot<Map<String, dynamic>>> batchesFuture =
          _firestore.collection('batches').get();

      final List<QuerySnapshot<Map<String, dynamic>>> all = await Future.wait<
        QuerySnapshot<Map<String, dynamic>>
      >(<Future<QuerySnapshot<Map<String, dynamic>>>>[
        usersFuture,
        teachersFuture,
        studentsFuture,
        batchesFuture,
      ]);
      totalUsers.value = all[0].size;
      totalTeachers.value = all[1].size;
      totalStudents.value = all[2].size;
      totalBatches.value = all[3].size;
    } catch (_) {
      errorText.value = 'Unable to load settings data.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> saveSettings({
    required String instituteNameValue,
    required String supportEmailValue,
    required int historyDays,
  }) async {
    isSaving.value = true;
    try {
      await NetworkGuard.run(
        _firestore.collection('app_settings').doc('general').set(
          <String, dynamic>{
            'instituteName': instituteNameValue.trim(),
            'supportEmail': supportEmailValue.trim(),
            'defaultHistoryDays': historyDays,
            'lockSubmittedSessions': lockSubmittedSessions.value,
            'requireCorrectionNote': requireCorrectionNote.value,
            'includeLeaveInAttendance': includeLeaveInAttendance.value,
            'appVersion': appVersion.value,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        ),
      );
      instituteName.value = instituteNameValue.trim();
      supportEmail.value = supportEmailValue.trim();
      defaultHistoryDays.value = historyDays;
    } finally {
      isSaving.value = false;
    }
  }

  void toggleLockSubmittedSessions(bool value) {
    lockSubmittedSessions.value = value;
  }

  void toggleRequireCorrectionNote(bool value) {
    requireCorrectionNote.value = value;
  }

  void toggleIncludeLeaveInAttendance(bool value) {
    includeLeaveInAttendance.value = value;
  }

  int _toInt(Object? value, {required int fallback}) {
    if (value is int) {
      return value;
    }
    return int.tryParse('$value') ?? fallback;
  }
}
