part of 'main_view.dart';

class MainController extends GetxController {

  RxInt currentIndex = 0.obs;

  @override
  void onInit() {

    Get.put(HomePageController());
    Get.put(RequestViewController());
    Get.put(ListViewController());

    super.onInit();
  }

  final pages = [
    HomePageView(),
    RequestView(),
    RequestListView(),
  ];

  void changeTab(int index) {
    currentIndex.value = index;
  }
}