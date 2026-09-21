import 'package:core_portal/screens/super_admin/super_admin_group_list_view.dart';
import 'package:core_portal/screens/super_admin/super_admin_role_list_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core_portal/screens/super_admin/super_admin_controller.dart';
import 'package:core_portal/widgets/custom_snackbar.dart';
import 'package:core_portal/widgets/logout_dialog.dart';
import 'package:core_portal/routes/page_route.dart';
import 'package:file_picker/file_picker.dart';
import 'package:core_portal/screens/super_admin/super_admin_edit_user_groups_view.dart';
import 'package:core_portal/screens/super_admin/super_admin_reports_view.dart';
import 'package:core_portal/screens/super_admin/super_admin_account_settings_view.dart';
import 'package:core_portal/core/api/services/auth_service.dart';
import 'package:core_portal/widgets/app_icon.dart';
import 'package:get_storage/get_storage.dart';

void showCustomSnackbar({
  String? title,
  required String message,
  bool isSuccess = true,
}) {
  if (isSuccess) {
    CustomSnackbar.showSuccess(title: title, message: message);
  } else {
    CustomSnackbar.showError(title: title, message: message);
  }
}

class SuperAdminView extends GetView<SuperAdminController> {
  const SuperAdminView({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildDashboardHome(context),
      const SuperAdminAppsListView(),
      _buildUsersTab(context),
      _buildAdminSettingsTab(context),
    ];

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      body: Obx(() => pages[controller.currentIndex.value]),
      bottomNavigationBar: Obx(
        () => Container(
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(35),
            border: Border.all(
              color: const Color(0xffD4AF37).withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xffD4AF37).withOpacity(0.08),
                blurRadius: 25,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(0, Icons.dashboard_rounded, "ផ្ទាំងគ្រប់គ្រង"),
              _buildNavItem(1, Icons.grid_view_rounded, "កម្មវិធី"),
              _buildNavItem(2, Icons.people_alt_rounded, "អ្នកប្រើប្រាស់"),
              _buildNavItem(3, Icons.settings_rounded, "ការកំណត់"),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = controller.currentIndex.value == index;

    return GestureDetector(
      onTap: () => controller.changeTab(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEFF4FB) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF163774).withOpacity(0.3)
                : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF163774)
                  : Colors.grey.shade500,
              size: 20,
            ),
            const SizedBox(width: 6),
            AnimatedCrossFade(
              firstChild: Text(
                label,
                style: GoogleFonts.kantumruyPro(
                  color: const Color(0xFF163774),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.1,
                ),
              ),
              secondChild: const SizedBox.shrink(),
              crossFadeState: isSelected
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              duration: const Duration(milliseconds: 200),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardHome(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          "ផ្ទាំងគ្រប់គ្រង Admin",
          style: GoogleFonts.kantumruyPro(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: const Color(0xff0F172A),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.logout_rounded,
              color: Color(0xff64748B),
              size: 22,
            ),
            onPressed: () => _confirmLogout(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: controller.refreshAllData,
        color: const Color(0xFF163774),
        child: Obx(() {
          if (controller.isLoading.value && controller.appsList.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF163774)),
              ),
            );
          }

          return Stack(
            children: [
              SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeCard(),
                    const SizedBox(height: 20),
                    _buildStatsGrid(),
                    const SizedBox(height: 20),
                    _buildUsersByGroupChart(),
                    const SizedBox(height: 20),
                    _buildAppsByGroupChart(),
                    const SizedBox(height: 20),
                    _buildAppsSection(context),
                    const SizedBox(height: 20),
                    _buildRecentAnnouncementsSection(),
                    const SizedBox(height: 20),
                    _buildAuditLogsSection(),
                    const SizedBox(height: 20),
                    _buildQuickAccessSection(context),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
              if (controller.isBackingUp.value) _buildBackupOverlay(),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF163774), Color(0xFF102652)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF163774).withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "សួស្តី, អភិបាលប្រព័ន្ធ!",
                style: GoogleFonts.kantumruyPro(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Text(
                  "Online",
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            "សូមស្វាគមន៍មកកាន់ប្រព័ន្ធគ្រប់គ្រងសេវាព័ត៌មានវិទ្យា ក្រសួងមហាផ្ទៃ។",
            style: GoogleFonts.kantumruyPro(
              color: Colors.white.withOpacity(0.85),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.0,
      children: [
        _buildStatCard(
          "អ្នកប្រើប្រាស់សរុប",
          controller.totalUsers.value.toString(),
          Icons.person_rounded,
          const Color(0xffF5F3FF),
          const Color(0xff7C3AED),
        ),
        _buildStatCard(
          "ក្រុមសរុប",
          controller.groupList.length.toString(),
          Icons.groups_rounded,
          const Color(0xffECFDF5),
          const Color(0xff10B981),
        ),
        _buildStatCard(
          "កម្មវិធីសរុប",
          controller.totalApps.value.toString(),
          Icons.grid_view_rounded,
          const Color(0xffEFF6FF),
          const Color(0xff2563EB),
        ),
        /*
        _buildStatCard(
          "សេចក្តីប្រកាសសរុប",
          controller.announcementsCount.value.toString(),
          Icons.campaign_rounded,
          const Color(0xffFEF3C7),
          const Color(0xffD97706),
        ),
        */
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color bgIconColor,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: bgIconColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.grey[300],
                size: 10,
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getGroupDisplayName(Map<String, dynamic> g) {
    final String khmerName =
        (g['nameKh'] ??
                g['name_kh'] ??
                g['displayNameKh'] ??
                g['groupNameKh'] ??
                '')
            .toString()
            .trim();
    if (khmerName.isNotEmpty) return khmerName;

    final String name = (g['name'] ?? '').toString().trim();
    final String code = (g['sublabel'] ?? g['code'] ?? '').toString().trim();

    for (var u in controller.usersList) {
      final List? empInfos = u['employmentInfos'];
      if (empInfos != null) {
        for (var emp in empInfos) {
          if (emp is Map) {
            final gCode = (emp['generalDepartmentCode'] ?? '')
                .toString()
                .trim();
            final gName =
                (emp['generalDepartmentName'] ??
                        emp['generalDepartmentNameKh'] ??
                        '')
                    .toString()
                    .trim();
            final dCode = (emp['departmentCode'] ?? '').toString().trim();
            final dName =
                (emp['departmentName'] ?? emp['departmentNameKh'] ?? '')
                    .toString()
                    .trim();
            final bCode = (emp['bureauCode'] ?? '').toString().trim();
            final bName = (emp['bureauName'] ?? emp['bureauNameKh'] ?? '')
                .toString()
                .trim();

            if (code.isNotEmpty) {
              if (gCode.toLowerCase() == code.toLowerCase() &&
                  gName.isNotEmpty) {
                return gName;
              }
              if (dCode.toLowerCase() == code.toLowerCase() &&
                  dName.isNotEmpty) {
                return dName;
              }
              if (bCode.toLowerCase() == code.toLowerCase() &&
                  bName.isNotEmpty) {
                return bName;
              }
            }
            if (name.isNotEmpty) {
              if (gCode.toLowerCase() == name.toLowerCase() &&
                  gName.isNotEmpty) {
                return gName;
              }
              if (dCode.toLowerCase() == name.toLowerCase() &&
                  dName.isNotEmpty) {
                return dName;
              }
              if (bCode.toLowerCase() == name.toLowerCase() &&
                  bName.isNotEmpty) {
                return bName;
              }
            }
          }
        }
      }
    }

    final Map<String, String> khmerMap = {
      'GDDTM': 'អគ្គនាយកដ្ឋានបច្ចេកវិទ្យាឌីជីថល និងផ្សព្វផ្សាយអប់រំ',
      'GDDTM Admins': 'អគ្គនាយកដ្ឋានបច្ចេកវិទ្យាឌីជីថល (Admin)',
      'GDDTM Users': 'អគ្គនាយកដ្ឋានបច្ចេកវិទ្យាឌីជីថល',
      'GDI': 'អគ្គនាយកដ្ឋានអន្តោប្រវេសន៍',
      'GDI Admins': 'អគ្គនាយកដ្ឋានអន្តោប្រវេសន៍ (Admin)',
      'GDI Users': 'អគ្គនាយកដ្ឋានអន្តោប្រវេសន៍ (User)',
      'GDP': 'អគ្គនាយកដ្ឋានពន្ធនាគារ',
      'GDP Group': 'អគ្គនាយកដ្ឋានពន្ធនាគារ',
      'GDP Admins': 'អគ្គនាយកដ្ឋានពន្ធនាគារ (Admin)',
      'GDP Users': 'អគ្គនាយកដ្ឋានពន្ធនាគារ (User)',
      'GDHR': 'អគ្គនាយកដ្ឋានធនធានមនុស្ស',
      'GDHR Admins': 'អគ្គនាយកដ្ឋានធនធានមនុស្ស (Admin)',
      'GDHR Users': 'អគ្គនាយកដ្ឋានធនធានមនុស្ស (User)',
      'PAC': 'បណ្ឌិត្យសភានគរបាលកម្ពុជា',
      'PAC Admins': 'បណ្ឌិត្យសភានគរបាលកម្ពុជា (Admin)',
      'PAC Users': 'បណ្ឌិត្យសភានគរបាលកម្ពុជា (User)',
      'GI': 'អគ្គាធិការដ្ឋាន',
      'GI Admins': 'អគ្គាធិការដ្ឋាន (Admin)',
      'GI Users': 'អគ្គាធិការដ្ឋាន (User)',
      'GIA': 'អគ្គនាយកដ្ឋានសវនកម្មផ្ទៃក្នុង',
      'GIA Admins': 'អគ្គនាយកដ្ឋានសវនកម្មផ្ទៃក្នុង (Admin)',
      'GIA Users': 'អគ្គនាយកដ្ឋានសវនកម្មផ្ទៃក្នុង (User)',
      'GID': 'អគ្គនាយកដ្ឋានអត្តសញ្ញាណកម្ម',
      'GID Admins': 'អគ្គនាយកដ្ឋានអត្តសញ្ញាណកម្ម (Admin)',
      'GID Users': 'អគ្គនាយកដ្ឋានអត្តសញ្ញាណកម្ម (User)',
      'GLF': 'អគ្គនាយកដ្ឋានភស្តុភារ និងហិរញ្ញវត្ថុ',
      'GLF Admins': 'អគ្គនាយកដ្ឋានភស្តុភារ និងហិរញ្ញវត្ថុ (Admin)',
      'GLF Users': 'អគ្គនាយកដ្ឋានភស្តុភារ និងហិរញ្ញវត្ថុ (User)',
      'GNP': 'អគ្គស្នងការដ្ឋាននគរបាលជាតិ',
      'GNP Admins': 'អគ្គស្នងការដ្ឋាននគរបាលជាតិ (Admin)',
      'GNP Users': 'អគ្គស្នងការដ្ឋាននគរបាលជាតិ (User)',
      'GS': 'អគ្គលេខាធិការដ្ឋាន',
      'GS Admins': 'អគ្គលេខាធិការដ្ឋាន (Admin)',
      'GS Users': 'អគ្គលេខាធិការដ្ឋាន (User)',
      'LC': 'ក្រុមប្រឹក្សានីតិកម្ម',
      'LC Admins': 'ក្រុមប្រឹក្សានីតិកម្ម (Admin)',
      'LC Users': 'ក្រុមប្រឹក្សានីតិកម្ម (User)',
      'GDDTM-N1': 'នាយកដ្ឋានរដ្ឋបាល-សរុប',
      'GDDTM-N2': 'នាយកដ្ឋានបណ្តុះបណ្តាល និងអភិបាលកិច្ចបច្ចេកវិទ្យាឌីជីថល',
      'GDDTM-N4': 'នាយកដ្ឋានហេដ្ឋារចនាសម្ព័ន្ធបច្ចេកវិទ្យាគមនាគមន៍ និងព័ត៌មាន',
      'GDI-N1': 'នាយកដ្ឋានរដ្ឋបាលសរុប (GDI)',
      'GDDTM-N1-B1': 'ការិយាល័យរដ្ឋបាល',
      'GDDTM-N1-B3': 'ការិយាល័យបុគ្គលិក',
      'GDDTM-N1-B4': 'ការិយាល័យភស្តុភារ និងគណនេយ្យ',
      'GDDTM-N2-B6': 'ការិយាល័យអភិបាលកិច្ចបច្ចេកវិទ្យាឌីជីថល',
      'GDDTM-N4-B1': 'ការិយាល័យរដ្ឋបាល-សរុប (N4)',
      'GDDTM-N4-B3': 'ការិយាល័យប្រតិបត្តិការមជ្ឍមណ្ឌលទិន្នន័យ',
    };

    if (khmerMap.containsKey(code)) return khmerMap[code]!;
    if (khmerMap.containsKey(name)) return khmerMap[name]!;

    return name.isNotEmpty ? name : code;
  }

  bool _matchesTarget(
    String tCode,
    String tName,
    String valCode,
    String valName,
  ) {
    var vCode = valCode.toLowerCase().trim();
    var vName = valName.toLowerCase().trim();
    var targetCode = tCode.toLowerCase().trim();
    var targetName = tName.toLowerCase().trim();

    if (vCode.startsWith('/')) vCode = vCode.substring(1);

    if (targetCode.isNotEmpty && vCode.isNotEmpty) {
      if (vCode == targetCode ||
          vCode.startsWith('${targetCode}_') ||
          vCode.startsWith('${targetCode}/')) {
        return true;
      }
    }

    if (targetName.isNotEmpty && vName.isNotEmpty) {
      if (vName == targetName) {
        return true;
      }
    }

    if (targetCode.isNotEmpty && vName.isNotEmpty) {
      if (vName == targetCode) return true;
    }

    return false;
  }

  int _getUserCountForGroup(String name, String code) {
    int count = 0;
    final targetName = name.toLowerCase().trim();
    final targetCode = code.toLowerCase().trim();

    if (targetName.isEmpty && targetCode.isEmpty) return 0;

    for (var u in controller.usersList) {
      bool matched = false;

      // 1. Check employmentInfos
      final List? empInfos = u['employmentInfos'];
      if (empInfos != null && empInfos.isNotEmpty) {
        for (var emp in empInfos) {
          if (emp is Map) {
            final gCode = (emp['generalDepartmentCode'] ?? '')
                .toString()
                .toLowerCase()
                .trim();
            final gName =
                (emp['generalDepartmentName'] ??
                        emp['generalDepartmentNameKh'] ??
                        '')
                    .toString()
                    .toLowerCase()
                    .trim();
            final dCode = (emp['departmentCode'] ?? '')
                .toString()
                .toLowerCase()
                .trim();
            final dName =
                (emp['departmentName'] ?? emp['departmentNameKh'] ?? '')
                    .toString()
                    .toLowerCase()
                    .trim();
            final bCode = (emp['bureauCode'] ?? '')
                .toString()
                .toLowerCase()
                .trim();
            final bName = (emp['bureauName'] ?? emp['bureauNameKh'] ?? '')
                .toString()
                .toLowerCase()
                .trim();

            if (_matchesTarget(targetCode, targetName, gCode, gName) ||
                _matchesTarget(targetCode, targetName, dCode, dName) ||
                _matchesTarget(targetCode, targetName, bCode, bName)) {
              matched = true;
              break;
            }
          }
        }
      }

      // 2. Check portalGroups array
      if (!matched) {
        final List? portalGroups = u['portalGroups'];
        if (portalGroups != null && portalGroups.isNotEmpty) {
          for (var pg in portalGroups) {
            if (pg is Map) {
              final pCode = (pg['groupCode'] ?? pg['code'] ?? '')
                  .toString()
                  .toLowerCase()
                  .trim();
              final pName = (pg['groupName'] ?? pg['name'] ?? '')
                  .toString()
                  .toLowerCase()
                  .trim();
              if (_matchesTarget(targetCode, targetName, pCode, pName)) {
                matched = true;
                break;
              }
            }
          }
        }
      }

      // 3. Check Keycloak Groups list
      if (!matched) {
        final List? userGroups = u['groups'] ?? u['userGroups'];
        if (userGroups != null && userGroups.isNotEmpty) {
          matched = userGroups.any((g) {
            String gStr = '';
            if (g is String) {
              gStr = g.toLowerCase().trim();
            } else if (g is Map) {
              gStr =
                  (g['code'] ??
                          g['groupCode'] ??
                          g['name'] ??
                          g['groupName'] ??
                          '')
                      .toString()
                      .toLowerCase()
                      .trim();
            }
            return _matchesTarget(targetCode, targetName, gStr, gStr);
          });
        }
      }

      if (matched) count++;
    }
    return count;
  }

  Map<String, int> _getGroupUserCounts() {
    final Map<String, int> counts = {};
    final userGroupsMap = controller.userGroupsMap; // groupCode → List<userId>

    for (var g in controller.groupList) {
      final name = g['name']?.toString() ?? '—';
      final code = (g['sublabel'] ?? g['code'] ?? '').toString().trim();

      // ① From API userGroupsMap (/api/mobile/admin/portal-groups/user-groups)
      if (userGroupsMap.isNotEmpty &&
          code.isNotEmpty &&
          userGroupsMap.containsKey(code)) {
        final uids = userGroupsMap[code];
        if (uids != null && uids.isNotEmpty) {
          counts[name] = uids.length;
          continue;
        }
      }

      // ② From group's server-provided users count or users array (/api/mobile/admin/portal-groups)
      final serverUsers = g['users'] ?? g['members'];
      if (serverUsers is List && serverUsers.isNotEmpty) {
        counts[name] = serverUsers.length;
        continue;
      }
      final serverCount =
          g['usersCount'] ??
          g['userCount'] ??
          g['totalUsers'] ??
          g['membersCount'];
      if (serverCount != null) {
        final int c = serverCount is int
            ? serverCount
            : int.tryParse(serverCount.toString()) ?? 0;
        if (c > 0) {
          counts[name] = c;
          continue;
        }
      }

      // ③ Client-side calculation from controller.usersList
      final c = _getUserCountForGroup(name, code);
      if (c > 0) {
        counts[name] = c;
      }
    }
    return counts;
  }

  Map<String, int> _getGroupAppCounts() {
    final Map<String, int> counts = {};
    final groupAppCountMap =
        controller.groupAppCountMap; // groupCode → app count

    for (var g in controller.groupList) {
      final displayName = _getGroupDisplayName(g);
      final code = (g['sublabel'] ?? g['code'] ?? '').toString().trim();

      // ① From group's server-provided applications list (/api/mobile/admin/portal-groups)
      final serverApps =
          g['applications'] ?? g['apps'] ?? g['portalApplications'];
      if (serverApps is List && serverApps.isNotEmpty) {
        counts[displayName] = serverApps.length;
        continue;
      }
      final serverCount =
          g['applicationsCount'] ??
          g['appsCount'] ??
          g['appCount'] ??
          g['totalApps'];
      if (serverCount != null) {
        final int c = serverCount is int
            ? serverCount
            : int.tryParse(serverCount.toString()) ?? 0;
        if (c > 0) {
          counts[displayName] = c;
          continue;
        }
      }

      // ② From access rules map (/api/mobile/admin/portal-app-access-rules)
      if (groupAppCountMap.isNotEmpty &&
          code.isNotEmpty &&
          groupAppCountMap.containsKey(code)) {
        final int c = groupAppCountMap[code] ?? 0;
        if (c > 0) {
          counts[displayName] = c;
          continue;
        }
      }

      // ③ Client-side calculation matching access rules or app groups
      final c = _getAppCountForGroup(g);
      if (c > 0) {
        counts[displayName] = c;
      }
    }
    return counts;
  }

  int _getAppCountForGroup(Map<String, dynamic> g) {
    final sublabel = (g['sublabel'] ?? g['code'] ?? '').toString();
    final groupName = (g['name'] ?? '').toString();
    final id = (g['id'] ?? '').toString();

    final codeTarget = sublabel.toLowerCase().trim();
    final nameTarget = groupName.toLowerCase().trim();
    final idTarget = id.toLowerCase().trim();

    if (codeTarget.isEmpty && nameTarget.isEmpty && idTarget.isEmpty) return 0;

    int count = 0;
    for (var app in controller.appsList) {
      final List accessRules = app['accessRules'] is List
          ? app['accessRules']
          : [];
      final List groups = app['groups'] is List
          ? app['groups']
          : (app['portalGroups'] is List ? app['portalGroups'] : []);
      bool matched = false;

      for (var rule in accessRules) {
        if (rule is Map) {
          final String rVal =
              (rule['ruleValue'] ?? rule['target'] ?? rule['value'] ?? '')
                  .toString()
                  .toLowerCase()
                  .trim();
          if (rVal.isNotEmpty) {
            if ((codeTarget.isNotEmpty && rVal == codeTarget) ||
                (nameTarget.isNotEmpty && rVal == nameTarget) ||
                (idTarget.isNotEmpty && rVal == idTarget)) {
              matched = true;
              break;
            }
          }
        }
      }

      if (!matched && groups.isNotEmpty) {
        for (var grp in groups) {
          final gName =
              (grp is Map
                      ? (grp['code'] ?? grp['name'] ?? grp['id'] ?? '')
                      : grp)
                  .toString()
                  .toLowerCase()
                  .trim();
          if ((codeTarget.isNotEmpty && gName == codeTarget) ||
              (nameTarget.isNotEmpty && gName == nameTarget) ||
              (idTarget.isNotEmpty && gName == idTarget)) {
            matched = true;
            break;
          }
        }
      }

      if (matched) count++;
    }
    return count;
  }

  PopupMenuItem<String> _buildChartFilterMenuItem({
    required BuildContext context,
    required String value,
    required String label,
    required bool isSelected,
  }) {
    return PopupMenuItem<String>(
      value: value,
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.kantumruyPro(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected
                  ? const Color(0xff92400E)
                  : const Color(0xff334155),
            ),
          ),
          if (isSelected)
            const Icon(Icons.check_rounded, size: 16, color: Color(0xffD97706)),
        ],
      ),
    );
  }

  Widget _buildUsersByGroupChart() {
    return Obx(() {
      final counts =
          _getGroupUserCounts(); // inside Obx → reacts to userGroupsMap
      final filter = controller.groupUserChartFilter.value;
      List<Map<String, dynamic>> groups = List.from(controller.groupList);

      if (filter == 'most_users') {
        groups.sort((a, b) {
          final countA = counts[a['name']] ?? 0;
          final countB = counts[b['name']] ?? 0;
          return countB.compareTo(countA);
        });
      } else if (filter == 'least_users') {
        groups.sort((a, b) {
          final countA = counts[a['name']] ?? 0;
          final countB = counts[b['name']] ?? 0;
          return countA.compareTo(countB);
        });
      } else if (filter == 'name') {
        groups.sort((a, b) {
          final nameA = _getGroupDisplayName(a);
          final nameB = _getGroupDisplayName(b);
          return nameA.compareTo(nameB);
        });
      }

      // Filter to groups with users if filtering by most/least users, or top groups to avoid empty clutter
      final activeGroups = groups.where((g) => (counts[g['name']] ?? 0) > 0).toList();
      final displayGroups = (filter == 'most_users' && activeGroups.isNotEmpty)
          ? activeGroups
          : (groups.length > 20 ? groups.sublist(0, 20) : groups);

      final maxCount = counts.values.isEmpty
          ? 1
          : counts.values.reduce((a, b) => a > b ? a : b);
      final double barChartHeight = 130.0;

      String filterLabel = "អ្នកប្រើច្រើនបំផុត";
      if (filter == 'least_users') filterLabel = "អ្នកប្រើតិចបំផុត";
      if (filter == 'name') filterLabel = "តាមឈ្មោះក្រុម";

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xffE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "អ្នកប្រើប្រាស់តាមក្រុម",
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff0F172A),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (val) =>
                      controller.groupUserChartFilter.value = val,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 6,
                  offset: const Offset(0, 40),
                  itemBuilder: (context) => [
                    _buildChartFilterMenuItem(
                      context: context,
                      value: 'most_users',
                      label: "អ្នកប្រើច្រើនបំផុត",
                      isSelected: filter == 'most_users',
                    ),
                    _buildChartFilterMenuItem(
                      context: context,
                      value: 'least_users',
                      label: "អ្នកប្រើតិចបំផុត",
                      isSelected: filter == 'least_users',
                    ),
                    _buildChartFilterMenuItem(
                      context: context,
                      value: 'name',
                      label: "តាមឈ្មោះក្រុម",
                      isSelected: filter == 'name',
                    ),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffFFFBEB),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xffFCD34D)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.tune_rounded,
                          size: 14,
                          color: Color(0xffD97706),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          filterLabel,
                          style: GoogleFonts.kantumruyPro(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff92400E),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          size: 16,
                          color: Color(0xffD97706),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            displayGroups.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 30),
                      child: Text(
                        "មិនមានទិន្នន័យ",
                        style: GoogleFonts.kantumruyPro(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: displayGroups.map((g) {
                        final name = g['name'] ?? '';
                        final displayName = _getGroupDisplayName(g);
                        final count = counts[name] ?? 0;
                        final barHeight = maxCount > 0
                            ? (count / maxCount) * (barChartHeight - 45)
                            : 0.0;

                        return Container(
                          width: 88,
                          margin: const EdgeInsets.only(right: 12),
                          child: Tooltip(
                            message: "$displayName: $count នាក់",
                            preferBelow: false,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xffFEF3C7),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    count.toString(),
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xffD97706),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  width: 32,
                                  height: barHeight > 6 ? barHeight : 6.0,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xffF59E0B),
                                        Color(0xffD97706),
                                      ],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(8),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xffF59E0B,
                                        ).withOpacity(0.2),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 42,
                                  child: Text(
                                    displayName,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.kantumruyPro(
                                      fontSize: 10,
                                      color: const Color(0xff64748B),
                                      height: 1.3,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ],
        ),
      );
    });
  }

  Widget _buildAppsByGroupChart() {
    return Obx(() {
      final counts =
          _getGroupAppCounts(); // inside Obx → reacts to groupAppCountMap
      final List<MapEntry<String, int>> activeGroups = counts.entries
          .where((e) => e.value > 0)
          .toList();

      final int totalAllocatedApps = activeGroups.fold(
        0,
        (sum, e) => sum + e.value,
      );

      final colorsList = [
        const Color(0xff2563EB),
        const Color(0xff10B981),
        const Color(0xffF59E0B),
        const Color(0xffEF4444),
        const Color(0xff7C3AED),
        const Color(0xffEC4899),
        const Color(0xff06B6D4),
        const Color(0xff8B5CF6),
      ];

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xffE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "កម្មវិធីតាមក្រុម",
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff0F172A),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xffBFDBFE)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.apps_rounded,
                        size: 13,
                        color: Color(0xff2563EB),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "${controller.totalApps.value} កម្មវិធីសរុប",
                        style: GoogleFonts.kantumruyPro(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xff1D4ED8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(110, 110),
                      painter: DonutChartPainter(
                        values: activeGroups
                            .map((e) => e.value.toDouble())
                            .toList(),
                        colors: colorsList,
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          totalAllocatedApps.toString(),
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff0F172A),
                          ),
                        ),
                        Text(
                          "បែងចែកសរុប",
                          style: GoogleFonts.kantumruyPro(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xff64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: activeGroups.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            child: Text(
                              "មិនមានទិន្នន័យ",
                              style: GoogleFonts.kantumruyPro(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: List.generate(activeGroups.length, (idx) {
                            final entry = activeGroups[idx];
                            final pct = totalAllocatedApps > 0
                                ? (entry.value / totalAllocatedApps * 100)
                                      .toStringAsFixed(0)
                                : '0';
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color:
                                          colorsList[idx % colorsList.length],
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      entry.key,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.kantumruyPro(
                                        fontSize: 11,
                                        height: 1.3,
                                        color: const Color(0xff334155),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    "${entry.value} ($pct%)",
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xff0F172A),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }

  Widget _buildRecentAnnouncementsSection() {
    // 🟢 Hidden as requested (Change 'if (true)' to 'if (false)' to show again)
    if (true) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "សេចក្តីប្រកាសថ្មីៗ",
              style: GoogleFonts.kantumruyPro(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xff0F172A),
              ),
            ),
            TextButton(
              onPressed: () =>
                  Get.toNamed(AppRoutes.announcement, arguments: 'admin'),
              child: Text(
                "មើលទាំងអស់ >",
                style: GoogleFonts.kantumruyPro(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF163774),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (controller.announcementsList.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xffE2E8F0)),
            ),
            child: Center(
              child: Text(
                "មិនទាន់មានសេចក្តីប្រកាសនៅឡើយទេ",
                style: GoogleFonts.kantumruyPro(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.announcementsList.length > 2
                ? 2
                : controller.announcementsList.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final announcement = controller.announcementsList[index];
              return _buildAnnouncementItemCard(announcement);
            },
          ),
      ],
    );
  }

  Widget _buildAnnouncementItemCard(Map<String, dynamic> ann) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffF1F5F9)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Color(0xffFEF3C7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.campaign_outlined,
              color: Color(0xffD97706),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ann['title'] ?? '',
                  style: GoogleFonts.kantumruyPro(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: const Color(0xff1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ann['date'] ?? '',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: const Color(0xff94A3B8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditLogsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "សកម្មភាពថ្មីៗនៃប្រព័ន្ធ",
          style: GoogleFonts.kantumruyPro(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xff0F172A),
          ),
        ),
        const SizedBox(height: 12),
        if (controller.auditLogs.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xffE2E8F0)),
            ),
            child: Center(
              child: Text(
                "មិនទាន់មានសកម្មភាពនៅឡើយទេ",
                style: GoogleFonts.kantumruyPro(
                  color: Colors.grey,
                  fontSize: 13,
                ),
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xffF1F5F9)),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.auditLogs.length > 3
                  ? 3
                  : controller.auditLogs.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 24, color: Color(0xffF1F5F9)),
              itemBuilder: (context, index) {
                final log = controller.auditLogs[index];
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Color(0xffDCFCE7),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.campaign_rounded,
                        color: Color(0xff16A34A),
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log['title'] ?? '',
                            style: GoogleFonts.kantumruyPro(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: const Color(0xff0F172A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            log['desc'] ?? '',
                            style: GoogleFonts.kantumruyPro(
                              fontSize: 11,
                              color: const Color(0xff475569),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            log['time'] ?? '',
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              color: const Color(0xff94A3B8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildAppsSection(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.grid_view_rounded,
                    color: Color(0xFF163774),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "កម្មវិធី",
                    style: GoogleFonts.kantumruyPro(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xff0F172A),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () => Get.to(() => const SuperAdminAppsListView()),
                child: Text(
                  "មើលទាំងអស់ >",
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF163774),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildAppTableHeader(),
          const Divider(height: 1, color: Color(0xffE2E8F0)),
          if (controller.appsList.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  "មិនមានទិន្នន័យឡើយ",
                  style: GoogleFonts.kantumruyPro(
                    color: Colors.grey,
                    fontSize: 13,
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: controller.appsList.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, color: Color(0xffF1F5F9)),
              itemBuilder: (context, index) {
                final app = controller.appsList[index];
                return _buildAppTableRow(index + 1, app);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildAppTableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              "#",
              style: GoogleFonts.kantumruyPro(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: const Color(0xff64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              "ឈ្មោះកម្មវិធី",
              style: GoogleFonts.kantumruyPro(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: const Color(0xff64748B),
              ),
            ),
          ),
          Text(
            "ស្ថានភាព",
            style: GoogleFonts.kantumruyPro(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: const Color(0xff64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppTableRow(int number, Map<String, dynamic> app) {
    final titleKh = app['titleKh'] ?? 'កម្មវិធី';
    final titleEn = app['titleEn'] ?? 'App';
    final bool isActive = app['isActive'] ?? true;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              number.toString(),
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xff475569),
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                _buildAppIconAvatar(app),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titleKh,
                        style: GoogleFonts.kantumruyPro(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xff0F172A),
                        ),
                      ),
                      Text(
                        titleEn,
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xff64748B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
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
              isActive ? "ដំណើរការ" : "ផ្អាក",
              style: GoogleFonts.kantumruyPro(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isActive
                    ? const Color(0xff065F46)
                    : const Color(0xff991B1B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bolt_outlined, color: Color(0xFF163774), size: 18),
            const SizedBox(width: 8),
            Text(
              "ចូលប្រើប្រាស់រហ័ស",
              style: GoogleFonts.kantumruyPro(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xff0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.1,
          children: [
            _buildQuickAccessBtn(
              "បន្ថែមកម្មវិធី",
              Icons.add_to_photos_rounded,
              const Color(0xff2563EB),
              () => Get.to(() => const SuperAdminAppsListView()),
            ),
            _buildQuickAccessBtn(
              "អ្នកប្រើប្រាស់",
              Icons.person_search_rounded,
              const Color(0xff10B981),
              () => controller.changeTab(2),
            ),
            _buildQuickAccessBtn(
              "ក្រុម និងតួនាទី",
              Icons.people_alt_rounded,
              const Color(0xff2563EB),
              () {
                if (!Get.isRegistered<SuperAdminController>()) {
                  Get.put(SuperAdminController());
                }
                Get.to(() => const SuperAdminGroupListView());
              },
            ),
            _buildQuickAccessBtn(
              "តួនាទី និងសិទ្ធិ",
              Icons.verified_user_rounded,
              const Color(0xff7C3AED),
              () {
                controller.fetchRolesData();
                Get.to(() => const SuperAdminRoleListView());
              },
            ),
            /*
            _buildQuickAccessBtn(
              "បន្ថែមសេចក្តីប្រកាស",
              Icons.add_comment_rounded,
              const Color(0xffD97706),
              () => Get.toNamed(AppRoutes.announcement, arguments: 'admin'),
            ),
            */
            _buildQuickAccessBtn(
              "របាយការណ៍",
              Icons.analytics_rounded,
              const Color(0xffE11D48),
              () => Get.to(() => const SuperAdminReportsView()),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAppIconAvatar(Map<String, dynamic> app) {
    final String iconPath = app['icon'] ?? 'assets/img/about-moi-logo.png';
    final String iconUrl = app['iconUrl'] ?? '';
    final String? token = GetStorage().read('token');
    final Map<String, String> authHeaders = token != null && token.isNotEmpty
        ? {'Authorization': 'Bearer $token'}
        : {};

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: AppIconWidget(
          iconUrl: iconUrl,
          localAsset: iconPath,
          token: token,
          size: 38,
        ),
      ),
    );
  }

  Widget _buildQuickAccessBtn(
    String label,
    IconData icon,
    Color iconColor,
    VoidCallback onTap,
  ) {
    return Container(
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(height: 10),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: GoogleFonts.kantumruyPro(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xff1E293B),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUsersTab(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          "អ្នកប្រើប្រាស់ប្រព័ន្ធ",
          style: GoogleFonts.kantumruyPro(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: const Color(0xff0F172A),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.person_add_alt_1_rounded,
              color: Color(0xFF163774),
              size: 22,
            ),
            onPressed: () => _showAddUserSheet(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Obx(() {
        final list = controller.filteredUsers;
        final total = controller.usersList.length;
        final active = controller.usersList
            .where(
              (u) =>
                  (u['status'] ?? 'ACTIVE').toString().toUpperCase() ==
                  'ACTIVE',
            )
            .length;
        final suspended = total - active;
        final assigned = controller.usersList.where((u) {
          final groups =
              u['groups'] ??
              u['userGroups'] ??
              u['portalGroups'] ??
              u['groupCodes'];
          return groups is List && groups.isNotEmpty;
        }).length;

        return RefreshIndicator(
          onRefresh: controller.fetchDashboardData,
          color: const Color(0xFF163774),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildUsersStatsScroll(total, active, suspended, assigned),

                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xffE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "បញ្ជីអ្នកប្រើប្រាស់",
                            style: GoogleFonts.kantumruyPro(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: const Color(0xff0F172A),
                            ),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xffE29D11),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              minimumSize: const Size(0, 36),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            icon: const Icon(Icons.group_add_rounded, size: 18),
                            label: Text(
                              "កំណត់អ្នកប្រើទៅក្រុម",
                              style: GoogleFonts.kantumruyPro(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            onPressed: () {
                              if (!Get.isRegistered<SuperAdminController>()) {
                                Get.put(SuperAdminController());
                              }
                              Get.to(
                                () => SuperAdminEditUserGroupsView(
                                  user: controller.usersList.isNotEmpty
                                      ? controller.usersList[0]
                                      : {},
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        onChanged: (val) =>
                            controller.userSearchQuery.value = val,
                        decoration: InputDecoration(
                          hintText: "ស្វែងរកតាមឈ្មោះ អ៊ីមែល ឬគណនី...",
                          hintStyle: GoogleFonts.kantumruyPro(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            color: Colors.grey,
                            size: 18,
                          ),
                          filled: true,
                          fillColor: const Color(0xffF8FAFC),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xffE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xffE2E8F0),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF163774),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xffF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xffE2E8F0),
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isDense: true,
                                  value: controller.selectedUserUnit.value,
                                  isExpanded: true,
                                  icon: const Icon(
                                    Icons.arrow_drop_down_rounded,
                                    color: Colors.grey,
                                  ),
                                  style: GoogleFonts.kantumruyPro(
                                    fontSize: 12,
                                    color: const Color(0xff0F172A),
                                  ),
                                  items: controller.uniqueUserUnits.map((
                                    String val,
                                  ) {
                                    return DropdownMenuItem<String>(
                                      value: val,
                                      child: Text(val),
                                    );
                                  }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      controller.selectedUserUnit.value = val;
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xffF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xffE2E8F0),
                                ),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  isDense: true,
                                  value: controller.selectedUserStatus.value,
                                  isExpanded: true,
                                  icon: const Icon(
                                    Icons.arrow_drop_down_rounded,
                                    color: Colors.grey,
                                  ),
                                  style: GoogleFonts.kantumruyPro(
                                    fontSize: 12,
                                    color: const Color(0xff0F172A),
                                  ),
                                  items:
                                      <String>[
                                        'ស្ថានភាពទាំងអស់',
                                        'ដំណើរការ',
                                        'ផ្អាក',
                                      ].map((String val) {
                                        return DropdownMenuItem<String>(
                                          value: val,
                                          child: Text(val),
                                        );
                                      }).toList(),
                                  onChanged: (val) {
                                    if (val != null) {
                                      controller.selectedUserStatus.value = val;
                                    }
                                  },
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (list.isEmpty)
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xffE2E8F0)),
                    ),
                    child: Center(
                      child: Text(
                        "មិនទាន់មានអ្នកប្រើប្រាស់ឡើយ",
                        style: GoogleFonts.kantumruyPro(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      return _buildUserItemCard(context, list[index], index);
                    },
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildUsersStatsScroll(
    int total,
    int active,
    int suspended,
    int assigned,
  ) {
    final double screenWidth = Get.width;
    final int crossAxisCount = screenWidth > 600 ? 4 : 2;
    final double childAspectRatio = screenWidth > 600
        ? 2.5
        : (screenWidth < 360 ? 1.6 : 1.9);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: childAspectRatio,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      children: [
        _buildUserStatCard(
          "អ្នកប្រើប្រាស់សរុប",
          total.toString(),
          "ក្នុងអង្គភាពទាំងអស់",
          Icons.people_alt_rounded,
          const Color(0xffEFF6FF),
          const Color(0xff2563EB),
        ),
        _buildUserStatCard(
          "អ្នកប្រើដំណើរការ",
          active.toString(),
          "${total > 0 ? (active / total * 100).toStringAsFixed(0) : 0}% នៃចំនួនសរុប",
          Icons.check_circle_rounded,
          const Color(0xffECFDF5),
          const Color(0xff10B981),
        ),
        _buildUserStatCard(
          "អ្នកប្រើផ្អាក",
          suspended.toString(),
          "${total > 0 ? (suspended / total * 100).toStringAsFixed(0) : 0}% នៃចំនួនសរុប",
          Icons.pause_circle_rounded,
          const Color(0xffFEF3C7),
          const Color(0xffF59E0B),
        ),
        _buildUserStatCard(
          "បានកំណត់ក្រុម",
          assigned.toString(),
          "${total > 0 ? (assigned / total * 100).toStringAsFixed(0) : 0}% នៃចំនួនសរុប",
          Icons.verified_user_rounded,
          const Color(0xffF5F3FF),
          const Color(0xff8B5CF6),
        ),
      ],
    );
  }

  Widget _buildUserStatCard(
    String title,
    String value,
    String subtitle,
    IconData icon,
    Color bgIconColor,
    Color accentColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bgIconColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 20),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.kantumruyPro(
                    color: const Color(0xff64748B),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: const Color(0xff0F172A),
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.kantumruyPro(
                    color: Colors.grey,
                    fontSize: 9,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserItemCard(
    BuildContext context,
    Map<String, dynamic> user,
    int index,
  ) {
    final email = (user['email'] ?? '').toString().trim();
    final String status = (user['status'] ?? 'ACTIVE').toString();
    final String unit = (user['unit'] ?? '—').toString().trim();
    final bool isActive = status.toUpperCase() == 'ACTIVE';
    final bool isSelf = controller.isSelfUser(user);

    // Resolve displayName and username
    final String rawUsername = (user['username'] ?? user['userName'] ?? user['accountName'] ?? '').toString().trim();
    final String rawId = (user['id'] ?? user['keycloakUserId'] ?? '').toString().trim();
    final String cleanUsername = (rawUsername.isNotEmpty && rawUsername != rawId)
        ? rawUsername
        : '';

    String rawDisplayName = (user['displayName'] ??
            user['display_name'] ??
            user['fullName'] ??
            user['full_name'] ??
            user['name_kh'] ??
            user['nameKh'] ??
            '')
        .toString()
        .trim();

    // Check Keycloak attributes map
    if ((rawDisplayName.isEmpty || rawDisplayName.toLowerCase() == cleanUsername.toLowerCase()) && user['attributes'] is Map) {
      final attrDisp = user['attributes']['displayName'] ?? user['attributes']['display_name'];
      if (attrDisp is List && attrDisp.isNotEmpty) {
        rawDisplayName = attrDisp.first.toString().trim();
      } else if (attrDisp is String) {
        rawDisplayName = attrDisp.trim();
      }
    }

    // Check firstName and lastName
    if (rawDisplayName.isEmpty || rawDisplayName.toLowerCase() == cleanUsername.toLowerCase()) {
      final first = (user['firstName'] ?? user['first_name'] ?? '').toString().trim();
      final last = (user['lastName'] ?? user['last_name'] ?? '').toString().trim();
      if (first.isNotEmpty || last.isNotEmpty) {
        rawDisplayName = '$first $last'.trim();
      }
    }

    // Check if logged-in user (self) has cached display name
    if ((rawDisplayName.isEmpty || rawDisplayName.toLowerCase() == cleanUsername.toLowerCase()) && isSelf) {
      final box = GetStorage();
      final selfName = (box.read('user_display_name') ?? box.read('displayName') ?? '').toString().trim();
      if (selfName.isNotEmpty) {
        rawDisplayName = selfName;
      }
    }

    // Check user['name'] only if it's different from username
    if (rawDisplayName.isEmpty || rawDisplayName.toLowerCase() == cleanUsername.toLowerCase()) {
      final rawName = (user['name'] ?? '').toString().trim();
      if (rawName.isNotEmpty && rawName.toLowerCase() != cleanUsername.toLowerCase()) {
        rawDisplayName = rawName;
      }
    }

    // Smart fallback for dot-formatted usernames (e.g. bin.sovanvong -> Sovanvong Bin)
    if (rawDisplayName.isEmpty || rawDisplayName.toLowerCase() == cleanUsername.toLowerCase()) {
      if (cleanUsername.contains('.')) {
        final parts = cleanUsername.split('.');
        if (parts.length == 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
          final p0 = '${parts[0][0].toUpperCase()}${parts[0].substring(1)}';
          final p1 = '${parts[1][0].toUpperCase()}${parts[1].substring(1)}';
          rawDisplayName = '$p1 $p0';
        } else {
          rawDisplayName = parts
              .where((p) => p.isNotEmpty)
              .map((p) => '${p[0].toUpperCase()}${p.substring(1)}')
              .join(' ');
        }
      }
    }

    final String displayName = rawDisplayName.isNotEmpty
        ? rawDisplayName
        : (cleanUsername.isNotEmpty ? cleanUsername : 'User');

    final String username = cleanUsername.isNotEmpty
        ? cleanUsername
        : (email.isNotEmpty ? email : displayName);

    String initial = 'U';
    final nameForInitial = displayName.isNotEmpty ? displayName : cleanUsername;
    if (nameForInitial.isNotEmpty) {
      final parts = nameForInitial.trim().split(RegExp(r'[\s._-]+')).where((p) => p.isNotEmpty).toList();
      if (parts.length >= 2) {
        initial = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else {
        final clean = nameForInitial.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '');
        if (clean.length >= 2) {
          initial = clean.substring(0, 2).toUpperCase();
        } else if (clean.isNotEmpty) {
          initial = clean.toUpperCase();
        }
      }
    }

    final List<String> assignedGroupsList = [];
    for (final key in [
      'groups',
      'userGroups',
      'portalGroups',
      'groupCodes',
      'user_groups',
    ]) {
      final val = user[key];
      if (val is List) {
        for (final item in val) {
          if (item != null) {
            final str =
                (item is Map
                        ? (item['name'] ??
                              item['groupName'] ??
                              item['code'] ??
                              item['sublabel'])
                        : item)
                    .toString()
                    .trim();
            final cleanStr = str.startsWith('/') ? str.substring(1) : str;
            if (cleanStr.isNotEmpty && !assignedGroupsList.contains(cleanStr)) {
              assignedGroupsList.add(cleanStr);
            }
          }
        }
      } else if (val is String && val.trim().isNotEmpty) {
        final cleanStr = val.startsWith('/')
            ? val.trim().substring(1)
            : val.trim();
        if (!assignedGroupsList.contains(cleanStr)) {
          assignedGroupsList.add(cleanStr);
        }
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xffE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xffEFF6FF),
                child: Text(
                  initial,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff2563EB),
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 14.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xff0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      username,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xff64748B),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.visibility_outlined,
                      size: 18,
                      color: Color(0xff64748B),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _showUserDetailDialog(context, user),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: controller.canEditUser(user)
                          ? const Color(0xff64748B)
                          : const Color(0xffCBD5E1),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: controller.canEditUser(user)
                        ? () => Get.to(
                            () => SuperAdminEditUserGroupsView(user: user),
                          )
                        : () {
                            CustomSnackbar.showWarning(
                              message:
                                  'មិនអាចកែសម្រួលគណនីផ្ទាល់ខ្លួនរបស់អ្នកបានឡើយ (You cannot edit your own account)',
                            );
                          },
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      size: 18,
                      color: Color(0xff64748B),
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _showUserActionsMenu(context, user, index),
                  ),
                ],
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: Color(0xffE2E8F0), height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "អង្គភាព (ក្រុម)",
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      unit,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xff0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "អ៊ីមែល",
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 10,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      email.isNotEmpty ? email : "-",
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: email.isNotEmpty
                            ? const Color(0xff334155)
                            : Colors.grey,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (isSelf) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFFBFDBFE),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    'គណនីផ្ទាល់ខ្លួន',
                    style: GoogleFonts.kantumruyPro(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1D4ED8),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
              ],
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
                        : const Color(0xffFCA5A5),
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xff10B981)
                            : const Color(0xffEF4444),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isActive ? "ដំណើរការ" : "ផ្អាក",
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: isActive
                            ? const Color(0xff065F46)
                            : const Color(0xff991B1B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (assignedGroupsList.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.people_alt_rounded,
                    size: 14,
                    color: Color(0xffD97706),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: assignedGroupsList.map((grp) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xffFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: const Color(0xffFDE68A),
                            width: 0.5,
                          ),
                        ),
                        child: Text(
                          grp,
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xffB45309),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _showUserDetailDialog(BuildContext context, Map<String, dynamic> user) {
    final String rawUsername = (user['username'] ?? user['accountName'] ?? '').toString().trim();
    final String rawId = (user['id'] ?? user['keycloakUserId'] ?? '').toString().trim();
    final String cleanUsername = (rawUsername.isNotEmpty && rawUsername != rawId)
        ? rawUsername
        : '';

    String rawDisplayName = (user['displayName'] ??
            user['display_name'] ??
            user['fullName'] ??
            user['full_name'] ??
            user['name_kh'] ??
            user['nameKh'] ??
            '')
        .toString()
        .trim();

    if ((rawDisplayName.isEmpty || rawDisplayName.toLowerCase() == cleanUsername.toLowerCase()) && user['attributes'] is Map) {
      final attrDisp = user['attributes']['displayName'] ?? user['attributes']['display_name'];
      if (attrDisp is List && attrDisp.isNotEmpty) {
        rawDisplayName = attrDisp.first.toString().trim();
      } else if (attrDisp is String) {
        rawDisplayName = attrDisp.trim();
      }
    }

    if (rawDisplayName.isEmpty || rawDisplayName.toLowerCase() == cleanUsername.toLowerCase()) {
      final first = (user['firstName'] ?? user['first_name'] ?? '').toString().trim();
      final last = (user['lastName'] ?? user['last_name'] ?? '').toString().trim();
      if (first.isNotEmpty || last.isNotEmpty) {
        rawDisplayName = '$first $last'.trim();
      }
    }

    if (rawDisplayName.isEmpty || rawDisplayName.toLowerCase() == cleanUsername.toLowerCase()) {
      final box = GetStorage();
      final selfName = (box.read('user_display_name') ?? box.read('displayName') ?? '').toString().trim();
      if (selfName.isNotEmpty && controller.isSelfUser(user)) {
        rawDisplayName = selfName;
      }
    }

    if (rawDisplayName.isEmpty || rawDisplayName.toLowerCase() == cleanUsername.toLowerCase()) {
      if (cleanUsername.contains('.')) {
        final parts = cleanUsername.split('.');
        if (parts.length == 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
          final p0 = '${parts[0][0].toUpperCase()}${parts[0].substring(1)}';
          final p1 = '${parts[1][0].toUpperCase()}${parts[1].substring(1)}';
          rawDisplayName = '$p1 $p0';
        }
      }
    }

    final String displayName = rawDisplayName.isNotEmpty
        ? rawDisplayName
        : (cleanUsername.isNotEmpty ? cleanUsername : 'User');
    
    // Ensure username is not displaying the raw UUID
    final String username = cleanUsername.isNotEmpty
        ? cleanUsername
        : (displayName.isNotEmpty ? displayName : 'admin');

    final String role = (user['role'] ?? user['roleName'] ?? 'User').toString();
    final String status = (user['status'] ?? 'ACTIVE').toString().toUpperCase();
    final bool isActive = status == 'ACTIVE';

    // Resolve Khmer Organization Name / Unit
    String unit = (user['unit'] ?? user['department'] ?? '').toString().trim();
    final List empInfos = user['employmentInfos'] is List ? user['employmentInfos'] : [];
    if (empInfos.isNotEmpty && empInfos[0] is Map) {
      final firstEmp = empInfos[0];
      final gName = (firstEmp['generalDepartmentNameKh'] ?? firstEmp['generalDepartmentName'] ?? firstEmp['generalDepartmentCode'] ?? '').toString().trim();
      if (gName.isNotEmpty) unit = gName;
    }
    if (unit.isEmpty || unit == '—') {
      unit = 'GDDTM';
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          clipBehavior: Clip.antiAlias,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Row with soft background
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF6F9FE),
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(28),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEFF6FF),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: Color(0xFF2563EB),
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'user_info_title'.tr,
                              style: GoogleFonts.kantumruyPro(
                                fontWeight: FontWeight.w800,
                                fontSize: 17.5,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'user_detail_subtitle'.tr,
                              style: GoogleFonts.kantumruyPro(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 38,
                        height: 38,
                        decoration: const BoxDecoration(
                          color: Color(0xFFEFF4FB),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: Color(0xFF0F172A),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(
                  color: Color(0xFFE2E8F0),
                  height: 1,
                  thickness: 1,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Tile 1: Account Name / Username
                      _buildModernUserDetailTile(
                        icon: Icons.mail_outline_rounded,
                        iconBgColor: const Color(0xFFEFF6FF),
                        iconColor: const Color(0xFF2563EB),
                        label: 'account_number_or_name'.tr,
                        value: username,
                      ),

                      // Tile 2: Role
                      _buildModernUserDetailTile(
                        icon: Icons.groups_rounded,
                        iconBgColor: const Color(0xFFFAF5FF),
                        iconColor: const Color(0xFF7C3AED),
                        label: 'role'.tr,
                        value: role,
                      ),

                      // Tile 3: Unit (Ministry)
                      _buildModernUserDetailTile(
                        icon: Icons.domain_rounded,
                        iconBgColor: const Color(0xFFFEF3C7),
                        iconColor: const Color(0xFFD97706),
                        label: 'unit_ministry'.tr,
                        value: unit,
                      ),

                      // Tile 4: Status
                      _buildModernUserStatusTile(isActive: isActive),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernUserDetailTile({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: GoogleFonts.poppins(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const Divider(
          height: 12,
          thickness: 1,
          color: Color(0xFFF1F5F9),
        ),
      ],
    );
  }

  Widget _buildModernUserStatusTile({required bool isActive}) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: Color(0xFF16A34A),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'status'.tr,
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFFECFDF5)
                        : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFFA7F3D0).withOpacity(0.6)
                          : const Color(0xFFFECACA),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFF10B981)
                              : const Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 7),
                      Text(
                        isActive
                            ? 'status_active_full'.tr
                            : 'status_inactive_full'.tr,
                        style: GoogleFonts.kantumruyPro(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? const Color(0xFF059669)
                              : const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showUserActionsMenu(
    BuildContext context,
    Map<String, dynamic> user,
    int index,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(
                  Icons.visibility_outlined,
                  color: Colors.blue,
                ),
                title: Text(
                  "មើលព័ត៌មានលម្អិត",
                  style: GoogleFonts.kantumruyPro(fontSize: 14),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _showUserDetailDialog(context, user);
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.edit_outlined,
                  color: controller.canEditUser(user) ? Colors.orange : Colors.grey,
                ),
                title: Text(
                  "កែប្រែគណនី",
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 14,
                    color: controller.canEditUser(user)
                        ? const Color(0xFF0F172A)
                        : Colors.grey,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  if (controller.canEditUser(user)) {
                    Get.to(() => SuperAdminEditUserGroupsView(user: user));
                  } else {
                    CustomSnackbar.showWarning(
                      message:
                          'មិនអាចកែសម្រួលគណនីផ្ទាល់ខ្លួនរបស់អ្នកបានឡើយ (You cannot edit your own account)',
                    );
                  }
                },
              ),
              ListTile(
                leading: Icon(
                  Icons.delete_outline_rounded,
                  color: controller.canEditUser(user) ? Colors.red : Colors.grey,
                ),
                title: Text(
                  "លុបគណនី",
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 14,
                    color: controller.canEditUser(user) ? Colors.red : Colors.grey,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  if (controller.canEditUser(user)) {
                    _confirmDeleteUser(context, index);
                  } else {
                    CustomSnackbar.showWarning(
                      message:
                          'មិនអាចលុបគណនីផ្ទាល់ខ្លួនរបស់អ្នកបានឡើយ (You cannot delete your own account)',
                    );
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDeleteUser(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            "លុបគណនី",
            style: GoogleFonts.kantumruyPro(fontWeight: FontWeight.bold),
          ),
          content: Text(
            "តើអ្នកប្រាកដជាចង់លុបគណនីអ្នកប្រើប្រាស់នេះមែនទេ?",
            style: GoogleFonts.kantumruyPro(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                "បោះបង់",
                style: GoogleFonts.kantumruyPro(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                controller.deleteUser(index);
                Navigator.of(context).pop();
              },
              child: Text(
                "លុប",
                style: GoogleFonts.kantumruyPro(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAdminSettingsTab(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          "ការកំណត់ Super Admin",
          style: GoogleFonts.kantumruyPro(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: const Color(0xff0F172A),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Profile Welcomer Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xffF1F5F9)),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Color(0xffF6EBC2),
                    child: Icon(
                      Icons.admin_panel_settings_rounded,
                      color: Color(0xFF163774),
                      size: 36,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "admin admin",
                          style: GoogleFonts.kantumruyPro(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff0F172A),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xffFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "SUPER ADMIN",
                            style: GoogleFonts.poppins(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xffD97706),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            /// System Management
            Text(
              "ប្រព័ន្ធគ្រប់គ្រង",
              style: GoogleFonts.kantumruyPro(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xff64748B),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xffF1F5F9)),
              ),
              child: Column(
                children: [
                  _buildSettingTile(
                    icon: Icons.home_rounded,
                    title: "ទៅកាន់ទំព័រដើម (Client Home)",
                    iconColor: const Color(0xFF163774),
                    onTap: () => Get.offAllNamed(AppRoutes.mainPage),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            /// Security & Account
            Text(
              "គណនី និងសន្តិសុខ",
              style: GoogleFonts.kantumruyPro(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xff64748B),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xffF1F5F9)),
              ),
              child: Column(
                children: [
                  _buildSettingTile(
                    icon: Icons.manage_accounts_rounded,
                    title: "ការកំណត់គណនី",
                    iconColor: const Color(0xff3B82F6),
                    onTap: () {
                      Get.to(() => const SuperAdminAccountSettingsView());
                    },
                  ),
                  const Divider(height: 1, color: Color(0xffF1F5F9)),
                  _buildSettingTile(
                    icon: Icons.lock_rounded,
                    title: "ផ្លាស់ប្តូរពាក្យសម្ងាត់",
                    iconColor: const Color(0xffD97706),
                    onTap: () {},
                  ),
                  const Divider(height: 1, color: Color(0xffF1F5F9)),
                  _buildSettingTile(
                    icon: Icons.logout_rounded,
                    title: "ចាកចេញពីគណនី",
                    iconColor: const Color(0xffEF4444),
                    textColor: const Color(0xffEF4444),
                    onTap: () => _confirmLogout(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required Color iconColor,
    required VoidCallback onTap,
    Color textColor = const Color(0xff1E293B),
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.kantumruyPro(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.6),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF163774)),
              ),
              const SizedBox(height: 24),
              Text(
                "កំពុងបម្រុងទុកទិន្នន័យ...",
                style: GoogleFonts.kantumruyPro(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: const Color(0xff1E293B),
                ),
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: controller.backupProgress.value,
                backgroundColor: const Color(0xffE2E8F0),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF163774),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "${(controller.backupProgress.value * 100).toInt()}%",
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF163774),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddUserSheet(BuildContext context) {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    String selectedRole = 'User';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
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
                "បង្កើតគណនីអ្នកប្រើប្រាស់ថ្មី",
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
                  labelText: "ឈ្មោះអ្នកប្រើប្រាស់",
                  labelStyle: GoogleFonts.kantumruyPro(fontSize: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: "អ៊ីមែល",
                  labelStyle: GoogleFonts.kantumruyPro(fontSize: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedRole,
                decoration: InputDecoration(
                  labelText: "តួនាទី",
                  labelStyle: GoogleFonts.kantumruyPro(fontSize: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                items: ['User', 'Moderator', 'Admin']
                    .map(
                      (role) =>
                          DropdownMenuItem(value: role, child: Text(role)),
                    )
                    .toList(),
                onChanged: (val) {
                  if (val != null) selectedRole = val;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF163774),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    final name = nameCtrl.text.trim();
                    final email = emailCtrl.text.trim();
                    if (name.isEmpty || email.isEmpty) {
                      CustomSnackbar.showError(
                        message: 'សូមបំពេញព័ត៌មានអោយបានគ្រប់គ្រាន់',
                      );
                      return;
                    }
                    controller.addNewUser(name, email, selectedRole);
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    "បង្កើតគណនី",
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
        );
      },
    );
  }

  void _confirmLogout(BuildContext context) {
    showLogoutConfirmDialog(
      context,
      message: 'logout_confirm_admin_message'.tr,
      onConfirm: controller.logout,
    );
  }
}

class SuperAdminAppsListView extends GetView<SuperAdminController> {
  const SuperAdminAppsListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF163774),
                ),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Text(
          "កម្មវិធីប្រើប្រាស់",
          style: GoogleFonts.kantumruyPro(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: const Color(0xff0F172A),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.add_rounded,
              color: Color(0xFF163774),
              size: 24,
            ),
            onPressed: () => Get.to(() => const SuperAdminAppCreateView()),
          ),
        ],
      ),
      body: Obx(() {
        final list = controller.filteredApps;

        return Stack(
          children: [
            RefreshIndicator(
              onRefresh: controller.fetchDashboardData,
              color: const Color(0xFF163774),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAppsStatsRow(controller),

                    Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  onChanged: (val) =>
                                      controller.appSearchQuery.value = val,
                                  decoration: InputDecoration(
                                    hintText: "ស្វែងរកកម្មវិធី...",
                                    hintStyle: GoogleFonts.kantumruyPro(
                                      fontSize: 13,
                                      color: Colors.grey,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.search_rounded,
                                      color: Colors.grey,
                                      size: 20,
                                    ),
                                    filled: true,
                                    fillColor: const Color(0xffF1F5F9),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Obx(() {
                                final currentStatus =
                                    controller.appStatusFilter.value;
                                String statusLabel = "ស្ថានភាពទាំងអស់";
                                if (currentStatus == 'active') {
                                  statusLabel = "កំពុងដំណើរការ";
                                } else if (currentStatus == 'inactive') {
                                  statusLabel = "មិនដំណើរការ";
                                }

                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    hoverColor: Colors.transparent,
                                    splashColor: Colors.transparent,
                                    highlightColor: Colors.transparent,
                                  ),
                                  child: PopupMenuButton<String>(
                                    onSelected: (value) =>
                                        controller.appStatusFilter.value =
                                            value,
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: 'all',
                                        child: Text(
                                          "ស្ថានភាពទាំងអស់",
                                          style: GoogleFonts.kantumruyPro(
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'active',
                                        child: Text(
                                          "កំពុងដំណើរការ",
                                          style: GoogleFonts.kantumruyPro(
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      PopupMenuItem(
                                        value: 'inactive',
                                        child: Text(
                                          "មិនដំណើរការ",
                                          style: GoogleFonts.kantumruyPro(
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                    child: Container(
                                      height: 38,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xffEFF6FF),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: const Color(0xff3B82F6),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(
                                            Icons.filter_alt_outlined,
                                            size: 16,
                                            color: Color(0xff2563EB),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            statusLabel,
                                            style: GoogleFonts.kantumruyPro(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: const Color(0xff2563EB),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "បញ្ជីកម្មវិធី",
                                style: GoogleFonts.kantumruyPro(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xff1E293B),
                                ),
                              ),
                              Obx(() {
                                final currentSort =
                                    controller.appSortFilter.value;
                                String sortLabel = "ថ្មីបំផុត";
                                if (currentSort == 'name_az') {
                                  sortLabel = "ឈ្មោះ: ក-អ";
                                } else if (currentSort == 'name_za') {
                                  sortLabel = "ឈ្មោះ: អ-ក";
                                } else if (currentSort == 'oldest') {
                                  sortLabel = "ចាស់បំផុត";
                                }

                                return PopupMenuButton<String>(
                                  onSelected: (value) =>
                                      controller.appSortFilter.value = value,
                                  itemBuilder: (context) => [
                                    PopupMenuItem(
                                      value: 'name_az',
                                      child: Text(
                                        "ឈ្មោះ: ក-អ",
                                        style: GoogleFonts.kantumruyPro(
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'name_za',
                                      child: Text(
                                        "ឈ្មោះ: អ-ក",
                                        style: GoogleFonts.kantumruyPro(
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'newest',
                                      child: Text(
                                        "ថ្មីបំផុត",
                                        style: GoogleFonts.kantumruyPro(
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    PopupMenuItem(
                                      value: 'oldest',
                                      child: Text(
                                        "ចាស់បំផុត",
                                        style: GoogleFonts.kantumruyPro(
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                  child: Container(
                                    height: 32,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xffF8FAFC),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xffE2E8F0),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          sortLabel,
                                          style: GoogleFonts.kantumruyPro(
                                            fontSize: 11,
                                            color: const Color(0xff475569),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          size: 14,
                                          color: Color(0xff475569),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),

                    list.isEmpty
                        ? SizedBox(
                            height: 200,
                            child: Center(
                              child: Text(
                                "មិនមានទិន្នន័យឡើយ",
                                style: GoogleFonts.kantumruyPro(
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            itemCount: list.length,
                            itemBuilder: (context, index) {
                              final app = list[index];
                              final originalIndex = controller.appsList.indexOf(
                                app,
                              );
                              return _buildAppMobileCard(
                                context,
                                originalIndex,
                                app,
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
            if (controller.isLoading.value)
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF163774)),
                ),
              ),
          ],
        );
      }),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xff2563EB),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        onPressed: () => Get.to(() => const SuperAdminAppCreateView()),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildAppsStatsRow(SuperAdminController controller) {
    final list = controller.appsList;
    final total = list.length;
    final active = list.where((app) => app['isActive'] == true).length;
    final inactive = list.where((app) => app['isActive'] != true).length;

    final usersWithAccessCount = controller.usersList.where((usr) {
      final status = (usr['status'] ?? 'ACTIVE').toString().toUpperCase();
      if (status != 'ACTIVE') return false;
      final role = (usr['role'] ?? '').toString().toUpperCase();
      if (role.contains('ADMIN') || role.contains('SUPER')) return true;
      if (list.isEmpty) return true;

      final List userGroups = (usr['groups'] is List) ? usr['groups'] : [];
      final String username = (usr['username'] ?? '').toString().toLowerCase();
      final String uid = (usr['id'] ?? usr['keycloakUserId'] ?? '')
          .toString()
          .toLowerCase();

      return list.any((app) {
        final List accessRules = app['accessRules'] is List
            ? app['accessRules']
            : [];
        if (accessRules.isEmpty) return true;
        return accessRules.any((rule) {
          if (rule is! Map) return false;
          final String rType =
              (rule['ruleType'] ?? rule['rule_type'] ?? rule['type'] ?? '')
                  .toString()
                  .toUpperCase();
          final String rVal =
              (rule['ruleValue'] ??
                      rule['rule_value'] ??
                      rule['value'] ??
                      rule['target'] ??
                      '')
                  .toString()
                  .trim()
                  .toLowerCase();
          if (rType.isEmpty || rType == 'ALL' || rType == 'PUBLIC') return true;
          if (rType.contains('GROUP') || rType.contains('PORTAL')) {
            return userGroups.any(
              (g) => g.toString().trim().toLowerCase() == rVal,
            );
          }
          if (rType.contains('USER')) {
            return username == rVal || uid == rVal;
          }
          if (rType.contains('ROLE')) {
            return role.toLowerCase() == rVal;
          }
          return false;
        });
      });
    }).length;

    final users = usersWithAccessCount > 0
        ? usersWithAccessCount
        : controller.totalUsers.value;

    final activePct = total > 0 ? (active / total * 100) : 0.0;
    final inactivePct = total > 0 ? (inactive / total * 100) : 0.0;

    final double screenWidth = Get.width;
    final int crossAxisCount = screenWidth > 600 ? 4 : 2;
    final double childAspectRatio = screenWidth > 600
        ? 2.5
        : (screenWidth < 360 ? 1.6 : 1.9);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: childAspectRatio,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      children: [
        _buildStatCardItem(
          title: "កម្មវិធីសរុប",
          value: total.toString(),
          subtitle: "កម្មវិធីក្នុងប្រព័ន្ធ",
          icon: Icons.apps_rounded,
          iconColor: const Color(0xff2563EB),
          bgIconColor: const Color(0xffEFF6FF),
        ),
        _buildStatCardItem(
          title: "កម្មវិធីដំណើរការ",
          value: active.toString(),
          subtitle: "${activePct.toStringAsFixed(1)}% នៃចំនួនសរុប",
          icon: Icons.check_circle_rounded,
          iconColor: const Color(0xff10B981),
          bgIconColor: const Color(0xffECFDF5),
        ),
        _buildStatCardItem(
          title: "កម្មវិធីមិនដំណើរការ",
          value: inactive.toString(),
          subtitle: "${inactivePct.toStringAsFixed(1)}% នៃចំនួនសរុប",
          icon: Icons.watch_later_outlined,
          iconColor: const Color(0xffD97706),
          bgIconColor: const Color(0xffFEF3C7),
        ),
        _buildStatCardItem(
          title: "អ្នកប្រើប្រាស់សរុប",
          value: users.toString(),
          subtitle: "សិទ្ធិចូលកម្មវិធី",
          icon: Icons.people_alt_rounded,
          iconColor: const Color(0xff7C3AED),
          bgIconColor: const Color(0xffF3E8FF),
        ),
      ],
    );
  }

  Widget _buildStatCardItem({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgIconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bgIconColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 9,
                    color: const Color(0xff94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppMobileCard(
    BuildContext context,
    int originalIndex,
    Map<String, dynamic> app,
  ) {
    final titleKh = app['titleKh'] ?? 'កម្មវិធី';
    final titleEn = app['titleEn'] ?? 'App';
    final route = app['route'] ?? '';
    final bool isActive = app['isActive'] ?? true;
    final ruleType = app['ruleType'] ?? 'អគ្គនាយកដ្ឋាន';
    final ruleValue = app['ruleValue'] ?? 'GDDTM';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showAppDetailDialog(context, app),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAppIconAvatar(app),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titleKh,
                              style: GoogleFonts.kantumruyPro(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xff0F172A),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              titleEn,
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xff64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _buildStatusBadge(isActive),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1, color: Color(0xffF1F5F9)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.link_rounded,
                        size: 16,
                        color: Color(0xff2563EB),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          route,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xff2563EB),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.security_rounded,
                        size: 16,
                        color: Color(0xff64748B),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "ច្បាប់ចូលប្រើប្រាស់: $ruleType ($ruleValue)",
                        style: GoogleFonts.kantumruyPro(
                          fontSize: 11,
                          color: const Color(0xff64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _buildMobileActionBtn(
                        icon: Icons.visibility_outlined,
                        label: "មើល",
                        color: const Color(0xff2563EB),
                        onTap: () => _showAppDetailDialog(context, app),
                      ),
                      const SizedBox(width: 8),
                      _buildMobileActionBtn(
                        icon: Icons.edit_outlined,
                        label: "កែប្រែ",
                        color: const Color(0xff475569),
                        onTap: () => Get.to(
                          () => SuperAdminAppCreateView(
                            isEdit: true,
                            appIndex: originalIndex,
                            appData: app,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildMobileActionBtn(
                        icon: Icons.delete_outline_rounded,
                        label: "លុប",
                        color: const Color(0xffEF4444),
                        onTap: () =>
                            _confirmDeleteApp(context, originalIndex, titleKh),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xffECFDF5) : const Color(0xffFEE2E2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isActive ? const Color(0xffA7F3D0) : const Color(0xffFECACA),
        ),
      ),
      child: Text(
        isActive ? "ដំណើរការ" : "ផ្អាក",
        style: GoogleFonts.kantumruyPro(
          fontSize: 9,
          fontWeight: FontWeight.bold,
          color: isActive ? const Color(0xff065F46) : const Color(0xff991B1B),
        ),
      ),
    );
  }

  Widget _buildMobileActionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.kantumruyPro(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppIconAvatar(Map<String, dynamic> app) {
    final String iconPath = app['icon'] ?? 'assets/img/about-moi-logo.png';
    final String iconUrl = app['iconUrl'] ?? '';
    final String? token = GetStorage().read('token');
    final Map<String, String> authHeaders = token != null && token.isNotEmpty
        ? {'Authorization': 'Bearer $token'}
        : {};

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: AppIconWidget(
          iconUrl: iconUrl,
          localAsset: iconPath,
          token: token,
          size: 38,
        ),
      ),
    );
  }

  void _showAppDetailDialog(BuildContext context, Map<String, dynamic> app) {
    final String titleKh = (app['titleKh'] ?? app['name'] ?? app['titleEn'] ?? 'កម្មវិធី').toString().trim();
    final String titleEn = (app['titleEn'] ?? titleKh).toString().trim();
    final String appCode = (app['code'] ?? app['appCode'] ?? app['id'] ?? 'APP').toString().trim().toUpperCase();
    final String routeUrl = (app['route'] ?? app['url'] ?? app['link'] ?? '—').toString().trim();
    final bool isActive = (app['isActive'] ?? app['active'] ?? true) == true;
    final String iconPath = (app['icon'] ?? 'assets/img/about-moi-logo.png').toString();
    final String iconUrl = (app['iconUrl'] ?? '').toString();
    final String createdDate = (app['createdAt'] ?? app['createdDate'] ?? '—').toString();

    // Determine Organization
    String org = (app['organization'] ?? app['department'] ?? app['unit'] ?? '').toString().trim();
    if (org.isEmpty || org == '—') {
      if (appCode.startsWith('GDDTM')) {
        org = 'GDDTM';
      } else if (appCode.startsWith('GDI')) {
        org = 'GDI';
      } else if (appCode.startsWith('GDP')) {
        org = 'GDP';
      } else {
        org = 'GDDTM';
      }
    }

    // Determine Icon file name
    String fileName = 'calendar_28_2x.png';
    if (iconUrl.isNotEmpty) {
      final uri = Uri.tryParse(iconUrl);
      if (uri != null && uri.pathSegments.isNotEmpty) {
        fileName = uri.pathSegments.last;
      }
    } else if (iconPath.isNotEmpty) {
      fileName = iconPath.split('/').last;
    }

    // Process Access Rules
    final List<String> ruleTags = [];
    final List rawRules = app['accessRules'] is List ? app['accessRules'] : [];
    for (final r in rawRules) {
      final String tag = _formatAccessRuleTag(r);
      if (tag.isNotEmpty && !ruleTags.contains(tag)) {
        ruleTags.add(tag);
      }
    }

    if (ruleTags.isEmpty) {
      final String rType = (app['ruleType'] ?? '').toString().trim();
      final String rVal = (app['ruleValue'] ?? '').toString().trim();
      if (rType.isNotEmpty && rVal.isNotEmpty) {
        ruleTags.add('$rType : $rVal');
      } else {
        ruleTags.add('ទូទៅ (ទាំងអស់)');
      }
    }

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWide = screenWidth > 680;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          width: isWide ? 580 : screenWidth * 0.95,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.90),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xffE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: AppIconWidget(
                          iconUrl: iconUrl,
                          localAsset: iconPath,
                          token: GetStorage().read('token'),
                          size: 34,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ព័ត៌មានលម្អិតកម្មវិធី',
                            style: GoogleFonts.kantumruyPro(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xff64748B),
                            ),
                          ),
                          Text(
                            titleKh,
                            style: GoogleFonts.kantumruyPro(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xff0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xffE2E8F0)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.close_rounded, size: 18, color: Color(0xff64748B)),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xffF1F5F9), thickness: 1),

              // Scrollable Detail Rows
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Column(
                    children: [
                      // 1. Code
                      _buildAppDetailRowItem(
                        icon: Icons.grid_view_rounded,
                        iconBg: const Color(0xffF8FAFC),
                        iconColor: const Color(0xff475569),
                        label: 'កូដ',
                        valueWidget: Text(
                          appCode,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff0F172A),
                          ),
                        ),
                      ),
                      const Divider(height: 24, color: Color(0xffF8FAFC)),

                      // 2. URL
                      _buildAppDetailRowItem(
                        icon: Icons.link_rounded,
                        iconBg: const Color(0xffF8FAFC),
                        iconColor: const Color(0xff475569),
                        label: 'URL',
                        valueWidget: InkWell(
                          onTap: () {},
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  routeUrl,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xff2563EB),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.north_east_rounded, size: 14, color: Color(0xff2563EB)),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 24, color: Color(0xffF8FAFC)),

                      // 3. Organization
                      _buildAppDetailRowItem(
                        icon: Icons.account_tree_outlined,
                        iconBg: const Color(0xffFEF3C7),
                        iconColor: const Color(0xffD97706),
                        label: 'អង្គភាព',
                        valueWidget: Text(
                          org,
                          style: GoogleFonts.kantumruyPro(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff0F172A),
                          ),
                        ),
                      ),
                      const Divider(height: 24, color: Color(0xffF8FAFC)),

                      // 4. Status
                      _buildAppDetailRowItem(
                        icon: Icons.check_circle_outline_rounded,
                        iconBg: const Color(0xffECFDF5),
                        iconColor: const Color(0xff10B981),
                        label: 'ស្ថានភាព',
                        valueWidget: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isActive ? const Color(0xffECFDF5) : const Color(0xffFEE2E2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isActive ? const Color(0xff10B981) : const Color(0xffEF4444),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isActive ? "កំពុងដំណើរការ" : "ផ្អាកដំណើរការ",
                                style: GoogleFonts.kantumruyPro(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isActive ? const Color(0xff047857) : const Color(0xffB91C1C),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 24, color: Color(0xffF8FAFC)),

                      // 5. Application Title
                      _buildAppDetailRowItem(
                        icon: Icons.apps_rounded,
                        iconBg: const Color(0xffF3E8FF),
                        iconColor: const Color(0xff9333EA),
                        label: 'កម្មវិធី',
                        valueWidget: Text(
                          titleKh,
                          style: GoogleFonts.kantumruyPro(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff0F172A),
                          ),
                        ),
                      ),
                      const Divider(height: 24, color: Color(0xffF8FAFC)),

                      // 6. Icon File
                      _buildAppDetailRowItem(
                        icon: Icons.insert_drive_file_outlined,
                        iconBg: const Color(0xffF8FAFC),
                        iconColor: const Color(0xff475569),
                        label: 'ឯកសាររូបតំណាង',
                        valueWidget: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xffE2E8F0)),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: AppIconWidget(
                                  iconUrl: iconUrl,
                                  localAsset: iconPath,
                                  token: GetStorage().read('token'),
                                  size: 28,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    fileName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xff0F172A),
                                    ),
                                  ),
                                  Text(
                                    'JPG, PNG, GIF, WEBP',
                                    style: GoogleFonts.poppins(
                                      fontSize: 10,
                                      color: const Color(0xff94A3B8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 24, color: Color(0xffF8FAFC)),

                      // 7. Access Rules
                      _buildAppDetailRowItem(
                        icon: Icons.shield_outlined,
                        iconBg: const Color(0xffFEF3C7),
                        iconColor: const Color(0xffD97706),
                        label: 'ច្បាប់ចូលប្រើប្រាស់',
                        valueWidget: FutureBuilder<dynamic>(
                          future: (app['id'] != null && app['id'].toString().isNotEmpty)
                              ? AuthService().fetchPortalAppAccessRulesByApp(app['id'].toString())
                              : Future.value(null),
                          builder: (context, snapshot) {
                            List<String> dynamicTags = List.from(ruleTags);
                            if (snapshot.hasData && snapshot.data != null) {
                              final res = snapshot.data;
                              List apiList = [];
                              if (res is List) {
                                apiList = res;
                              } else if (res is Map) {
                                apiList = (res['data'] as List?) ??
                                    (res['items'] as List?) ??
                                    (res['value'] as List?) ??
                                    (res['content'] as List?) ??
                                    [];
                              }
                              if (apiList.isNotEmpty) {
                                dynamicTags.clear();
                                for (final r in apiList) {
                                  final String tag = _formatAccessRuleTag(r);
                                  if (tag.isNotEmpty && !dynamicTags.contains(tag)) {
                                    dynamicTags.add(tag);
                                  }
                                }
                              }
                            }
                            if (dynamicTags.isEmpty) {
                              dynamicTags.add('ទូទៅ (ទាំងអស់)');
                            }
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: dynamicTags.map((tag) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xffFEF3C7),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: const Color(0xffFDE68A),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    tag,
                                    style: GoogleFonts.kantumruyPro(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xffB45309),
                                    ),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ),
                      const Divider(height: 24, color: Color(0xffF8FAFC)),

                      // 8. Created Date
                      _buildAppDetailRowItem(
                        icon: Icons.calendar_today_outlined,
                        iconBg: const Color(0xffF8FAFC),
                        iconColor: const Color(0xff475569),
                        label: 'កាលបរិច្ឆេទបង្កើត',
                        valueWidget: Text(
                          createdDate,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff0F172A),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Close Button
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xffE29D11),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'បិទ',
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatAccessRuleTag(dynamic rule) {
    if (rule is String) return rule;
    if (rule is! Map) return rule.toString();

    final String typeRaw = (rule['ruleType'] ?? rule['rule_type'] ?? rule['type'] ?? '').toString().toUpperCase();
    final String val = (rule['ruleValue'] ?? rule['rule_value'] ?? rule['value'] ?? rule['target'] ?? '').toString().trim();

    String typeKh = '';
    if (typeRaw.contains('GENERAL') || typeRaw.contains('GD')) {
      typeKh = 'អគ្គនាយកដ្ឋាន';
    } else if (typeRaw.contains('DEPT') || typeRaw.contains('DEPARTMENT')) {
      typeKh = 'នាយកដ្ឋាន';
    } else if (typeRaw.contains('BUREAU')) {
      typeKh = 'ការិយាល័យ';
    } else if (typeRaw.contains('BLOCK_USER') || typeRaw.contains('DENY_USER')) {
      typeKh = 'បដិសេធអ្នកប្រើប្រាស់';
    } else if (typeRaw.contains('BLOCK') || typeRaw.contains('DENY')) {
      typeKh = 'បដិសេធក្រុម';
    } else if (typeRaw.contains('JOB') || typeRaw.contains('TITLE') || typeRaw.contains('POSITION')) {
      typeKh = 'មុខតំណែង';
    } else if (typeRaw.contains('ROLE')) {
      typeKh = 'តួនាទី';
    } else if (typeRaw.contains('GROUP')) {
      typeKh = 'ក្រុម';
    } else if (typeRaw.contains('USER')) {
      typeKh = 'អ្នកប្រើប្រាស់';
    } else {
      typeKh = 'ក្រុម';
    }

    if (val.isNotEmpty) {
      return '$typeKh : $val';
    }
    return typeKh;
  }

  Widget _buildAppDetailRowItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required Widget valueWidget,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: iconColor),
        ),
        const SizedBox(width: 14),
        SizedBox(
          width: 120,
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              label,
              style: GoogleFonts.kantumruyPro(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xff475569),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: valueWidget,
          ),
        ),
      ],
    );
  }

  void _confirmDeleteApp(BuildContext context, int originalIndex, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          "លុបកម្មវិធី",
          style: GoogleFonts.kantumruyPro(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'តើអ្នកពិតជាចង់លុបកម្មវិធី "$name" នេះចេញពីប្រព័ន្ធមែនទេ?',
          style: GoogleFonts.kantumruyPro(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              "បោះបង់",
              style: GoogleFonts.kantumruyPro(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size(80, 36),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              controller.deleteApp(originalIndex);
            },
            child: Text(
              "លុប",
              style: GoogleFonts.kantumruyPro(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class SuperAdminAccessRuleEntry {
  String? id;
  String ruleType;
  String ruleValue;
  List<Map<String, String>> dynamicOptions;
  bool isLoading;

  SuperAdminAccessRuleEntry({
    this.id,
    required this.ruleType,
    required this.ruleValue,
    this.dynamicOptions = const [],
    this.isLoading = false,
  });
}

class SuperAdminAppCreateView extends StatefulWidget {
  final bool isEdit;
  final int? appIndex;
  final Map<String, dynamic>? appData;

  const SuperAdminAppCreateView({
    super.key,
    this.isEdit = false,
    this.appIndex,
    this.appData,
  });

  @override
  State<SuperAdminAppCreateView> createState() =>
      _SuperAdminAppCreateViewState();
}

class _SuperAdminAppCreateViewState extends State<SuperAdminAppCreateView> {
  final _controller = Get.find<SuperAdminController>();
  late final TextEditingController nameKhCtrl;
  late final TextEditingController nameEnCtrl;
  late final TextEditingController urlCtrl;
  late bool isActive;

  final List<SuperAdminAccessRuleEntry> accessRuleEntries = [];
  final List<String> _initialRuleIds = [];
  final Map<String, List<Map<String, String>>> _cachedRuleOptionsByType = {};

  List<int>? _pickedFileBytes;
  String? _pickedFileName;

  final List<Map<String, String>> ruleTypeOptions = [
    {'value': 'GENERAL_DEPARTMENT', 'label': 'អគ្គនាយកដ្ឋាន'},
    {'value': 'DEPARTMENT', 'label': 'នាយកដ្ឋាន'},
    {'value': 'BUREAU', 'label': 'ការិយាល័យ'},
    {'value': 'JOB_TITLE', 'label': 'មុខតំណែង'},
    {'value': 'ROLE', 'label': 'តួនាទី'},
    {'value': 'GROUP', 'label': 'ក្រុម'},
    {'value': 'USER', 'label': 'អ្នកប្រើប្រាស់'},
    {'value': 'DENY_GROUP', 'label': 'បដិសេធក្រុម'},
    {'value': 'DENY_USER', 'label': 'បដិសេធអ្នកប្រើប្រាស់'},
  ];

  Future<void> _pickIconFile() async {
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'svg'],
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        setState(() {
          _pickedFileBytes = file.bytes;
          _pickedFileName = file.name;
        });
      }
    } catch (e) {
      debugPrint("Error picking file: $e");
      CustomSnackbar.showError(message: 'មិនអាចជ្រើសរើសឯកសារបានទេ');
    }
  }

  String _normalizeRuleTypeToEnum(String input) {
    switch (input.trim()) {
      case 'អគ្គនាយកដ្ឋាន':
      case 'GENERAL_DEPARTMENT':
        return 'GENERAL_DEPARTMENT';
      case 'នាយកដ្ឋាន':
      case 'DEPARTMENT':
        return 'DEPARTMENT';
      case 'ការិយាល័យ':
      case 'BUREAU':
        return 'BUREAU';
      case 'មុខតំណែង':
      case 'តួនាទី / មុខតំណែង':
      case 'JOB_TITLE':
      case 'POSITION':
        return 'JOB_TITLE';
      case 'តួនាទី':
      case 'ROLE':
        return 'ROLE';
      case 'ក្រុម':
      case 'GROUP':
      case 'PORTAL_USER_GROUPS':
        return 'GROUP';
      case 'អ្នកប្រើប្រាស់':
      case 'USER':
        return 'USER';
      case 'បដិសេធក្រុម':
      case 'DENY_GROUP':
        return 'DENY_GROUP';
      case 'បដិសេធអ្នកប្រើប្រាស់':
      case 'DENY_USER':
        return 'DENY_USER';
      default:
        return input.trim().toUpperCase();
    }
  }

  String _extractKhmerText(String input) {
    final RegExp khmerRegex = RegExp(r'[\u1780-\u17FF\s]+');
    final matches = khmerRegex.allMatches(input);
    final khmerStr = matches.map((m) => m.group(0)).join(' ').trim();
    return khmerStr.isNotEmpty ? khmerStr : input;
  }

  Future<void> _fetchRuleValuesForEntry(SuperAdminAccessRuleEntry entry) async {
    final String apiRuleType = _normalizeRuleTypeToEnum(entry.ruleType);

    if (_cachedRuleOptionsByType.containsKey(apiRuleType) &&
        _cachedRuleOptionsByType[apiRuleType]!.isNotEmpty) {
      final cached = _cachedRuleOptionsByType[apiRuleType]!;
      setState(() {
        entry.dynamicOptions = cached;
        entry.isLoading = false;
        if (entry.ruleValue.isEmpty ||
            !cached.any((o) => o['value'] == entry.ruleValue)) {
          if (cached.isNotEmpty) {
            entry.ruleValue = cached.first['value']!;
          }
        }
      });
      return;
    }

    setState(() {
      entry.isLoading = true;
    });

    try {
      final List<Map<String, String>> options = [];
      final Set<String> addedValues = {};

      try {
        final authService = AuthService();
        final res = await authService.fetchRuleValues(apiRuleType);

        if (res != null) {
          List list = [];
          if (res is List) {
            list = res;
          } else if (res is Map) {
            list =
                (res['data'] as List?) ??
                (res['items'] as List?) ??
                (res['value'] as List?) ??
                (res['content'] as List?) ??
                (res['payload'] as List?) ??
                (res['results'] as List?) ??
                [];
          }
          for (var item in list) {
            if (item is Map) {
              final val =
                  (item['value'] ??
                          item['code'] ??
                          item['ruleValue'] ??
                          item['id'] ??
                          item['key'] ??
                          item['name'] ??
                          item['username'] ??
                          '')
                      .toString()
                      .trim();
              final rawLbl =
                  (item['label'] ??
                          item['name'] ??
                          item['title'] ??
                          item['description'] ??
                          item['groupName'] ??
                          item['fullName'] ??
                          val)
                      .toString()
                      .trim();

              final khmerLbl = _extractKhmerText(rawLbl);

              if (val.isNotEmpty && !addedValues.contains(val)) {
                addedValues.add(val);
                options.add({'value': val, 'label': khmerLbl});
              }
            } else if (item is String && item.trim().isNotEmpty) {
              final val = item.trim();
              if (!addedValues.contains(val)) {
                addedValues.add(val);
                options.add({'value': val, 'label': _extractKhmerText(val)});
              }
            }
          }
        }
      } catch (e) {
        debugPrint("Error fetching rule-values for $apiRuleType: $e");
      }

      if (options.isEmpty) {
        if (apiRuleType == 'GENERAL_DEPARTMENT') {
          final apiDepartments = [
            {
              'value': 'GDDTM',
              'label': 'អគ្គនាយកដ្ឋានបច្ចេកវិទ្យាឌីជីថល និងផ្សព្វផ្សាយ',
            },
            {'value': 'GDI', 'label': 'អគ្គនាយកដ្ឋានអន្តោប្រវេសន៍'},
            {'value': 'GS', 'label': 'អគ្គលេខាធិការដ្ឋាន'},
            {'value': 'GNP', 'label': 'អគ្គស្នងការដ្ឋាននគរបាលជាតិ'},
            {'value': 'GI', 'label': 'អគ្គាធិការដ្ឋាន'},
            {'value': 'GID', 'label': 'អគ្គនាយកដ្ឋានអត្តសញ្ញាណកម្ម'},
            {'value': 'GIA', 'label': 'អគ្គនាយកដ្ឋានសវនកម្មផ្ទៃក្នុង'},
            {'value': 'GLF', 'label': 'អគ្គនាយដ្ឋានភស្តុភារ និងហិរញ្ញវត្ថុ'},
            {'value': 'PAC', 'label': 'បណ្ឌិតសភានគរបាលកម្ពុជា'},
            {'value': 'LC', 'label': 'ក្រុមប្រឹក្សានីតិកម្ម'},
          ];
          for (var dept in apiDepartments) {
            if (!addedValues.contains(dept['value'])) {
              addedValues.add(dept['value']!);
              options.add(dept);
            }
          }
        } else if (apiRuleType == 'DEPARTMENT') {
          final deps = [
            {'value': 'GDDTM-D1', 'label': 'នាយកដ្ឋានបច្ចេកវិទ្យា'},
            {'value': 'GDDTM-D2', 'label': 'នាយកដ្ឋានព័ត៌មានវិទ្យា'},
            {'value': 'GDI-D1', 'label': 'នាយកដ្ឋានអន្តោប្រវេសន៍ I'},
            {'value': 'GID-D1', 'label': 'នាយកដ្ឋានអត្តសញ្ញាណកម្ម I'},
            {'value': 'GIA-D1', 'label': 'នាយកដ្ឋានសវនកម្ម I'},
            {'value': 'GS-D1', 'label': 'នាយកដ្ឋានលេខាធិការ'},
            {'value': 'GDHR-N*', 'label': 'នាយកដ្ឋានគ្រប់គ្រងបុគ្គលិក (GDHR)'},
            {'value': 'PAC', 'label': 'បណ្ឌិតសភានគរបាលកម្ពុជា'},
          ];
          for (var d in deps) {
            if (!addedValues.contains(d['value'])) {
              addedValues.add(d['value']!);
              options.add(d);
            }
          }
        } else if (apiRuleType == 'BUREAU') {
          final bureaus = [
            {'value': 'GDDTM-N1-B1', 'label': 'ការិយាល័យបច្ចេកទេស'},
            {'value': 'GDI-N1-B1', 'label': 'ការិយាល័យអន្តោប្រវេសន៍'},
            {'value': 'GID-N1-B1', 'label': 'ការិយាល័យអត្តសញ្ញាណ'},
            {'value': 'GDHR-N*-B*', 'label': 'ការិយាល័យបុគ្គលិកទូទៅ'},
          ];
          for (var b in bureaus) {
            if (!addedValues.contains(b['value'])) {
              addedValues.add(b['value']!);
              options.add(b);
            }
          }
        } else if (apiRuleType == 'JOB_TITLE' || apiRuleType == 'POSITION') {
          final defaults = [
            {'value': 'DIRECTOR', 'label': 'ប្រធាន (DIRECTOR)'},
            {'value': 'DEPUTY_DIRECTOR', 'label': 'អនុប្រធាន (DEPUTY_DIRECTOR)'},
            {'value': 'CHIEF', 'label': 'ប្រធានការិយាល័យ (CHIEF)'},
            {'value': 'OFFICER', 'label': 'មន្ត្រី (OFFICER)'},
            {'value': 'ASSISTANT', 'label': 'ជំនួយការ (ASSISTANT)'},
          ];
          options.addAll(defaults);
        } else if (apiRuleType == 'ROLE') {
          final defaults = [
            {
              'value': 'GENERAL_DEPARTMENT_ADMIN',
              'label': 'អ្នកគ្រប់គ្រងអគ្គនាយកដ្ឋាន',
            },
            {'value': 'PORTAL_ADMIN', 'label': 'អ្នកគ្រប់គ្រងប្រព័ន្ធ (PORTAL_ADMIN)'},
            {'value': 'ROLE_SUPER_ADMIN', 'label': 'អ្នកគ្រប់គ្រងជាន់ខ្ពស់'},
            {'value': 'ROLE_USER', 'label': 'អ្នកប្រើប្រាស់ទូទៅ'},
          ];
          options.addAll(defaults);
        } else if (apiRuleType == 'GROUP' ||
            apiRuleType == 'PORTAL_USER_GROUPS') {
          final defaults = [
            {'value': 'GDDTM_ADMINS', 'label': 'ក្រុមគ្រប់គ្រង GDDTM'},
            {'value': 'GDDTM_USERS', 'label': 'ក្រុមអ្នកប្រើប្រាស់ GDDTM'},
            {'value': 'GDHR_USERS', 'label': 'ក្រុមអ្នកប្រើប្រាស់ GDHR'},
            {'value': 'GDI_USERS', 'label': 'ក្រុមអ្នកប្រើប្រាស់ GDI'},
            {'value': 'GS_USERS', 'label': 'ក្រុមអ្នកប្រើប្រាស់ GS'},
          ];
          options.addAll(defaults);
        } else if (apiRuleType == 'DENY_GROUP') {
          final defaults = [
            {'value': 'BLOCKED_PORTAL_USERS', 'label': 'ក្រុមអ្នកប្រើប្រាស់ដែលត្រូវបានរារាំង'},
            {'value': 'GDHR', 'label': 'ក្រុម GDHR'},
            {'value': 'TEMP_BLOCKED', 'label': 'ក្រុមផ្អាកបណ្ដោះអាសន្ន'},
          ];
          options.addAll(defaults);
        } else if (apiRuleType == 'USER') {
          final controller = Get.find<SuperAdminController>();
          for (var item in controller.usersList) {
            final uname = (item['username'] ?? item['email'] ?? '').toString();
            final name = _extractKhmerText(
              (item['fullName'] ?? item['name'] ?? uname).toString(),
            );
            if (uname.isNotEmpty && !addedValues.contains(uname)) {
              addedValues.add(uname);
              options.add({'value': uname, 'label': name});
            }
          }
          if (options.isEmpty) {
            options.add({
              'value': 'DEV.PORTAL.USER',
              'label': 'គណនីអភិវឌ្ឍន៍ (DEV.PORTAL.USER)',
            });
          }
        } else if (apiRuleType == 'DENY_USER') {
          options.addAll([
            {
              'value': 'DISABLED.DEV.USER',
              'label': 'គណនីផ្អាក (DISABLED.DEV.USER)',
            },
            {
              'value': 'SUSPENDED_USER',
              'label': 'គណនីជាប់ពិន័យ (SUSPENDED_USER)',
            },
          ]);
        }
      }

      _cachedRuleOptionsByType[apiRuleType] = options;

      setState(() {
        entry.dynamicOptions = options;
        entry.isLoading = false;
        if (entry.ruleValue.isEmpty ||
            !options.any((o) => o['value'] == entry.ruleValue)) {
          if (options.isNotEmpty) {
            entry.ruleValue = options.first['value']!;
          }
        }
      });
    } catch (e) {
      debugPrint("Error fetching rule values: $e");
      setState(() {
        entry.isLoading = false;
      });
    }
  }

  void _addRuleEntry([String? ruleType, String? ruleValue, String? id]) {
    final newEntry = SuperAdminAccessRuleEntry(
      id: id,
      ruleType: ruleType ?? 'GENERAL_DEPARTMENT',
      ruleValue: ruleValue ?? 'GDDTM',
    );
    setState(() {
      accessRuleEntries.add(newEntry);
    });
    _fetchRuleValuesForEntry(newEntry);
  }

  void _removeRuleEntry(int index) {
    if (accessRuleEntries.length > 1 && index >= 0 && index < accessRuleEntries.length) {
      setState(() {
        accessRuleEntries.removeAt(index);
      });
    }
  }

  Future<void> _loadAccessRulesFromApi() async {
    final String appId = (widget.appData?['id'] ?? widget.appData?['appId'] ?? '').toString();
    if (appId.isEmpty) return;

    try {
      final authService = AuthService();
      final res = await authService.fetchPortalAppAccessRulesByApp(appId);
      if (res != null) {
        List rawList = [];
        if (res is List) {
          rawList = res;
        } else if (res is Map) {
          rawList = (res['data'] as List?) ??
              (res['items'] as List?) ??
              (res['value'] as List?) ??
              (res['content'] as List?) ??
              [];
        }
        if (rawList.isNotEmpty && mounted) {
          final List<SuperAdminAccessRuleEntry> apiEntries = [];
          _initialRuleIds.clear();

          for (var r in rawList) {
            if (r is Map) {
              final String? rId = r['id']?.toString();
              if (rId != null && rId.isNotEmpty) {
                _initialRuleIds.add(rId);
              }
              final String t = _normalizeRuleTypeToEnum(
                (r['ruleType'] ?? r['rule_type'] ?? r['type'] ?? 'GENERAL_DEPARTMENT').toString(),
              );
              final String v = (r['ruleValue'] ?? r['rule_value'] ?? r['value'] ?? '').toString().trim();
              if (t.isNotEmpty && v.isNotEmpty) {
                apiEntries.add(
                  SuperAdminAccessRuleEntry(id: rId, ruleType: t, ruleValue: v),
                );
              }
            }
          }

          if (apiEntries.isNotEmpty) {
            setState(() {
              accessRuleEntries.clear();
              accessRuleEntries.addAll(apiEntries);
            });
            for (final entry in accessRuleEntries) {
              _fetchRuleValuesForEntry(entry);
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading access rules from API for app $appId: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    String nameKh = '';
    String nameEn = '';
    String url = '';
    isActive = true;

    if (widget.isEdit && widget.appData != null) {
      nameKh = widget.appData!['titleKh'] ?? '';
      nameEn = widget.appData!['titleEn'] ?? '';
      url = widget.appData!['route'] ?? '';
      isActive = widget.appData!['isActive'] ?? true;

      final List rawRules = widget.appData!['accessRules'] is List
          ? widget.appData!['accessRules']
          : [];

      if (rawRules.isNotEmpty) {
        for (final r in rawRules) {
          if (r is Map) {
            final String? rId = r['id']?.toString();
            if (rId != null && rId.isNotEmpty) {
              _initialRuleIds.add(rId);
            }
            final String t = _normalizeRuleTypeToEnum(
              (r['ruleType'] ?? r['type'] ?? 'GENERAL_DEPARTMENT').toString(),
            );
            final String v =
                (r['ruleValue'] ?? r['value'] ?? '').toString().trim();
            if (t.isNotEmpty && v.isNotEmpty) {
              accessRuleEntries.add(
                SuperAdminAccessRuleEntry(id: rId, ruleType: t, ruleValue: v),
              );
            }
          }
        }
      }

      if (accessRuleEntries.isEmpty && widget.appData!['ruleType'] != null) {
        final String t = _normalizeRuleTypeToEnum(
          widget.appData!['ruleType'] ?? 'GENERAL_DEPARTMENT',
        );
        final String v = (widget.appData!['ruleValue'] ?? 'GDDTM').toString().trim();
        accessRuleEntries.add(
          SuperAdminAccessRuleEntry(ruleType: t, ruleValue: v),
        );
      }
      
      // Also query fresh rules from API for this app
      _loadAccessRulesFromApi();
    }

    if (accessRuleEntries.isEmpty) {
      accessRuleEntries.add(
        SuperAdminAccessRuleEntry(
          ruleType: 'GENERAL_DEPARTMENT',
          ruleValue: 'GDDTM',
        ),
      );
    }

    nameKhCtrl = TextEditingController(text: nameKh);
    nameEnCtrl = TextEditingController(text: nameEn);
    urlCtrl = TextEditingController(text: url);

    for (final entry in accessRuleEntries) {
      _fetchRuleValuesForEntry(entry);
    }
  }

  @override
  void dispose() {
    nameKhCtrl.dispose();
    nameEnCtrl.dispose();
    urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF163774),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.isEdit
              ? "កែប្រែកម្មវិធីប្រើប្រាស់"
              : "បង្កើតកម្មវិធីប្រើប្រាស់ថ្មី",
          style: GoogleFonts.kantumruyPro(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: const Color(0xff0F172A),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Color(0xffE2E8F0))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.isEdit
                        ? "កែប្រែកម្មវិធីប្រើប្រាស់"
                        : "បង្កើតកម្មវិធីប្រើប្រាស់ថ្មី",
                    style: GoogleFonts.kantumruyPro(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xff0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "បញ្ចូលព័ត៌មានកម្មវិធី URL ច្បាប់ចូលប្រើប្រាស់ និងរូបសញ្ញា",
                    style: GoogleFonts.kantumruyPro(
                      fontSize: 12,
                      color: const Color(0xff64748B),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputLabel("ឈ្មោះកម្មវិធី (ខ្មែរ) *"),
                            TextField(
                              controller: nameKhCtrl,
                              decoration: _buildInputDecoration(
                                "បញ្ចូលឈ្មោះកម្មវិធីជាភាសាខ្មែរ",
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInputLabel("ឈ្មោះកម្មវិធី (អង់គ្លេស) *"),
                            TextField(
                              controller: nameEnCtrl,
                              decoration: _buildInputDecoration(
                                "បញ្ចូលឈ្មោះកម្មវិធីជាភាសាអង់គ្លេស",
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildInputLabel("URL *"),
                  TextField(
                    controller: urlCtrl,
                    decoration: _buildInputDecoration(
                      "បញ្ចូល URL (ឧ. https://example.moi.gov.kh)",
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ─── Multiple Access Rules (ច្បាប់ចូលប្រើប្រាស់) ───
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInputLabel("ច្បាប់ចូលប្រើប្រាស់ *"),
                      InkWell(
                        onTap: () => _addRuleEntry(),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF163774).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFF163774).withOpacity(0.2),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.add_circle_outline_rounded,
                                size: 15,
                                color: Color(0xFF163774),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "បន្ថែមច្បាប់",
                                style: GoogleFonts.kantumruyPro(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF163774),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: accessRuleEntries.length,
                    separatorBuilder: (context, i) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final entry = accessRuleEntries[index];
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xffF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xffE2E8F0)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        color: const Color(0xffFEF3C7),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.shield_outlined,
                                          size: 13,
                                          color: Color(0xffD97706),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "ច្បាប់ #${index + 1}",
                                      style: GoogleFonts.kantumruyPro(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xff0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                                if (accessRuleEntries.length > 1)
                                  InkWell(
                                    onTap: () => _removeRuleEntry(index),
                                    borderRadius: BorderRadius.circular(6),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: const Color(0xffFEE2E2),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(
                                        Icons.delete_outline_rounded,
                                        size: 16,
                                        color: Color(0xffEF4444),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildSubInputLabel("ប្រភេទច្បាប់"),
                                      _buildStyledDropdown<String>(
                                        value:
                                            ruleTypeOptions.any(
                                              (o) => o['value'] == entry.ruleType,
                                            )
                                            ? entry.ruleType
                                            : 'GENERAL_DEPARTMENT',
                                        prefixIcon: Icons.gavel_rounded,
                                        items: ruleTypeOptions.map((opt) {
                                          return DropdownMenuItem<String>(
                                            value: opt['value'],
                                            child: Text(
                                              opt['label']!,
                                              style: GoogleFonts.kantumruyPro(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: const Color(0xff0F172A),
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (val) {
                                          if (val != null) {
                                            setState(() {
                                              entry.ruleType = val;
                                            });
                                            _fetchRuleValuesForEntry(entry);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      _buildSubInputLabel("តម្លៃច្បាប់"),
                                      entry.isLoading
                                          ? Container(
                                              height: 48,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: const Color(0xffE2E8F0),
                                                ),
                                              ),
                                              child: const Center(
                                                child: SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    color: Color(0xFF163774),
                                                  ),
                                                ),
                                              ),
                                            )
                                          : entry.dynamicOptions.isEmpty
                                          ? TextField(
                                              controller: TextEditingController(
                                                text: entry.ruleValue,
                                              )..selection =
                                                  TextSelection.fromPosition(
                                                    TextPosition(
                                                      offset:
                                                          entry
                                                              .ruleValue
                                                              .length,
                                                    ),
                                                  ),
                                              onChanged: (v) =>
                                                  entry.ruleValue = v,
                                              decoration: _buildInputDecoration(
                                                'បញ្ចូលតម្លៃច្បាប់',
                                              ),
                                              style: GoogleFonts.kantumruyPro(
                                                fontSize: 13,
                                              ),
                                            )
                                          : _buildStyledDropdown<String>(
                                              value:
                                                  entry.dynamicOptions.any(
                                                    (o) =>
                                                        o['value'] ==
                                                        entry.ruleValue,
                                                  )
                                                  ? entry.ruleValue
                                                  : entry
                                                      .dynamicOptions
                                                      .first['value'],
                                              prefixIcon: Icons.tune_rounded,
                                              items: entry.dynamicOptions.map((
                                                opt,
                                              ) {
                                                return DropdownMenuItem<String>(
                                                  value: opt['value'],
                                                  child: Text(
                                                    opt['label'] ??
                                                        opt['value'] ??
                                                        '',
                                                    style:
                                                        GoogleFonts.kantumruyPro(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: const Color(
                                                            0xff0F172A,
                                                          ),
                                                        ),
                                                  ),
                                                );
                                              }).toList(),
                                              onChanged: (val) {
                                                if (val != null) {
                                                  setState(() {
                                                    entry.ruleValue = val;
                                                  });
                                                }
                                              },
                                            ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF163774),
                      side: const BorderSide(
                        color: Color(0xFF163774),
                        width: 1.2,
                      ),
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => _addRuleEntry(),
                    icon: const Icon(
                      Icons.add_circle_outline_rounded,
                      size: 18,
                    ),
                    label: Text(
                      "បន្ថែមច្បាប់ចូលប្រើប្រាស់ថ្មី",
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildInputLabel("រូបសញ្ញា / Icon Logo (File)"),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xffE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.01),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF163774,
                            ).withOpacity(0.1),
                            foregroundColor: const Color(0xFF163774),
                            elevation: 0,
                            minimumSize: const Size(0, 40),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _pickIconFile,
                          icon: const Icon(
                            Icons.file_upload_outlined,
                            size: 18,
                          ),
                          label: Text(
                            "ជ្រើសរើសឯកសារ",
                            style: GoogleFonts.kantumruyPro(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _pickedFileName ??
                                (widget.isEdit
                                    ? "រក្សាទុករូបសញ្ញាចាស់"
                                    : "មិនទាន់មានឯកសារជ្រើសរើសទេ"),
                            style: GoogleFonts.kantumruyPro(
                              fontSize: 12,
                              color: _pickedFileName != null
                                  ? Colors.black
                                  : Colors.grey,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildInputLabel("ស្ថានភាព *"),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatusRadioCard("កំពុងដំណើរការ", true),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildStatusRadioCard("មិនដំណើរការ", false),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xff475569),
                          elevation: 0,
                          side: const BorderSide(color: Color(0xffCBD5E1)),
                          minimumSize: const Size(100, 42),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          "បោះបង់",
                          style: GoogleFonts.kantumruyPro(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff2563EB),
                          foregroundColor: Colors.white,
                          elevation: 2,
                          shadowColor: const Color(0xff2563EB).withOpacity(0.3),
                          minimumSize: const Size(100, 42),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                        ),
                        onPressed: _saveForm,
                        icon: const Icon(Icons.save_rounded, size: 18),
                        label: Text(
                          "រក្សាទុក",
                          style: GoogleFonts.kantumruyPro(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Custom expandable Card Picker to handle long multi-line Khmer labels without clipping
  Widget _buildStyledDropdown<T>({
    required T? value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    required IconData prefixIcon,
  }) {
    String displayLabel = 'ជ្រើសរើស';
    for (var item in items) {
      if (item.value == value) {
        if (item.child is Text) {
          displayLabel = (item.child as Text).data ?? '';
        }
        break;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffCBD5E1), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff0F172A).withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Get.bottomSheet(
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 16,
                ),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "ជ្រើសរើសទិន្នន័យ",
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xff0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: items.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1, color: Color(0xffF1F5F9)),
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final isSelected = item.value == value;

                          String label = '';
                          if (item.child is Text) {
                            label = (item.child as Text).data ?? '';
                          }

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            title: Text(
                              label,
                              style: GoogleFonts.kantumruyPro(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? const Color(0xff2563EB)
                                    : const Color(0xff1E293B),
                                height: 1.4,
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(
                                    Icons.check_circle_rounded,
                                    color: Color(0xff2563EB),
                                    size: 20,
                                  )
                                : null,
                            onTap: () {
                              onChanged(item.value);
                              Get.back();
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              isScrollControlled: true,
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Icon(prefixIcon, size: 18, color: const Color(0xff64748B)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    displayLabel,
                    style: GoogleFonts.kantumruyPro(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xff0F172A),
                      height: 1.4,
                    ),
                    softWrap: true,
                    maxLines: 4,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xff64748B),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.kantumruyPro(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: const Color(0xff334155),
        ),
      ),
    );
  }

  Widget _buildSubInputLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: GoogleFonts.kantumruyPro(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: const Color(0xff64748B),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.kantumruyPro(
        fontSize: 13,
        color: Colors.grey[400],
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xffCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xffCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xff2563EB), width: 1.5),
      ),
    );
  }

  Widget _buildStatusRadioCard(String label, bool value) {
    final isSelected = isActive == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          isActive = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xffFEF3C7).withOpacity(0.3)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xffD97706)
                : const Color(0xffE2E8F0),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? const Color(0xffD97706) : Colors.grey,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Container(
                      margin: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xffD97706),
                        shape: BoxShape.circle,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.kantumruyPro(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? const Color(0xff92400E)
                    : const Color(0xff1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveForm() {
    final nameKh = nameKhCtrl.text.trim();
    final nameEn = nameEnCtrl.text.trim();
    final url = urlCtrl.text.trim();

    final List<Map<String, dynamic>> compiledAccessRules = [];
    for (final entry in accessRuleEntries) {
      if (entry.ruleType.trim().isNotEmpty &&
          entry.ruleValue.trim().isNotEmpty) {
        compiledAccessRules.add({
          if (entry.id != null && entry.id!.isNotEmpty) 'id': entry.id,
          'ruleType': entry.ruleType.trim(),
          'ruleValue': entry.ruleValue.trim(),
        });
      }
    }

    if (nameKh.isEmpty ||
        nameEn.isEmpty ||
        url.isEmpty ||
        compiledAccessRules.isEmpty) {
      CustomSnackbar.showError(message: 'សូមបំពេញព័ត៌មានអោយបានគ្រប់គ្រាន់');
      return;
    }

    final List<String> currentRuleIds = compiledAccessRules
        .map((r) => r['id']?.toString() ?? '')
        .where((id) => id.isNotEmpty)
        .toList();
    final List<String> deletedRuleIds = _initialRuleIds
        .where((origId) => !currentRuleIds.contains(origId))
        .toList();

    if (widget.isEdit && widget.appIndex != null) {
      _controller.updateApp(
        index: widget.appIndex!,
        nameKh: nameKh,
        nameEn: nameEn,
        url: url,
        accessRules: compiledAccessRules,
        deletedRuleIds: deletedRuleIds,
        isActive: isActive,
        fileBytes: _pickedFileBytes,
        fileName: _pickedFileName,
      );
    } else {
      _controller.addNewApp(
        nameKh: nameKh,
        nameEn: nameEn,
        url: url,
        accessRules: compiledAccessRules,
        isActive: isActive,
        fileBytes: _pickedFileBytes,
        fileName: _pickedFileName,
      );
    }
    Navigator.of(context).pop();
  }
}

class DonutChartPainter extends CustomPainter {
  final List<double> values;
  final List<Color> colors;

  DonutChartPainter({required this.values, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final double total = values.fold(0, (sum, val) => sum + val);
    if (total == 0) {
      final paint = Paint()
        ..color = const Color(0xffF1F5F9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14;
      canvas.drawCircle(
        Offset(size.width / 2, size.height / 2),
        size.width / 2 - 10,
        paint,
      );
      return;
    }

    final double center = size.width / 2;
    final double radius = size.width / 2 - 10;
    final rect = Rect.fromCircle(
      center: Offset(center, center),
      radius: radius,
    );

    double startAngle = -3.1415926535 / 2;
    for (int i = 0; i < values.length; i++) {
      if (values[i] == 0) continue;
      final sweepAngle = (values[i] / total) * 3.1415926535 * 2;
      final paint = Paint()
        ..color = colors[i % colors.length]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 14
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
