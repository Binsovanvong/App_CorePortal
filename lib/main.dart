import 'package:core_portal/routes/apppage.dart';
import 'package:core_portal/routes/page_route.dart';
import 'package:core_portal/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await GetStorage.init();

  final box = GetStorage();
  final token = box.read('token');

  runApp(
    MainApp(
      initialRoute: token != null && token.toString().isNotEmpty
          ? AppRoutes.mainPage
          : AppRoutes.login,
    ),
  );
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
    );
  }
}
