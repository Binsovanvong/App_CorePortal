import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../screens/message/message_view.dart';
import '../screens/home/home_controller.dart';

class NavController extends GetxController {
  var currentIndex = 0.obs;
  final _box = GetStorage();
  final unreadCount = 0.obs;

  void changeTab(int index) {
    currentIndex.value = index;
    if (index == 1) {
      List<Map<String, dynamic>> list = [];
      if (Get.isRegistered<MessageViewController>()) {
        list = Get.find<MessageViewController>().announcements;
      }
      if (list.isEmpty && Get.isRegistered<HomeController>()) {
        list = Get.find<HomeController>().announcements;
      }
      markAllAsRead(list);
    }
  }

  void updateUnreadCount(List<Map<String, dynamic>> fetchedAnnouncements) {
    if (currentIndex.value == 1) {
      markAllAsRead(fetchedAnnouncements);
      return;
    }

    final readIds = List<String>.from(_box.read<List>('read_announcements') ?? []);
    int count = 0;
    for (var item in fetchedAnnouncements) {
      final id = (item['id'] ?? item['uuid'] ?? item['title'] ?? item['createdAt'] ?? '').toString();
      if (id.isNotEmpty && !readIds.contains(id)) {
        count++;
      }
    }
    unreadCount.value = count;
  }

  void markAllAsRead(List<Map<String, dynamic>> currentAnnouncements) {
    final readIds = List<String>.from(_box.read<List>('read_announcements') ?? []);
    bool changed = false;
    for (var item in currentAnnouncements) {
      final id = (item['id'] ?? item['uuid'] ?? item['title'] ?? item['createdAt'] ?? '').toString();
      if (id.isNotEmpty && !readIds.contains(id)) {
        readIds.add(id);
        changed = true;
      }
    }
    if (changed) {
      _box.write('read_announcements', readIds);
    }
    unreadCount.value = 0;
  }
}