import 'package:core_portal/models/request_model.dart';
import 'package:core_portal/routes/page_route.dart';
import 'package:core_portal/screens/modules/list/list_view.dart';
import 'package:core_portal/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:core_portal/pages/Main/main_view.dart';
import 'package:intl/intl.dart';

part 'request_binding.dart';
part 'request_controller.dart';

class RequestView extends GetView<RequestViewController> {
  const RequestView({super.key});

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
          'កត់ត្រាការស្នាក់នៅ',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildHeaderCard(),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0x02000000),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Title and Description
                  const Text(
                    'ព័ត៌មានអត្តសញ្ញាណប័ណ្ណ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'បញ្ចូលព័ត៌មានឯកសារ កាលបរិច្ឆេទ សញ្ជាតិ និងព័ត៌មានទំនាក់ទំនង ដើម្បីងាយស្រួលផ្ទៀងផ្ទាត់។',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section 1: Identity info fields
                  _buildLabel('ឈ្មោះខ្មែរ'),
                  _buildTextField(
                    controller: controller.firstName,
                    hint: 'បញ្ចូលឈ្មោះ',
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('ឈ្មោះឡាតាំង/បរទេស'),
                  _buildTextField(
                    controller: controller.lastName,
                    hint: 'Enter Name',
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('ប្រភេទប្រភពកត់ត្រា'),
                  Obx(
                    () => _buildDropdownField<String>(
                      value: controller.recordSourceType.value,
                      items: const [
                        DropdownMenuItem(
                          value: 'ជនជាតិខ្មែរ',
                          child: Text('ជនជាតិខ្មែរ'),
                        ),
                        DropdownMenuItem(
                          value: 'ជនបរទេស',
                          child: Text('ជនបរទេស'),
                        ),
                      ],
                      onChanged: (v) =>
                          controller.recordSourceType.value = v ?? '',
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('ភេទ'),
                            Obx(
                              () => _buildDropdownField<String>(
                                value: controller.gender.value,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'ប្រុស',
                                    child: Text('ប្រុស'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'ស្រី',
                                    child: Text('ស្រី'),
                                  ),
                                ],
                                onChanged: (v) =>
                                    controller.gender.value = v ?? '',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('ថ្ងៃខែឆ្នាំកំណើត'),
                            _buildTextField(
                              controller: controller.dobController,
                              hint: 'mm/dd/yyyy',
                              readOnly: true,
                              onTap: () => controller.selectDate(context),
                              suffixIcon: const Icon(
                                Icons.calendar_today_outlined,
                                size: 16,
                                color: Color(0xFF9CA3AF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('សញ្ជាតិ'),
                  Obx(
                    () => _buildTextField(
                      controller: TextEditingController(
                        text: controller.nationality.value,
                      ),
                      hint: 'Cambodian',
                    ),
                  ),

                  // Divider between Section 1 and Section 2
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Divider(color: Color(0xFFE2E8F0), height: 1),
                  ),

                  // Section 2: Document & Contact Title
                  const Text(
                    'ឯកសារ និងព័ត៌មានទាក់ទង',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildLabel('ប្រភេទឯកសារ'),
                  Obx(
                    () => _buildDropdownField<String>(
                      value: controller.docType.value,
                      items: const [
                        DropdownMenuItem(
                          value: 'អត្តសញ្ញាណប័ណ្ណ',
                          child: Text('អត្តសញ្ញាណប័ណ្ណ'),
                        ),
                        DropdownMenuItem(
                          value: 'លិខិតឆ្លងដែន',
                          child: Text('លិខិតឆ្លងដែន'),
                        ),
                      ],
                      onChanged: (v) => controller.docType.value = v ?? '',
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('អត្តសញ្ញាណប័ណ្ណ / លិខិតឆ្លងដែន'),
                  _buildTextField(
                    controller: controller.idNumber,
                    hint: 'បញ្ចូលលេខ',
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('លេខទូរស័ព្ទ'),
                  Row(
                    children: [
                      Container(
                        height: 46,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          border: Border.all(color: const Color(0xFFD1D5DB)),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(8),
                            bottomLeft: Radius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text(
                              '+855',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF374151),
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
                              Icons.keyboard_arrow_down,
                              size: 16,
                              color: Color(0xFF9CA3AF),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: TextFormField(
                          controller: controller.phone,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: '12 345 678',
                            hintStyle: const TextStyle(
                              color: Color(0xFF9CA3AF),
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            enabledBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                              ),
                              borderSide: BorderSide(
                                color: Color(0xFFD1D5DB),
                                width: 1,
                              ),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderRadius: BorderRadius.only(
                                topRight: Radius.circular(8),
                                bottomRight: Radius.circular(8),
                              ),
                              borderSide: BorderSide(
                                color: AppColors.primary,
                                width: 1.5,
                              ),
                            ),
                          ),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF1F2937),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('អ៊ីមែល'),
                  _buildTextField(
                    controller: controller.email,
                    hint: 'example@mail.com',
                    keyboardType: TextInputType.emailAddress,
                  ),

                  // Divider between Section 2 and Section 3
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Divider(color: Color(0xFFE2E8F0), height: 1),
                  ),

                  // Section 3: Location Title
                  const Text(
                    'ទីតាំងស្នាក់នៅ និងស្នាក់នៅ',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('ខេត្ត / ក្រុង'),
                            Obx(
                              () => _buildDropdownField<String>(
                                value: controller.province.value,
                                items: const [
                                  DropdownMenuItem(
                                    value: 'ភ្នំពេញ',
                                    child: Text('ភ្នំពេញ'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'សៀមរាប',
                                    child: Text('សៀមរាប'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'ព្រះសីហនុ',
                                    child: Text('ព្រះសីហនុ'),
                                  ),
                                  DropdownMenuItem(
                                    value: 'បាត់ដំបង',
                                    child: Text('បាត់ដំបង'),
                                  ),
                                ],
                                onChanged: (v) =>
                                    controller.province.value = v ?? '',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('ស្រុក / ខណ្ឌ'),
                            _buildTextField(
                              controller: controller.district,
                              hint: 'បញ្ចូលស្រុក / ខណ្ឌ',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('ឃុំ / សង្កាត់'),
                            _buildTextField(
                              controller: controller.commune,
                              hint: 'បញ្ចូលឃុំ / សង្កាត់',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('ភូមិ'),
                            _buildTextField(
                              controller: controller.village,
                              hint: 'បញ្ចូលភូមិ',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('ប្រភេទទីកន្លែងស្នាក់នៅ'),
                  Obx(
                    () => _buildDropdownField<String>(
                      value: controller.accommodationType.value,
                      items: const [
                        DropdownMenuItem(
                          value: 'សណ្ឋាគារ',
                          child: Text('សណ្ឋាគារ'),
                        ),
                        DropdownMenuItem(
                          value: 'ផ្ទះសំណាក់',
                          child: Text('ផ្ទះសំណាក់'),
                        ),
                        DropdownMenuItem(
                          value: 'ផ្ទះជួល',
                          child: Text('ផ្ទះជួល'),
                        ),
                      ],
                      onChanged: (v) =>
                          controller.accommodationType.value = v ?? '',
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('គោលបំណងស្នាក់នៅ'),
                  Obx(
                    () => _buildDropdownField<String>(
                      value: controller.stayPurpose.value,
                      items: const [
                        DropdownMenuItem(
                          value: 'ស្នាក់នៅបែបអ្នកការទូត',
                          child: Text('ស្នាក់នៅបែបអ្នកការទូត'),
                        ),
                        DropdownMenuItem(
                          value: 'ទេសចរណ៍',
                          child: Text('ទេសចរណ៍'),
                        ),
                        DropdownMenuItem(
                          value: 'ធុរកិច្ច',
                          child: Text('ធុរកិច្ច'),
                        ),
                      ],
                      onChanged: (v) => controller.stayPurpose.value = v ?? '',
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildLabel('ស្នាក់នៅដល់'),
                  Obx(
                    () => _buildDropdownField<String>(
                      value: controller.stayUntil.value,
                      items: const [
                        DropdownMenuItem(
                          value: 'កំពុងស្នាក់នៅ',
                          child: Text('កំពុងស្នាក់នៅ'),
                        ),
                        DropdownMenuItem(value: '១ ខែ', child: Text('១ ខែ')),
                        DropdownMenuItem(value: '៣ ខែ', child: Text('៣ ខែ')),
                      ],
                      onChanged: (v) => controller.stayUntil.value = v ?? '',
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Bottom buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            if (Get.currentRoute == AppRoutes.request) {
                              Get.back();
                            } else if (Get.isRegistered<MainController>()) {
                              Get.find<MainController>().currentIndex.value = 0; // switch to Home tab
                            } else {
                              Get.back();
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Color(0xFFD1D5DB)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'បោះបង់',
                            style: TextStyle(
                              color: Color(0xFF374151),
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => controller.saveRequest(),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff3B51C5),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            'រក្សាទុកព័ត៌មាន',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Center(
                    child: Text(
                      'សូមត្រួតពិនិត្យព័ត៌មានមុននឹងរក្សាទុក',
                      style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF374151),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    bool readOnly = false,
    VoidCallback? onTap,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      readOnly: readOnly,
      onTap: onTap,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        suffixIcon: suffixIcon,
      ),
      style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
    );
  }

  Widget _buildDropdownField<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      items: items,
      onChanged: onChanged,
      icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFF9CA3AF)),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFD1D5DB), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
      style: const TextStyle(fontSize: 14, color: Color(0xFF1F2937)),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0x02000000),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 850;
          if (isMobile) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLeftHeaderContent(),
                const SizedBox(height: 16),
                _buildRightTabsContent(isMobile: true),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(flex: 4, child: _buildLeftHeaderContent()),
              const SizedBox(width: 24),
              Expanded(flex: 5, child: _buildRightTabsContent(isMobile: false)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLeftHeaderContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFFEF9C3), // Yellow-100
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'គ្រប់ខេត្តក្រុងនៃប្រទេសកម្ពុជា',
            style: TextStyle(
              color: Color(0xffA88400),
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'កត់ត្រាការស្នាក់នៅ',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'បញ្ចូលព័ត៌មានស្នាក់នៅសម្រាប់ជនបរទេស និងជនជាតិខ្មែរគ្រប់ខេត្តក្រុង',
          style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }

  Widget _buildRightTabsContent({required bool isMobile}) {
    final double cardPadding = isMobile ? 8 : 10;
    return Row(
      children: [
        // Tab 1: កត់ត្រា (Active)
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: cardPadding,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF), // Active blue background
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFBFDBFE), width: 1),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0x0D000000),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.description_outlined,
                    color: Color(0xFF3B51C5),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'កត់ត្រា',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'បញ្ចូលអត្តសញ្ញាណ ទីតាំង និងព័ត៌មានស្នាក់នៅ',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 9,
                          color: Color(0xFF6B7280),
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Tab 2: បញ្ជីស្នាក់
        Expanded(
          child: InkWell(
            onTap: () {
              if (Get.isRegistered<MainController>()) {
                Get.find<MainController>().currentIndex.value = 2;
              } else {
                Get.toNamed(AppRoutes.requestList);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: cardPadding,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0x0D000000),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.assignment_outlined,
                      color: Color(0xFF4B5563),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Text(
                          'បញ្ជីស្នាក់',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'ពិនិត្យឯកសារ និងរបាយការណ៍ព័ត៌មាន',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9,
                            color: Color(0xFF9CA3AF),
                            height: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
