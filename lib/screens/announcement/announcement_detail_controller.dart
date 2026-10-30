import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dio/dio.dart';
import 'package:core_portal/core/api/services/auth_service.dart';
import 'package:core_portal/controllers/nav_controller.dart';
import 'package:core_portal/screens/announcement/announcement_controller.dart';

class AnnouncementDetailController extends GetxController {
  final AuthService _authService = AuthService();

  final announcement = RxMap<String, dynamic>();
  final isLoading = false.obs;
  final isRefreshing = false.obs;
  final errorMessage = ''.obs;

  String announcementId = '';
  bool isAdmin = false;

  void initData(Map<String, dynamic>? initialData, {String? id, bool? admin}) {
    if (admin != null) {
      isAdmin = admin;
    } else if (Get.isRegistered<NavController>()) {
      isAdmin = Get.find<NavController>().isAdmin.value;
    }

    if (initialData != null) {
      announcement.assignAll(initialData);
    } else {
      final args = Get.arguments;
      if (args is Map<String, dynamic>) {
        announcement.assignAll(args);
      } else if (args is Map) {
        announcement.assignAll(Map<String, dynamic>.from(args));
      }
    }

    announcementId =
        (id ??
                announcement['id'] ??
                announcement['uuid'] ??
                announcement['_id'] ??
                '')
            .toString()
            .trim();

    // If initial data is empty but we have an ID, look it up in AnnouncementController
    if (announcement.isEmpty && announcementId.isNotEmpty) {
      if (Get.isRegistered<AnnouncementController>()) {
        final annCtrl = Get.find<AnnouncementController>();
        final match = annCtrl.effectiveAnnouncements.firstWhereOrNull(
          (a) =>
              (a['id'] ?? a['uuid'] ?? a['_id'] ?? '').toString() ==
              announcementId,
        );
        if (match != null) {
          announcement.assignAll(match);
        }
      }
    }

    // Defer state updates and API fetching until after widget build phase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Mark as read in AnnouncementController if registered
      if (announcement.isNotEmpty &&
          Get.isRegistered<AnnouncementController>()) {
        Get.find<AnnouncementController>().markAsRead(announcement);
      }

      // If ID is valid and not a local-only mock prefix, fetch full details from API
      if (announcementId.isNotEmpty && !announcementId.startsWith('concept_')) {
        fetchDetailFromApi();
      }
    });
  }

  /// Fetch announcement details directly from API
  Future<void> fetchDetailFromApi({bool isRefresh = false}) async {
    if (announcementId.isEmpty) return;

    try {
      if (isRefresh) {
        isRefreshing.value = true;
      } else if (announcement.isEmpty) {
        isLoading.value = true;
      }
      errorMessage.value = '';

      final response = await _authService.fetchAnnouncementDetail(
        announcementId,
        isAdmin: isAdmin,
      );

      if (response != null) {
        Map<String, dynamic> detailMap = {};
        if (response is Map) {
          if (response['data'] is Map) {
            detailMap = Map<String, dynamic>.from(response['data'] as Map);
          } else if (response['value'] is Map) {
            detailMap = Map<String, dynamic>.from(response['value'] as Map);
          } else {
            detailMap = Map<String, dynamic>.from(response);
          }
        }

        if (detailMap.isNotEmpty) {
          // Merge API data over existing data
          announcement.addAll(detailMap);
          announcement.refresh();

          // Also synchronize with AnnouncementController list if present
          if (Get.isRegistered<AnnouncementController>()) {
            final annCtrl = Get.find<AnnouncementController>();
            final idx = annCtrl.announcements.indexWhere(
              (a) =>
                  (a['id'] ?? a['uuid'] ?? a['_id'] ?? '').toString() ==
                  announcementId,
            );
            if (idx != -1) {
              annCtrl.announcements[idx].addAll(detailMap);
              annCtrl.announcements.refresh();
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching announcement detail from API: $e");
      if (e is DioException) {
        final err = e.response?.data;
        if (err is Map && err['message'] != null) {
          errorMessage.value = err['message'].toString();
        } else {
          errorMessage.value = 'cannot_fetch_announcements'.tr;
        }
      } else {
        errorMessage.value = e.toString();
      }
    } finally {
      isLoading.value = false;
      isRefreshing.value = false;
    }
  }
}
