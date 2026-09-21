import 'dart:io';
import 'package:core_portal/core/localization/app_translations.dart';
import 'package:core_portal/routes/apppage.dart';
import 'package:core_portal/routes/page_route.dart';
import 'package:core_portal/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

Future<String> _determineInitialRoute(
  GetStorage box, {
  bool skipAuth = false,
  String devRole = 'portal_user',
}) async {
  if (skipAuth) {
    final bool isAdm =
        devRole == 'admin' ||
        devRole == 'general_department_admin' ||
        devRole == 'portal_administrator';
    final roles = isAdm
        ? (devRole == 'general_department_admin'
              ? ['portal_user', 'general_department_admin', 'admin']
              : ['portal_user', 'portal_administrator', 'admin'])
        : ['portal_user'];
    await box.write('token', 'mock_dev_token');
    await box.write('username', 'DevUser');
    await box.write('roles', roles);
    await box.write('isAdmin', isAdm);
    await box.write('is_face_enrolled', true);
    return AppRoutes.mainPage;
  }

  return AppRoutes.splash;
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();

  await GetStorage.init();

  final box = GetStorage();

  // Set skipAuth: true to skip both login and face scan during development/testing.
  // Options for devRole: 'general_department_admin', 'portal_administrator', 'portal_user'
  final String initialRoute = await _determineInitialRoute(
    box,
    skipAuth: false,
    devRole: 'super_admin',
  );

  runApp(MainApp(initialRoute: initialRoute));
}

class MainApp extends StatelessWidget {
  final String initialRoute;

  const MainApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: initialRoute,
      getPages: AppPages.routes,
      translations: AppTranslations(),
      locale: LocalizationService.currentLocale,
      fallbackLocale: const Locale('km', 'KH'),
    );
  }
}
