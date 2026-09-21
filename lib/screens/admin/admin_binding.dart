import 'package:core_portal/screens/admin/admin_controller.dart';
import 'package:core_portal/screens/super_admin/super_admin_controller.dart';
// ignore: unused_import
import 'package:core_portal/screens/announcement/announcement_controller.dart';
// ignore: unused_import
import 'package:core_portal/screens/setting/setting_view.dart';
import 'package:get/get.dart';

class AdminBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AdminController>(() => AdminController());
    Get.lazyPut<SettingViewController>(() => SettingViewController());
    Get.lazyPut<AnnouncementController>(() => AnnouncementController());
    Get.lazyPut<SuperAdminController>(() => SuperAdminController());
  }
}
