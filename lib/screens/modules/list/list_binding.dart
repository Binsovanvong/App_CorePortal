part of 'list_view.dart';

class ListViewBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ListViewController>(
      () => ListViewController(),
    );
  }
}