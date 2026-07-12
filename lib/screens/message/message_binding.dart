part of 'message_view.dart';

class MessageViewBinding extends Bindings {

   @override
   void dependencies() {
       Get.lazyPut(() => MessageViewController());
   }
}