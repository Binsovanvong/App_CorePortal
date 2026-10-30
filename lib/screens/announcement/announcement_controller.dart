import 'package:flutter/widgets.dart';
import 'package:flutter/scheduler.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:core_portal/core/api/services/auth_service.dart';
import 'package:core_portal/controllers/nav_controller.dart';
import 'package:core_portal/screens/admin/admin_controller.dart';
import 'package:dio/dio.dart' show DioException, DioExceptionType;

class AnnouncementController extends GetxController {
  final LayerLink categoryDropdownLink = LayerLink();
  OverlayEntry? categoryOverlayEntry;
  final RxBool isCategoryDropdownOpen = false.obs;
  final AuthService _authService = AuthService();
  final GetStorage _box = GetStorage();

  final announcements = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final isSubmitting = false.obs;
  final errorMessage = "".obs;

  // Concept Design Filter: 'all' vs 'unread'
  final RxString selectedFilterTab = 'all'.obs;
  final RxSet<String> readAnnouncementIds = <String>{}.obs;

  // Concept fallback announcements matching design mockup
  static final List<Map<String, dynamic>> conceptFallbackAnnouncements = [
    {
      'id': 'concept_ann_1',
      'title': 'ការជូនដំណឹងអំពីការធ្វើបច្ចុប្បន្នភាពប្រព័ន្ធ',
      'titleEn': 'System Update Notification',
      'content':
          'សូមជម្រាបជូនមន្ត្រីទាំងអស់ថា ប្រព័ន្ធនឹងត្រូវបានធ្វើបច្ចុប្បន្នភាពនៅថ្ងៃទី ៣០ តុលា ២០២៦ ចាប់ពីម៉ោង ២២:០០ ដល់ម៉ោង ០២:០០ ព្រឹកថ្ងៃបន្ទាប់។\n\nក្នុងអំឡុងពេលនេះ កម្មវិធីមួយចំនួនអាចមិនអាចចូលប្រើបានជាបណ្តោះអាសន្ន។ សូមរក្សាទុកការងារ មុនពេលចាប់ផ្តើមធ្វើបច្ចុប្បន្នភាព។ សូមអរគុណចំពោះកិច្ចសហការ។',
      'date': '2026-10-27T09:30:00',
      'displayDateKh': '២៧ តុលា ២០២៦ · ម៉ោង ០៩:៣០',
      'displayDateEn': '27 Oct 2026 · 09:30 AM',
      'department': 'អគ្គនាយកដ្ឋានរដ្ឋបាល',
      'isDefaultUnread': true,
      'category': 'GENERAL',
      'status': 'PUBLISHED',
    },
    {
      'id': 'concept_ann_2',
      'title': 'សេចក្តីណែនាំស្តីពីការស្នើសុំចេញលិខិតស្គាល់',
      'titleEn': 'Guidelines on ID Letter Requests',
      'content':
          'សេចក្តីណែនាំស្តីពីនីតិវិធី និងបែបបទនៃការស្នើសុំចេញលិខិតស្គាល់អត្តសញ្ញាណតាមប្រព័ន្ធឌីជីថល សម្រាប់អង្គភាពចំណុះក្រសួងមហាផ្ទៃ។',
      'date': '2026-10-26T15:10:00',
      'displayDateKh': '២៦ តុលា ២០២៦ · ម៉ោង ១៥:១០',
      'displayDateEn': '26 Oct 2026 · 03:10 PM',
      'isDefaultUnread': true,
      'category': 'POLICY',
      'status': 'PUBLISHED',
    },
    {
      'id': 'concept_ann_3',
      'title': 'កាលវិភាគថែទាំប្រព័ន្ធប្រចាំសប្តាហ៍',
      'titleEn': 'Weekly System Maintenance Schedule',
      'content':
          'កាលវិភាគសម្រាប់ការថែទាំប្រព័ន្ធបច្ចេកវិទ្យាព័ត៌មានប្រចាំសប្តាហ៍ នឹងប្រព្រឹត្តទៅនៅរៀងរាល់ចុងសប្តាហ៍ ដើម្បីធានានិរន្តរភាព និងល្បឿននៃការប្រើប្រាស់។',
      'date': '2026-10-24T10:00:00',
      'displayDateKh': '២៤ តុលា ២០២៦ · ម៉ោង ១០:០០',
      'displayDateEn': '24 Oct 2026 · 10:00 AM',
      'isDefaultUnread': false,
      'category': 'GENERAL',
      'status': 'PUBLISHED',
    },
    {
      'id': 'concept_ann_4',
      'title': 'ការអនុញ្ញាតឱ្យចូលប្រើកម្មវិធីថ្មី',
      'titleEn': 'Permission to Access New Applications',
      'content':
          'ការអនុញ្ញាតឱ្យមន្ត្រីរាជការនៃអគ្គនាយកដ្ឋានទាំងអស់ចូលប្រើប្រាស់កម្មវិធី និងប្រព័ន្ធការងារថ្មីៗរបស់ក្រសួងមហាផ្ទៃជាផ្លូវការ។',
      'date': '2026-10-20T08:45:00',
      'displayDateKh': '២០ តុលា ២០២៦ · ម៉ោង ០៨:៤៥',
      'displayDateEn': '20 Oct 2026 · 08:45 AM',
      'isDefaultUnread': false,
      'category': 'EVENT',
      'status': 'PUBLISHED',
    },
    {
      'id': 'concept_ann_5',
      'title': 'សេចក្តីប្រកាសស្តីពីម៉ោងធ្វើការ',
      'titleEn': 'Announcement on Working Hours',
      'content':
          'សេចក្តីប្រកាសស្តីពីការអនុវត្តម៉ោងបំពេញការងារ និងការគោរពវិន័យការងារឱ្យស្របតាមបទបញ្ជាផ្ទៃក្នុងរបស់ក្រសួងមហាផ្ទៃ។',
      'date': '2026-10-18T14:20:00',
      'displayDateKh': '១៨ តុលា ២០២៦ · ម៉ោង ១៤:២០',
      'displayDateEn': '18 Oct 2026 · 02:20 PM',
      'isDefaultUnread': false,
      'category': 'POLICY',
      'status': 'PUBLISHED',
    },
  ];

  List<Map<String, dynamic>> get effectiveAnnouncements {
    if (announcements.isNotEmpty) {
      return announcements;
    }
    return conceptFallbackAnnouncements;
  }

  bool isAnnouncementUnread(Map<String, dynamic> item) {
    final String id =
        (item['id'] ?? item['uuid'] ?? item['title'] ?? item['createdAt'] ?? '')
            .toString();
    if (id.isNotEmpty && readAnnouncementIds.contains(id)) {
      return false;
    }
    if (item.containsKey('isDefaultUnread')) {
      return item['isDefaultUnread'] == true;
    }
    if (item['isRead'] == true || item['read'] == true) {
      return false;
    }
    if (item['isRead'] == false || item['read'] == false) {
      return true;
    }
    return true;
  }

  int get unreadCount {
    return effectiveAnnouncements.where((a) => isAnnouncementUnread(a)).length;
  }

  List<Map<String, dynamic>> get conceptFilteredAnnouncements {
    if (selectedFilterTab.value == 'unread') {
      return effectiveAnnouncements
          .where((a) => isAnnouncementUnread(a))
          .toList();
    }
    return effectiveAnnouncements;
  }

  void markAsRead(Map<String, dynamic> item) {
    final String id =
        (item['id'] ?? item['uuid'] ?? item['title'] ?? item['createdAt'] ?? '')
            .toString();
    item['isRead'] = true;
    item['isDefaultUnread'] = false;

    void updateState() {
      if (id.isNotEmpty && !readAnnouncementIds.contains(id)) {
        readAnnouncementIds.add(id);
        _box.write('read_announcements', readAnnouncementIds.toList());
      }
      readAnnouncementIds.refresh();
      announcements.refresh();
      if (Get.isRegistered<NavController>()) {
        Get.find<NavController>().updateUnreadCount(effectiveAnnouncements);
      }
    }

    if (WidgetsBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback((_) => updateState());
    } else {
      updateState();
    }
  }

  // Search and Filter States
  final searchQuery = "".obs;
  final selectedCategory = 'all_categories'.tr.obs;
  final selectedStatus = 'all_statuses'.tr.obs;
  final Rxn<DateTime> startDate = Rxn<DateTime>();
  final Rxn<DateTime> endDate = Rxn<DateTime>();

  // Pagination State
  final currentPage = 1.obs;
  final int itemsPerPage = 10;

  @override
  void onInit() {
    super.onInit();
    final storedRead = _box.read<List>('read_announcements');
    if (storedRead != null) {
      readAnnouncementIds.addAll(storedRead.map((e) => e.toString()));
    }
    ever(searchQuery, (_) => currentPage.value = 1);
    ever(selectedCategory, (_) => currentPage.value = 1);
    ever(selectedStatus, (_) => currentPage.value = 1);
    ever(startDate, (_) => currentPage.value = 1);
    ever(endDate, (_) => currentPage.value = 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.arguments == 'admin') {
        fetchAdminAnnouncements();
      } else {
        fetchAnnouncements();
      }
      if (Get.isRegistered<NavController>()) {
        Get.find<NavController>().updateUnreadCount(effectiveAnnouncements);
      }
    });
  }

  Future<void> fetchAnnouncements() async {
    try {
      isLoading.value = true;
      errorMessage.value = "";

      final response = await _authService.fetchAnnouncements();
      if (response != null) {
        List<Map<String, dynamic>> rawList = [];

        if (response is List) {
          rawList = response.map<Map<String, dynamic>>((item) {
            return Map<String, dynamic>.from(item as Map);
          }).toList();
        } else if (response is Map) {
          final data = response['value'] ?? response['data'];
          if (data is List) {
            rawList = data.map<Map<String, dynamic>>((item) {
              return Map<String, dynamic>.from(item as Map);
            }).toList();
          }
        }

        // 🟢 FIX ADDED: Chronologically sort announcements descending (Newest on Top)
        rawList.sort((a, b) {
          final String timeA = (a['createdAt'] ?? a['time'] ?? a['date'] ?? '')
              .toString();
          final String timeB = (b['createdAt'] ?? b['time'] ?? b['date'] ?? '')
              .toString();

          DateTime dateTimeA =
              DateTime.tryParse(timeA) ??
              DateTime.fromMillisecondsSinceEpoch(0);
          DateTime dateTimeB =
              DateTime.tryParse(timeB) ??
              DateTime.fromMillisecondsSinceEpoch(0);

          return dateTimeB.compareTo(
            dateTimeA,
          ); // Newest timestamp moves up to index 0
        });

        announcements.assignAll(rawList);

        if (Get.isRegistered<NavController>()) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (Get.isRegistered<NavController>()) {
              Get.find<NavController>().updateUnreadCount(
                effectiveAnnouncements,
              );
            }
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching announcements: $e");
      if (e is DioException) {
        if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.sendTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          errorMessage.value = 'timeout_error'.tr;
        } else if (e.type == DioExceptionType.connectionError) {
          errorMessage.value = 'no_internet_error'.tr;
        } else {
          final errorData = e.response?.data;
          String msg = 'cannot_fetch_announcements'.tr;
          if (errorData is Map) {
            msg =
                errorData['detail']?.toString() ??
                errorData['message']?.toString() ??
                msg;
          } else if (errorData is String) {
            msg = errorData;
          }
          errorMessage.value = msg;
        }
      } else {
        errorMessage.value = 'cannot_fetch_announcements'.tr;
      }
    } finally {
      isLoading.value = false;
    }
  }

  /// Fetch all announcements via the admin endpoint (PUBLISHED + DRAFT + SCHEDULED)
  Future<void> fetchAdminAnnouncements() async {
    try {
      isLoading.value = true;
      errorMessage.value = "";

      final response = await _authService.fetchAdminAnnouncements();
      List rawList = [];
      if (response != null) {
        if (response is List) {
          rawList = response;
        } else if (response is Map) {
          rawList = response['value'] ?? response['data'] ?? [];
        }
      }

      List<Map<String, dynamic>> parsedList = rawList.map<Map<String, dynamic>>(
        (item) {
          return Map<String, dynamic>.from(item as Map);
        },
      ).toList();

      // 🟢 ALSO SORT HERE: Keep admin announcements list sorted descending as well
      parsedList.sort((a, b) {
        final String timeA = (a['createdAt'] ?? a['time'] ?? a['date'] ?? '')
            .toString();
        final String timeB = (b['createdAt'] ?? b['time'] ?? b['date'] ?? '')
            .toString();

        DateTime dateTimeA =
            DateTime.tryParse(timeA) ?? DateTime.fromMillisecondsSinceEpoch(0);
        DateTime dateTimeB =
            DateTime.tryParse(timeB) ?? DateTime.fromMillisecondsSinceEpoch(0);

        return dateTimeB.compareTo(dateTimeA);
      });

      announcements.assignAll(parsedList);

      if (Get.isRegistered<NavController>()) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (Get.isRegistered<NavController>()) {
            Get.find<NavController>().updateUnreadCount(effectiveAnnouncements);
          }
        });
      }
    } catch (e) {
      debugPrint("Error fetching admin announcements: $e");
      errorMessage.value = e.toString();
    } finally {
      isLoading.value = false;
    }
  }

  void clearFilters() {
    searchQuery.value = "";
    selectedCategory.value = 'all_categories'.tr;
    selectedStatus.value = 'all_statuses'.tr;
    startDate.value = null;
    endDate.value = null;
    currentPage.value = 1;
  }

  /// Create a new announcement via API
  Future<bool> createAnnouncement({
    required String title,
    required String content,
    required String status, // PUBLISHED / DRAFT / SCHEDULED
    required String priority, // IMPORTANT / NORMAL / LOW
    String? publishStartAt,
    String? publishEndAt,
    List<Map<String, String>>? targets,
  }) async {
    try {
      isSubmitting.value = true;
      final data = {
        'title': title,
        'content': content,
        'status': status,
        'priority': priority,
        if (publishStartAt != null) 'publishStartAt': publishStartAt,
        if (publishEndAt != null) 'publishEndAt': publishEndAt,
        'targets':
            targets ??
            [
              {'targetType': 'ALL', 'targetValue': 'ALL'},
            ],
      };
      await _authService.createAdminAnnouncement(data);
      await fetchAdminAnnouncements();
      _refreshDashboards();
      return true;
    } catch (e) {
      debugPrint("Error creating announcement: $e");
      _showError(e, 'cannot_create_announcement'.tr);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Update an existing announcement via API
  Future<bool> updateAnnouncement({
    required String id,
    required String title,
    required String content,
    required String status,
    required String priority,
    String? publishStartAt,
    String? publishEndAt,
    List<Map<String, String>>? targets,
  }) async {
    try {
      isSubmitting.value = true;
      final data = {
        'title': title,
        'content': content,
        'status': status,
        'priority': priority,
        if (publishStartAt != null) 'publishStartAt': publishStartAt,
        if (publishEndAt != null) 'publishEndAt': publishEndAt,
        'targets':
            targets ??
            [
              {'targetType': 'ALL', 'targetValue': 'ALL'},
            ],
      };
      await _authService.updateAdminAnnouncement(id, data);
      await fetchAdminAnnouncements();
      _refreshDashboards();
      return true;
    } catch (e) {
      debugPrint("Error updating announcement: $e");
      _showError(e, 'cannot_update_announcement'.tr);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  /// Delete an announcement via API
  Future<bool> deleteAnnouncement(String id) async {
    try {
      isSubmitting.value = true;
      await _authService.deleteAdminAnnouncement(id);
      announcements.removeWhere((a) => a['id']?.toString() == id);
      if (Get.isRegistered<NavController>()) {
        Get.find<NavController>().updateUnreadCount(announcements);
      }
      _refreshDashboards();
      return true;
    } catch (e) {
      debugPrint("Error deleting announcement: $e");
      _showError(e, 'cannot_delete_announcement'.tr);
      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  void _refreshDashboards() {
    if (Get.isRegistered<AdminController>()) {
      Get.find<AdminController>().fetchDashboardData();
    }
  }

  void _showError(Object e, String fallback) {
    String msg = fallback;
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        msg = 'timeout_error'.tr;
      } else if (e.type == DioExceptionType.connectionError) {
        msg = 'no_internet_error'.tr;
      } else {
        final d = e.response?.data;
        if (d is Map) {
          msg = d['detail']?.toString() ?? d['message']?.toString() ?? fallback;
        } else if (d is String) {
          msg = d;
        }
      }
    }
    errorMessage.value = msg;
  }

  // Reactive filtered announcements
  List<Map<String, dynamic>> get filteredAnnouncements {
    return announcements.where((ann) {
      // 1. Search Query Filter
      final title = (ann['title'] ?? '').toString().toLowerCase();
      final titleEn = (ann['titleEn'] ?? '').toString().toLowerCase();
      final content = (ann['content'] ?? ann['body'] ?? '')
          .toString()
          .toLowerCase();
      final query = searchQuery.value.toLowerCase().trim();

      bool matchesSearch = true;
      if (query.isNotEmpty) {
        matchesSearch =
            title.contains(query) ||
            titleEn.contains(query) ||
            content.contains(query);
      }

      // 2. Category / Priority Filter
      final cat = (ann['category'] ?? ann['priority'] ?? '')
          .toString()
          .toUpperCase();
      final selectedCat = selectedCategory.value;
      bool matchesCategory = true;
      if (selectedCat != 'ប្រភេទទាំងអស់') {
        if (selectedCat == 'បន្ទាន់') {
          matchesCategory =
              (cat == 'URGENT' || cat == 'IMPORTANT' || cat == 'បន្ទាន់');
        } else if (selectedCat == 'គោលការណ៍') {
          matchesCategory =
              (cat == 'POLICY' || cat == 'NORMAL' || cat == 'គោលការណ៍');
        } else if (selectedCat == 'ព្រឹត្តិការណ៍') {
          matchesCategory =
              (cat == 'EVENT' || cat == 'LOW' || cat == 'ព្រឹត្តិការណ៍');
        } else if (selectedCat == 'ទូទៅ') {
          matchesCategory =
              (cat == 'GENERAL' ||
              cat == 'OFFICIAL' ||
              cat == 'ទូទៅ' ||
              cat.isEmpty);
        } else {
          matchesCategory = false;
        }
      }

      // 3. Status Filter
      final status = (ann['status'] ?? '').toString().toUpperCase();
      final selectedStat = selectedStatus.value;
      bool matchesStatus = true;
      if (selectedStat != 'ស្ថានភាពទាំងអស់' && selectedStat != 'ទាំងអស់') {
        if (selectedStat == 'ផ្សព្វផ្សាយ' || selectedStat == 'ផ្សាយ') {
          matchesStatus =
              (status == 'PUBLISHED' ||
              status == 'ACTIVE' ||
              status == 'ផ្សព្វផ្សាយ' ||
              status == 'ផ្សាយ' ||
              status.isEmpty);
        } else if (selectedStat == 'ព្រាង') {
          matchesStatus =
              (status == 'DRAFT' || status == 'INACTIVE' || status == 'ព្រាង');
        } else if (selectedStat == 'កំណត់ពេលវេលា') {
          matchesStatus = (status == 'SCHEDULED' || status == 'កំណត់ពេលវេលា');
        } else {
          matchesStatus = false;
        }
      }

      // 4. Date Range Filter
      bool matchesDate = true;
      if (startDate.value != null || endDate.value != null) {
        final dateStr = ann['createdAt'] ?? ann['time'] ?? ann['date'] ?? '';
        final annDate = DateTime.tryParse(dateStr.toString());
        if (annDate != null) {
          if (startDate.value != null) {
            final start = DateTime(
              startDate.value!.year,
              startDate.value!.month,
              startDate.value!.day,
            );
            final check = DateTime(annDate.year, annDate.month, annDate.day);
            if (check.isBefore(start)) {
              matchesDate = false;
            }
          }
          if (endDate.value != null) {
            final end = DateTime(
              endDate.value!.year,
              endDate.value!.month,
              endDate.value!.day,
            );
            final check = DateTime(annDate.year, annDate.month, annDate.day);
            if (check.isAfter(end)) {
              matchesDate = false;
            }
          }
        } else {
          matchesDate = false;
        }
      }

      return matchesSearch && matchesCategory && matchesStatus && matchesDate;
    }).toList();
  }

  int get totalPages {
    final len = filteredAnnouncements.length;
    if (len == 0) return 1;
    return (len / itemsPerPage).ceil();
  }

  List<Map<String, dynamic>> get paginatedAnnouncements {
    final list = filteredAnnouncements;
    final start = (currentPage.value - 1) * itemsPerPage;
    if (start >= list.length) return [];
    final end = start + itemsPerPage;
    return list.sublist(start, end > list.length ? list.length : end);
  }
}
