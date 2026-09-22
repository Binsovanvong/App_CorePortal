import 'package:core_portal/pages/Main/main_view.dart';
import 'package:core_portal/pages/mainpage/mainpage_binding.dart';
import 'package:core_portal/pages/mainpage/mainpage_view.dart';
import 'package:core_portal/routes/page_route.dart';
import 'package:core_portal/screens/application/application_view.dart';
import 'package:core_portal/screens/home/home_binding.dart';
import 'package:core_portal/screens/home/home_view.dart';
import 'package:core_portal/screens/login/login_binding.dart';
import 'package:core_portal/screens/login/login_view.dart';
import 'package:core_portal/screens/announcement/announcement_view.dart';
import 'package:core_portal/screens/announcement/announcement_binding.dart';
import 'package:core_portal/screens/modules/homepage/homepage_view.dart';
import 'package:core_portal/screens/notification/notification_binding.dart';
import 'package:core_portal/screens/notification/notification_view.dart';
import 'package:core_portal/screens/modules/request/request_view.dart';
import 'package:core_portal/screens/modules/list/list_view.dart';
import 'package:get/get.dart';

import 'package:core_portal/screens/web_view/web_view_screen.dart';
import 'package:core_portal/screens/first_login_change_password/first_login_change_password_view.dart';
import 'package:core_portal/screens/first_login_change_password/first_login_change_password_binding.dart';

import 'package:core_portal/screens/super_admin/super_admin_binding.dart';
import 'package:core_portal/screens/super_admin/super_admin_view.dart';
import 'package:core_portal/screens/admin/admin_binding.dart';
import 'package:core_portal/screens/admin/admin_view.dart';
import 'package:core_portal/screens/splash/splash_binding.dart';
import 'package:core_portal/screens/splash/splash_view.dart';
import 'package:core_portal/screens/reset_password/reset_password_view.dart';
import 'package:core_portal/screens/reset_password/reset_password_binding.dart';
import '../screens/setting/setting_view.dart';

class AppPages {
  static final routes = <GetPage>[
    GetPage(
      name: AppRoutes.splash,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: AppRoutes.login,
      page: () => LoginView(),
      binding: LoginBinding(),
    ),
    GetPage(
      name: AppRoutes.home,
      page: () => HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: AppRoutes.announcement,
      page: () => const AnnouncementView(),
      binding: AnnouncementBinding(),
    ),
    GetPage(
      name: AppRoutes.setting,
      page: () => SettingView(),
      binding: SettingViewBinding(),
    ),
    GetPage(
      name: AppRoutes.notification,
      page: () => NotificationView(),
      binding: NotificationBinding(),
    ),
    GetPage(
      name: AppRoutes.mainPage,
      page: () => MainpageView(),
      binding: MainpageBinding(),
    ),
    GetPage(
      name: AppRoutes.mainView,
      page: () => MainView(),
      binding: MainViewBinding(),
    ),
    GetPage(
      name: AppRoutes.homepage,
      page: () => HomePageView(),
      binding: HomePageBinding(),
    ),
    GetPage(
      name: AppRoutes.request,
      page: () => const RequestView(),
      binding: RequestViewBinding(),
    ),
    GetPage(
      name: AppRoutes.requestList,
      page: () => const RequestListView(),
      binding: ListViewBinding(),
    ),
    GetPage(name: AppRoutes.webView, page: () => const WebViewScreen()),
    GetPage(
      name: AppRoutes.firstLoginChangePassword,
      page: () => const FirstLoginChangePasswordView(),
      binding: FirstLoginChangePasswordBinding(),
    ),
    GetPage(
      name: AppRoutes.superAdmin,
      page: () => const SuperAdminView(),
      binding: SuperAdminBinding(),
    ),
    GetPage(
      name: AppRoutes.admin,
      page: () => const AdminView(),
      binding: AdminBinding(),
    ),
    GetPage(
      name: AppRoutes.application,
      page: () => const ApplicationView(),
      binding: ApplicationViewBinding(),
    ),
    GetPage(
      name: AppRoutes.resetPassword,
      page: () => const ResetPasswordView(),
      binding: ResetPasswordBinding(),
    ),
  ];
}
