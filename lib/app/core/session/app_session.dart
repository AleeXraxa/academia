import 'package:academia/app/core/enums/user_role.dart';
import 'package:get/get.dart';

class AppSession extends GetxService {
  final Rxn<UserRole> role = Rxn<UserRole>();

  UserRole get roleOrStaff => role.value ?? UserRole.staff;
  bool get isTeacher => role.value == UserRole.teacher;

  void setRole(UserRole nextRole) {
    role.value = nextRole;
  }

  void clear() {
    role.value = null;
  }
}
