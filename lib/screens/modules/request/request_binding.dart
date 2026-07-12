part of 'request_view.dart';

class RequestViewBinding extends Bindings {

   @override
   void dependencies() {
       Get.lazyPut(() => RequestViewController());
   }
}