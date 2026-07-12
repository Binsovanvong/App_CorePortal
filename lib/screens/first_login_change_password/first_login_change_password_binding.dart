import 'package:get/get.dart';
import 'first_login_change_password_controller.dart';

class FirstLoginChangePasswordBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => FirstLoginChangePasswordController());
  }
}
