import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:core_portal/core/api/api_client.dart';
import 'package:core_portal/routes/page_route.dart';

/// Middleware guarding authenticated routes against unauthorized navigation
class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    final token = ApiClient.currentToken;
    final box = GetStorage();
    final bool isLoggedIn = box.read('is_logged_in') == true;

    if ((token == null || token.isEmpty) && !isLoggedIn) {
      return const RouteSettings(name: AppRoutes.login);
    }
    return null;
  }
}

/// Middleware strictly guarding administrative portals (/admin, /super-admin)
class AdminMiddleware extends GetMiddleware {
  @override
  int? get priority => 2;

  @override
  RouteSettings? redirect(String? route) {
    final token = ApiClient.currentToken;
    final box = GetStorage();
    final bool isLoggedIn = box.read('is_logged_in') == true;

    if ((token == null || token.isEmpty) && !isLoggedIn) {
      return const RouteSettings(name: AppRoutes.login);
    }

    final bool isAdmin = box.read('isAdmin') == true;
    final rawRoles = box.read('roles');
    final List<String> roles = (rawRoles is List)
        ? rawRoles.map((r) => r.toString().toLowerCase()).toList()
        : [];

    final bool hasAdminPrivileges = isAdmin ||
        roles.any((r) =>
            r.contains('admin') ||
            r.contains('portal_administrator') ||
            r.contains('general_department_admin'));

    if (!hasAdminPrivileges) {
      return const RouteSettings(name: AppRoutes.mainPage);
    }
    return null;
  }
}
