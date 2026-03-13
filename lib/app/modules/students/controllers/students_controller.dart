import 'dart:async';

import 'package:academia/app/data/models/batch_model.dart';
import 'package:academia/app/data/models/student_model.dart';
import 'package:academia/app/services/audit_log_service.dart';
import 'package:academia/app/services/network_guard.dart';
import 'package:academia/app/widgets/common/app_notifier.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class StudentsController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuditLogService _auditLogService = AuditLogService();

  final RxList<StudentModel> students = <StudentModel>[].obs;
  final RxList<BatchModel> batches = <BatchModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxString errorText = ''.obs;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>?
  _studentsSubscription;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _batchesSubscription;

  int get totalStudents => students.length;
  int get activeStudents => students
      .where((StudentModel student) => _status(student) == 'active')
      .length;
  int get completedStudents => students
      .where((StudentModel student) => _status(student) == 'completed')
      .length;
  int get dropStudents => students
      .where((StudentModel student) => _status(student) == 'drop')
      .length;
  int get assignedStudents => students
      .where(
        (StudentModel student) => (student.batchId ?? '').trim().isNotEmpty,
      )
      .length;

  @override
  void onInit() {
    super.onInit();
    _listenStudents();
    _listenBatches();
  }

  void _listenStudents() {
    _studentsSubscription?.cancel();
    isLoading.value = true;

    _studentsSubscription = _firestore
        .collection('students')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (QuerySnapshot<Map<String, dynamic>> snapshot) {
            final List<StudentModel> mapped = snapshot.docs
                .map(
                  (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                      StudentModel.fromMap(id: doc.id, map: doc.data()),
                )
                .toList();

            students.assignAll(mapped);
            unawaited(_syncBatchStudentCounts(mapped));
            errorText.value = '';
            isLoading.value = false;
          },
          onError: (_) {
            errorText.value = 'Failed to load students from Firestore.';
            isLoading.value = false;
          },
        );
  }

  void _listenBatches() {
    _batchesSubscription?.cancel();
    _batchesSubscription = _firestore
        .collection('batches')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
          (QuerySnapshot<Map<String, dynamic>> snapshot) {
            final List<BatchModel> mapped = snapshot.docs
                .map(
                  (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                      BatchModel.fromMap(id: doc.id, map: doc.data()),
                )
                .toList();
            batches.assignAll(mapped);
            unawaited(_syncBatchStudentCounts(students));
          },
          onError: (_) {
            batches.clear();
          },
        );
  }

  Future<void> _syncBatchStudentCounts(List<StudentModel> source) async {
    if (batches.isEmpty) {
      return;
    }

    final Map<String, int> countsByBatch = <String, int>{};
    for (final StudentModel student in source) {
      if (_status(student) != 'active') {
        continue;
      }
      final String batchId = (student.batchId ?? '').trim();
      if (batchId.isEmpty) {
        continue;
      }
      countsByBatch[batchId] = (countsByBatch[batchId] ?? 0) + 1;
    }

    final WriteBatch writer = _firestore.batch();
    bool hasChanges = false;

    for (final BatchModel batch in batches) {
      final int expected = countsByBatch[batch.id] ?? 0;
      final int current = batch.studentsCount ?? 0;
      if (expected == current) {
        continue;
      }

      hasChanges = true;
      writer.update(
        _firestore.collection('batches').doc(batch.id),
        <String, dynamic>{
          'studentsCount': expected,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
    }

    if (hasChanges) {
      try {
        await NetworkGuard.run(writer.commit());
      } catch (e) {
        if (AppNotifier.isNetworkError(e)) {
          await AppNotifier.showNetworkDialog(
            title: 'Network error',
            message:
                'Unable to sync batch counts. Check connection and retry later.',
          );
        }
      }
    }
  }

  Future<void> createStudent({
    required String name,
    String? studentId,
    required String email,
    required String contactNo,
    required String parentContact,
    required String gender,
    required String status,
    required String batchId,
    required String batchName,
  }) async {
    await _ensureUniqueStudentId(studentId: studentId, excludeDocId: null);
    final String normalizedStatus = status.trim().toLowerCase();
    final bool isActive = normalizedStatus == 'active';
    final String normalizedBatchId = isActive ? batchId.trim() : '';
    final String normalizedBatchName = isActive ? batchName.trim() : '';
    final DocumentReference<Map<String, dynamic>> studentDoc = _firestore
        .collection('students')
        .doc();

    final WriteBatch batch = _firestore.batch();
    batch.set(studentDoc, <String, dynamic>{
      'name': name.trim(),
      'studentId': (studentId ?? '').trim(),
      'email': email.trim().toLowerCase(),
      'contactNo': contactNo.trim(),
      'parentContact': parentContact.trim(),
      'gender': gender.trim(),
      'status': normalizedStatus,
      'batchId': normalizedBatchId,
      'batchName': normalizedBatchName,
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (isActive && normalizedBatchId.isNotEmpty) {
      final DocumentReference<Map<String, dynamic>> batchDoc = _firestore
          .collection('batches')
          .doc(normalizedBatchId);
      batch.update(batchDoc, <String, dynamic>{
        'studentsCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await NetworkGuard.run(batch.commit());
    await _auditLogService.log(
      action: 'create',
      entityType: 'student',
      entityId: studentDoc.id,
      entityName: name.trim(),
      meta: <String, dynamic>{
        'studentId': (studentId ?? '').trim(),
        'status': normalizedStatus,
        'batchId': normalizedBatchId,
      },
    );
  }

  String get bulkImportTemplateCsv =>
      'fullName,studentId,email,contactNo,parentContact,gender,batchId,batchName,status\n'
      'John Doe,STD-001,john@example.com,03001234567,03007654321,Male,,Batch A,active\n'
      'Jane Smith,STD-002,jane@example.com,,,Female,batch_document_id,,completed\n';

  BulkStudentImportPreview previewBulkImport(String csvContent) {
    final List<List<String>> rows = _parseCsv(csvContent);
    if (rows.isEmpty) {
      throw Exception('CSV file is empty.');
    }
    if (rows.length == 1) {
      throw Exception('CSV has header only. Add at least one student row.');
    }

    final List<String> headers = rows.first
        .map((String value) => _normalizeHeader(value))
        .toList();
    final List<BulkStudentImportRow> parsedRows = <BulkStudentImportRow>[];
    final Set<String> existingStudentIds = students
        .map((StudentModel s) => (s.studentId ?? '').trim().toLowerCase())
        .where((String id) => id.isNotEmpty)
        .toSet();

    for (int i = 1; i < rows.length; i++) {
      final List<String> row = rows[i];
      final Map<String, String> byHeader = <String, String>{};
      for (int j = 0; j < headers.length; j++) {
        final String key = headers[j];
        byHeader[key] = j < row.length ? row[j].trim() : '';
      }

      final List<String> errors = <String>[];
      final String fullName = _pick(byHeader, <String>[
        'fullname',
        'full_name',
        'name',
      ]).trim();
      final String studentId = _pick(byHeader, <String>[
        'studentid',
        'student_id',
      ]).trim();
      final String email = _pick(byHeader, <String>['email']).trim();
      final String contactNo = _pick(byHeader, <String>[
        'contactno',
        'contact_no',
      ]).trim();
      final String parentContact = _pick(byHeader, <String>[
        'parentcontact',
        'parent_contact',
      ]).trim();
      final String genderRaw = _pick(byHeader, <String>['gender']).trim();
      final String batchIdRaw = _pick(byHeader, <String>[
        'batchid',
        'batch_id',
      ]).trim();
      final String batchNameRaw = _pick(byHeader, <String>[
        'batchname',
        'batch_name',
      ]).trim();
      final String statusRaw = _pick(byHeader, <String>['status']).trim();

      if (fullName.isEmpty) {
        errors.add('Full Name is required.');
      }
      if (studentId.isNotEmpty &&
          existingStudentIds.contains(studentId.toLowerCase())) {
        errors.add('StudentID already exists.');
      }
      if (email.isNotEmpty && !_isValidEmail(email)) {
        errors.add('Invalid email format.');
      }

      final String statusNormalized = statusRaw.isEmpty
          ? 'active'
          : statusRaw.toLowerCase();
      const Set<String> allowedStatus = <String>{'active', 'completed', 'drop'};
      if (!allowedStatus.contains(statusNormalized)) {
        errors.add('Status must be active, completed, or drop.');
      }
      final BatchModel? matchedBatch = _matchBatch(
        batchId: batchIdRaw,
        batchName: batchNameRaw,
      );
      if (statusNormalized == 'active') {
        if ((batchIdRaw.isEmpty && batchNameRaw.isEmpty) ||
            matchedBatch == null) {
          errors.add('Batch not found. Provide valid batchId or batchName.');
        }
      }

      String genderNormalized = genderRaw.isEmpty ? 'Male' : genderRaw;
      final String genderLower = genderNormalized.toLowerCase();
      if (genderLower == 'male' || genderLower == 'm') {
        genderNormalized = 'Male';
      } else if (genderLower == 'female' || genderLower == 'f') {
        genderNormalized = 'Female';
      } else if (genderLower == 'other' || genderLower == 'o') {
        genderNormalized = 'Other';
      } else {
        errors.add('Gender must be Male, Female, or Other.');
      }

      parsedRows.add(
        BulkStudentImportRow(
          rowNumber: i + 1,
          fullName: fullName,
          studentId: studentId,
          email: email.toLowerCase(),
          contactNo: contactNo,
          parentContact: parentContact,
          gender: genderNormalized,
          status: statusNormalized,
          batchId: statusNormalized == 'active' ? (matchedBatch?.id ?? '') : '',
          batchName: statusNormalized == 'active'
              ? (matchedBatch?.name ?? '')
              : '',
          errors: errors,
        ),
      );
    }

    final Map<String, int> duplicateCounter = <String, int>{};
    for (final BulkStudentImportRow row in parsedRows) {
      final String normalized = row.studentId.trim().toLowerCase();
      if (normalized.isEmpty) {
        continue;
      }
      duplicateCounter[normalized] = (duplicateCounter[normalized] ?? 0) + 1;
    }
    for (int i = 0; i < parsedRows.length; i++) {
      final BulkStudentImportRow row = parsedRows[i];
      final String normalized = row.studentId.trim().toLowerCase();
      if (normalized.isNotEmpty && (duplicateCounter[normalized] ?? 0) > 1) {
        final List<String> updatedErrors = <String>[
          ...row.errors,
          'StudentID is duplicated in CSV.',
        ];
        parsedRows[i] = BulkStudentImportRow(
          rowNumber: row.rowNumber,
          fullName: row.fullName,
          studentId: row.studentId,
          email: row.email,
          contactNo: row.contactNo,
          parentContact: row.parentContact,
          gender: row.gender,
          status: row.status,
          batchId: row.batchId,
          batchName: row.batchName,
          errors: updatedErrors,
        );
      }
    }

    return BulkStudentImportPreview(rows: parsedRows);
  }

  Future<BulkStudentImportResult> importBulkStudents({
    required BulkStudentImportPreview preview,
    bool skipInvalid = true,
  }) async {
    final List<BulkStudentImportRow> validRows = preview.rows
        .where((BulkStudentImportRow row) => row.isValid)
        .toList();
    final List<BulkStudentImportRow> invalidRows = preview.rows
        .where((BulkStudentImportRow row) => !row.isValid)
        .toList();

    if (!skipInvalid && invalidRows.isNotEmpty) {
      throw Exception('Fix invalid rows or enable skip invalid rows.');
    }
    if (validRows.isEmpty) {
      throw Exception('No valid rows to import.');
    }

    final Set<String> existingIds = students
        .map((StudentModel s) => (s.studentId ?? '').trim().toLowerCase())
        .where((String id) => id.isNotEmpty)
        .toSet();
    final Set<String> seenImportIds = <String>{};
    final List<BulkStudentImportRow> importableRows = <BulkStudentImportRow>[];
    final List<String> failed = <String>[];

    for (final BulkStudentImportRow row in validRows) {
      final String normalized = row.studentId.trim().toLowerCase();
      if (normalized.isNotEmpty && existingIds.contains(normalized)) {
        failed.add(
          'Row ${row.rowNumber}: StudentID "${row.studentId}" already exists.',
        );
        continue;
      }
      if (normalized.isNotEmpty && seenImportIds.contains(normalized)) {
        failed.add(
          'Row ${row.rowNumber}: StudentID "${row.studentId}" duplicated in import.',
        );
        continue;
      }
      if (normalized.isNotEmpty) {
        seenImportIds.add(normalized);
      }
      importableRows.add(row);
    }

    int imported = 0;
    const int chunkSize = 380;

    for (int start = 0; start < importableRows.length; start += chunkSize) {
      final int end = (start + chunkSize) > importableRows.length
          ? importableRows.length
          : start + chunkSize;
      final List<BulkStudentImportRow> chunk = importableRows.sublist(
        start,
        end,
      );
      final WriteBatch writeBatch = _firestore.batch();

      for (final BulkStudentImportRow row in chunk) {
        final DocumentReference<Map<String, dynamic>> doc = _firestore
            .collection('students')
            .doc();
        writeBatch.set(doc, <String, dynamic>{
          'name': row.fullName,
          'studentId': row.studentId,
          'email': row.email,
          'contactNo': row.contactNo,
          'parentContact': row.parentContact,
          'gender': row.gender,
          'status': row.status,
          'batchId': row.batchId,
          'batchName': row.batchName,
          'createdAt': FieldValue.serverTimestamp(),
        });
        _auditLogService.addToBatch(
          writeBatch,
          action: 'create',
          entityType: 'student',
          entityId: doc.id,
          entityName: row.fullName,
          meta: <String, dynamic>{
            'studentId': row.studentId,
            'status': row.status,
            'batchId': row.batchId,
          },
        );
      }

      try {
        await NetworkGuard.run(writeBatch.commit());
        imported += chunk.length;
      } catch (e) {
        failed.add('Rows ${chunk.first.rowNumber}-${chunk.last.rowNumber}: $e');
      }
    }

    unawaited(_syncBatchStudentCountsFromFirestore());

    return BulkStudentImportResult(
      total: preview.totalRows,
      imported: imported,
      skipped: skipInvalid
          ? invalidRows.length + (validRows.length - importableRows.length)
          : (validRows.length - importableRows.length),
      failed: failed,
    );
  }

  Future<void> _syncBatchStudentCountsFromFirestore() async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _firestore
        .collection('students')
        .get();
    final List<StudentModel> mapped = snapshot.docs
        .map(
          (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
              StudentModel.fromMap(id: doc.id, map: doc.data()),
        )
        .toList();
    await _syncBatchStudentCounts(mapped);
  }

  BatchModel? _matchBatch({
    required String batchId,
    required String batchName,
  }) {
    final String normalizedId = batchId.trim();
    if (normalizedId.isNotEmpty) {
      for (final BatchModel batch in batches) {
        if (batch.id.trim() == normalizedId) {
          return batch;
        }
      }
    }

    final String normalizedName = batchName.trim().toLowerCase();
    if (normalizedName.isNotEmpty) {
      for (final BatchModel batch in batches) {
        if (batch.name.trim().toLowerCase() == normalizedName) {
          return batch;
        }
      }
    }
    return null;
  }

  String _normalizeHeader(String header) {
    return header.trim().toLowerCase().replaceAll(' ', '').replaceAll('-', '_');
  }

  String _pick(Map<String, String> byHeader, List<String> keys) {
    for (final String key in keys) {
      if (byHeader.containsKey(key)) {
        return byHeader[key] ?? '';
      }
    }
    return '';
  }

  bool _isValidEmail(String value) {
    final RegExp regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return regex.hasMatch(value);
  }

  List<List<String>> _parseCsv(String input) {
    final List<List<String>> rows = <List<String>>[];
    final StringBuffer field = StringBuffer();
    List<String> row = <String>[];
    bool inQuotes = false;

    for (int i = 0; i < input.length; i++) {
      final String char = input[i];
      if (char == '"') {
        if (inQuotes && i + 1 < input.length && input[i + 1] == '"') {
          field.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        row.add(field.toString().trim());
        field.clear();
      } else if ((char == '\n' || char == '\r') && !inQuotes) {
        if (char == '\r' && i + 1 < input.length && input[i + 1] == '\n') {
          i++;
        }
        row.add(field.toString().trim());
        field.clear();
        final bool isRowEmpty = row.every((String value) => value.isEmpty);
        if (!isRowEmpty) {
          rows.add(row);
        }
        row = <String>[];
      } else {
        field.write(char);
      }
    }

    row.add(field.toString().trim());
    final bool isLastRowEmpty = row.every((String value) => value.isEmpty);
    if (!isLastRowEmpty) {
      rows.add(row);
    }
    return rows;
  }

  Future<void> updateStudent({
    required String id,
    required String name,
    String? studentId,
    required String email,
    required String contactNo,
    required String parentContact,
    required String gender,
    required String status,
    required String batchId,
    required String batchName,
  }) async {
    await _ensureUniqueStudentId(studentId: studentId, excludeDocId: id);
    final DocumentReference<Map<String, dynamic>> studentDoc = _firestore
        .collection('students')
        .doc(id);
    final DocumentSnapshot<Map<String, dynamic>> before = await studentDoc
        .get();
    final String previousBatchId = (before.data()?['batchId'] as String? ?? '')
        .trim();
    final String normalizedStatus = status.trim().toLowerCase();
    final bool isActive = normalizedStatus == 'active';
    final String nextBatchId = isActive ? batchId.trim() : '';
    final String nextBatchName = isActive ? batchName.trim() : '';

    final WriteBatch batch = _firestore.batch();
    batch.update(studentDoc, <String, dynamic>{
      'name': name.trim(),
      'studentId': (studentId ?? '').trim(),
      'email': email.trim().toLowerCase(),
      'contactNo': contactNo.trim(),
      'parentContact': parentContact.trim(),
      'gender': gender.trim(),
      'status': normalizedStatus,
      'batchId': nextBatchId,
      'batchName': nextBatchName,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (previousBatchId.isNotEmpty && previousBatchId != nextBatchId) {
      final DocumentReference<Map<String, dynamic>> previousBatchDoc =
          _firestore.collection('batches').doc(previousBatchId);
      batch.update(previousBatchDoc, <String, dynamic>{
        'studentsCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    if (nextBatchId.isNotEmpty && previousBatchId != nextBatchId) {
      final DocumentReference<Map<String, dynamic>> nextBatchDoc = _firestore
          .collection('batches')
          .doc(nextBatchId);
      batch.update(nextBatchDoc, <String, dynamic>{
        'studentsCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await NetworkGuard.run(batch.commit());
    await _auditLogService.log(
      action: 'update',
      entityType: 'student',
      entityId: id.trim(),
      entityName: name.trim(),
      meta: <String, dynamic>{
        'studentId': (studentId ?? '').trim(),
        'status': normalizedStatus,
        'batchId': nextBatchId,
      },
    );
  }

  Future<void> _ensureUniqueStudentId({
    required String? studentId,
    required String? excludeDocId,
  }) async {
    final String normalized = (studentId ?? '').trim();
    if (normalized.isEmpty) {
      return;
    }
    final String lower = normalized.toLowerCase();
    for (final StudentModel student in students) {
      if (excludeDocId != null && student.id == excludeDocId) {
        continue;
      }
      final String existing = (student.studentId ?? '').trim().toLowerCase();
      if (existing.isNotEmpty && existing == lower) {
        throw Exception(
          'StudentID "$normalized" already exists. Please use a unique StudentID.',
        );
      }
    }

    final QuerySnapshot<Map<String, dynamic>> snap = await _firestore
        .collection('students')
        .where('studentId', isEqualTo: normalized)
        .limit(2)
        .get();
    if (snap.docs.isEmpty) {
      return;
    }
    if (excludeDocId != null &&
        snap.docs.length == 1 &&
        snap.docs.first.id == excludeDocId) {
      return;
    }
    final bool hasOther = snap.docs.any(
      (QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
          excludeDocId == null || doc.id != excludeDocId,
    );
    if (hasOther) {
      throw Exception(
        'StudentID "$normalized" already exists. Please use a unique StudentID.',
      );
    }
  }

  Future<void> deleteStudent(String id) async {
    final DocumentReference<Map<String, dynamic>> studentDoc = _firestore
        .collection('students')
        .doc(id);
    final DocumentSnapshot<Map<String, dynamic>> before = await studentDoc
        .get();
    final String batchId = (before.data()?['batchId'] as String? ?? '').trim();

    final WriteBatch batch = _firestore.batch();
    batch.delete(studentDoc);
    if (batchId.isNotEmpty) {
      final DocumentReference<Map<String, dynamic>> batchDoc = _firestore
          .collection('batches')
          .doc(batchId);
      batch.update(batchDoc, <String, dynamic>{
        'studentsCount': FieldValue.increment(-1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
    await NetworkGuard.run(batch.commit());
    await _auditLogService.log(
      action: 'delete',
      entityType: 'student',
      entityId: id.trim(),
      entityName: (before.data()?['name'] as String? ?? '').trim(),
      meta: <String, dynamic>{
        'studentId': (before.data()?['studentId'] as String? ?? '').trim(),
        'batchId': batchId,
      },
    );
  }

  String statusLabel(StudentModel student) {
    final String normalized = _status(student);
    return normalized[0].toUpperCase() + normalized.substring(1);
  }

  String _status(StudentModel student) {
    final String normalized = student.status.trim().toLowerCase();
    if (normalized.isEmpty) {
      return 'active';
    }
    return normalized;
  }

  @override
  void onClose() {
    _studentsSubscription?.cancel();
    _batchesSubscription?.cancel();
    super.onClose();
  }
}

class BulkStudentImportRow {
  const BulkStudentImportRow({
    required this.rowNumber,
    required this.fullName,
    required this.studentId,
    required this.email,
    required this.contactNo,
    required this.parentContact,
    required this.gender,
    required this.status,
    required this.batchId,
    required this.batchName,
    required this.errors,
  });

  final int rowNumber;
  final String fullName;
  final String studentId;
  final String email;
  final String contactNo;
  final String parentContact;
  final String gender;
  final String status;
  final String batchId;
  final String batchName;
  final List<String> errors;

  bool get isValid => errors.isEmpty;
}

class BulkStudentImportPreview {
  const BulkStudentImportPreview({required this.rows});

  final List<BulkStudentImportRow> rows;

  int get totalRows => rows.length;
  int get validRows =>
      rows.where((BulkStudentImportRow row) => row.isValid).length;
  int get invalidRows =>
      rows.where((BulkStudentImportRow row) => !row.isValid).length;
}

class BulkStudentImportResult {
  const BulkStudentImportResult({
    required this.total,
    required this.imported,
    required this.skipped,
    required this.failed,
  });

  final int total;
  final int imported;
  final int skipped;
  final List<String> failed;
}
