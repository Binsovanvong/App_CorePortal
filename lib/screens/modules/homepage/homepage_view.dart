import 'package:core_portal/widgets/dashboard_card.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:core_portal/routes/page_route.dart';
import 'package:core_portal/pages/Main/main_view.dart';
import 'package:core_portal/screens/modules/request/request_view.dart';

part 'homepage_binding.dart';
part 'homepage_controller.dart';

class HomePageView extends GetView<HomePageController> {
  const HomePageView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xff7A5B00)),
          onPressed: () {
            Get.back();
          },
        ),

        title: const Text(
          "ប្រព័ន្ធគ្រប់គ្រងការស្នាក់នៅ",
          style: TextStyle(
            color: Color(0xff7A5B00),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              /// Welcome Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xffF6EBC2),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Text(
                        "គ្រប់គ្រងក្នុងប្រទេសកម្ពុជា",
                        style: TextStyle(
                          color: Color(0xffA88400),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      "ប្រព័ន្ធគ្រប់គ្រង\nការស្នាក់នៅ",
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "បញ្ចូលព័ត៌មានស្នាក់នៅសម្រាប់ជនបរទេស និង\nជនជាតិខ្មែរគ្រប់ខេត្តក្រុង ដើម្បីធានានូវសុវត្ថិភាព\n និងស្ថេរភាពសង្គម។",
                      style: TextStyle(fontSize: 16, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xffA88400),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        if (Get.isRegistered<RequestViewController>()) {
                          Get.find<RequestViewController>().clearForm();
                        }
                        if (Get.isRegistered<MainController>()) {
                          Get.find<MainController>().currentIndex.value = 1;
                        } else {
                          Get.toNamed(AppRoutes.request);
                        }
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text(
                        "កត់ត្រាថ្មី",
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[500],
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        if (Get.isRegistered<MainController>()) {
                          Get.find<MainController>().currentIndex.value = 2;
                        } else {
                          Get.toNamed(AppRoutes.requestList);
                        }
                      },
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text(
                        "មើលបញ្ជី",
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Obx(
                () => DashboardCard(
                  title: "ចំនួនសរុប",
                  value: controller.total.value.toString(),
                  icon: Icons.people,
                ),
              ),

              const SizedBox(height: 15),

              Obx(
                () => DashboardCard(
                  title: "កំពុងរង់ចាំ",
                  value: controller.pending.value.toString(),
                  icon: Icons.hourglass_bottom,
                ),
              ),

              const SizedBox(height: 15),

              Obx(
                () => DashboardCard(
                  title: "បានអនុម័ត",
                  value: controller.approved.value.toString(),
                  icon: Icons.check_circle,
                ),
              ),
              const SizedBox(height: 15),
              summaryCard(),
              const SizedBox(height: 16),
              chartCard(),
              const SizedBox(height: 16),
              progressCard(),
              const SizedBox(height: 16),
              recentCard(),
            ],
          ),
        ),
      ),
    );
  }

  Widget summaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "ស្ថិតិការស្នាក់នៅសរុប",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Icon(Icons.assignment, color: Color(0xffB58A00)),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _item("ចំនួនសរុប", controller.total.value.toString()),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _item("បានអនុម័ត", controller.approved.value.toString()),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _item("ផុតកំណត់", controller.expired.value.toString()),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _item("រង់ចាំ", controller.pending.value.toString()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _item(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffF6F6F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xff0B2C69),
            ),
          ),
        ],
      ),
    );
  }

  Widget chartCard() {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "ស្ថិតិប្រចាំខែ",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 180,
          child: LineChart(
            LineChartData(
              borderData: FlBorderData(show: false),
              gridData: FlGridData(show: false),
              lineBarsData: [
                LineChartBarData(
                  isCurved: true,
                  color: const Color(0xffB58A00),
                  spots: [
                    FlSpot(0, 10),
                    FlSpot(1, 30),
                    FlSpot(2, 20),
                    FlSpot(3, 40),
                    FlSpot(4, 35),
                    FlSpot(5, 50),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
Widget progressCard() {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      children: [
        const Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "ស្ថានភាពបច្ចុប្បន្ន",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 20),
        CircularPercentIndicator(
          radius: 70,
          lineWidth: 12,
          percent: 1,
          center: const Text(
            "1",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          progressColor: const Color(0xffB58A00),
        ),
      ],
    ),
  );
}

  Widget recentCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          ListTile(
            title: const Text("ព័ត៌មានថ្មីៗ"),
            trailing: TextButton(
              onPressed: () {},
              child: const Text("មើលទាំងអស់"),
            ),
          ),

          const Divider(height: 1),

          DataTable(
            columns: const [
              DataColumn(label: Text("ឈ្មោះ")),
              DataColumn(label: Text("ភេទ")),
              DataColumn(label: Text("កាលបរិច្ឆេទ")),
            ],
            rows: const [
              DataRow(
                cells: [
                  DataCell(Text("សុខ សាន")),
                  DataCell(Text("ប្រុស")),
                  DataCell(Text("12/12/2026")),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
