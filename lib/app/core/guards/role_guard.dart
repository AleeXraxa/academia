import 'package:academia/app/core/enums/user_role.dart';

class RoleGuard {
  static bool canAccess({
    required UserRole activeRole,
    required List<UserRole> allowedRoles,
  }) {
    if (activeRole == UserRole.superAdmin || activeRole == UserRole.cah) {
      return true;
    }

    return allowedRoles.contains(activeRole);
  }
}
