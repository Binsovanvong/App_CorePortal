part of 'application_view.dart';

class ApplicationViewBinding extends Bindings {

   @override
   void dependencies() {
       Get.lazyPut(() => ApplicationViewController());
   }
}