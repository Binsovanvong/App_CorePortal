import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core_portal/screens/super_admin/super_admin_controller.dart';
import 'package:core_portal/widgets/custom_snackbar.dart';
import 'package:core_portal/screens/super_admin/super_admin_edit_role_view.dart';
import 'package:core_portal/screens/super_admin/super_admin_view_role_dialog.dart';

class SuperAdminRoleListView extends StatefulWidget {
  const SuperAdminRoleListView({super.key});

  @override
  State<SuperAdminRoleListView> createState() => _SuperAdminRoleListViewState();
}

class _SuperAdminRoleListViewState extends State<SuperAdminRoleListView> {
  final SuperAdminController controller = Get.find<SuperAdminController>();

  final statusFilter = 'ស្ថានភាពទាំងអស់'.obs;
  final currentPage = 1.obs;
  static const int itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchRolesData();
    });
  }

  List<Map<String, dynamic>> getFilteredAndPagedRoles(
    List<Map<String, dynamic>> liveRoles,
  ) {
    List<Map<String, dynamic>> filtered = liveRoles.where((role) {
      if (statusFilter.value != 'ស្ថានភាពទាំងអស់') {
        final st = role['status'] ?? 'ACTIVE';
        return statusFilter.value == 'ដំណើរការ'
            ? st == 'ACTIVE'
            : st != 'ACTIVE';
      }
      return true;
    }).toList();

    return filtered;
  }

  List<Map<String, dynamic>> getPagedRoles(
    List<Map<String, dynamic>> filtered,
  ) {
    final start = (currentPage.value - 1) * itemsPerPage;
    final end = (start + itemsPerPage).clamp(0, filtered.length);
    if (start >= filtered.length) return [];
    return filtered.sublist(start, end);
  }

  int getTotalPages(int total) => (total / itemsPerPage).ceil().clamp(1, 999);

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobileLayout = screenWidth < 768;

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xff0F172A),
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'ការកំណត់សិទ្ធិ និងតួនាទី',
          style: GoogleFonts.kantumruyPro(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: const Color(0xff0F172A),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: controller.fetchRolesData,
        color: const Color(0xffE29D11),
        child: Obx(() {
          final liveRoles = controller.filteredRoles;
          final processedRoles = getFilteredAndPagedRoles(liveRoles);
          final pagedRoles = getPagedRoles(processedRoles);
          final totalPages = getTotalPages(processedRoles.length);

          final int startIndex = processedRoles.isEmpty
              ? 0
              : (currentPage.value - 1) * itemsPerPage + 1;
          final int endIndex =
              ((currentPage.value - 1) * itemsPerPage + pagedRoles.length)
                  .clamp(0, processedRoles.length);

          final int totalRolesCount = controller.rolesList.isNotEmpty
              ? controller.rolesList.length
              : 5;
          final int totalPermsCount = controller.permissionsCount.value > 0
              ? controller.permissionsCount.value
              : 16;
          final int totalAssignedUsers =
              controller.assignedRoleUsersCount.value;

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.all(isMobileLayout ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final double cardWidth =
                        (constraints.maxWidth - (isMobileLayout ? 12 : 32)) / 3;
                    final double ratio = cardWidth / (isMobileLayout ? 115 : 105);
                    return GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: isMobileLayout ? 6 : 16,
                      mainAxisSpacing: 10,
                      childAspectRatio: ratio.clamp(0.65, 3.0),
                      children: [
                        _buildSummaryCard(
                          'តួនាទីសរុប',
                          '$totalRolesCount',
                          'តួនាទីទាំងអស់ក្នុងប្រព័ន្ធ',
                          Icons.verified_user_outlined,
                          const Color(0xff2563EB),
                          isMobileLayout: isMobileLayout,
                        ),
                        _buildSummaryCard(
                          'សិទ្ធិសរុប',
                          '$totalPermsCount',
                          'សិទ្ធិដែលបានកំណត់',
                          Icons.key_outlined,
                          const Color(0xff7C3AED),
                          isMobileLayout: isMobileLayout,
                        ),
                        _buildSummaryCard(
                          'អ្នកប្រើប្រាស់សរុប',
                          '$totalAssignedUsers',
                          'អ្នកប្រើដែលទទួលតួនាទី',
                          Icons.person_outline_rounded,
                          const Color(0xffD97706),
                          isMobileLayout: isMobileLayout,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                Container(
                  padding: EdgeInsets.all(isMobileLayout ? 12 : 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xffE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      isMobileLayout
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(
                                  'បញ្ជីតួនាទី',
                                  style: GoogleFonts.kantumruyPro(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: const Color(0xff0F172A),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildSearchField(),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xffE29D11),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    minimumSize: const Size(0, 44),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  label: Text(
                                    'បង្កើតតួនាទីថ្មី',
                                    style: GoogleFonts.kantumruyPro(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onPressed: () => _showAddRoleSheet(context),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Text(
                                  'បញ្ជីតួនាទី',
                                  style: GoogleFonts.kantumruyPro(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: const Color(0xff0F172A),
                                  ),
                                ),
                                const Spacer(),
                                SizedBox(
                                  width: 240,
                                  child: _buildSearchField(),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xffE29D11),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    minimumSize: const Size(0, 40),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  icon: const Icon(Icons.add_rounded, size: 18),
                                  label: Text(
                                    'បង្កើតតួនាទីថ្មី',
                                    style: GoogleFonts.kantumruyPro(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onPressed: () => _showAddRoleSheet(context),
                                ),
                              ],
                            ),
                      const SizedBox(height: 20),

                      if (!isMobileLayout) ...[
                        _buildTableLabelsRow(),
                        const Divider(height: 1, color: Color(0xffEDF2F7)),
                      ],

                      if (controller.isLoading.value && pagedRoles.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 60),
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Color(0xffE29D11),
                              ),
                            ),
                          ),
                        )
                      else if (pagedRoles.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 60),
                          child: Center(
                            child: Text(
                              'រកមិនឃើញទិន្នន័យតួនាទីឡើយ',
                              style: GoogleFonts.kantumruyPro(
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: pagedRoles.length,
                          separatorBuilder: (context, index) => const Divider(
                            height: 1,
                            color: Color(0xffF1F5F9),
                          ),
                          itemBuilder: (context, idx) {
                            final role = pagedRoles[idx];
                            final globalNo =
                                (currentPage.value - 1) * itemsPerPage +
                                idx +
                                1;
                            return isMobileLayout
                                ? _buildRoleMobileCard(globalNo, role)
                                : _buildRoleDataRow(globalNo, role);
                          },
                        ),
                      const SizedBox(height: 20),

                      if (processedRoles.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'បង្ហាញ $startIndex ដល់ $endIndex នៃ ${processedRoles.length}',
                              style: GoogleFonts.kantumruyPro(
                                fontSize: 11,
                                color: const Color(0xff718096),
                              ),
                            ),
                            Row(
                              children: [
                                _buildPageArrowBtn(
                                  icon: Icons.chevron_left_rounded,
                                  onTap: currentPage.value > 1
                                      ? () => currentPage.value--
                                      : null,
                                ),
                                const SizedBox(width: 4),
                                ...List.generate(totalPages, (i) {
                                  final page = i + 1;
                                  final isSel = page == currentPage.value;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 1,
                                    ),
                                    child: GestureDetector(
                                      onTap: () => currentPage.value = page,
                                      child: Container(
                                        width: 28,
                                        height: 28,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: isSel
                                              ? const Color(0xffE29D11)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                          border: Border.all(
                                            color: isSel
                                                ? const Color(0xffE29D11)
                                                : const Color(0xffE2E8F0),
                                          ),
                                        ),
                                        child: Text(
                                          '$page',
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            fontWeight: isSel
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: isSel
                                                ? Colors.white
                                                : const Color(0xff475569),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                                const SizedBox(width: 4),
                                _buildPageArrowBtn(
                                  icon: Icons.chevron_right_rounded,
                                  onTap: currentPage.value < totalPages
                                      ? () => currentPage.value++
                                      : null,
                                ),
                              ],
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSummaryCard(
    String title,
    String count,
    String subtitle,
    IconData icon,
    Color accentColor, {
    bool isMobileLayout = false,
  }) {
    if (isMobileLayout) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xffE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.015),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 20),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.kantumruyPro(
                  fontSize: 12,
                  color: const Color(0xff475569),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                count,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                softWrap: true,
                style: GoogleFonts.kantumruyPro(
                  fontSize: 9,
                  color: const Color(0xff94A3B8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 13,
                    color: const Color(0xff475569),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  count,
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 11,
                    color: const Color(0xff94A3B8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableLabelsRow() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              'ល.រ',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xff718096),
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              'ឈ្មោះតួនាទី',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xff718096),
                fontSize: 11,
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                'ក្រុម (សរុប)',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xff718096),
                  fontSize: 11,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                'សិទ្ធិ (សរុប)',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xff718096),
                  fontSize: 11,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                'អ្នកប្រើ (សរុប)',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xff718096),
                  fontSize: 11,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Text(
                'ស្ថានភាព',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xff718096),
                  fontSize: 11,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 110,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                'សកម្មភាព',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xff718096),
                  fontSize: 11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleDataRow(int index, Map<String, dynamic> role) {
    final bool isActive =
        (role['status'] ?? 'ACTIVE').toString().toUpperCase() == 'ACTIVE';
    final Color iconColor = role['icon_color'] ?? const Color(0xff2563EB);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '$index',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xff4A5568),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: Colors.white,
                    size: 15,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        role['name'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.kantumruyPro(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: const Color(0xff2D3748),
                        ),
                      ),
                      Text(
                        role['code'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.poppins(
                          fontSize: 9,
                          color: const Color(0xffA0AEC0),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: _buildCountIndicatorBadge(
                Icons.people_alt_outlined,
                role['groups_count'],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: _buildCountIndicatorBadge(
                Icons.key_outlined,
                role['perms_count'],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: _buildCountIndicatorBadge(
                Icons.person_outline_rounded,
                role['users_count'],
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xffE6FFFA)
                      : const Color(0xffFFF5F5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isActive ? '• ដំណើរការ' : '• ផ្អាក',
                  style: GoogleFonts.kantumruyPro(
                    color: isActive
                        ? const Color(0xff319795)
                        : const Color(0xffE53E3E),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 110,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildActionButton(
                  Icons.visibility_outlined,
                  () => _showViewRoleSheet(context, role),
                ),
                const SizedBox(width: 4),
                _buildActionButton(
                  Icons.edit_outlined,
                  () => Get.to(() => SuperAdminEditRoleView(role: role)),
                ),
                const SizedBox(width: 4),
                _buildActionButton(
                  Icons.more_vert_rounded,
                  () => _showRoleOptionsSheet(context, role),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleMobileCard(int index, Map<String, dynamic> role) {
    final bool isActive =
        (role['status'] ?? 'ACTIVE').toString().toUpperCase() == 'ACTIVE';
    final Color iconColor = role['icon_color'] ?? const Color(0xff2563EB);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '$index. ',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconColor,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: Colors.white,
                  size: 14,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      role['name'] ?? '',
                      style: GoogleFonts.kantumruyPro(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      role['code'] ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isActive
                      ? const Color(0xffE6FFFA)
                      : const Color(0xffFFF5F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isActive ? 'ដំណើរការ' : 'ផ្អាក',
                  style: GoogleFonts.kantumruyPro(
                    color: isActive
                        ? const Color(0xff319795)
                        : const Color(0xffE53E3E),
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildCountIndicatorBadge(
                Icons.people_alt_outlined,
                role['groups_count'],
              ),
              const SizedBox(width: 6),
              _buildCountIndicatorBadge(
                Icons.key_outlined,
                role['perms_count'],
              ),
              const SizedBox(width: 6),
              _buildCountIndicatorBadge(
                Icons.person_outline_rounded,
                role['users_count'],
              ),
              const Spacer(),
              _buildActionButton(
                Icons.visibility_outlined,
                () => _showViewRoleSheet(context, role),
              ),
              const SizedBox(width: 6),
              _buildActionButton(
                Icons.edit_outlined,
                () => Get.to(() => SuperAdminEditRoleView(role: role)),
              ),
              const SizedBox(width: 6),
              _buildActionButton(
                Icons.delete_outline_rounded,
                () => _showDeleteConfirmation(context, role),
                color: Colors.red,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCountIndicatorBadge(IconData icon, int count) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xffE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xff475569)),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xff334155),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, VoidCallback onTap, {Color? color}) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        icon: Icon(icon, size: 14, color: color ?? const Color(0xff718096)),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildPageArrowBtn({required IconData icon, VoidCallback? onTap}) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xffE2E8F0)),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? const Color(0xff4A5568) : Colors.grey.shade300,
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: TextField(
        onChanged: (val) {
          controller.roleSearchQuery.value = val;
          currentPage.value = 1;
        },
        decoration: InputDecoration(
          hintText: 'ស្វែងរកតាមឈ្មោះតួនាទី...',
          hintStyle: GoogleFonts.kantumruyPro(fontSize: 12, color: Colors.grey),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: Colors.grey,
            size: 16,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  void _showAddRoleSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final codeCtrl = TextEditingController();
    String selectedStatus = 'ACTIVE';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'បង្កើតតួនាទីថ្មី',
              style: GoogleFonts.kantumruyPro(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: const Color(0xff1E293B),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: 'ឈ្មោះតួនាទី',
                labelStyle: GoogleFonts.kantumruyPro(fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: codeCtrl,
              decoration: InputDecoration(
                labelText: 'លេខកូដតួនាទី (Role Code)',
                labelStyle: GoogleFonts.kantumruyPro(fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedStatus,
              decoration: InputDecoration(
                labelText: 'ស្ថានភាព',
                labelStyle: GoogleFonts.kantumruyPro(fontSize: 13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              items: [
                DropdownMenuItem(
                  value: 'ACTIVE',
                  child: Text(
                    'ដំណើរការ',
                    style: GoogleFonts.kantumruyPro(fontSize: 13),
                  ),
                ),
                DropdownMenuItem(
                  value: 'INACTIVE',
                  child: Text(
                    'ផ្អាក',
                    style: GoogleFonts.kantumruyPro(fontSize: 13),
                  ),
                ),
              ],
              onChanged: (val) {
                if (val != null) selectedStatus = val;
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xffE29D11),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                onPressed: () {
                  final name = nameCtrl.text.trim();
                  final code = codeCtrl.text.trim();
                  if (name.isEmpty || code.isEmpty) {
                    CustomSnackbar.showError(
                      message: 'សូមបំពេញព័ត៌មានអោយបានគ្រប់គ្រាន់',
                    );
                    return;
                  }
                  controller.addNewRole(name, code, selectedStatus);
                  Navigator.of(context).pop();
                  CustomSnackbar.showSuccess(
                    message: 'បានបង្កើតតួនាទីដោយជោគជ័យ!',
                  );
                },
                child: Text(
                  'បង្កើតតួនាទី',
                  style: GoogleFonts.kantumruyPro(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _showViewRoleSheet(BuildContext context, Map<String, dynamic> role) {
    showSuperAdminViewRoleModal(context, role);
  }

  void _showDeleteConfirmation(
    BuildContext context,
    Map<String, dynamic> role,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'លុបតួនាទី',
          style: GoogleFonts.kantumruyPro(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'តើអ្នកពិតជាចង់លុបតួនាទី "${role['name']}" នេះមែនទេ?',
          style: GoogleFonts.kantumruyPro(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'បោះបង់',
              style: GoogleFonts.kantumruyPro(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              controller.deleteRoleByCode(role['code'] ?? '');
              Navigator.of(context).pop();
              CustomSnackbar.showSuccess(message: 'បានលុបតួនាទីដោយជោគជ័យ!');
            },
            child: Text(
              'លុប',
              style: GoogleFonts.kantumruyPro(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRoleOptionsSheet(BuildContext context, Map<String, dynamic> role) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.visibility_outlined,
                color: Colors.blue,
              ),
              title: Text(
                'មើលព័ត៌មានលម្អិត',
                style: GoogleFonts.kantumruyPro(),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _showViewRoleSheet(context, role);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: Colors.amber),
              title: Text('កែប្រែព័ត៌មាន', style: GoogleFonts.kantumruyPro()),
              onTap: () {
                Navigator.of(context).pop();
                Get.to(() => SuperAdminEditRoleView(role: role));
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.red,
              ),
              title: Text(
                'លុបតួនាទី',
                style: GoogleFonts.kantumruyPro(color: Colors.red),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _showDeleteConfirmation(context, role);
              },
            ),
          ],
        ),
      ),
    );
  }
}
