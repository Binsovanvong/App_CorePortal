part of 'request_view.dart';

class RequestViewController extends GetxController {
  RequestModel? editingRequest;

  @override
  void onInit() {
    super.onInit();
    if (Get.arguments is RequestModel) {
      startEditing(Get.arguments as RequestModel);
    } else {
      clearForm();
    }
  }

  void startEditing(RequestModel request) {
    editingRequest = request;
    String engName = request.name;
    String khmerName = "";
    if (engName == "Kao Satya") {
      khmerName = "កៅ សត្យា";
    } else if (engName == "Sorn Sophy") {
      khmerName = "សន សូភី";
    } else if (engName == "Linda Smith") {
      khmerName = "លីនដា ស្មីត";
    } else {
      khmerName = engName;
    }

    firstName.text = khmerName;
    lastName.text = engName;
    gender.value = request.gender;
    idNumber.text = request.idNumber;
    nationality.value = request.nationality;
    province.value = request.address;
  }

  void clearForm() {
    editingRequest = null;
    firstName.clear();
    lastName.clear();
    phone.clear();
    email.clear();
    dobController.clear();
    idNumber.clear();
    district.clear();
    commune.clear();
    village.clear();
    gender.value = 'ប្រុស';
    nationality.value = 'Cambodian';
    recordSourceType.value = 'ជនជាតិខ្មែរ';
    docType.value = 'អត្តសញ្ញាណប័ណ្ណ';
    province.value = 'ភ្នំពេញ';
    accommodationType.value = 'សណ្ឋាគារ';
    stayPurpose.value = 'ស្នាក់នៅបែបអ្នកការទូត';
    stayUntil.value = 'កំពុងស្នាក់នៅ';
  }

  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final dobController = TextEditingController();

  // New text controllers
  final idNumber = TextEditingController();
  final district = TextEditingController();
  final commune = TextEditingController();
  final village = TextEditingController();

  final gender = 'ប្រុស'.obs;
  final nationality = 'Cambodian'.obs;
  final serviceType = ''.obs;

  // New reactive variables for dropdown selection
  final recordSourceType = 'ជនជាតិខ្មែរ'.obs;
  final docType = 'អត្តសញ្ញាណប័ណ្ណ'.obs;
  final province = 'ភ្នំពេញ'.obs;
  final accommodationType = 'សណ្ឋាគារ'.obs;
  final stayPurpose = 'ស្នាក់នៅបែបអ្នកការទូត'.obs;
  final stayUntil = 'កំពុងស្នាក់នៅ'.obs;

  Future<void> selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(), // today selected by default
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      dobController.text = DateFormat('dd/MM/yyyy').format(pickedDate);
    }
  }

  void saveRequest() {
    if (firstName.text.trim().isEmpty && lastName.text.trim().isEmpty) {
      CustomSnackbar.showWarning(
        message: 'សូមបញ្ចូលឈ្មោះខ្មែរ ឬឈ្មោះឡាតាំង',
      );
      return;
    }

    final ListViewController listController =
        Get.isRegistered<ListViewController>()
        ? Get.find<ListViewController>()
        : Get.put(ListViewController());

    if (editingRequest != null) {
      final index = listController.requests.indexOf(editingRequest!);
      if (index != -1) {
        final updatedRequest = RequestModel(
          name: lastName.text.trim().isNotEmpty
              ? lastName.text.trim()
              : firstName.text.trim(),
          gender: gender.value,
          idNumber: idNumber.text.trim().isNotEmpty
              ? idNumber.text.trim()
              : editingRequest!.idNumber,
          nationality: nationality.value,
          address: province.value,
          status: editingRequest!.status,
        );
        listController.requests[index] = updatedRequest;
      }
    } else {
      final newRequest = RequestModel(
        name: lastName.text.trim().isNotEmpty
            ? lastName.text.trim()
            : firstName.text.trim(),
        gender: gender.value,
        idNumber: idNumber.text.trim().isNotEmpty
            ? idNumber.text.trim()
            : "5734524753",
        nationality: nationality.value,
        address: province.value,
        status:
            "Pending", // defaults to pending (renders as "បានអនុម័ត" in active view)
      );
      listController.requests.insert(0, newRequest);
      listController.total.value++;
      listController.users.value++;
    }

    CustomSnackbar.showSuccess(
      message: 'ព័ត៌មានត្រូវបានរក្សាទុកដោយជោគជ័យ',
    );

    // Navigation logic
    if (Get.currentRoute == AppRoutes.request) {
      Get.back();
    } else if (Get.isRegistered<MainController>()) {
      Get.find<MainController>().currentIndex.value = 2; // Switch to list tab
    } else {
      Get.back();
    }
  }
}
