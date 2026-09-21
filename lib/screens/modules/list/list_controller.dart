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
    CustomSnackbar.showSuccess(message: 'បានលុបកំណត់ត្រាដោយជោគជ័យ');
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
      CustomSnackbar.showSuccess(message: 'បានអនុម័តសំណើដោយជោគជ័យ');
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
      CustomSnackbar.showSuccess(message: 'បានកត់ត្រាការចូលស្នាក់នៅដោយជោគជ័យ');
    }
  }
}
