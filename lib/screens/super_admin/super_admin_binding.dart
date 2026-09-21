import 'package:core_portal/screens/super_admin/super_admin_controller.dart';
// ignore: unused_import
import 'package:core_portal/screens/announcement/announcement_controller.dart';
// ignore: unused_import
import 'package:core_portal/screens/setting/setting_view.dart';
import 'package:get/get.dart';

class SuperAdminBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SuperAdminController>(() => SuperAdminController());
    Get.lazyPut<SettingViewController>(() => SettingViewController());
    Get.lazyPut<AnnouncementController>(() => AnnouncementController());
  }
}
