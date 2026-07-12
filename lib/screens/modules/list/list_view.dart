import 'package:core_portal/data/dummy_data.dart';
import 'package:core_portal/models/request_model.dart';
import 'package:core_portal/routes/page_route.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:core_portal/pages/Main/main_view.dart';
import 'package:core_portal/screens/modules/request/request_view.dart';
import '../../../widgets/request_card.dart';

part 'list_binding.dart';
part 'list_controller.dart';

class RequestListView extends GetView<ListViewController> {
  const RequestListView({super.key});

  String toKhmerDigits(String numberStr) {
    const english = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const khmer = ['០', '១', '២', '៣', '៤', '៥', '៦', '៧', '៨', '៩'];
    String result = numberStr;
    for (int i = 0; i < english.length; i++) {
      result = result.replaceAll(english[i], khmer[i]);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF1F2937),
            size: 18,
          ),
          onPressed: () => Get.back(),
        ),
        title: const Text(
          'បញ្ជីកត់ត្រាស្នាក់នៅ',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xffA88400),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        child: const Icon(Icons.add, size: 24),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 2. Banner Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF9C3), // Yellow-100
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  "គ្រប់គ្រងស្នាក់នៅប្រទេសកម្ពុជា",
                  style: TextStyle(
                    color: Color(0xffA88400),
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "បញ្ជីកំណត់ត្រាស្នាក់នៅ",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "ស្វែងរក កែប្រែ និងគ្រប់គ្រងកំណត់ត្រាស្នាក់នៅរបស់ជនបរទេស",
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
              ),

              const SizedBox(height: 20),

              // 3. Search Bar
              TextField(
                onChanged: (value) => controller.searchQuery.value = value,
                decoration: InputDecoration(
                  hintText:
                      "ស្វែងរកតាមរយៈ ឈ្មោះ អត្តសញ្ញាណប័ណ្ណ លេខលិខិតឆ្លងដែន",
                  hintStyle: const TextStyle(
                    color: Color(0xFF9CA3AF),
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF9CA3AF),
                    size: 20,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xFFD1D5DB),
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: Color(0xffA88400),
                      width: 1.5,
                    ),
                  ),
                ),
                style: const TextStyle(fontSize: 13),
              ),

              const SizedBox(height: 16),

              // 4. Filters Bar
              Obx(
                () => SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Tag 1: ទាំងអស់ (Selected)
                      _buildFilterTag(
                        label: "ទាំងអស់",
                        icon: Icons.filter_list,
                        isSelected:
                            controller.selectedFilter.value == 'ទាំងអស់',
                        onTap: () =>
                            controller.selectedFilter.value = 'ទាំងអស់',
                      ),
                      const SizedBox(width: 8),
                      // Tag 2: ភ្នំពេញ (Unselected)
                      _buildFilterTag(
                        label: "ភ្នំពេញ",
                        icon: Icons.location_on_outlined,
                        isSelected:
                            controller.selectedFilter.value == 'ភ្នំពេញ',
                        onTap: () =>
                            controller.selectedFilter.value = 'ភ្នំពេញ',
                      ),
                      const SizedBox(width: 8),
                      // Tag 3: បានអនុម័ត (Unselected)
                      _buildFilterTag(
                        label: "បានអនុម័ត",
                        icon: Icons.check_circle_outline,
                        isSelected:
                            controller.selectedFilter.value == 'បានអនុម័ត',
                        onTap: () =>
                            controller.selectedFilter.value = 'បានអនុម័ត',
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 5. Statistics Cards
              Row(
                children: [
                  // Stat Card 1: កត់ត្រាសរុប
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "កត់ត្រាសរុប",
                                  style: TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Obx(() {
                                  final totalFormatted = NumberFormat(
                                    '#,###',
                                  ).format(controller.total.value);
                                  return Text(
                                    toKhmerDigits(totalFormatted),
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1F2937),
                                    ),
                                  );
                                }),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF9C3), // soft yellow
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.people_outline,
                              color: Color(0xffA88400),
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Stat Card 2: អ្នកស្នាក់ថ្មីថ្ងៃនេះ
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "អ្នកស្នាក់ថ្មីថ្ងៃនេះ",
                                  style: TextStyle(
                                    color: Color(0xFF6B7280),
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Obx(
                                  () => Text(
                                    toKhmerDigits(
                                      controller.users.value.toString(),
                                    ),
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF), // soft blue
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.person_add_alt_1_outlined,
                              color: Color(0xFF3B51C5),
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 6. List Cards
              Obx(
                () => ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.filteredRequests.length,
                  itemBuilder: (_, index) {
                    return RequestCard(
                      request: controller.filteredRequests[index],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterTag({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    if (isSelected) {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xffA88400),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: Size.zero,
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      );
    } else {
      return OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF4B5563),
          side: const BorderSide(color: Color(0xFFD1D5DB)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          minimumSize: Size.zero,
        ),
        onPressed: onTap,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12)),
      );
    }
  }
}
