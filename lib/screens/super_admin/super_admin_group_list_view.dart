import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core_portal/screens/super_admin/super_admin_controller.dart';
import 'package:core_portal/screens/super_admin/super_admin_create_group_view.dart';
import 'package:core_portal/screens/super_admin/super_admin_edit_group_view.dart';
import 'package:core_portal/screens/super_admin/super_admin_edit_role_view.dart';
import 'package:core_portal/screens/super_admin/super_admin_view_role_dialog.dart';

class SuperAdminGroupListView extends StatefulWidget {
  final Map<String, dynamic>? user;

  const SuperAdminGroupListView({super.key, this.user});

  @override
  State<SuperAdminGroupListView> createState() =>
      _SuperAdminGroupListViewState();
}

class _SuperAdminGroupListViewState extends State<SuperAdminGroupListView> {
  late SuperAdminController controller;

  final searchQuery = ''.obs;
  final statusFilter = 'ស្ថានភាពទាំងអស់'.obs;
  final currentPage = 1.obs;
  final itemsPerPage = 10.obs;

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<SuperAdminController>()) {
      controller = Get.find<SuperAdminController>();
    } else {
      controller = Get.put(SuperAdminController());
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.fetchPortalGroupsData();
      if (controller.usersList.isEmpty) {
        controller.fetchDashboardData();
      }
    });
  }

  List<Map<String, dynamic>> _getAllGroups() {
    return controller.groupList;
  }

  String _resolveKhmerNameByGroupCode(String inputCode) {
    String code = inputCode.trim();
    if (code.startsWith('/')) code = code.substring(1);
    code = code.replaceAll('/', '-').toUpperCase();

    // 1. Direct dictionary mapping by organizational code
    final Map<String, String> khmerMap = {
      // General Departments
      'GDDTM': 'អគ្គនាយកដ្ឋានបច្ចេកវិទ្យាឌីជីថល និងផ្សព្វផ្សាយអប់រំ',
      'GDDTM ADMINS': 'អគ្គនាយកដ្ឋានបច្ចេកវិទ្យាឌីជីថល និងផ្សព្វផ្សាយអប់រំ',
      'GDDTM USERS': 'អគ្គនាយកដ្ឋានបច្ចេកវិទ្យាឌីជីថល និងផ្សព្វផ្សាយអប់រំ',
      'GDI': 'អគ្គនាយកដ្ឋានអន្តោប្រវេសន៍',
      'GDI ADMINS': 'អគ្គនាយកដ្ឋានអន្តោប្រវេសន៍',
      'GDI USERS': 'អគ្គនាយកដ្ឋានអន្តោប្រវេសន៍',
      'GDP': 'អគ្គនាយកដ្ឋានពន្ធនាគារ',
      'GDP GROUP': 'អគ្គនាយកដ្ឋានពន្ធនាគារ',
      'GDP ADMINS': 'អគ្គនាយកដ្ឋានពន្ធនាគារ',
      'GDP USERS': 'អគ្គនាយកដ្ឋានពន្ធនាគារ',
      'GDHR': 'អគ្គនាយកដ្ឋានធនធានមនុស្ស',
      'GDHR ADMINS': 'អគ្គនាយកដ្ឋានធនធានមនុស្ស',
      'GDHR USERS': 'អគ្គនាយកដ្ឋានធនធានមនុស្ស',
      'PAC': 'បណ្ឌិត្យសភានគរបាលកម្ពុជា',
      'PAC ADMINS': 'បណ្ឌិត្យសភានគរបាលកម្ពុជា',
      'PAC USERS': 'បណ្ឌិត្យសភានគរបាលកម្ពុជា',
      'GI': 'អគ្គាធិការដ្ឋាន',
      'GI ADMINS': 'អគ្គាធិការដ្ឋាន',
      'GI USERS': 'អគ្គាធិការដ្ឋាន',
      'GIA': 'អគ្គនាយកដ្ឋានសវនកម្មផ្ទៃក្នុង',
      'GIA ADMINS': 'អគ្គនាយកដ្ឋានសវនកម្មផ្ទៃក្នុង',
      'GIA USERS': 'អគ្គនាយកដ្ឋានសវនកម្មផ្ទៃក្នុង',
      'GID': 'អគ្គនាយកដ្ឋានអត្តសញ្ញាណកម្ម',
      'GID ADMINS': 'អគ្គនាយកដ្ឋានអត្តសញ្ញាណកម្ម',
      'GID USERS': 'អគ្គនាយកដ្ឋានអត្តសញ្ញាណកម្ម',
      'GLF': 'អគ្គនាយកដ្ឋានភស្តុភារ និងហិរញ្ញវត្ថុ',
      'GLF ADMINS': 'អគ្គនាយកដ្ឋានភស្តុភារ និងហិរញ្ញវត្ថុ',
      'GLF USERS': 'អគ្គនាយកដ្ឋានភស្តុភារ និងហិរញ្ញវត្ថុ',
      'GNP': 'អគ្គស្នងការដ្ឋាននគរបាលជាតិ',
      'GNP ADMINS': 'អគ្គស្នងការដ្ឋាននគរបាលជាតិ',
      'GNP USERS': 'អគ្គស្នងការដ្ឋាននគរបាលជាតិ',
      'GS': 'អគ្គលេខាធិការដ្ឋាន',
      'GS ADMINS': 'អគ្គលេខាធិការដ្ឋាន',
      'GS USERS': 'អគ្គលេខាធិការដ្ឋាន',
      'LC': 'ក្រុមប្រឹក្សានីតិកម្ម',
      'LC ADMINS': 'ក្រុមប្រឹក្សានីតិកម្ម',
      'LC USERS': 'ក្រុមប្រឹក្សានីតិកម្ម',

      // Departments
      'GDDTM-N1': 'នាយកដ្ឋានរដ្ឋបាល-សរុប',
      'GDDTM-N2': 'នាយកដ្ឋានបណ្តុះបណ្តាល និងអភិបាលកិច្ចបច្ចេកវិទ្យាឌីជីថល',
      'GDDTM-N3': 'នាយកដ្ឋានផ្សព្វផ្សាយ និងទំនាក់ទំនងសាធារណៈ',
      'GDDTM-N4': 'នាយកដ្ឋានហេដ្ឋារចនាសម្ព័ន្ធបច្ចេកវិទ្យាគមនាគមន៍ និងព័ត៌មាន',
      'GDI-N1': 'នាយកដ្ឋានរដ្ឋបាលសរុប (GDI)',

      // Bureaus
      'GDDTM-N1-B1': 'ការិយាល័យរដ្ឋបាល',
      'GDDTM-N1-B2': 'ការិយាល័យផែនការ',
      'GDDTM-N1-B3': 'ការិយាល័យបុគ្គលិក',
      'GDDTM-N1-B4': 'ការិយាល័យភស្តុភារ និងគណនេយ្យ',
      'GDDTM-N2-B1': 'ការិយាល័យបណ្តុះបណ្តាល',
      'GDDTM-N2-B6': 'ការិយាល័យអភិបាលកិច្ចបច្ចេកវិទ្យាឌីជីថល',
      'GDDTM-N4-B1': 'ការិយាល័យរដ្ឋបាល-សរុប (N4)',
      'GDDTM-N4-B2': 'ការិយាល័យបច្ចេកវិទ្យា និងអភិវឌ្ឍន៍',
      'GDDTM-N4-B3': 'ការិយាល័យប្រតិបត្តិការមជ្ឍមណ្ឌលទិន្នន័យ',
      'GDDTM-N4-B4': 'ការិយាល័យសន្តិសុខបច្ចេកវិទ្យាឌីជីថល',
    };

    if (khmerMap.containsKey(code)) return khmerMap[code]!;

    // 2. Check Employment Infos from Live User Profiles
    for (var u in controller.usersList) {
      final List? empInfos = u['employmentInfos'];
      if (empInfos != null) {
        for (var emp in empInfos) {
          if (emp is Map) {
            final bCode = (emp['bureauCode'] ?? '').toString().trim().toUpperCase();
            final bName = (emp['bureauNameKh'] ?? emp['bureauName'] ?? '').toString().trim();
            if (bCode.isNotEmpty && (bCode == code || code.endsWith(bCode)) && bName.isNotEmpty) {
              return bName;
            }

            final dCode = (emp['departmentCode'] ?? '').toString().trim().toUpperCase();
            final dName = (emp['departmentNameKh'] ?? emp['departmentName'] ?? '').toString().trim();
            if (dCode.isNotEmpty && (dCode == code || code.endsWith(dCode)) && dName.isNotEmpty) {
              return dName;
            }

            final gCode = (emp['generalDepartmentCode'] ?? '').toString().trim().toUpperCase();
            final gName = (emp['generalDepartmentNameKh'] ?? emp['generalDepartmentName'] ?? '').toString().trim();
            if (gCode.isNotEmpty && (gCode == code || code.startsWith(gCode)) && gName.isNotEmpty) {
              return gName;
            }
          }
        }
      }
    }

    return '';
  }

  String _getGroupMainTitle(Map<String, dynamic> group) {
    String code = (group['sublabel'] ?? group['code'] ?? group['name'] ?? group['groupName'] ?? '').toString().trim();
    if (code.startsWith('/')) {
      code = code.substring(1).replaceAll('/', '-');
    }
    if (code.isNotEmpty && code != '—') return code;
    return 'Group';
  }

  String _getGroupSubtitle(Map<String, dynamic> group) {
    final String code = (group['sublabel'] ?? group['code'] ?? group['name'] ?? group['groupName'] ?? '').toString().trim();
    final String name = (group['name'] ?? group['groupName'] ?? '').toString().trim();

    // 1. Resolve Khmer name strictly by Group Code / Name
    final khmerByCode = _resolveKhmerNameByGroupCode(code);
    if (khmerByCode.isNotEmpty) return khmerByCode;

    final khmerByName = _resolveKhmerNameByGroupCode(name);
    if (khmerByName.isNotEmpty) return khmerByName;

    // 2. Direct Khmer field from API
    final String khmerField = (group['nameKh'] ??
            group['name_kh'] ??
            group['displayNameKh'] ??
            group['groupNameKh'] ??
            '')
        .toString()
        .trim();
    if (khmerField.isNotEmpty && khmerField != 'null') return khmerField;

    // 3. API Description directly from backend
    final desc =
        (group['description'] ?? group['desc'] ?? group['details'] ?? '')
            .toString()
            .trim();
    if (desc.isNotEmpty && desc != 'null') return desc;

    return '';
  }

  int _getMemberCount(Map<String, dynamic> group) {
    return _getGroupUsers(group).length;
  }

  List<Map<String, dynamic>> _getFilteredGroups(
    List<Map<String, dynamic>> all,
  ) {
    return all.where((group) {
      final name = (group['name'] ?? '').toString().toLowerCase();
      final code = (group['sublabel'] ?? group['code'] ?? '')
          .toString()
          .toLowerCase();
      final q = searchQuery.value.trim().toLowerCase();

      final matchesQuery = q.isEmpty || name.contains(q) || code.contains(q);

      final st = (group['status'] ?? 'ACTIVE').toString().toUpperCase();
      bool matchesStatus = true;
      if (statusFilter.value == 'ដំណើរការ') {
        matchesStatus = st == 'ACTIVE';
      } else if (statusFilter.value == 'ផ្អាក') {
        matchesStatus = st != 'ACTIVE';
      }

      return matchesQuery && matchesStatus;
    }).toList();
  }

  List<Map<String, dynamic>> _getPagedGroups(
    List<Map<String, dynamic>> filtered,
  ) {
    final start = (currentPage.value - 1) * itemsPerPage.value;
    if (start >= filtered.length) return [];
    final end = (start + itemsPerPage.value).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  int _getTotalPages(int totalItems) {
    if (totalItems <= 0) return 1;
    return (totalItems / itemsPerPage.value).ceil();
  }

  List<int> _getVisiblePages(int current, int total) {
    if (total <= 5) {
      return List.generate(total, (i) => i + 1);
    }
    int start = current - 2;
    int end = current + 2;

    if (start < 1) {
      start = 1;
      end = 5;
    } else if (end > total) {
      end = total;
      start = total - 4;
    }

    return List.generate(end - start + 1, (i) => start + i);
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 900;
    final bool isTablet = screenWidth > 600 && screenWidth <= 900;

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xff0F172A),
            size: 20,
          ),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'គ្រប់គ្រងក្រុម និងតួនាទី',
          style: GoogleFonts.kantumruyPro(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: const Color(0xff0F172A),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: controller.fetchPortalGroupsData,
        color: const Color(0xffF59E0B),
        child: Obx(() {
          final allGroups = _getAllGroups();
          final filteredGroups = _getFilteredGroups(allGroups);
          final pagedGroups = _getPagedGroups(filteredGroups);

          final int activeCount = allGroups.where((g) {
            final st = (g['status'] ?? 'ACTIVE').toString().toUpperCase();
            return st == 'ACTIVE';
          }).length;
          final int inactiveCount = allGroups.length - activeCount;
          final int totalBoardCount = controller.totalUsers.value;

          final int totalPages = _getTotalPages(filteredGroups.length);
          if (currentPage.value > totalPages && totalPages > 0) {
            currentPage.value = totalPages;
          }

          final int startIdx = filteredGroups.isEmpty
              ? 0
              : (currentPage.value - 1) * itemsPerPage.value + 1;
          final int endIdx = (currentPage.value * itemsPerPage.value).clamp(
            0,
            filteredGroups.length,
          );

          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummaryCards(
                  allCount: allGroups.length,
                  activeCount: activeCount,
                  inactiveCount: inactiveCount,
                  boardCount: totalBoardCount,
                  isDesktop: isDesktop,
                  isTablet: isTablet,
                ),
                const SizedBox(height: 24),
                _buildMainTableCard(
                  filteredGroups: filteredGroups,
                  pagedGroups: pagedGroups,
                  startIdx: startIdx,
                  endIdx: endIdx,
                  totalPages: totalPages,
                  isDesktop: isDesktop,
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSummaryCards({
    required int allCount,
    required int activeCount,
    required int inactiveCount,
    required int boardCount,
    required bool isDesktop,
    required bool isTablet,
  }) {
    int crossAxisCount = 4;
    if (isTablet) crossAxisCount = 2;
    if (!isDesktop && !isTablet) crossAxisCount = 2;

    final cards = [
      _buildStatCard(
        title: 'អង្គភាពសរុប',
        value: '$allCount',
        subtext: 'អង្គភាពទាំងអស់ក្នុងប្រព័ន្ធ',
        icon: Icons.people_outline_rounded,
        iconBg: const Color(0xffF3E8FF),
        iconColor: const Color(0xff9333EA),
      ),
      _buildStatCard(
        title: 'អង្គភាពដំណើរការ',
        value: '$activeCount',
        subtext: '100% នៃចំនួនសរុប',
        icon: Icons.check_circle_outline_rounded,
        iconBg: const Color(0xffDCFCE7),
        iconColor: const Color(0xff16A34A),
      ),
      _buildStatCard(
        title: 'អង្គភាពផ្អាក',
        value: '$inactiveCount',
        subtext: '0% នៃចំនួនសរុប',
        icon: Icons.pause_circle_outline_rounded,
        iconBg: const Color(0xffFEF3C7),
        iconColor: const Color(0xffD97706),
      ),
      _buildStatCard(
        title: 'ក្រុមប្រឹក្សាភិបាលសរុប',
        value: '$boardCount',
        subtext: 'ក្រុមសរុបទាំងអស់',
        icon: Icons.person_outline_rounded,
        iconBg: const Color(0xffE0F2FE),
        iconColor: const Color(0xff0284C7),
      ),
    ];

    if (isDesktop) {
      return Row(
        children: cards
            .map(
              (c) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: c,
                ),
              ),
            )
            .toList(),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double itemWidth = (width - 12) / crossAxisCount;
        final double ratio = (itemWidth / 96).clamp(1.1, 2.5);

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: ratio,
          children: cards,
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String subtext,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.kantumruyPro(
                      fontSize: 11,
                      color: const Color(0xff64748B),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xff0F172A),
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtext,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.kantumruyPro(
                      fontSize: 10,
                      color: const Color(0xff94A3B8),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainTableCard({
    required List<Map<String, dynamic>> filteredGroups,
    required List<Map<String, dynamic>> pagedGroups,
    required int startIdx,
    required int endIdx,
    required int totalPages,
    required bool isDesktop,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Controls Row
          Padding(
            padding: const EdgeInsets.all(20),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bool isStackControls = constraints.maxWidth < 780;

                Widget titleWidget = Text(
                  'បញ្ជីអង្គភាព',
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff0F172A),
                  ),
                );

                Widget controlsWidget = Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: isStackControls
                      ? WrapAlignment.start
                      : WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    // Search Bar
                    SizedBox(
                      width: isStackControls ? double.infinity : 220,
                      height: 38,
                      child: TextField(
                        onChanged: (val) {
                          searchQuery.value = val;
                          currentPage.value = 1;
                        },
                        style: GoogleFonts.kantumruyPro(fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'ស្វែងរកឈ្មោះអង្គភាព...',
                          hintStyle: GoogleFonts.kantumruyPro(
                            fontSize: 11,
                            color: const Color(0xff94A3B8),
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 18,
                            color: Color(0xff94A3B8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                            horizontal: 12,
                          ),
                          fillColor: const Color(0xffF8FAFC),
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xffE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xffE2E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(
                              color: Color(0xffF59E0B),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Status Dropdown Filter
                    Container(
                      height: 38,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xffF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xffE2E8F0)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          isDense: true,
                          value: statusFilter.value,
                          icon: const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: Color(0xff64748B),
                          ),
                          items: ['ស្ថានភាពទាំងអស់', 'ដំណើរការ', 'ផ្អាក'].map((
                            s,
                          ) {
                            return DropdownMenuItem(
                              value: s,
                              child: Text(
                                s == 'ស្ថានភាពទាំងអស់' ? 'ប្រភេទ (ទាំងអស់)' : s,
                                style: GoogleFonts.kantumruyPro(
                                  fontSize: 11,
                                  color: const Color(0xff334155),
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (v) {
                            if (v != null) {
                              statusFilter.value = v;
                              currentPage.value = 1;
                            }
                          },
                        ),
                      ),
                    ),

                    // Sync AD Groups Button
                    ElevatedButton.icon(
                      onPressed: () async {
                        await controller.syncGroupsFromKeycloak();
                      },
                      icon: const Icon(
                        Icons.sync_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: Text(
                        'ធ្វើសមកាលកម្មក្រុម AD',
                        style: GoogleFonts.kantumruyPro(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),

                    // Add Unit Primary Button
                    ElevatedButton.icon(
                      onPressed: () =>
                          Get.to(() => const SuperAdminCreateGroupView()),
                      icon: const Icon(
                        Icons.add_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      label: Text(
                        'បន្ថែមអង្គភាពថ្មី',
                        style: GoogleFonts.kantumruyPro(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xffF59E0B),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                );

                if (isStackControls) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      titleWidget,
                      const SizedBox(height: 12),
                      controlsWidget,
                    ],
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    titleWidget,
                    const SizedBox(width: 16),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: controlsWidget,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const Divider(height: 1, color: Color(0xffE2E8F0)),

          // Table Header
          Container(
            color: const Color(0xffF8FAFC),
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 32,
                  child: Text(
                    'ល.រ',
                    style: GoogleFonts.kantumruyPro(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xff64748B),
                    ),
                  ),
                ),
                Expanded(
                  flex: 5,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4, right: 8),
                    child: Text(
                      'ឈ្មោះក្រុម (អង្គភាព)',
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xff64748B),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.center,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'អ្នកប្រើ',
                        style: GoogleFonts.kantumruyPro(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xff64748B),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'ស្ថានភាព',
                        style: GoogleFonts.kantumruyPro(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xff64748B),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xffE2E8F0)),

          // Table Rows
          if (controller.isLoading.value && filteredGroups.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xffF59E0B),
                ),
              ),
            )
          else if (pagedGroups.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.folder_open_rounded,
                      size: 40,
                      color: Color(0xff94A3B8),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'មិនមានអង្គភាពត្រូវបង្ហាញទេ',
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 13,
                        color: const Color(0xff64748B),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pagedGroups.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                color: Color(0xffF1F5F9),
              ),
              itemBuilder: (context, index) {
                final group = pagedGroups[index];
                final rowNumber = startIdx + index;
                return _buildTableRowItem(group, rowNumber);
              },
            ),

            const Divider(height: 1, color: Color(0xffE2E8F0)),

          // Footer Pagination
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bool isNarrow = constraints.maxWidth < 600;

                Widget infoText = Text(
                  'បង្ហាញ $startIdx ដល់ $endIdx នៃ ${filteredGroups.length} លទ្ធផល',
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 11,
                    color: const Color(0xff64748B),
                  ),
                );

                Widget paginationControls = FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: isNarrow
                      ? Alignment.center
                      : Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Previous button
                      IconButton(
                        icon: const Icon(Icons.chevron_left_rounded, size: 20),
                        onPressed: currentPage.value > 1
                            ? () => currentPage.value--
                            : null,
                        color: const Color(0xff64748B),
                        disabledColor: const Color(0xffCBD5E1),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(6),
                      ),
                      const SizedBox(width: 4),

                      // Page Buttons (dynamic sliding window e.g. 1-5, 3-7, 5-9)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: _getVisiblePages(
                          currentPage.value,
                          totalPages,
                        ).map((pageNum) {
                          final isSelected = currentPage.value == pageNum;
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            child: InkWell(
                              onTap: () => currentPage.value = pageNum,
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? const Color(0xffF59E0B)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected
                                        ? const Color(0xffF59E0B)
                                        : const Color(0xffE2E8F0),
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  '$pageNum',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : const Color(0xff475569),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(width: 4),

                      // Next button
                      IconButton(
                        icon: const Icon(Icons.chevron_right_rounded, size: 20),
                        onPressed: currentPage.value < totalPages
                            ? () => currentPage.value++
                            : null,
                        color: const Color(0xff64748B),
                        disabledColor: const Color(0xffCBD5E1),
                        constraints: const BoxConstraints(),
                        padding: const EdgeInsets.all(6),
                      ),

                      const SizedBox(width: 8),

                      // Items per page dropdown
                      Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xffE2E8F0)),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<int>(
                            isDense: true,
                            value: itemsPerPage.value,
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 16,
                              color: Color(0xff64748B),
                            ),
                            items: [10, 25, 50].map((count) {
                              return DropdownMenuItem(
                                value: count,
                                child: Text(
                                  '$count / page',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: const Color(0xff475569),
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                itemsPerPage.value = val;
                                currentPage.value = 1;
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );

                if (isNarrow) {
                  return Column(
                    children: [
                      infoText,
                      const SizedBox(height: 12),
                      paginationControls,
                    ],
                  );
                }

                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    infoText,
                    Flexible(child: paginationControls),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRowItem(Map<String, dynamic> group, int rowNumber) {
    final String mainTitle = _getGroupMainTitle(group);
    final String subTitle = _getGroupSubtitle(group);
    final int memberCount = _getMemberCount(group);
    final String status = (group['status'] ?? 'ACTIVE')
        .toString()
        .toUpperCase();
    final bool isActive = status == 'ACTIVE';

    return InkWell(
      onTap: () => _showViewGroupDialog(group),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            // Index column
            SizedBox(
              width: 32,
              child: Text(
                '$rowNumber',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xff475569),
                ),
              ),
            ),

            // Group Icon & Name column
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.only(left: 4, right: 8),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xff2563EB),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(
                        Icons.people_outline_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            mainTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xff0F172A),
                            ),
                          ),
                          if (subTitle.isNotEmpty) ...[
                            const SizedBox(height: 1),
                            Text(
                              subTitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.kantumruyPro(
                                fontSize: 10,
                                color: const Color(0xff64748B),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Member Count column
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.center,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xffE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.person_outline_rounded,
                          size: 13,
                          color: Color(0xff475569),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$memberCount',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xff1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Status column
            Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerRight,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xffECFDF5)
                          : const Color(0xffFEF2F2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xff10B981)
                                : const Color(0xffEF4444),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isActive ? "ដំណើរការ" : "ផ្អាក",
                          style: GoogleFonts.kantumruyPro(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isActive
                                ? const Color(0xff059669)
                                : const Color(0xffDC2626),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showViewGroupDialog(Map<String, dynamic> group) {
    final String name = (group['name'] ?? 'Group').toString();
    final String code = (group['sublabel'] ?? group['code'] ?? name).toString();
    final int count = _getMemberCount(group);
    final String status = (group['status'] ?? 'ACTIVE')
        .toString()
        .toUpperCase();
    final bool isActive = status == 'ACTIVE';

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xff2563EB),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.people_alt_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.kantumruyPro(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff0F172A),
                          ),
                        ),
                        Text(
                          'កូដអង្គភាព: $code',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xff64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Get.back(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.group_outlined,
                      size: 16,
                      color: Color(0xff64748B),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'សមាជិកសរុប:',
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 13,
                        color: const Color(0xff64748B),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$count នាក់',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xff0F172A),
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xffECFDF5)
                        : const Color(0xffFEE2E2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xffA7F3D0)
                          : const Color(0xffFECACA),
                    ),
                  ),
                  child: Text(
                    isActive ? "• ដំណើរការ" : "• ផ្អាក",
                    style: GoogleFonts.kantumruyPro(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isActive
                          ? const Color(0xff047857)
                          : const Color(0xffB91C1C),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Get.back();
                      _showEditGroupDialog(group);
                    },
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: Text(
                      'កែប្រែក្រុម (អង្គភាព)',
                      style: GoogleFonts.kantumruyPro(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xffE2E8F0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.back();
                      _showGroupDetailsModalDialog(group);
                    },
                    icon: const Icon(
                      Icons.edit_note_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    label: Text(
                      'មើលព័ត៌មានលម្អិត',
                      style: GoogleFonts.kantumruyPro(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff2563EB),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditGroupDialog(Map<String, dynamic> group) {
    Get.to(() => SuperAdminEditGroupView(group: group));
  }

  String _getGroupDescriptionKh(Map<String, dynamic> group) {
    // 1. If API provides a description, use it directly
    final apiDesc = group['description'] ?? group['desc'] ?? group['details'];
    if (apiDesc != null && apiDesc.toString().trim().isNotEmpty) {
      return apiDesc.toString();
    }

    // 2. Auto-generate Khmer description from group name/code
    final String name = (group['name'] ?? group['groupName'] ?? '')
        .toString()
        .trim();
    final String code = (group['sublabel'] ?? group['code'] ?? '')
        .toString()
        .trim()
        .toUpperCase();

    // Khmer department name mapping
    const Map<String, String> deptMap = {
      'GDDTM': 'អគ្គនាយកដ្ឋានបច្ចេកវិទ្យាឌីជីថល និងផ្សព្វផ្សាយអប់រំ',
      'GDI': 'នាយកដ្ឋានហេដ្ឋារចនាសម្ព័ន្ធឌីជីថល',
      'GDP': 'នាយកដ្ឋានគោលនយោបាយឌីជីថល',
      'GI': 'នាយកដ្ឋានពត៌មានវិទ្យា',
      'GIA': 'នាយកដ្ឋានរដ្ឋបាលទូទៅ',
      'GID': 'នាយកដ្ឋានអភិវឌ្ឍន៍ឌីជីថល',
      'GLF': 'នាយកដ្ឋានច្បាប់ និងហិរញ្ញវត្ថុ',
      'GNP': 'នាយកដ្ឋានផែនការជាតិ',
      'GS': 'នាយកដ្ឋានសេវាកម្មទូទៅ',
      'LC': 'គណៈកម្មាធិការនីតិកម្ម',
      'PAC': 'គណៈកម្មាធិការសវនកម្ម',
    };

    // Extract the department prefix from the code (e.g., GDDTM_ADMIN -> GDDTM)
    String prefix = '';
    for (final key in deptMap.keys) {
      if (code.startsWith(key) || name.toUpperCase().startsWith(key)) {
        prefix = key;
        break;
      }
    }

    final String deptNameKh = deptMap[prefix] ?? 'ប្រព័ន្ធគ្រប់គ្រង';

    // Determine if Admin or User group
    final bool isAdmin = code.contains('ADMIN') ||
        name.toLowerCase().contains('admin');

    if (isAdmin) {
      return 'ក្រុមអ្នកគ្រប់គ្រងសម្រាប់ $deptNameKh';
    } else {
      return 'ក្រុមអ្នកប្រើប្រាស់សម្រាប់ $deptNameKh';
    }
  }

  List<Map<String, dynamic>> _getGroupUsers(Map<String, dynamic> group) {
    final rawName =
        (group['name'] ?? group['groupName'] ?? '').toString().trim();
    final rawCode =
        (group['sublabel'] ?? group['code'] ?? '').toString().trim();
    final rawId = (group['id'] ?? '').toString().trim();

    String normalize(String s) {
      String res = s.trim().toLowerCase();
      if (res.startsWith('/')) res = res.substring(1);
      return res.replaceAll('/', '-');
    }

    final normName = normalize(rawName);
    final normCode = normalize(rawCode);
    final normId = normalize(rawId);

    final Set<String> targetKeys = {
      if (rawName.isNotEmpty) rawName.toLowerCase(),
      if (rawCode.isNotEmpty) rawCode.toLowerCase(),
      if (normName.isNotEmpty) normName,
      if (normCode.isNotEmpty) normCode,
      if (normId.isNotEmpty) normId,
    };

    final List<Map<String, dynamic>> matchedUsers = [];
    final Set<String> matchedIds = {};

    // 1. User IDs from controller.userGroupsMap (fetched from /api/mobile/admin/portal-groups/user-groups)
    final Set<String> assignedUserIds = {};
    for (var entry in controller.userGroupsMap.entries) {
      final k = entry.key.trim().toLowerCase();
      final nk = normalize(k);
      if (targetKeys.contains(k) || targetKeys.contains(nk)) {
        assignedUserIds.addAll(entry.value);
      }
    }

    // 2. Scan controller.usersList
    for (var u in controller.usersList) {
      final String uid = (u['id'] ?? u['keycloakUserId'] ?? u['username'] ?? '')
          .toString()
          .trim();
      if (uid.isEmpty) continue;

      bool isMatch = assignedUserIds.contains(uid);

      if (!isMatch) {
        final List? userGroups =
            u['groups'] ?? u['userGroups'] ?? u['portalGroups'];
        if (userGroups != null) {
          for (var g in userGroups) {
            String gStr = '';
            if (g is String) {
              gStr = g;
            } else if (g is Map) {
              gStr = (g['code'] ?? g['groupCode'] ?? g['name'] ?? '')
                  .toString();
            }
            if (gStr.isNotEmpty) {
              final gLow = gStr.trim().toLowerCase();
              final gNorm = normalize(gStr);
              if (targetKeys.contains(gLow) || targetKeys.contains(gNorm)) {
                isMatch = true;
                break;
              }
            }
          }
        }
      }

      if (!isMatch) {
        final List? empInfos = u['employmentInfos'];
        if (empInfos != null) {
          final bool isBureauGroup = normCode.contains('-b') ||
              normName.contains('-b') ||
              normCode.contains('/b') ||
              normName.contains('/b');
          final bool isDeptGroup = !isBureauGroup &&
              (normCode.contains('-n') ||
                  normName.contains('-n') ||
                  normCode.contains('/n') ||
                  normName.contains('/n'));
          final bool isGenDeptGroup = !isBureauGroup && !isDeptGroup;

          for (var emp in empInfos) {
            if (emp is Map) {
              final bCode = normalize((emp['bureauCode'] ?? '').toString());
              final dCode = normalize((emp['departmentCode'] ?? '').toString());
              final gCode =
                  normalize((emp['generalDepartmentCode'] ?? '').toString());

              if (isBureauGroup && bCode.isNotEmpty) {
                if (targetKeys.contains(bCode) ||
                    normCode == bCode ||
                    normName == bCode) {
                  isMatch = true;
                  break;
                }
              } else if (isDeptGroup && dCode.isNotEmpty) {
                if (targetKeys.contains(dCode) ||
                    normCode == dCode ||
                    normName == dCode) {
                  isMatch = true;
                  break;
                }
              } else if (isGenDeptGroup && gCode.isNotEmpty) {
                if (targetKeys.contains(gCode) ||
                    normCode == gCode ||
                    normName == gCode) {
                  isMatch = true;
                  break;
                }
              }
            }
          }
        }
      }

      if (isMatch && !matchedIds.contains(uid)) {
        matchedIds.add(uid);
        matchedUsers.add(u);
      }
    }

    // 3. Check group['users'] from API if directly attached
    if (group['users'] is List) {
      for (var u in group['users']) {
        if (u is Map<String, dynamic>) {
          final String uid =
              (u['id'] ?? u['keycloakUserId'] ?? u['username'] ?? '')
                  .toString()
                  .trim();
          if (!matchedIds.contains(uid)) {
            matchedIds.add(uid);
            matchedUsers.add(u);
          }
        } else if (u is String && !matchedIds.contains(u)) {
          matchedIds.add(u);
          matchedUsers.add({'username': u, 'name': u});
        }
      }
    }

    return matchedUsers;
  }

  List<String> _getGroupRoles(Map<String, dynamic> group) {
    final rolesData = _getGroupRolesData(group);
    return rolesData
        .map((r) => (r['name'] ?? r['code'] ?? '').toString())
        .toList();
  }

  List<Map<String, dynamic>> _getGroupRolesData(Map<String, dynamic> group) {
    if (group['roles'] != null && group['roles'] is List) {
      final rawRoles = group['roles'] as List;
      if (rawRoles.isNotEmpty) {
        if (rawRoles.first is Map) {
          return rawRoles
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
        }
        final List<Map<String, dynamic>> matchedFromRaw = [];
        for (final item in rawRoles) {
          final str = item.toString().toUpperCase();
          final found = controller.rolesList.firstWhereOrNull(
            (r) {
              final rCode =
                  (r['code'] ?? r['name'] ?? '').toString().toUpperCase();
              final rName = (r['name'] ?? '').toString().toUpperCase();
              return rCode == str || rName == str;
            },
          );
          if (found != null) {
            matchedFromRaw.add(Map<String, dynamic>.from(found));
          } else {
            matchedFromRaw.add({
              'name': item.toString(),
              'code': item.toString().toUpperCase(),
              'status': 'ACTIVE',
            });
          }
        }
        if (matchedFromRaw.isNotEmpty) return matchedFromRaw;
      }
    }
    return [];
  }

  List<dynamic> _getGroupApps(Map<String, dynamic> group) {
    if (group['applications'] != null && group['applications'] is List) {
      return group['applications'] as List;
    }
    if (group['apps'] != null && group['apps'] is List) {
      return group['apps'] as List;
    }

    final rawCode =
        (group['sublabel'] ?? group['code'] ?? group['name'] ?? '')
            .toString()
            .trim()
            .toUpperCase();
    final rawName =
        (group['name'] ?? group['groupName'] ?? '').toString().trim().toUpperCase();

    final matchedApps = controller.appsList.where((app) {
      final List rules = app['accessRules'] is List ? app['accessRules'] : [];
      for (final r in rules) {
        if (r is Map) {
          final rVal = (r['ruleValue'] ??
                  r['rule_value'] ??
                  r['target'] ??
                  r['value'] ??
                  '')
              .toString()
              .trim()
              .toUpperCase();
          if (rVal.isNotEmpty && (rVal == rawCode || rVal == rawName)) {
            return true;
          }
        }
      }
      return false;
    }).map((app) => app['titleKh'] ?? app['titleEn'] ?? app['name'] ?? 'App').toList();

    return matchedApps;
  }

  void _showGroupDetailsModalDialog(Map<String, dynamic> group) {
    final isRootExpanded = true.obs;
    final isRolesExpanded = true.obs;
    final isAppsExpanded = true.obs;
    final isUsersExpanded = true.obs;

    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(
          maxHeight: Get.height * 0.90,
          maxWidth: Get.width > 600 ? 560 : Get.width,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.all(20.0),
        child: Obx(() {
          final String groupName =
              (group['name'] ?? group['groupName'] ?? 'GDDTM Admins')
                  .toString();
          final String description = _getGroupDescriptionKh(group);
          final String statusStr =
              (group['status'] ?? 'ACTIVE').toString().toUpperCase();
          final bool isActive = statusStr == 'ACTIVE';

          final List<Map<String, dynamic>> users = _getGroupUsers(group);
          final int memberCount =
              users.isNotEmpty ? users.length : _getMemberCount(group);
          final List<String> roles = _getGroupRoles(group);
          final List<Map<String, dynamic>> rolesData =
              _getGroupRolesData(group);
          final List<dynamic> apps = _getGroupApps(group);

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top drag indicator handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xffCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // 1. Header Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xff2563EB),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    const Color(0xff2563EB).withOpacity(0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.people_alt_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ព័ត៌មានលម្អិតអង្គភាព',
                                style: GoogleFonts.kantumruyPro(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xff64748B),
                                ),
                              ),
                              Text(
                                groupName,
                                style: GoogleFonts.kantumruyPro(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xff0F172A),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => Get.back(),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xffE2E8F0)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: Color(0xff64748B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. Scrollable Body Content
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Stat Metric Cards Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricStatCard(
                              icon: Icons.person_outline_rounded,
                              iconBgColor: const Color(0xffEFF6FF),
                              iconColor: const Color(0xff2563EB),
                              label: 'អ្នកប្រើ',
                              value: '$memberCount',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildMetricStatCard(
                              icon: Icons.shield_outlined,
                              iconBgColor: const Color(0xffF3E8FF),
                              iconColor: const Color(0xff8B5CF6),
                              label: 'តួនាទី',
                              value: '${roles.length}',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildMetricStatCard(
                              icon: Icons.grid_view_rounded,
                              iconBgColor: const Color(0xffFEF3C7),
                              iconColor: const Color(0xffF59E0B),
                              label: 'កម្មវិធី',
                              value: '${apps.length}',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Description Card (Full Width)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xffFAFAFA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xffF1F5F9)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'ការពិពណ៌នា',
                                  style: GoogleFonts.kantumruyPro(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xff94A3B8),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isActive
                                        ? const Color(0xffECFDF5)
                                        : const Color(0xffFEE2E2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isActive
                                          ? const Color(0xffA7F3D0)
                                          : const Color(0xffFECACA),
                                    ),
                                  ),
                                  child: Text(
                                    isActive ? '• ដំណើរការ' : '• ផ្អាក',
                                    style: GoogleFonts.kantumruyPro(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isActive
                                          ? const Color(0xff047857)
                                          : const Color(0xffB91C1C),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              description,
                              style: GoogleFonts.kantumruyPro(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xff0F172A),
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Tree Structure ("រចនាសម្ព័ន្ធក្រុម") Section
                      _buildSectionContainer(
                        title: 'រចនាសម្ព័ន្ធក្រុម',
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xffFAFAFA),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xffF1F5F9)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Root Node (Clickable)
                              InkWell(
                                onTap: () => isRootExpanded.toggle(),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xffEFF6FF),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: const Color(0xffBFDBFE)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        isRootExpanded.value
                                            ? Icons.keyboard_arrow_down_rounded
                                            : Icons.keyboard_arrow_right_rounded,
                                        size: 18,
                                        color: const Color(0xff2563EB),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.people_alt_outlined,
                                          size: 16, color: Color(0xff2563EB)),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          groupName,
                                          style: GoogleFonts.kantumruyPro(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xff1E40AF),
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 20,
                                        height: 20,
                                        alignment: Alignment.center,
                                        decoration: const BoxDecoration(
                                          color: Color(0xff2563EB),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          '${roles.length + apps.length + users.length}',
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Tree Sub-nodes (Renders when root expanded)
                              if (isRootExpanded.value)
                                Padding(
                                  padding: const EdgeInsets.only(left: 12),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Category 1: Roles
                                      _buildTreeCategoryNode(
                                        icon: Icons.shield_outlined,
                                        iconColor: const Color(0xff8B5CF6),
                                        title: 'តួនាទី',
                                        count: roles.length,
                                        isExpanded: isRolesExpanded.value,
                                        onTap: () => isRolesExpanded.toggle(),
                                      ),
                                      if (isRolesExpanded.value)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              left: 24, top: 4, bottom: 8),
                                          child: Column(
                                            children: roles
                                                .map((roleName) =>
                                                    _buildTreeLeafItem(
                                                      icon: Icons
                                                          .verified_user_outlined,
                                                      title: roleName,
                                                    ))
                                                .toList(),
                                          ),
                                        ),

                                      // Category 2: Applications
                                      _buildTreeCategoryNode(
                                        icon: Icons.grid_view_rounded,
                                        iconColor: const Color(0xffF59E0B),
                                        title: 'កម្មវិធី',
                                        count: apps.length,
                                        isExpanded: isAppsExpanded.value,
                                        onTap: () => isAppsExpanded.toggle(),
                                      ),
                                      if (isAppsExpanded.value && apps.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              left: 24, top: 4, bottom: 8),
                                          child: Column(
                                            children: apps
                                                .map((appName) =>
                                                    _buildTreeLeafItem(
                                                      icon: Icons
                                                          .grid_view_rounded,
                                                      title: appName.toString(),
                                                    ))
                                                .toList(),
                                          ),
                                        ),
                                      const SizedBox(height: 4),

                                      // Category 3: Group Users
                                      _buildTreeCategoryNode(
                                        icon: Icons.person_outline_rounded,
                                        iconColor: const Color(0xff2563EB),
                                        title: 'អ្នកប្រើប្រាស់ក្នុងក្រុម',
                                        count: users.length,
                                        isExpanded: isUsersExpanded.value,
                                        onTap: () => isUsersExpanded.toggle(),
                                      ),
                                      if (isUsersExpanded.value)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              left: 24, top: 4),
                                          child: Column(
                                            children: users
                                                .map((u) => _buildTreeLeafItem(
                                                      icon: Icons
                                                          .person_outline_rounded,
                                                      title: (u['username'] ??
                                                              u['name'] ??
                                                              'user')
                                                          .toString(),
                                                    ))
                                                .toList(),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      // Section: Roles (តួនាទី) - Mobile App Card Design (matching Image 1)
                      _buildSectionContainer(
                        title: 'តួនាទី',
                        child: Column(
                          children: rolesData.asMap().entries.map((entry) {
                            final int idx = entry.key;
                            final Map<String, dynamic> roleData = entry.value;
                            final String roleName =
                                (roleData['name'] ?? roleData['code'] ?? 'តួនាទី')
                                    .toString();
                            final String roleCode =
                                (roleData['code'] ?? '').toString();
                            final String roleStatus =
                                (roleData['status'] ?? 'ACTIVE')
                                    .toString()
                                    .toUpperCase();
                            final bool roleActive = roleStatus == 'ACTIVE';
                            final Color iconColor = roleData['icon_color'] ??
                                (roleName.contains('Super')
                                    ? const Color(0xff10B981)
                                    : roleName.contains('Admin')
                                        ? const Color(0xff2563EB)
                                        : const Color(0xff7C3AED));

                            final int permsCount =
                                (roleData['perms_count'] ?? 0) is int
                                    ? roleData['perms_count'] as int
                                    : int.tryParse(
                                            roleData['perms_count'].toString()) ??
                                        0;
                            final int groupsCount =
                                (roleData['groups_count'] ?? 0) is int
                                    ? roleData['groups_count'] as int
                                    : int.tryParse(
                                            roleData['groups_count'].toString()) ??
                                        0;
                            final int usersCount =
                                (roleData['users_count'] ?? 0) is int
                                    ? roleData['users_count'] as int
                                    : int.tryParse(
                                            roleData['users_count'].toString()) ??
                                        0;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 12, horizontal: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border:
                                    Border.all(color: const Color(0xffE2E8F0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Top row: Index, Icon, Name + Code, Status Badge
                                  Row(
                                    children: [
                                      Text(
                                        '${idx + 1}. ',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          color: const Color(0xff94A3B8),
                                        ),
                                      ),
                                      Container(
                                        width: 30,
                                        height: 30,
                                        decoration: BoxDecoration(
                                          color: iconColor,
                                          borderRadius:
                                              BorderRadius.circular(6),
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
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              roleName,
                                              style: GoogleFonts.kantumruyPro(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 13,
                                                color: const Color(0xff1E293B),
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (roleCode.isNotEmpty)
                                              Text(
                                                roleCode,
                                                style: GoogleFonts.poppins(
                                                  fontSize: 9,
                                                  color: const Color(0xff94A3B8),
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: roleActive
                                              ? const Color(0xffE6FFFA)
                                              : const Color(0xffFFF5F5),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          roleActive ? '• ដំណើរការ' : '• ផ្អាក',
                                          style: GoogleFonts.kantumruyPro(
                                            color: roleActive
                                                ? const Color(0xff319795)
                                                : const Color(0xffE53E3E),
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),

                                  // Bottom row: Stat Badges + Action Buttons
                                  Row(
                                    children: [
                                      // Badge 1: Groups
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: const Color(0xffE2E8F0)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.people_alt_outlined,
                                              size: 13,
                                              color: Color(0xff475569),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '$groupsCount',
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xff334155),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 6),

                                      // Badge 2: Permissions
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: const Color(0xffE2E8F0)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.key_outlined,
                                              size: 13,
                                              color: Color(0xff475569),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '$permsCount',
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xff334155),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 6),

                                      // Badge 3: Users
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: const Color(0xffE2E8F0)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.person_outline_rounded,
                                              size: 13,
                                              color: Color(0xff475569),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              '$usersCount',
                                              style: GoogleFonts.poppins(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: const Color(0xff334155),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Spacer(),

                                      // Action Buttons: View, Edit
                                      InkWell(
                                        onTap: () {
                                          Get.back();
                                          showSuperAdminViewRoleModal(
                                              context, roleData);
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                                color: const Color(0xffE2E8F0)),
                                          ),
                                          child: const Icon(
                                            Icons.visibility_outlined,
                                            size: 16,
                                            color: Color(0xff64748B),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      InkWell(
                                        onTap: () {
                                          Get.back();
                                          Get.to(() => SuperAdminEditRoleView(
                                              role: roleData));
                                        },
                                        borderRadius: BorderRadius.circular(8),
                                        child: Container(
                                          width: 32,
                                          height: 32,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            border: Border.all(
                                                color: const Color(0xffE2E8F0)),
                                          ),
                                          child: const Icon(
                                            Icons.edit_outlined,
                                            size: 16,
                                            color: Color(0xff64748B),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Section: Applications (កម្មវិធី)
                      _buildSectionContainer(
                        title: 'កម្មវិធី',
                        child: apps.isEmpty
                            ? Text(
                                '—',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: const Color(0xff94A3B8),
                                ),
                              )
                            : Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: apps
                                    .map(
                                      (app) => Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: const Color(0xffFEF3C7),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                              color: const Color(0xffFDE68A)),
                                        ),
                                        child: Text(
                                          app.toString(),
                                          style: GoogleFonts.kantumruyPro(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: const Color(0xffD97706),
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                      ),
                      const SizedBox(height: 14),

                      // Section: Group Users (អ្នកប្រើប្រាស់ក្នុងក្រុម)
                      _buildSectionContainer(
                        title: 'អ្នកប្រើប្រាស់ក្នុងក្រុម',
                        child: users.isEmpty
                            ? Text(
                                '—',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: const Color(0xff94A3B8),
                                ),
                              )
                            : Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: users.map((u) {
                                  final uname = (u['username'] ??
                                          u['name'] ??
                                          'bin.sovanvong')
                                      .toString();
                                  return Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: const Color(0xffF8FAFC),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: const Color(0xffF1F5F9)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 34,
                                          height: 34,
                                          decoration: const BoxDecoration(
                                            color: Color(0xffEFF6FF),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.person_outline_rounded,
                                            size: 18,
                                            color: Color(0xff2563EB),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              uname,
                                              style: GoogleFonts.kantumruyPro(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: const Color(0xff0F172A),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Bottom Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Get.back(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xffEAB308),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'បិទ',
                    style: GoogleFonts.kantumruyPro(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        }),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }

  Widget _buildTreeCategoryNode({
    required IconData icon,
    required Color iconColor,
    required String title,
    required int count,
    bool isExpanded = true,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            Icon(
              isExpanded
                  ? Icons.keyboard_arrow_down_rounded
                  : Icons.keyboard_arrow_right_rounded,
              size: 18,
              color: const Color(0xff64748B),
            ),
            const SizedBox(width: 4),
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Text(
              title,
              style: GoogleFonts.kantumruyPro(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: const Color(0xff334155),
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xffE2E8F0)),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff64748B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTreeLeafItem({required IconData icon, required String title}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xff94A3B8)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: const Color(0xff64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricStatCard({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.kantumruyPro(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xff64748B),
                ),
              ),
              Text(
                value,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff0F172A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionContainer({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.kantumruyPro(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xff0F172A),
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
