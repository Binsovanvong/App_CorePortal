import 'package:get/get.dart';
import 'package:core_portal/screens/announcement/announcement_controller.dart';

class AnnouncementBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AnnouncementController());
  }
}
