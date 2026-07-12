part of 'setting_view.dart';

class SettingViewBinding extends Bindings {

   @override
   void dependencies() {
       Get.lazyPut(() => SettingViewController());
   }
}