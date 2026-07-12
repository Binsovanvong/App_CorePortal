part of 'list_view.dart';

class ListViewController extends GetxController {
  final requests = DummyData.requests.obs;

  final total = 9520.obs;

  final users = 12.obs;

  final searchQuery = ''.obs;
  final selectedFilter = 'ទាំងអស់'.obs;

  List<RequestModel> get filteredRequests {
    List<RequestModel> result = List.from(requests);

    // Filter by tab
    if (selectedFilter.value == 'ភ្នំពេញ') {
      result = result.where((r) => r.address == 'ភ្នំពេញ').toList();
    } else if (selectedFilter.value == 'បានអនុម័ត') {
      result = result.where((r) => r.status == 'Approved').toList();
    }

    // Filter by search query
    if (searchQuery.value.trim().isNotEmpty) {
      final query = searchQuery.value.trim().toLowerCase();
      result = result.where((r) {
        return r.name.toLowerCase().contains(query) ||
            r.idNumber.toLowerCase().contains(query) ||
            r.nationality.toLowerCase().contains(query);
      }).toList();
    }

    return result;
  }

  void deleteRequest(RequestModel request) {
    requests.remove(request);
    if (total.value > 0) total.value--;
    if (users.value > 0) users.value--;
    Get.snackbar(
      'ជោគជ័យ',
      'បានលុបកំណត់ត្រាដោយជោគជ័យ',
      backgroundColor: const Color(0xFFDCFCE7),
      colorText: const Color(0xFF16803D),
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void approveRequest(RequestModel request) {
    final index = requests.indexOf(request);
    if (index != -1) {
      final updated = RequestModel(
        name: request.name,
        gender: request.gender,
        idNumber: request.idNumber,
        nationality: request.nationality,
        address: request.address,
        status: "Pending", // displays as "បានអនុម័ត"
      );
      requests[index] = updated;
      Get.snackbar(
        'ជោគជ័យ',
        'បានអនុម័តសំណើដោយជោគជ័យ',
        backgroundColor: const Color(0xFFDCFCE7),
        colorText: const Color(0xFF16803D),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  void checkInRequest(RequestModel request) {
    final index = requests.indexOf(request);
    if (index != -1) {
      final updated = RequestModel(
        name: request.name,
        gender: request.gender,
        idNumber: request.idNumber,
        nationality: request.nationality,
        address: request.address,
        status: "Approved", // displays as "កំពុងស្នាក់នៅ"
      );
      requests[index] = updated;
      Get.snackbar(
        'ជោគជ័យ',
        'បានកត់ត្រាការចូលស្នាក់នៅដោយជោគជ័យ',
        backgroundColor: const Color(0xFFDCFCE7),
        colorText: const Color(0xFF16803D),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
