import 'package:core_portal/controllers/nav_controller.dart';
import 'package:core_portal/screens/home/home_controller.dart';
import 'package:core_portal/screens/setting/setting_view.dart';
import 'package:core_portal/screens/announcement/announcement_controller.dart';
import 'package:core_portal/screens/application/application_view.dart';
import 'package:core_portal/screens/admin/admin_controller.dart';
import 'package:get/get.dart';

class MainpageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NavController>(() => NavController());
    Get.lazyPut<HomeController>(() => HomeController());
    Get.lazyPut<SettingViewController>(() => SettingViewController());
    Get.lazyPut<AnnouncementController>(() => AnnouncementController());
    Get.lazyPut<ApplicationViewController>(() => ApplicationViewController());
    Get.lazyPut<AdminController>(() => AdminController());
  }
}
