import 'package:core_portal/controllers/nav_controller.dart';
import 'package:core_portal/screens/home/home_controller.dart';
import 'package:core_portal/screens/message/message_view.dart';
import 'package:get/get.dart';

import '../../screens/setting/setting_view.dart';

class MainpageBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => NavController());
    Get.lazyPut(() => HomeController());
    Get.lazyPut(() => SettingViewController());
    Get.lazyPut(() => MessageViewController());
  }
}