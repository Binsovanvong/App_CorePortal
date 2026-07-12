part of 'main_view.dart';

class MainViewBinding extends Bindings {

   @override
   void dependencies() {
       Get.lazyPut(() => MainController());
   }
}