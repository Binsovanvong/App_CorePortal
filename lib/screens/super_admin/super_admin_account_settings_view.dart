import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core_portal/core/api/services/auth_service.dart';

// ==========================================
// CONTROLLER
// ==========================================
class SuperAdminAccountSettingsController extends GetxController {
  final AuthService _authService = AuthService();

  final isLoading = false.obs;
  final userId = "e9ba0fa9-dc6d-41aa-aa3d-e81e468b35f2".obs;
  final displayName = "admin admin".obs;
  final username = "admin".obs;
  final email = "admin@mail.com".obs;
  final phone = "—".obs;
  final organization = "GDDTM".obs;
  final classLevel = "GDDTM".obs;
  final position = "—".obs;
  final loginDate = "—".obs;
  final mechanism = "—".obs;
  final status = "សកម្ម".obs;

  final permissionsList = <Map<String, String>>[].obs;
  final searchQuery = ''.obs;
  final selectedTypeFilter = 'ALL'.obs;

  // Pagination states
  final currentPage = 1.obs;
  final int itemsPerPage = 10;

  // Computed properties for easy UI access and reactive processing
  List<Map<String, String>> get filteredList {
    return permissionsList.where((item) {
      final matchesType = selectedTypeFilter.value == 'ALL' ||
          item['type'] == selectedTypeFilter.value;
      final q = searchQuery.value.toLowerCase().trim();
      final matchesQuery = q.isEmpty ||
          (item['name'] ?? '').toLowerCase().contains(q) ||
          (item['type'] ?? '').toLowerCase().contains(q);
      return matchesType && matchesQuery;
    }).toList();
  }

  int get totalItems => filteredList.length;

  int get totalPages => (totalItems / itemsPerPage).ceil() == 0
      ? 1
      : (totalItems / itemsPerPage).ceil();

  int get startIdx => (currentPage.value - 1) * itemsPerPage;

  int get endIdx => (startIdx + itemsPerPage) > totalItems
      ? totalItems
      : (startIdx + itemsPerPage);

  List<Map<String, String>> get paginatedList {
    if (currentPage.value > totalPages) {
      currentPage.value = totalPages > 0 ? totalPages : 1;
    }
    return filteredList.skip(startIdx).take(itemsPerPage).toList();
  }

  @override
  void onInit() {
    super.onInit();
    fetchProfileData();
  }

  Future<void> fetchProfileData() async {
    try {
      isLoading.value = true;
      final rawData = await _authService.fetchProfile();
      if (rawData != null && rawData is Map) {
        final Map<String, dynamic> data = rawData['user'] is Map
            ? Map<String, dynamic>.from(rawData['user'])
            : rawData['data'] is Map
                ? Map<String, dynamic>.from(rawData['data'])
                : Map<String, dynamic>.from(rawData);

        userId.value =
            (data['id'] ??
                    data['sub'] ??
                    data['userProfileUserId'] ??
                    data['keycloakUserId'] ??
                    "e9ba0fa9-dc6d-41aa-aa3d-e81e468b35f2")
                .toString();
        final rawUname = (data['username'] ?? "admin").toString();
        username.value = rawUname;

        String dName = (data['displayName'] ??
                data['display_name'] ??
                data['fullName'] ??
                data['full_name'] ??
                data['name_kh'] ??
                data['nameKh'] ??
                '')
            .toString()
            .trim();

        if ((dName.isEmpty || dName.toLowerCase() == rawUname.toLowerCase()) && data['attributes'] is Map) {
          final attrDisp = data['attributes']['displayName'] ?? data['attributes']['display_name'];
          if (attrDisp is List && attrDisp.isNotEmpty) {
            dName = attrDisp.first.toString().trim();
          } else if (attrDisp is String) {
            dName = attrDisp.trim();
          }
        }

        if (dName.isEmpty || dName.toLowerCase() == rawUname.toLowerCase()) {
          final first = (data['firstName'] ?? data['first_name'] ?? '').toString().trim();
          final last = (data['lastName'] ?? data['last_name'] ?? '').toString().trim();
          if (first.isNotEmpty || last.isNotEmpty) {
            dName = '$first $last'.trim();
          }
        }

        if (dName.isEmpty || dName.toLowerCase() == rawUname.toLowerCase()) {
          final rawName = (data['name'] ?? '').toString().trim();
          if (rawName.isNotEmpty && rawName.toLowerCase() != rawUname.toLowerCase()) {
            dName = rawName;
          }
        }

        if (dName.isEmpty || dName.toLowerCase() == rawUname.toLowerCase()) {
          if (rawUname.contains('.')) {
            final parts = rawUname.split('.');
            if (parts.length == 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
              final p0 = '${parts[0][0].toUpperCase()}${parts[0].substring(1)}';
              final p1 = '${parts[1][0].toUpperCase()}${parts[1].substring(1)}';
              dName = '$p1 $p0';
            }
          }
        }

        if (dName.isEmpty) {
          dName = rawUname.isNotEmpty ? rawUname : "admin admin";
        }

        displayName.value = dName;
        email.value = (data['email'] ?? "admin@mail.com").toString();
        phone.value = (data['phone'] ?? data['phoneNumber'] ?? "—").toString();
        organization.value =
            (data['generalDepartmentNameKh'] ??
                    data['generalDepartmentName'] ??
                    data['organization'] ??
                    data['department'] ??
                    "GDDTM")
                .toString();
        classLevel.value = (data['classLevel'] ?? "GDDTM").toString();
        position.value = (data['position'] ?? "—").toString();
        loginDate.value = (data['loginDate'] ?? data['lastLogin'] ?? "—")
            .toString();
        mechanism.value = (data['mechanism'] ?? "—").toString();
        status.value = (data['status'] ?? "សកម្ម").toString();

        final List<Map<String, String>> list = [];

        // Parse roles from API payload
        dynamic rolesVal = data['roles'] ?? data['userRoles'] ?? data['role'];
        if (data['realm_access'] is Map &&
            data['realm_access']['roles'] is List) {
          rolesVal = data['realm_access']['roles'];
        }
        if (rolesVal is List) {
          for (var r in rolesVal) {
            final String name =
                (r is Map ? (r['name'] ?? r['code'] ?? r.toString()) : r)
                    .toString()
                    .trim();
            if (name.isNotEmpty && !name.startsWith('default-roles')) {
              list.add({
                'type': 'តួនាទី',
                'name': name,
                'source': 'រៀបចំដោយកម្មវិធីផ្ទាល់',
              });
            }
          }
        } else if (rolesVal is String && rolesVal.isNotEmpty) {
          list.add({
            'type': 'តួនាទី',
            'name': rolesVal,
            'source': 'រៀបចំដោយកម្មវិធីផ្ទាល់',
          });
        }

        // Parse groups from API payload
        dynamic groupsVal =
            data['groups'] ??
            data['userGroups'] ??
            data['portalGroups'] ??
            data['groupCodes'];
        if (groupsVal is List) {
          for (var g in groupsVal) {
            final String name =
                (g is Map
                        ? (g['name'] ??
                              g['groupName'] ??
                              g['code'] ??
                              g.toString())
                        : g)
                    .toString()
                    .trim();
            final cleanName = name.startsWith('/') ? name.substring(1) : name;
            if (cleanName.isNotEmpty) {
              list.add({
                'type': 'ក្រុម',
                'name': cleanName,
                'source': 'រៀបចំដោយកម្មវិធីផ្ទាល់',
              });
            }
          }
        }

        // Dynamic fetch user groups from API service
        if (userId.value.isNotEmpty) {
          try {
            final userGroupsRes = await _authService.fetchUserGroups(
              userId.value,
            );
            if (userGroupsRes != null) {
              List items = [];
              if (userGroupsRes is List) {
                items = userGroupsRes;
              } else if (userGroupsRes is Map) {
                final d =
                    userGroupsRes['data'] ??
                    userGroupsRes['items'] ??
                    userGroupsRes['userGroups'] ??
                    userGroupsRes['groups'];
                if (d is List) items = d;
              }
              for (var item in items) {
                String? name;
                if (item is Map) {
                  final grpObj = item['group'] is Map ? item['group'] : item;
                  name =
                      (grpObj['name'] ??
                              grpObj['groupName'] ??
                              grpObj['groupCode'] ??
                              grpObj['code'])
                          ?.toString();
                } else if (item is String) {
                  name = item.startsWith('/') ? item.substring(1) : item;
                }
                if (name != null && name.trim().isNotEmpty) {
                  final clean = name.trim();
                  if (!list.any(
                    (e) => e['name'] == clean && e['type'] == 'ក្រុម',
                  )) {
                    list.add({
                      'type': 'ក្រុម',
                      'name': clean,
                      'source': 'រៀបចំដោយកម្មវិធីផ្ទាល់',
                    });
                  }
                }
              }
            }
          } catch (e) {
            debugPrint("Error fetching account settings user groups: $e");
          }
        }

        // Parse permissions from API payload
        dynamic permsVal =
            data['permissions'] ??
            data['userPermissions'] ??
            data['scopes'] ??
            data['authorities'];
        if (permsVal is List) {
          for (var p in permsVal) {
            final String name =
                (p is Map
                        ? (p['name'] ??
                              p['code'] ??
                              p['authority'] ??
                              p.toString())
                        : p)
                    .toString()
                    .trim();
            if (name.isNotEmpty) {
              list.add({
                'type': 'សិទ្ធិ',
                'name': name,
                'source': 'រៀបចំដោយកម្មវិធីផ្ទាល់',
              });
            }
          }
        }

        permissionsList.value = list;
        currentPage.value = 1;
      }
    } catch (e) {
      debugPrint("Failed to fetch account settings profile: $e");
    } finally {
      isLoading.value = false;
    }
  }
}

// ==========================================
// VIEW
// ==========================================
class SuperAdminAccountSettingsView extends StatelessWidget {
  const SuperAdminAccountSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SuperAdminAccountSettingsController());

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: SafeArea(child: _buildHeader(context)),
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFB08940)),
          );
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // CONTAINER 1: Premium Avatar & Status Header Card
                  _buildModernAvatarCard(controller),
                  const SizedBox(height: 16),

                  // CONTAINER 2: Ultra-Clean Structured Information Card
                  _buildModernInfoGridCard(context, constraints, controller),
                  const SizedBox(height: 16),

                  // CONTAINER 3: Permissions Section with Active Pagination
                  _buildPermissionsCard(context, controller),
                ],
              ),
            );
          },
        );
      }),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 16, right: 16, top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff0F172A).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                size: 16,
                color: Color(0xff334155),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              "ព័ត៌មានគណនី",
              style: GoogleFonts.kantumruyPro(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFB08940),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernAvatarCard(
    SuperAdminAccountSettingsController controller,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xffE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xff0F172A).withOpacity(0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xff2563EB), Color(0xff3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xff2563EB).withOpacity(0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              "AA",
              style: GoogleFonts.poppins(
                fontSize: 34,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            controller.displayName.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.kantumruyPro(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xff0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "អ្នកគ្រប់គ្រងប្រព័ន្ធ",
            style: GoogleFonts.kantumruyPro(
              fontSize: 13,
              color: const Color(0xff64748B),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xffECFDF5),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: const Color(0xffA7F3D0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xff10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  "សកម្ម",
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff059669),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernInfoGridCard(
    BuildContext context,
    BoxConstraints constraints,
    SuperAdminAccountSettingsController controller,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xff2563EB).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.person_pin_rounded,
                  color: Color(0xff2563EB),
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "ព័ត៌មានអ្នកប្រើប្រាស់",
                style: GoogleFonts.kantumruyPro(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff0F172A),
                ),
              ),
            ],
          ),
          const Divider(height: 32, color: Color(0xffF1F5F9), thickness: 1.5),

          _buildInfoRow(
            "លេខសម្គាល់គណនី",
            controller.userId.value,
            isHighlight: true,
          ),
          _buildInfoRowDivider(),
          _buildInfoRow("ឈ្មោះពេញ", controller.displayName.value),
          _buildInfoRowDivider(),
          _buildInfoRow("ឈ្មោះគណនី", controller.username.value),
          _buildInfoRowDivider(),
          _buildInfoRow("អ៊ីមែល", controller.email.value),
          _buildInfoRowDivider(),
          _buildInfoRow("លេខទូរស័ព្ទ", controller.phone.value),
          _buildInfoRowDivider(),
          _buildInfoRow("អង្គភាព", controller.organization.value),
          _buildInfoRowDivider(),
          _buildInfoRow("កម្រិតថ្នាក់", controller.classLevel.value),
          _buildInfoRowDivider(),
          _buildInfoRow("មុខតំណែង", controller.position.value),
          _buildInfoRowDivider(),
          _buildInfoRow("ថ្ងៃចូលប្រើ", controller.loginDate.value),
          _buildInfoRowDivider(),
          _buildInfoRow("ការរៀបចំយន្តការ", controller.mechanism.value),
          _buildInfoRowDivider(),
          _buildInfoRow("ស្ថានភាព", controller.status.value, isStatus: true),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isHighlight = false,
    bool isStatus = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 4,
            child: Text(
              label,
              style: GoogleFonts.kantumruyPro(
                fontSize: 13,
                color: const Color(0xff64748B),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 7,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: GoogleFonts.kantumruyPro(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isStatus
                    ? const Color(0xff10B981)
                    : (isHighlight
                          ? const Color(0xff2563EB)
                          : const Color(0xff1E293B)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRowDivider() {
    return const Divider(height: 20, color: Color(0xffF8FAFC), thickness: 1);
  }

  Widget _buildPermissionsCard(
    BuildContext context,
    SuperAdminAccountSettingsController controller,
  ) {
    final int roleCount = controller.permissionsList
        .where((item) => item['type'] == 'តួនាទី')
        .length;
    final int groupCount = controller.permissionsList
        .where((item) => item['type'] == 'ក្រុម')
        .length;
    final int permCount = controller.permissionsList
        .where((item) => item['type'] == 'សិទ្ធិ')
        .length;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
                    Icons.verified_user_rounded,
                    color: Color(0xff8B5CF6),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "សម្រេចសិទ្ធិប្រើប្រាស់",
                    style: GoogleFonts.kantumruyPro(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xff0F172A),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            "ប្រភព ក្រុម និងសិទ្ធិដែលសកម្មលើគណនីប្រើប្រាស់ផ្ទាល់",
            style: GoogleFonts.kantumruyPro(
              fontSize: 11,
              color: const Color(0xff64748B),
            ),
          ),
          const SizedBox(height: 14),

          // Search Bar & Filter Controls
          TextField(
            onChanged: (val) {
              controller.searchQuery.value = val;
              controller.currentPage.value = 1;
            },
            decoration: InputDecoration(
              hintText: "ស្វែងរកសិទ្ធិ ក្រុម ឬតួនាទី...",
              hintStyle: GoogleFonts.kantumruyPro(
                fontSize: 12,
                color: Colors.grey,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 16,
                color: Colors.grey,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              filled: true,
              fillColor: const Color(0xffF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xffE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xffE2E8F0)),
              ),
            ),
          ),
          const SizedBox(height: 12),

          Obx(() {
            final activeFilter = controller.selectedTypeFilter.value;
            final int allCount = controller.permissionsList.length;

            return Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                GestureDetector(
                  onTap: () {
                    controller.selectedTypeFilter.value = 'ALL';
                    controller.currentPage.value = 1;
                  },
                  child: _buildCountBadge(
                    "ទាំងអស់ ($allCount)",
                    activeFilter == 'ALL'
                        ? const Color(0xffE2E8F0)
                        : const Color(0xffF8FAFC),
                    const Color(0xff334155),
                    isSelected: activeFilter == 'ALL',
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    controller.selectedTypeFilter.value =
                        activeFilter == 'តួនាទី' ? 'ALL' : 'តួនាទី';
                    controller.currentPage.value = 1;
                  },
                  child: _buildCountBadge(
                    "$roleCount តួនាទី",
                    const Color(0xffF3E8FF),
                    const Color(0xff8B5CF6),
                    isSelected: activeFilter == 'តួនាទី',
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    controller.selectedTypeFilter.value =
                        activeFilter == 'ក្រុម' ? 'ALL' : 'ក្រុម';
                    controller.currentPage.value = 1;
                  },
                  child: _buildCountBadge(
                    "$groupCount ក្រុម",
                    const Color(0xffDBEAFE),
                    const Color(0xff2563EB),
                    isSelected: activeFilter == 'ក្រុម',
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    controller.selectedTypeFilter.value =
                        activeFilter == 'សិទ្ធិ' ? 'ALL' : 'សិទ្ធិ';
                    controller.currentPage.value = 1;
                  },
                  child: _buildCountBadge(
                    "$permCount សិទ្ធិ",
                    const Color(0xffFEF3C7),
                    const Color(0xffD97706),
                    isSelected: activeFilter == 'សិទ្ធិ',
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 20),

          Obx(() {
            final paginatedList = controller.paginatedList;
            final totalItems = controller.totalItems;
            final startIdx = controller.startIdx;
            final endIdx = controller.endIdx;
            final totalPages = controller.totalPages;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (paginatedList.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        "មិនមានសិទ្ធិប្រើប្រាស់ទេ",
                        style: GoogleFonts.kantumruyPro(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )
                else
                  ...paginatedList.map((item) => _buildPermissionItem(item)),

                const SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "បង្ហាញ ${toKhmerNumerals((totalItems == 0 ? 0 : startIdx + 1).toString())} ដល់ ${toKhmerNumerals(endIdx.toString())} នៃ ${toKhmerNumerals(totalItems.toString())} ធាតុ",
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 10,
                        color: const Color(0xff94A3B8),
                      ),
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: controller.currentPage.value > 1
                              ? () => controller.currentPage.value--
                              : null,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: controller.currentPage.value > 1
                                  ? const Color(0xffF1F5F9)
                                  : const Color(0xffF8FAFC),
                              border: Border.all(
                                color: controller.currentPage.value > 1
                                    ? const Color(0xffE2E8F0)
                                    : const Color(0xffF1F5F9),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.chevron_left_rounded,
                              size: 18,
                              color: controller.currentPage.value > 1
                                  ? const Color(0xff475569)
                                  : const Color(0xffCBD5E1),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "ទំព័រ ${toKhmerNumerals(controller.currentPage.value.toString())} នៃ ${toKhmerNumerals(totalPages.toString())}",
                          style: GoogleFonts.kantumruyPro(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff334155),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: controller.currentPage.value < totalPages
                              ? () => controller.currentPage.value++
                              : null,
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: controller.currentPage.value < totalPages
                                  ? const Color(0xffF1F5F9)
                                  : const Color(0xffF8FAFC),
                              border: Border.all(
                                color: controller.currentPage.value < totalPages
                                    ? const Color(0xffE2E8F0)
                                    : const Color(0xffF1F5F9),
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: controller.currentPage.value < totalPages
                                  ? const Color(0xff475569)
                                  : const Color(0xffCBD5E1),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPermissionItem(Map<String, String> item) {
    final type = item['type'] ?? '';
    final name = item['name'] ?? '';
    final source = item['source'] ?? '';
    final isRole = type == 'តួនាទី';
    final isGroup = type == 'ក្រុម';

    Color themeColor;
    IconData icon;
    Color bgBadge;

    if (isRole) {
      themeColor = const Color(0xff8B5CF6);
      icon = Icons.shield_rounded;
      bgBadge = const Color(0xffF3E8FF);
    } else if (isGroup) {
      themeColor = const Color(0xff2563EB);
      icon = Icons.group_rounded;
      bgBadge = const Color(0xffDBEAFE);
    } else {
      themeColor = const Color(0xffD97706);
      icon = Icons.vpn_key_rounded;
      bgBadge = const Color(0xffFEF3C7);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xffF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffF1F5F9)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: themeColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: themeColor, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: bgBadge,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        type,
                        style: GoogleFonts.kantumruyPro(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: themeColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        source,
                        style: GoogleFonts.kantumruyPro(
                          fontSize: 10,
                          color: const Color(0xff64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountBadge(
    String label,
    Color bg,
    Color text, {
    bool isSelected = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? text : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Text(
        label,
        style: GoogleFonts.kantumruyPro(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: text,
        ),
      ),
    );
  }

  String toKhmerNumerals(String input) {
    const khmerDigits = ['០', '១', '២', '៣', '៤', '៥', '៦', '៧', '៨', '៩'];
    return input.replaceAllMapped(
      RegExp(r'\d'),
      (m) => khmerDigits[int.parse(m.group(0)!)],
    );
  }
}
