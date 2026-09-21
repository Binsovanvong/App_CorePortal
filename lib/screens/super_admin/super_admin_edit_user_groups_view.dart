import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core_portal/core/api/services/auth_service.dart';
import 'package:core_portal/screens/super_admin/super_admin_controller.dart';
import 'package:core_portal/screens/admin/admin_controller.dart';
import 'package:core_portal/widgets/group_tag_chip.dart';
import 'package:core_portal/widgets/custom_snackbar.dart';

class SuperAdminEditUserGroupsView extends StatefulWidget {
  final Map<String, dynamic> user;
  final bool? isAdmin;
  final dynamic customController;

  const SuperAdminEditUserGroupsView({
    super.key,
    required this.user,
    this.isAdmin,
    this.customController,
  });

  @override
  State<SuperAdminEditUserGroupsView> createState() =>
      _SuperAdminEditUserGroupsViewState();
}

class _SuperAdminEditUserGroupsViewState
    extends State<SuperAdminEditUserGroupsView> {
  late dynamic controller;
  late Map<String, dynamic> _selectedUser;

  final leftSearchQuery = "".obs;
  final leftChecked = <String>{}.obs;
  final rightChecked = <String>{}.obs;
  final deletedGroupCodes = <String>{}.obs;

  final availableGroups = <String>[].obs;
  final assignedGroups = <String>[].obs;
  final filteredAvailableGroups = <String>[].obs;

  @override
  void initState() {
    super.initState();
    _selectedUser = widget.user;

    // Resolve controller dynamically
    if (widget.customController != null) {
      controller = widget.customController;
    } else if (widget.isAdmin == true && Get.isRegistered<AdminController>()) {
      controller = Get.find<AdminController>();
    } else if (Get.isRegistered<SuperAdminController>()) {
      controller = Get.find<SuperAdminController>();
    } else if (Get.isRegistered<AdminController>()) {
      controller = Get.find<AdminController>();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadUserGroups(_selectedUser);
      }
    });

    ever(availableGroups, (_) => _updateFiltered());
    ever(leftSearchQuery, (_) => _updateFiltered());
    _updateFiltered();
  }

  Future<void> _loadUserGroups(Map<String, dynamic> user) async {
    final bool isAdminMode =
        widget.isAdmin == true || controller is AdminController;
    try {
      if (isAdminMode) {
        // Fetch groups created by me using GET /api/mobile/admin/portal-groups/created-by-me
        final res = await AuthService().fetchPortalGroupsCreatedByMe();
        List rawList = [];
        if (res is List) {
          rawList = res;
        } else if (res is Map) {
          rawList = res['value'] ?? res['data'] ?? res['items'] ?? [];
        }
        final parsed = rawList.map<Map<String, dynamic>>((g) {
          final Map<String, dynamic> item = g is Map
              ? Map<String, dynamic>.from(g)
              : {};
          final name =
              (item['name'] ?? item['groupName'] ?? item['code'] ?? '—')
                  .toString()
                  .trim();
          final code =
              (item['code'] ?? item['groupCode'] ?? item['sublabel'] ?? name)
                  .toString()
                  .trim();
          return {
            'id': item['id']?.toString(),
            'name': name,
            'sublabel': code,
            'code': code,
            'status': item['status'] ?? 'ACTIVE',
            'description':
                item['description'] ?? item['desc'] ?? item['details'],
          };
        }).toList();

        controller.groupList.assignAll(parsed);
      } else if (controller.groupList.isEmpty) {
        if (controller is SuperAdminController) {
          await (controller as SuperAdminController).fetchPortalGroupsData();
        } else if (controller is AdminController) {
          await (controller as AdminController).fetchPortalGroupsCreatedByMe();
        }
      }
    } catch (e) {
      debugPrint("Error fetching portal groups in _loadUserGroups: $e");
    }

    final List<Map<String, dynamic>> allGroups = controller.groupList;

    final List<String> allGroupDisplayNames = [];
    for (final group in allGroups) {
      final name = (group['name'] ?? group['code'] ?? group['groupCode'] ?? '')
          .toString()
          .trim();
      if (name.isNotEmpty && !allGroupDisplayNames.contains(name)) {
        allGroupDisplayNames.add(name);
      }
    }

    // Extract user assigned groups across strictly portal group payload keys
    final List<String> rawAssignedList = [];
    final keysToCheck = [
      'groups',
      'userGroups',
      'portalGroups',
      'groupCodes',
      'user_groups',
    ];

    for (final key in keysToCheck) {
      final val = user[key];
      if (val is List && val.isNotEmpty) {
        for (final item in val) {
          String? extracted;
          if (item is String) {
            extracted = item.startsWith('/') ? item.substring(1) : item;
          } else if (item is Map) {
            extracted =
                (item['code'] ??
                        item['groupCode'] ??
                        item['group_code'] ??
                        item['name'] ??
                        item['groupName'] ??
                        item['sublabel'] ??
                        item['id'])
                    ?.toString();
          }
          if (extracted != null && extracted.trim().isNotEmpty) {
            final cleaned = extracted.trim();
            if (!rawAssignedList.contains(cleaned)) {
              rawAssignedList.add(cleaned);
            }
          }
        }
        if (rawAssignedList.isNotEmpty) {
          break; // Found the primary user groups list!
        }
      }
    }

    if (rawAssignedList.isEmpty && user['attributes'] is Map) {
      final Map attrs = user['attributes'];
      for (final key in ['groups', 'group', 'groupCodes', 'user_groups']) {
        final val = attrs[key];
        if (val is List) {
          for (final item in val) {
            if (item != null) {
              final str = item.toString().trim();
              final extracted = str.startsWith('/') ? str.substring(1) : str;
              if (extracted.isNotEmpty &&
                  !rawAssignedList.contains(extracted)) {
                rawAssignedList.add(extracted);
              }
            }
          }
        } else if (val is String && val.trim().isNotEmpty) {
          final extracted = val.startsWith('/')
              ? val.trim().substring(1)
              : val.trim();
          if (!rawAssignedList.contains(extracted)) {
            rawAssignedList.add(extracted);
          }
        }
      }
    }

    // Dynamic fetch from API for this user with strict user ID filtering
    final String targetId =
        (user['keycloakUserId'] ?? user['keycloak_user_id'] ?? user['id'] ?? '')
            .toString()
            .toLowerCase()
            .trim();
    final String targetUName = (user['username'] ?? '')
        .toString()
        .toLowerCase()
        .trim();

    if (targetId.isNotEmpty) {
      try {
        final res = await AuthService().fetchUserGroups(targetId);
        if (res != null) {
          List items = [];
          if (res is List) {
            items = res;
          } else {
            final data =
                res['data'] ??
                res['items'] ??
                res['value'] ??
                res['userGroups'] ??
                res['groups'];
            if (data is List) items = data;
          }
          final List<String> apiAssignedList = [];
          for (final item in items) {
            if (item is Map) {
              final String itemUserId =
                  (item['keycloakUserId'] ??
                          item['keycloak_user_id'] ??
                          item['userId'] ??
                          item['user_id'] ??
                          '')
                      .toString()
                      .toLowerCase()
                      .trim();

              // Filter out mappings that belong to OTHER users
              if (itemUserId.isNotEmpty &&
                  itemUserId != targetId &&
                  itemUserId != targetUName) {
                continue;
              }

              final grpObj = item['group'] is Map ? item['group'] : item;
              final extracted =
                  (grpObj['groupCode'] ??
                          grpObj['group_code'] ??
                          grpObj['code'] ??
                          grpObj['groupName'] ??
                          grpObj['group_name'] ??
                          grpObj['name'] ??
                          grpObj['sublabel'] ??
                          item['groupCode'] ??
                          item['group_code'] ??
                          item['code'] ??
                          item['groupName'] ??
                          item['group_name'] ??
                          item['name'] ??
                          item['sublabel'])
                      ?.toString()
                      .trim();

              if (extracted != null &&
                  extracted.isNotEmpty &&
                  !apiAssignedList.contains(extracted)) {
                apiAssignedList.add(extracted);
              }
            } else if (item is String && item.trim().isNotEmpty) {
              final str = item.trim().startsWith('/')
                  ? item.trim().substring(1)
                  : item.trim();
              if (!apiAssignedList.contains(str)) {
                apiAssignedList.add(str);
              }
            }
          }

          if (res != null) {
            // Overwrite rawAssignedList with fresh API data so removed items are cleared
            rawAssignedList.clear();
            rawAssignedList.addAll(apiAssignedList);
          }
        }
      } catch (e) {
        debugPrint("Error fetching user groups dynamically: $e");
      }
    }

    debugPrint("USER KEYS: ${user.keys.toList()}");
    debugPrint("RAW ASSIGNED FROM API: $rawAssignedList");

    // Match assigned raw strings/codes against allGroups
    final List<String> initialAssigned = [];

    for (final rawGroup in rawAssignedList) {
      final rawLower = rawGroup.toLowerCase().trim();
      final normalizedRaw = rawLower.replaceAll('_', ' ').replaceAll('-', ' ');

      // Step 1: Exact match on code, sublabel, id, or name
      var match = allGroups.firstWhereOrNull((g) {
        final name = (g['name'] ?? '').toString().toLowerCase().trim();
        final code = (g['sublabel'] ?? g['code'] ?? '')
            .toString()
            .toLowerCase()
            .trim();
        final id = (g['id'] ?? '').toString().toLowerCase().trim();
        return name == rawLower || code == rawLower || id == rawLower;
      });

      // Step 2: Normalized match on name or code (_ and - replaced by space)
      match ??= allGroups.firstWhereOrNull((g) {
        final normName = (g['name'] ?? '')
            .toString()
            .toLowerCase()
            .trim()
            .replaceAll('_', ' ')
            .replaceAll('-', ' ');
        final normCode = (g['sublabel'] ?? g['code'] ?? '')
            .toString()
            .toLowerCase()
            .trim()
            .replaceAll('_', ' ')
            .replaceAll('-', ' ');
        return normName == normalizedRaw || normCode == normalizedRaw;
      });

      String? displayName = match != null
          ? (match['name'] ?? '').toString().trim()
          : null;

      // Step 3: Check allGroupDisplayNames for exact or normalized match
      if (displayName == null || displayName.isEmpty) {
        final foundName = allGroupDisplayNames.firstWhereOrNull((dName) {
          final dLower = dName.toLowerCase().trim();
          final dNorm = dLower.replaceAll('_', ' ').replaceAll('-', ' ');
          return dLower == rawLower || dNorm == normalizedRaw;
        });
        if (foundName != null) {
          displayName = foundName;
        }
      }

      // Step 4: Fallback to raw group formatted string
      if (displayName == null || displayName.isEmpty) {
        displayName = rawGroup.contains('_')
            ? rawGroup.replaceAll('_', ' ')
            : rawGroup;
      }

      if (displayName.isNotEmpty && !initialAssigned.contains(displayName)) {
        initialAssigned.add(displayName);
      }
    }

    assignedGroups.assignAll(initialAssigned);

    availableGroups.assignAll(
      allGroupDisplayNames.where((g) => !initialAssigned.contains(g)).toList(),
    );

    leftChecked.clear();
    rightChecked.clear();
  }

  void _updateFiltered() {
    if (leftSearchQuery.value.isEmpty) {
      filteredAvailableGroups.assignAll(availableGroups);
    } else {
      filteredAvailableGroups.assignAll(
        availableGroups
            .where(
              (g) =>
                  g.toLowerCase().contains(leftSearchQuery.value.toLowerCase()),
            )
            .toList(),
      );
    }
  }

  void _onUserChanged(Map<String, dynamic>? newUser) {
    if (newUser != null) {
      setState(() {
        _selectedUser = newUser;
      });
      _loadUserGroups(newUser);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 900;
    final bool canEdit = controller is SuperAdminController
        ? (controller as SuperAdminController).canEditUser(_selectedUser)
        : (controller is AdminController
            ? (controller as AdminController).canEditUser(_selectedUser)
            : true);

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              if (!canEdit) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        color: Color(0xFFDC2626),
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'គណនីផ្ទាល់ខ្លួន: អ្នកមិនអាចកែសម្រួលក្រុមរបស់ខ្លួនឯងបានឡើយ (You cannot edit your own account)',
                          style: GoogleFonts.kantumruyPro(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF991B1B),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _buildUserSelector(),
              const SizedBox(height: 16),
              _buildUserDetailsCard(isDesktop),
              const SizedBox(height: 24),
              _buildTransferMatrix(isDesktop),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  onPressed: () => Get.back(),
                ),
                const SizedBox(width: 8),
                Text(
                  'កែសម្រួលក្រុមរបស់អ្នកប្រើ',
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff1E293B),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 44),
              child: Text(
                'គ្រប់គ្រងក្រុម និងសិទ្ធិក្រុមរបស់អ្នកប្រើ។',
                style: GoogleFonts.kantumruyPro(
                  fontSize: 12,
                  color: const Color(0xff64748B),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserSelector() {
    final List<Map<String, dynamic>> users = controller.usersList;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "ជ្រើសរើសគណនីអ្នកប្រើប្រាស់",
            style: GoogleFonts.kantumruyPro(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xff64748B),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xffF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xffE2E8F0)),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Map<String, dynamic>>(
                value:
                    users.firstWhereOrNull(
                      (u) => u['username'] == _selectedUser['username'],
                    ) ??
                    _selectedUser,
                isExpanded: true,
                items: users.map((user) {
                  return DropdownMenuItem<Map<String, dynamic>>(
                    value: user,
                    child: Text(
                      "${user['username']} - ${user['email'].isNotEmpty ? user['email'] : 'គ្មានអ៊ីមែល'}",
                      style: GoogleFonts.poppins(fontSize: 13),
                    ),
                  );
                }).toList(),
                onChanged: _onUserChanged,
                dropdownColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserDetailsCard(bool isDesktop) {
    final rawUsername = (_selectedUser['username'] ?? '').toString().trim();
    final rawId = (_selectedUser['id'] ?? _selectedUser['keycloakUserId'] ?? '')
        .toString()
        .trim();
    final displayName =
        (_selectedUser['displayName'] ??
                _selectedUser['display_name'] ??
                _selectedUser['name'] ??
                _selectedUser['fullName'] ??
                (rawUsername.isNotEmpty ? rawUsername : 'User'))
            .toString()
            .trim();
    final username = (rawUsername.isNotEmpty && rawUsername != rawId)
        ? rawUsername
        : (displayName.isNotEmpty ? displayName : 'admin');
    final email = (_selectedUser['email'] ?? '').toString().trim();
    final String status = (_selectedUser['status'] ?? 'ACTIVE')
        .toString()
        .toUpperCase();
    final bool isActive = status == 'ACTIVE';
    final String phone =
        (_selectedUser['phone'] ?? _selectedUser['phoneNumber'] ?? '—')
            .toString();
    final String position =
        (_selectedUser['position'] ??
                _selectedUser['jobTitle'] ??
                _selectedUser['title'] ??
                '—')
            .toString();
    final String createdDate =
        (_selectedUser['createdAt'] ?? _selectedUser['createdDate'] ?? '—')
            .toString();

    // Khmer Department / General Department Name
    String unit = (_selectedUser['unit'] ?? '').toString().trim();
    final List empInfos = _selectedUser['employmentInfos'] is List
        ? _selectedUser['employmentInfos']
        : [];
    if (empInfos.isNotEmpty && empInfos[0] is Map) {
      final firstEmp = empInfos[0];
      final gName =
          (firstEmp['generalDepartmentNameKh'] ??
                  firstEmp['generalDepartmentName'] ??
                  firstEmp['departmentNameKh'] ??
                  firstEmp['generalDepartmentCode'] ??
                  '')
              .toString()
              .trim();
      if (gName.isNotEmpty) unit = gName;
    }
    if (unit.isEmpty || unit == '—') {
      unit = 'អគ្គនាយកដ្ឋានបច្ចេកវិទ្យាឌីជីថល និងផ្សព្វផ្សាយអប់រំ';
    }

    String initial = 'U';
    if (displayName.isNotEmpty) {
      final parts = displayName.trim().split(' ');
      if (parts.length >= 2) {
        initial = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else {
        initial = displayName
            .substring(0, displayName.length >= 2 ? 2 : 1)
            .toUpperCase();
      }
    }

    Widget profileSection = Row(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: const Color(0xffEFF6FF),
          child: Text(
            initial,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              color: const Color(0xff2563EB),
              fontSize: 22,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      displayName,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xff0F172A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 3,
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
                            color: isActive
                                ? const Color(0xff047857)
                                : const Color(0xffB91C1C),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(
                    Icons.account_circle_outlined,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    username,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: const Color(0xff64748B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.mail_outline_rounded,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      email.isNotEmpty ? email : "—",
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(
                    Icons.phone_outlined,
                    size: 14,
                    color: Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    phone,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    Widget infoTable = Table(
      columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
      children: [
        _buildTableRow("អង្គភាព", unit),
        _buildTableRow("មុខតំណែង", position),
      ],
    );

    Widget datesTable = Table(
      columnWidths: const {0: IntrinsicColumnWidth(), 1: FlexColumnWidth()},
      children: [
        _buildTableRow("កាលបរិច្ឆេទបង្កើត", createdDate),
        _buildTableRow("ប្រភេទ", isActive ? "ដំណើរការ" : "ផ្អាក"),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: isDesktop
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: profileSection),
                const SizedBox(width: 24),
                Expanded(flex: 4, child: infoTable),
                const SizedBox(width: 24),
                Expanded(flex: 3, child: datesTable),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                profileSection,
                const SizedBox(height: 20),
                const Divider(color: Color(0xffE2E8F0)),
                const SizedBox(height: 12),
                infoTable,
                const SizedBox(height: 12),
                datesTable,
              ],
            ),
    );
  }

  TableRow _buildTableRow(String label, String value, {bool isUuid = false}) {
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Text(
            label,
            style: GoogleFonts.kantumruyPro(fontSize: 12, color: Colors.grey),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Text(
            value,
            style: isUuid
                ? GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff0F172A),
                  )
                : GoogleFonts.kantumruyPro(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff0F172A),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransferMatrix(bool isDesktop) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.group_add_outlined,
                color: Color(0xffE29D11),
                size: 20,
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "កំណត់ក្រុមអ្នកប្រើប្រាស់",
                    style: GoogleFonts.kantumruyPro(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: const Color(0xff0F172A),
                    ),
                  ),
                  Text(
                    "ភ្ជាប់គណនីអ្នកប្រើប្រាស់ ទៅនឹងសិទ្ធិក្រុមផ្សេងៗ។",
                    style: GoogleFonts.kantumruyPro(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Obx(() {
            Widget leftColumn = _buildAvailableColumn();
            Widget rightColumn = _buildAssignedColumn();
            Widget middleButtons = _buildTransferButtons(isDesktop);

            return isDesktop
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(child: leftColumn),
                      middleButtons,
                      Expanded(child: rightColumn),
                    ],
                  )
                : Column(
                    children: [
                      leftColumn,
                      const SizedBox(height: 12),
                      middleButtons,
                      const SizedBox(height: 12),
                      rightColumn,
                    ],
                  );
          }),
          const SizedBox(height: 24),
          _buildActionRow(),
        ],
      ),
    );
  }

  void _showCreateGroupDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final isCreating = false.obs;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 420,
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xffEFF6FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.group_add_rounded,
                      color: Color(0xff1D4ED8),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "បង្កើតក្រុមថ្មី (Add Portal Group)",
                          style: GoogleFonts.kantumruyPro(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff0F172A),
                          ),
                        ),
                        Text(
                          "បញ្ចូលព័ត៌មានក្រុមសម្រាប់ភ្ជាប់អ្នកប្រើប្រាស់",
                          style: GoogleFonts.kantumruyPro(
                            fontSize: 11,
                            color: const Color(0xff64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                "ឈ្មោះក្រុម (Group Name) *",
                style: GoogleFonts.kantumruyPro(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff475569),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: "ឧទាហរណ៍៖ IT Support, GDD-Team",
                  hintStyle: GoogleFonts.kantumruyPro(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
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
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xff1D4ED8),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                "ការពិពណ៌នា (Description)",
                style: GoogleFonts.kantumruyPro(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff475569),
                ),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: descCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: "បញ្ចូលព័ត៌មានបន្ថែមអំពីក្រុម...",
                  hintStyle: GoogleFonts.kantumruyPro(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  contentPadding: const EdgeInsets.all(12),
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
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(
                      color: Color(0xff1D4ED8),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Get.back(),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    child: Text(
                      "បោះបង់",
                      style: GoogleFonts.kantumruyPro(
                        color: const Color(0xff64748B),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Obx(
                    () => ElevatedButton(
                      onPressed: isCreating.value
                          ? null
                          : () async {
                              final name = nameCtrl.text.trim();
                              if (name.isEmpty) {
                                CustomSnackbar.showWarning(
                                  title: "សូមបញ្ជាក់",
                                  message: "សូមបញ្ចូលឈ្មោះក្រុម!",
                                );
                                return;
                              }
                              isCreating.value = true;
                              try {
                                final payload = {
                                  'name': name,
                                  if (descCtrl.text.trim().isNotEmpty)
                                    'description': descCtrl.text.trim(),
                                };
                                await AuthService().createAdminGroup(payload);
                                Get.back();
                                CustomSnackbar.showSuccess(
                                  title: "ជោគជ័យ",
                                  message: "បានបង្កើតក្រុមដោយជោគជ័យ!",
                                );
                                await _loadUserGroups(_selectedUser);
                              } catch (e) {
                                isCreating.value = false;
                                CustomSnackbar.showError(
                                  title: "កំហុស",
                                  message: "មិនអាចបង្កើតក្រុមបានទេ: $e",
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xffE29D11),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                      ),
                      child: isCreating.value
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              "បង្កើតក្រុម",
                              style: GoogleFonts.kantumruyPro(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvailableColumn() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "ក្រុមដែលអាចជ្រើសរើស (${availableGroups.length})",
                    style: GoogleFonts.kantumruyPro(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: const Color(0xff0F172A),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                InkWell(
                  onTap: () => _showCreateGroupDialog(context),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xffBFDBFE),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.add_rounded,
                          size: 14,
                          color: Color(0xff1D4ED8),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          "បង្កើតក្រុម",
                          style: GoogleFonts.kantumruyPro(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff1D4ED8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: TextField(
              onChanged: (val) => leftSearchQuery.value = val,
              decoration: InputDecoration(
                hintText: "ស្វែងរកក្រុម...",
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
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filteredAvailableGroups.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "គ្មានក្រុមដែលអាចជ្រើសរើសឡើយ",
                          style: GoogleFonts.kantumruyPro(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () => _showCreateGroupDialog(context),
                          icon: const Icon(
                            Icons.add_rounded,
                            size: 16,
                            color: Color(0xff1D4ED8),
                          ),
                          label: Text(
                            "បង្កើតក្រុមថ្មី",
                            style: GoogleFonts.kantumruyPro(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xff1D4ED8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredAvailableGroups.length,
                    itemBuilder: (context, idx) {
                      final group = filteredAvailableGroups[idx];
                      final isChecked = leftChecked.contains(group);
                      return CheckboxListTile(
                        title: Text(
                          group,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          group.split(" ").first,
                          style: GoogleFonts.poppins(
                            fontSize: 9,
                            color: Colors.grey,
                          ),
                        ),
                        value: isChecked,
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (val) {
                          if (val == true) {
                            leftChecked.add(group);
                          } else {
                            leftChecked.remove(group);
                          }
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Map<String, List<String>> _groupAssignedByCategory() {
    final Map<String, List<String>> categories = {};
    for (final group in assignedGroups) {
      final clean = group.trim();
      if (clean.isEmpty) continue;

      String category = clean.contains('_')
          ? clean.split('_').first
          : clean.split(' ').first;
      category = category.toUpperCase();

      if (!categories.containsKey(category)) {
        categories[category] = [];
      }
      categories[category]!.add(group);
    }
    return categories;
  }

  Widget _buildAssignedColumn() {
    final Map<String, List<String>> categorized = _groupAssignedByCategory();

    return Container(
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              "ក្រុមដែលបានកំណត់ (${assignedGroups.length})",
              style: GoogleFonts.kantumruyPro(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: const Color(0xff0F172A),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: assignedGroups.isEmpty
                ? Center(
                    child: Text(
                      "មិនទាន់មានការកំណត់ក្រុម",
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: categorized.keys.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final categoryTitle = categorized.keys.elementAt(index);
                      final groupsList = categorized[categoryTitle]!;
                      return GroupCategorySection(
                        categoryTitle: categoryTitle,
                        groups: groupsList,
                        onDeleteGroup: (group) {
                          assignedGroups.remove(group);
                          rightChecked.remove(group);
                          deletedGroupCodes.add(group);
                          if (!availableGroups.contains(group)) {
                            availableGroups.add(group);
                            _updateFiltered();
                          }
                          assignedGroups.refresh();
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransferButtons(bool isDesktop) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 12 : 0,
        vertical: isDesktop ? 0 : 8,
      ),
      child: isDesktop
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.chevron_right_rounded,
                    color: Color(0xffE29D11),
                    size: 28,
                  ),
                  onPressed: leftChecked.isEmpty
                      ? null
                      : () {
                          for (final item in leftChecked) {
                            if (!assignedGroups.contains(item)) {
                              assignedGroups.add(item);
                            }
                            deletedGroupCodes.remove(item);
                          }
                          availableGroups.removeWhere(
                            (g) => leftChecked.contains(g),
                          );
                          leftChecked.clear();
                          _updateFiltered();
                          assignedGroups.refresh();
                        },
                ),
                const SizedBox(height: 12),
                IconButton(
                  icon: const Icon(
                    Icons.chevron_left_rounded,
                    color: Color(0xffE29D11),
                    size: 28,
                  ),
                  onPressed: rightChecked.isEmpty
                      ? null
                      : () {
                          availableGroups.addAll(rightChecked);
                          deletedGroupCodes.addAll(rightChecked);
                          assignedGroups.removeWhere(
                            (g) => rightChecked.contains(g),
                          );
                          rightChecked.clear();
                          _updateFiltered();
                          assignedGroups.refresh();
                        },
                ),
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: Color(0xffE29D11),
                    size: 28,
                  ),
                  onPressed: leftChecked.isEmpty
                      ? null
                      : () {
                          for (final item in leftChecked) {
                            if (!assignedGroups.contains(item)) {
                              assignedGroups.add(item);
                            }
                            deletedGroupCodes.remove(item);
                          }
                          availableGroups.removeWhere(
                            (g) => leftChecked.contains(g),
                          );
                          leftChecked.clear();
                          _updateFiltered();
                          assignedGroups.refresh();
                        },
                ),
                const SizedBox(width: 24),
                IconButton(
                  icon: const Icon(
                    Icons.keyboard_arrow_up_rounded,
                    color: Color(0xffE29D11),
                    size: 28,
                  ),
                  onPressed: rightChecked.isEmpty
                      ? null
                      : () {
                          availableGroups.addAll(rightChecked);
                          deletedGroupCodes.addAll(rightChecked);
                          assignedGroups.removeWhere(
                            (g) => rightChecked.contains(g),
                          );
                          rightChecked.clear();
                          _updateFiltered();
                          assignedGroups.refresh();
                        },
                ),
              ],
            ),
    );
  }

  Widget _buildActionRow() {
    const Color buttonBg = Color(0xffE29D11);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            side: const BorderSide(color: Color(0xffCBD5E1)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          onPressed: () => Get.back(),
          child: Text(
            "បោះបង់",
            style: GoogleFonts.kantumruyPro(
              fontSize: 13,
              color: const Color(0xff64748B),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: buttonBg,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            minimumSize: const Size(0, 0),
          ),
          onPressed: () async {
            final bool canEdit = controller is SuperAdminController
                ? (controller as SuperAdminController).canEditUser(_selectedUser)
                : (controller is AdminController
                    ? (controller as AdminController).canEditUser(_selectedUser)
                    : true);

            if (!canEdit) {
              CustomSnackbar.showWarning(
                message:
                    'មិនអាចកែសម្រួលគណនីផ្ទាល់ខ្លួនរបស់អ្នកបានឡើយ (You cannot edit your own account)',
              );
              return;
            }

            if (leftChecked.isNotEmpty) {
              assignedGroups.addAll(leftChecked);
              availableGroups.removeWhere((g) => leftChecked.contains(g));
              deletedGroupCodes.removeAll(leftChecked);
              leftChecked.clear();
              _updateFiltered();
              assignedGroups.refresh();
            }

            // Handle DELETE for unassigned / removed groups
            for (final removedCode in deletedGroupCodes) {
              try {
                await controller.removeUserGroupFromUser(
                  _selectedUser,
                  removedCode,
                );
              } catch (_) {}
            }

            bool isSaved = await controller.assignGroupsToUser(
              _selectedUser,
              assignedGroups.toList(),
            );

            if (isSaved) {
              _selectedUser['groups'] = List<String>.from(assignedGroups);
              _selectedUser['userGroups'] = List<String>.from(assignedGroups);
              _selectedUser['portalGroups'] = List<String>.from(assignedGroups);
              _selectedUser['groupCodes'] = List<String>.from(assignedGroups);
              _selectedUser['user_groups'] = List<String>.from(assignedGroups);
              if (_selectedUser['attributes'] is Map) {
                (_selectedUser['attributes'] as Map).remove('groups');
                (_selectedUser['attributes'] as Map).remove('group');
                (_selectedUser['attributes'] as Map).remove('groupCodes');
                (_selectedUser['attributes'] as Map).remove('user_groups');
              }

              try {
                if (controller is SuperAdminController) {
                  await (controller as SuperAdminController)
                      .fetchDashboardData();
                  await (controller as SuperAdminController)
                      .fetchPortalGroupsData();
                } else if (controller is AdminController) {
                  await (controller as AdminController).fetchDashboardData();
                  await (controller as AdminController)
                      .fetchPortalGroupsCreatedByMe();
                }
              } catch (_) {}

              Get.back();
            }
          },
          child: Text(
            "រក្សាទុកការភ្ជាប់ក្រុម",
            style: GoogleFonts.kantumruyPro(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
