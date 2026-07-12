import 'package:core_portal/screens/modules/homepage/homepage_view.dart';
import 'package:core_portal/screens/modules/list/list_view.dart';
import 'package:core_portal/screens/modules/request/request_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

part 'main_binding.dart';
part 'main_controller.dart';

class MainView extends GetView<MainController> {
  const MainView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
          body: controller.pages[controller.currentIndex.value],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: controller.currentIndex.value,
            onTap: (i) => controller.currentIndex.value = i,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                label: "ទំព័រដើម",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.add_circle_outline),
                label: "កំណត់",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.list),
                label: "បញ្ជី",
              ),
              
            ],
          ),
        ));
  }
}