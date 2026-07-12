part of 'homepage_view.dart';

class HomePageController extends GetxController {

  RxInt total = 9520.obs;

  RxInt pending = 520.obs;

  RxInt approved = 9000.obs;

  RxInt expired = 0.obs;
  RxDouble progress = 1.0.obs;

  RxList<FlSpot> chartData = <FlSpot>[
    FlSpot(0, 10),
    FlSpot(1, 20),
    FlSpot(2, 15),
    FlSpot(3, 35),
    FlSpot(4, 30),
    FlSpot(5, 50),
  ].obs;
}