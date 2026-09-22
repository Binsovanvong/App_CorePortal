import 'package:get/get.dart';
import 'package:core_portal/screens/reset_password/reset_password_controller.dart';

class ResetPasswordBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ResetPasswordController>(() => ResetPasswordController());
  }
}
