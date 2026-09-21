import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../screens/announcement/announcement_controller.dart';
import '../screens/home/home_controller.dart';

class NavController extends GetxController {
  var currentIndex = 0.obs;
  final _box = GetStorage();
  final unreadCount = 0.obs;
  final isAdmin = false.obs;

  @override
  void onInit() {
    super.onInit();
    checkAdminRole();
  }

  void checkAdminRole() {
    final roles = _box.read('roles');
    if (roles is List && roles.isNotEmpty) {
      final list = roles.map((e) => e.toString().toLowerCase().trim()).toList();
      final hasAdmin = list.contains('admin') ||
          list.contains('administrator') ||
          list.contains('portal_administrator') ||
          list.contains('general_department_admin') ||
          list.contains('general_department') ||
          list.contains('portal_admin') ||
          list.contains('gddtm_admin') ||
          list.contains('gddtm_admins') ||
          list.contains('portal_admins');
      isAdmin.value = hasAdmin;
      _box.write('isAdmin', hasAdmin);
      return;
    }

    final groups = _box.read('groups') ?? _box.read('userGroups') ?? _box.read('user_groups');
    if (groups is List && groups.isNotEmpty) {
      for (var g in groups) {
        String str = '';
        if (g is Map) {
          str = (g['code'] ?? g['name'] ?? g['role'] ?? g['groupCode'] ?? '').toString().toLowerCase().trim();
        } else {
          str = g.toString().toLowerCase().trim();
        }
        if (str == 'admin' ||
            str == 'administrator' ||
            str == 'portal_administrator' ||
            str == 'general_department_admin' ||
            str == 'general_department' ||
            str == 'gddtm_admin' ||
            str == 'portal_admin' ||
            str.contains('general_department') ||
            str.contains('administrator')) {
          isAdmin.value = true;
          _box.write('isAdmin', true);
          return;
        }
      }
    }

    final isAdm = _box.read('isAdmin');
    if (isAdm == true) {
      isAdmin.value = true;
      return;
    }

    isAdmin.value = false;
    _box.write('isAdmin', false);
  }

  void changeTab(int index) {
    currentIndex.value = index;
    final announcementIndex = isAdmin.value ? 3 : 1;
    if (index == announcementIndex) {
      List<Map<String, dynamic>> list = [];
      if (Get.isRegistered<AnnouncementController>()) {
        list = Get.find<AnnouncementController>().announcements;
      }
      if (list.isEmpty && Get.isRegistered<HomeController>()) {
        list = Get.find<HomeController>().announcements;
      }
      markAllAsRead(list);
    }
  }

  void updateUnreadCount(List<Map<String, dynamic>> fetchedAnnouncements) {
    final announcementIndex = isAdmin.value ? 3 : 1;
    if (currentIndex.value == announcementIndex) {
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