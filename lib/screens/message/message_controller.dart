part of 'message_view.dart';

class MessageViewController extends GetxController {
  final AuthService _authService = AuthService();

  final announcements = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final errorMessage = "".obs;

  @override
  void onInit() {
    super.onInit();
    fetchAnnouncements();
  }

  Future<void> fetchAnnouncements() async {
    try {
      isLoading.value = true;
      errorMessage.value = "";

      final response = await _authService.fetchAnnouncements();
      if (response != null) {
        if (response is List) {
          announcements.assignAll(
            response.map<Map<String, dynamic>>((item) {
              return Map<String, dynamic>.from(item as Map);
            }).toList(),
          );
        } else if (response is Map) {
          final data = response['value'] ?? response['data'];
          if (data is List) {
            announcements.assignAll(
              data.map<Map<String, dynamic>>((item) {
                return Map<String, dynamic>.from(item as Map);
              }).toList(),
            );
          }
        }
        if (Get.isRegistered<NavController>()) {
          Get.find<NavController>().updateUnreadCount(announcements);
        }
      }
    } catch (e) {
      debugPrint("Error fetching announcements: $e");
      if (e is DioException) {
        final errorData = e.response?.data;
        String msg = "មិនអាចទាញយកសេចក្តីប្រកាសបានទេ";
        if (errorData is Map) {
          msg =
              errorData['detail']?.toString() ??
              errorData['message']?.toString() ??
              msg;
        } else if (errorData is String) {
          msg = errorData;
        }
        errorMessage.value = msg;
      } else {
        errorMessage.value = e.toString();
      }
    } finally {
      isLoading.value = false;
    }
  }
}
