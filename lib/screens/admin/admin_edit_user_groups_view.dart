import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core_portal/core/api/services/auth_service.dart';
import 'package:core_portal/screens/admin/admin_controller.dart';
import 'package:core_portal/screens/admin/admin_create_group_view.dart';
import 'package:core_portal/screens/admin/admin_edit_group_view.dart';
import 'package:core_portal/widgets/custom_snackbar.dart';
import 'package:get_storage/get_storage.dart';

class AdminEditUserGroupsView extends StatefulWidget {
  final Map<String, dynamic> user;

  const AdminEditUserGroupsView({super.key, required this.user});

  @override
  State<AdminEditUserGroupsView> createState() =>
      _AdminEditUserGroupsViewState();
}

class _AdminEditUserGroupsViewState extends State<AdminEditUserGroupsView> {
  late AdminController controller;
  late Map<String, dynamic> _selectedUser;

  final searchQuery = "".obs;
  final assignedGroups = <String>[].obs;
  final deletedGroupCodes = <String>{}.obs;
  final allGroups = <Map<String, dynamic>>[].obs;
  final isAssignedExpanded = true.obs;
  final isLoadingGroups = false.obs;
  final isSaving = false.obs;

  @override
  void initState() {
    super.initState();
    _selectedUser = widget.user;
    controller = Get.find<AdminController>();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadUserGroups(_selectedUser);
      }
    });
  }

  Future<List<Map<String, dynamic>>> _fetchAndParsePortalGroups() async {
    try {
      final res = await AuthService().fetchPortalGroupsCreatedByMe();
      List rawList = [];
      if (res is List) {
        rawList = res;
      } else if (res is Map) {
        rawList =
            res['data'] ??
            res['items'] ??
            res['value'] ??
            res['groups'] ??
            [];
      }
      return rawList.map<Map<String, dynamic>>((g) {
        final Map<String, dynamic> item =
            g is Map ? Map<String, dynamic>.from(g) : {};
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
    } catch (e) {
      debugPrint("Error fetching portal groups in _fetchAndParsePortalGroups: $e");
      return [];
    }
  }

  /// Exact API data fetching logic as before - NO hardcoded fake data
  Future<void> _loadUserGroups(Map<String, dynamic> user) async {
    isLoadingGroups.value = true;
    try {
      // 1. Fetch portal groups created by me via GET /api/mobile/admin/portal-groups/created-by-me
      final parsed = await _fetchAndParsePortalGroups();
      controller.groupList.assignAll(parsed);
    } catch (e) {
      debugPrint("Error fetching portal groups in _loadUserGroups: $e");
    }

    final List<Map<String, dynamic>> allGroupsList = controller.groupList;

    final List<String> allGroupDisplayNames = [];
    for (final group in allGroupsList) {
      final name = (group['name'] ?? group['code'] ?? group['groupCode'] ?? '')
          .toString()
          .trim();
      if (name.isNotEmpty && !allGroupDisplayNames.contains(name)) {
        allGroupDisplayNames.add(name);
      }
    }

    final String targetId =
        (user['keycloakUserId'] ?? user['keycloak_user_id'] ?? user['id'] ?? '')
            .toString()
            .toLowerCase()
            .trim();
    final String targetUName = (user['username'] ?? '')
        .toString()
        .toLowerCase()
        .trim();

    final Set<String> assignedGroupCodes = {};

    // 2. Dynamic fetch from API (/api/mobile/admin/portal-groups/user-groups)
    if (targetId.isNotEmpty) {
      try {
        final res = await AuthService().fetchUserGroups(targetId);
        if (res != null) {
          List items = [];
          if (res is List) {
            items = res;
          } else if (res is Map) {
            final data =
                res['data'] ??
                res['items'] ??
                res['value'] ??
                res['userGroups'] ??
                res['groups'];
            if (data is List) items = data;
          }

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
                  !extracted.startsWith('/')) {
                assignedGroupCodes.add(extracted);
              }
            } else if (item is String && item.trim().isNotEmpty) {
              final str = item.trim();
              if (!str.startsWith('/')) {
                assignedGroupCodes.add(str);
              }
            }
          }
        }
      } catch (e) {
        debugPrint("Error fetching user groups dynamically: $e");
      }
    }

    // 3. Also check controller.userGroupsMap (keyed by groupCode -> [userIds])
    for (final entry in controller.userGroupsMap.entries) {
      final code = entry.key.trim();
      if (code.startsWith('/')) continue;
      final uids = entry.value.map((u) => u.toLowerCase().trim()).toSet();
      if (uids.contains(targetId) ||
          (targetUName.isNotEmpty && uids.contains(targetUName))) {
        assignedGroupCodes.add(code);
      }
    }

    // 4. Match assigned group codes ONLY against allGroups (groups created by this admin)
    final List<String> initialAssigned = [];

    for (final rawGroup in assignedGroupCodes) {
      final rawLower = rawGroup.toLowerCase().trim();
      final normalizedRaw = rawLower.replaceAll('_', ' ').replaceAll('-', ' ');

      var match = allGroupsList.firstWhereOrNull((g) {
        final name = (g['name'] ?? '').toString().toLowerCase().trim();
        final code = (g['sublabel'] ?? g['code'] ?? '')
            .toString()
            .toLowerCase()
            .trim();
        final id = (g['id'] ?? '').toString().toLowerCase().trim();
        return name == rawLower || code == rawLower || id == rawLower;
      });

      match ??= allGroupsList.firstWhereOrNull((g) {
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

      if (displayName != null &&
          displayName.isNotEmpty &&
          !initialAssigned.contains(displayName)) {
        initialAssigned.add(displayName);
      }
    }

    assignedGroups.assignAll(initialAssigned);
    allGroups.assignAll(allGroupsList);
    deletedGroupCodes.clear();
    isLoadingGroups.value = false;
  }

  void _onUserChanged(Map<String, dynamic>? newUser) {
    if (newUser != null) {
      setState(() {
        _selectedUser = newUser;
      });
      _loadUserGroups(newUser);
    }
  }

  void _toggleGroup(String groupName) {
    if (assignedGroups.contains(groupName)) {
      assignedGroups.remove(groupName);
      deletedGroupCodes.add(groupName);
    } else {
      assignedGroups.add(groupName);
      deletedGroupCodes.remove(groupName);
    }
    assignedGroups.refresh();
  }

  Future<void> _onSave() async {
    if (isSaving.value) return;
    if (!controller.canEditUser(_selectedUser)) {
      CustomSnackbar.showWarning(
        message:
            'មិនអាចកែសម្រួលគណនីផ្ទាល់ខ្លួនរបស់អ្នកបានឡើយ (You cannot edit your own account)',
      );
      return;
    }
    isSaving.value = true;

    try {
      // 1. Remove deleted groups
      for (final removedCode in deletedGroupCodes) {
        try {
          await controller.removeUserGroupFromUser(
            _selectedUser,
            removedCode,
          );
        } catch (_) {}
      }

      // 2. Assign remaining groups
      final bool isSaved = await controller.assignGroupsToUser(
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
          await controller.fetchDashboardData();
          await controller.fetchPortalGroupsCreatedByMe();
        } catch (_) {}

        Get.back();
      }
    } catch (e) {
      CustomSnackbar.showError(
        title: 'error'.tr,
        message: 'cannot_save_groups'.tr,
      );
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> _openCreateGroupView({String? initialName}) async {
    final result = await Get.to(() => AdminCreateGroupView(
          initialName: initialName,
          initialUser: _selectedUser,
        ));

    if (result is Map) {
      final name = (result['name'] ?? result['code'] ?? '').toString().trim();
      final currentAssigned = List<String>.from(assignedGroups);
      if (name.isNotEmpty && !currentAssigned.contains(name)) {
        currentAssigned.add(name);
      }
      deletedGroupCodes.remove(name);
      await _refreshGroups(
        preserveAssigned: currentAssigned,
        newGroupName: name,
      );
    } else {
      await _refreshGroups(preserveAssigned: assignedGroups.toList());
    }
  }

  Future<void> _refreshGroups({
    List<String>? preserveAssigned,
    String? newGroupName,
  }) async {
    isLoadingGroups.value = true;
    try {
      final parsed = await _fetchAndParsePortalGroups();

      // If backend hasn't reflected the new group yet, create a local fallback entry
      if (newGroupName != null &&
          newGroupName.isNotEmpty &&
          !parsed.any((g) =>
              (g['name'] ?? '').toString().toLowerCase() ==
              newGroupName.toLowerCase())) {
        parsed.insert(0, {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'name': newGroupName,
          'sublabel': newGroupName,
          'code': newGroupName,
          'status': 'ACTIVE',
          'description': '',
        });
      }

      controller.groupList.assignAll(parsed);
      allGroups.assignAll(parsed);

      if (preserveAssigned != null) {
        assignedGroups.assignAll(preserveAssigned);
      }
    } catch (e) {
      debugPrint("Error refreshing portal groups: $e");
    } finally {
      isLoadingGroups.value = false;
    }
  }



  int _getUserCountForGroup(Map<String, dynamic> grp) {
    int count = controller.getUserCountForGroup(grp);
    final String name = (grp['name'] ?? grp['code'] ?? '').toString().trim();
    final String code = (grp['code'] ?? grp['sublabel'] ?? name).toString().trim();
    if (assignedGroups.contains(name) || assignedGroups.contains(code)) {
      if (count == 0) count = 1;
    }
    return count;
  }

  bool _hasAssignedUsers(Map<String, dynamic> grp) {
    return _getUserCountForGroup(grp) > 0;
  }

  void _showCannotDeleteGroupDialog(Map<String, dynamic> grp, int userCount) {
    final String name = (grp['name'] ?? grp['code'] ?? '—').toString();

    showDialog(
      context: context,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 380),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Warning Shield/Alert Icon
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFDE68A),
                      width: 1.5,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFD97706),
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  'មិនអាចលុបក្រុមបានឡើយ',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),

                // Subtitle description
                Text(
                  'ក្រុម «$name» កំពុងមានអ្នកប្រើប្រាស់ ($userCount នាក់) ត្រូវបានចាត់តាំងរួចហើយ។\n\nអ្នកមិនអាចលុបក្រុមដែលមានអ្នកប្រើប្រាស់បានឡើយ។ សូមដកអ្នកប្រើប្រាស់ចេញពីក្រុមនេះជាមុនសិន ទើបអាចលុបបាន។',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 22),

                // Understand / Close Button
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(dialogCtx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'យល់ព្រម',
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _confirmDeleteGroup(Map<String, dynamic> grp) {
    final int assignedCount = _getUserCountForGroup(grp);
    if (assignedCount > 0) {
      _showCannotDeleteGroupDialog(grp, assignedCount);
      return;
    }

    final String name = (grp['name'] ?? grp['code'] ?? '—').toString();
    final String code = (grp['code'] ?? grp['sublabel'] ?? name).toString();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return Dialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 380),
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Clean Soft Red Trash Icon
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFEE2E2),
                      width: 1.5,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: Color(0xFFEF4444),
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  'លុបក្រុម (អង្គភាព)',
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),

                // Subtitle description
                Text(
                  'តើអ្នកពិតជាចង់លុបក្រុមនេះមែនទេ? សកម្មភាពនេះមិនអាចត្រឡប់វិញបានឡើយ។',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 12.5,
                    color: const Color(0xFF64748B),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),

                // Group Info Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.groups_rounded,
                          color: Color(0xFFEF4444),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                            if (code.isNotEmpty)
                              Text(
                                code.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'លុបចេញ',
                          style: GoogleFonts.kantumruyPro(
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Action Buttons (Cancel & Delete)
                Row(
                  children: [
                    // បោះបង់ Button
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(dialogCtx).pop(),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: Color(0xFFCBD5E1),
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            foregroundColor: const Color(0xFF475569),
                            elevation: 0,
                          ),
                          child: Text(
                            'បោះបង់',
                            style: GoogleFonts.kantumruyPro(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF475569),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // លុបក្រុម Button
                    Expanded(
                      child: SizedBox(
                        height: 44,
                        child: ElevatedButton(
                          onPressed: () async {
                            Navigator.of(dialogCtx).pop();
                            await _deleteGroup(grp);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'លុបក្រុម',
                            style: GoogleFonts.kantumruyPro(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
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
      },
    );
  }

  Future<void> _deleteGroup(Map<String, dynamic> grp) async {
    final int assignedCount = _getUserCountForGroup(grp);
    if (assignedCount > 0) {
      CustomSnackbar.showWarning(
        title: 'មិនអាចលុបបានទេ',
        message: 'មិនអាចលុបក្រុមដែលមានអ្នកប្រើប្រាស់ ($assignedCount នាក់) បានឡើយ',
      );
      return;
    }

    final String id = (grp['id'] ?? '').toString();
    final String name = (grp['name'] ?? grp['code'] ?? '').toString();
    final String code = (grp['code'] ?? grp['sublabel'] ?? name).toString();
    final String targetIdOrCode = id.isNotEmpty ? id : (code.isNotEmpty ? code : name);

    isLoadingGroups.value = true;
    try {
      try {
        await AuthService().deleteAdminGroup(targetIdOrCode);
      } catch (e) {
        debugPrint("API deleteAdminGroup error ($targetIdOrCode): $e");
        String msg = 'cannot_delete_group'.tr;
        if (msg.isEmpty || msg == 'cannot_delete_group') {
          msg = 'មិនអាចលុបក្រុមនេះបានឡើយ (Failed to delete group)';
        }
        CustomSnackbar.showError(
          title: 'error'.tr,
          message: msg,
        );
        return;
      }

      // Remove from allGroups
      allGroups.removeWhere((g) =>
          (id.isNotEmpty && g['id'] == id) ||
          g['name'] == name ||
          g['code'] == code);
      allGroups.refresh();

      // Remove from assignedGroups
      assignedGroups.remove(name);
      assignedGroups.remove(code);
      assignedGroups.refresh();

      // Track as deleted so saving won't re-add
      deletedGroupCodes.add(name);
      if (code.isNotEmpty) deletedGroupCodes.add(code);

      // Remove from controller.groupList
      controller.groupList.removeWhere((g) =>
          (id.isNotEmpty && g['id'] == id) ||
          g['name'] == name ||
          g['code'] == code);
      controller.groupList.refresh();

      try {
        GetStorage().write('cached_admin_group_list', controller.groupList.toList());
      } catch (_) {}

      // Load Clean Delete Success Dialog
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogCtx) {
            return Dialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 380),
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Clean Emerald Icon Container
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFDCFCE7),
                          width: 1.5,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.check_rounded,
                          color: Color(0xFF16A34A),
                          size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Title
                    Text(
                      'លុបបានជោគជ័យ',
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Subtitle description
                    Text(
                      'ក្រុម (អង្គភាព) ត្រូវបានលុបចេញពីប្រព័ន្ធដោយជោគជ័យ',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 12.5,
                        color: const Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Group Info Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.groups_rounded,
                              color: Color(0xFFEF4444),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                if (code.isNotEmpty)
                                  Text(
                                    code.toUpperCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: const Color(0xFF94A3B8),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF2F2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'បានលុប',
                              style: GoogleFonts.kantumruyPro(
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFEF4444),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(dialogCtx).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'យល់ព្រម',
                          style: GoogleFonts.kantumruyPro(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      }
    } catch (e) {
      CustomSnackbar.showError(message: 'cannot_delete_group'.tr);
    } finally {
      isLoadingGroups.value = false;
    }
  }



  @override
  Widget build(BuildContext context) {
    final bool canEdit = controller.canEditUser(_selectedUser);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
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
              _buildUserDetailsCard(),
              const SizedBox(height: 20),
              _buildAssignGroupsCard(),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  // ─── 1. Header ────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: const BoxDecoration(
            color: Color(0xFFEFF6FF),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: Color(0xFF1E293B),
            ),
            onPressed: () => Get.back(),
            padding: EdgeInsets.zero,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'កែសម្រួលក្រុមប្រើប្រាស់',
                style: GoogleFonts.kantumruyPro(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'គ្រប់គ្រងក្រុម និងសិទ្ធិក្រុមរបស់អ្នកប្រើប្រាស់',
                style: GoogleFonts.kantumruyPro(
                  fontSize: 12,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── 2. User Selector Dropdown Card (Using Live Users from API) ───────────
  Widget _buildUserSelector() {
    final List<Map<String, dynamic>> users = controller.usersList;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'select_user_account'.tr,
            style: GoogleFonts.kantumruyPro(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.groups_rounded,
                    color: Color(0xFF2563EB),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Map<String, dynamic>>(
                      value: users.firstWhereOrNull(
                            (u) => u['username'] == _selectedUser['username'],
                          ) ??
                          _selectedUser,
                      isExpanded: true,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF64748B),
                      ),
                      items: users.map((user) {
                        final uEmail = (user['email'] ?? '').toString().trim();
                        final uName = (user['username'] ?? user['name'] ?? '').toString().trim();
                        return DropdownMenuItem<Map<String, dynamic>>(
                          value: user,
                          child: Text(
                            uEmail.isNotEmpty ? "$uName - $uEmail" : uName,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: _onUserChanged,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 3. User Details Card (Email, Phone, Position, Date REMOVED) ──────────
  Widget _buildUserDetailsCard() {
    final String rawUsername = (_selectedUser['username'] ??
            _selectedUser['userName'] ??
            _selectedUser['accountName'] ??
            '')
        .toString()
        .trim();
    final String rawId = (_selectedUser['id'] ??
            _selectedUser['keycloakUserId'] ??
            '')
        .toString()
        .trim();
    final String cleanUsername = (rawUsername.isNotEmpty && rawUsername != rawId)
        ? rawUsername
        : '';

    String rawDisplayName = (_selectedUser['displayName'] ??
            _selectedUser['display_name'] ??
            _selectedUser['fullName'] ??
            _selectedUser['full_name'] ??
            _selectedUser['name_kh'] ??
            _selectedUser['nameKh'] ??
            _selectedUser['displayNameKh'] ??
            '')
        .toString()
        .trim();

    if ((rawDisplayName.isEmpty || rawDisplayName.toLowerCase() == cleanUsername.toLowerCase()) &&
        _selectedUser['attributes'] is Map) {
      final attrDisp = _selectedUser['attributes']['displayName'] ??
          _selectedUser['attributes']['display_name'];
      if (attrDisp is List && attrDisp.isNotEmpty) {
        rawDisplayName = attrDisp.first.toString().trim();
      } else if (attrDisp is String) {
        rawDisplayName = attrDisp.trim();
      }
    }

    if (rawDisplayName.isEmpty || rawDisplayName.toLowerCase() == cleanUsername.toLowerCase()) {
      final first = (_selectedUser['firstName'] ?? _selectedUser['first_name'] ?? '').toString().trim();
      final last = (_selectedUser['lastName'] ?? _selectedUser['last_name'] ?? '').toString().trim();
      if (first.isNotEmpty || last.isNotEmpty) {
        rawDisplayName = '$first $last'.trim();
      }
    }

    final box = GetStorage();
    final currentUname = (box.read('username') ?? '').toString().trim().toLowerCase();
    if ((rawDisplayName.isEmpty || rawDisplayName.toLowerCase() == cleanUsername.toLowerCase()) &&
        cleanUsername.toLowerCase() == currentUname) {
      final selfName = (box.read('user_display_name') ?? box.read('displayName') ?? '').toString().trim();
      if (selfName.isNotEmpty) {
        rawDisplayName = selfName;
      }
    }

    if (rawDisplayName.isEmpty || rawDisplayName.toLowerCase() == cleanUsername.toLowerCase()) {
      final rawName = (_selectedUser['name'] ?? '').toString().trim();
      if (rawName.isNotEmpty && rawName.toLowerCase() != cleanUsername.toLowerCase()) {
        rawDisplayName = rawName;
      }
    }

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
        : (cleanUsername.isNotEmpty ? cleanUsername : '—');
    final String username = cleanUsername.isNotEmpty
        ? cleanUsername
        : (displayName != '—' ? displayName : '—');
    final isActive =
        (_selectedUser['status'] ?? 'ACTIVE').toString().toUpperCase() ==
        'ACTIVE';

    // Format unit using AdminController.formatDepartmentToKhmer
    String unit = (_selectedUser['unit'] ??
            _selectedUser['department'] ??
            _selectedUser['departmentName'] ??
            _selectedUser['org'] ??
            '')
        .toString()
        .trim();

    final List empInfos = _selectedUser['employmentInfos'] is List
        ? _selectedUser['employmentInfos']
        : [];
    if (empInfos.isNotEmpty && empInfos[0] is Map) {
      final firstEmp = empInfos[0];
      final rawKh = (firstEmp['generalDepartmentNameKh'] ??
              firstEmp['departmentNameKh'] ??
              '')
          .toString()
          .trim();
      if (rawKh.isNotEmpty && rawKh != '—' && rawKh != '-') {
        unit = rawKh;
      } else {
        final raw = (firstEmp['generalDepartmentCode'] ??
                firstEmp['generalDepartmentName'] ??
                '')
            .toString()
            .trim();
        unit = AdminController.formatDepartmentToKhmer(raw);
      }
    } else {
      unit = AdminController.formatDepartmentToKhmer(unit);
    }

    // Extract 2 initials for avatar
    String initial = 'U';
    final nameForInitial = displayName != '—' ? displayName : username;
    if (nameForInitial.isNotEmpty && nameForInitial != '—') {
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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row: Avatar + Name + Status + Username
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  color: Color(0xFFEFF6FF),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initial,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF2563EB),
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
                            style: GoogleFonts.poppins(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
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
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                isActive ? 'active'.tr : 'inactive'.tr,
                                style: GoogleFonts.kantumruyPro(
                                  fontSize: 10.5,
                                  color: isActive
                                      ? const Color(0xFF047857)
                                      : const Color(0xFFB91C1C),
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
                          Icons.person_outline_rounded,
                          size: 15,
                          color: Color(0xFF64748B),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          username,
                          style: GoogleFonts.poppins(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1.2),
          const SizedBox(height: 14),

          // Detail row 1: អង្គភាព
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    'unit_department'.tr,
                    style: GoogleFonts.kantumruyPro(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    unit,
                    style: GoogleFonts.kantumruyPro(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Detail row 2: ប្រភេទ / ស្ថានភាព
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    'category'.tr,
                    style: GoogleFonts.kantumruyPro(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    isActive ? 'active'.tr : 'inactive'.tr,
                    style: GoogleFonts.kantumruyPro(
                      fontSize: 12.5,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 4. Assign Groups Checklist Card (Data from API) ───────────────────────
  Widget _buildAssignGroupsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Amber icon + Title + Subtitle + Create Group Button
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.group_add_rounded,
                  color: Color(0xFFD97706),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'configure_user_groups'.tr,
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      'assign_user_group_desc'.tr,
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 11.5,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => _openCreateGroupView(),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: const Color(0xFFBFDBFE),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add_rounded,
                        size: 16,
                        color: Color(0xFF2563EB),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'create_group'.tr,
                        style: GoogleFonts.kantumruyPro(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Search Field
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              onChanged: (val) => searchQuery.value = val,
              style: GoogleFonts.kantumruyPro(
                fontSize: 13,
                color: const Color(0xFF0F172A),
              ),
              decoration: InputDecoration(
                hintText: 'search_group_hint'.tr,
                hintStyle: GoogleFonts.kantumruyPro(
                  fontSize: 13,
                  color: const Color(0xFF94A3B8),
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 20,
                  color: Color(0xFF94A3B8),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Checklist of Groups from API
          Obx(() {
            if (isLoadingGroups.value) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 30),
                alignment: Alignment.center,
                child: const CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Color(0xFF2563EB),
                ),
              );
            }

            final query = searchQuery.value.toLowerCase().trim();
            final filtered = allGroups.where((g) {
              final name = (g['name'] ?? '').toString().toLowerCase();
              final code = (g['code'] ?? g['sublabel'] ?? '').toString().toLowerCase();
              return name.contains(query) || code.contains(query);
            }).toList();

            if (filtered.isEmpty) {
              final isSearching = query.isNotEmpty;
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isSearching
                            ? Icons.search_off_rounded
                            : Icons.groups_outlined,
                        color: const Color(0xFF94A3B8),
                        size: 22,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      allGroups.isEmpty
                          ? 'no_groups_created_yet'.tr
                          : 'no_matching_groups_found'.tr,
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 13,
                        color: const Color(0xFF94A3B8),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _openCreateGroupView(
                        initialName: isSearching ? searchQuery.value.trim() : null,
                      ),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: Text(
                        isSearching && searchQuery.value.trim().isNotEmpty
                            ? "${'create_group'.tr} \"${searchQuery.value.trim()}\""
                            : 'create_new_group'.tr,
                        style: GoogleFonts.kantumruyPro(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 9,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            return Column(
              children: filtered.map((grp) {
                final String name = (grp['name'] ?? grp['code'] ?? '—').toString();
                final String code = (grp['code'] ?? grp['sublabel'] ?? name).toString();
                final bool isChecked = assignedGroups.contains(name);
                final int assignedUserCount = _getUserCountForGroup(grp);
                final bool hasAssignedUsers = _hasAssignedUsers(grp);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isChecked ? const Color(0xFFBFDBFE) : const Color(0xFFF1F5F9),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    child: Row(
                      children: [
                        // Left area: Checkbox + Name & Code toggles selection
                        Expanded(
                          child: InkWell(
                            onTap: () => _toggleGroup(name),
                            borderRadius: BorderRadius.circular(10),
                            child: Row(
                              children: [
                                // Custom Checkbox matching mockup
                                Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: isChecked ? const Color(0xFF2563EB) : Colors.white,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: isChecked
                                          ? const Color(0xFF2563EB)
                                          : const Color(0xFFCBD5E1),
                                      width: 1.6,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: isChecked
                                      ? const Icon(
                                          Icons.check_rounded,
                                          size: 15,
                                          color: Colors.white,
                                        )
                                      : null,
                                ),
                                const SizedBox(width: 14),
                                // Group Name & Code
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        style: GoogleFonts.poppins(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(height: 1),
                                      Row(
                                        children: [
                                          if (code.isNotEmpty)
                                            Text(
                                              code,
                                              style: GoogleFonts.poppins(
                                                fontSize: 11.5,
                                                color: const Color(0xFF94A3B8),
                                              ),
                                            ),
                                          if (hasAssignedUsers) ...[
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 6,
                                                vertical: 1.5,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFEFF6FF),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: const Color(0xFFBFDBFE),
                                                  width: 0.6,
                                                ),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  const Icon(
                                                    Icons.person_outline_rounded,
                                                    size: 11,
                                                    color: Color(0xFF2563EB),
                                                  ),
                                                  const SizedBox(width: 3),
                                                  Text(
                                                    '$assignedUserCount នាក់',
                                                    style: GoogleFonts.kantumruyPro(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w600,
                                                      color: const Color(0xFF2563EB),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Action buttons: Edit & Delete
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Edit Icon Button
                            InkWell(
                              onTap: () async {
                                final result = await Get.to(() => AdminEditGroupView(
                                      group: grp,
                                      user: _selectedUser,
                                    ));
                                if (result is Map) {
                                  final updatedName = (result['name'] ?? result['code'] ?? '').toString().trim();
                                  final currentAssigned = List<String>.from(assignedGroups);
                                  await _refreshGroups(
                                    preserveAssigned: currentAssigned,
                                    newGroupName: updatedName,
                                  );
                                } else {
                                  await _refreshGroups(preserveAssigned: assignedGroups.toList());
                                }
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 32,
                                height: 32,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFBFDBFE),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.edit_outlined,
                                  size: 16,
                                  color: Color(0xFF2563EB),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Delete Icon Button
                            InkWell(
                              onTap: hasAssignedUsers
                                  ? () => _showCannotDeleteGroupDialog(
                                        grp,
                                        assignedUserCount,
                                      )
                                  : () => _confirmDeleteGroup(grp),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 32,
                                height: 32,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: hasAssignedUsers
                                      ? const Color(0xFFF1F5F9)
                                      : const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: hasAssignedUsers
                                        ? const Color(0xFFE2E8F0)
                                        : const Color(0xFFFECACA),
                                  ),
                                ),
                                child: Icon(
                                  Icons.delete_outline_rounded,
                                  size: 16,
                                  color: hasAssignedUsers
                                      ? const Color(0xFF94A3B8)
                                      : const Color(0xFFEF4444),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          }),

          const SizedBox(height: 16),
          const Divider(color: Color(0xFFF1F5F9), height: 1, thickness: 1.2),
          const SizedBox(height: 14),

          // ─── Bottom Section: ក្រុមដែលបានកំណត់ (X) ──────────────────────────
          Obx(() {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => isAssignedExpanded.toggle(),
                  borderRadius: BorderRadius.circular(8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.groups_rounded,
                        color: Color(0xFFEF4444),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "${'assigned_groups'.tr} (${assignedGroups.length})",
                        style: GoogleFonts.kantumruyPro(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        isAssignedExpanded.value
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: const Color(0xFF64748B),
                        size: 22,
                      ),
                    ],
                  ),
                ),
                if (isAssignedExpanded.value) ...[
                  const SizedBox(height: 12),
                  if (assignedGroups.isEmpty)
                    Text(
                      'no_groups_assigned_yet'.tr,
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: assignedGroups.map((groupCode) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: const Color(0xFFFCA5A5).withOpacity(0.5),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                groupCode,
                                style: GoogleFonts.poppins(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFEF4444),
                                ),
                              ),
                              const SizedBox(width: 6),
                              InkWell(
                                onTap: () => _toggleGroup(groupCode),
                                borderRadius: BorderRadius.circular(10),
                                child: const Padding(
                                  padding: EdgeInsets.all(2),
                                  child: Icon(
                                    Icons.close_rounded,
                                    size: 14,
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ],
            );
          }),
        ],
      ),
    );
  }

  // ─── 5. Pinned Bottom Navigation Bar ──────────────────────────────────────
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFF1F5F9), width: 1.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // ត្រឡប់ Button
          Expanded(
            child: SizedBox(
              height: 48,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                onPressed: () => Get.back(),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'back'.tr,
                    maxLines: 1,
                    style: GoogleFonts.kantumruyPro(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // រក្សាទុកការកែប្រែ Button
          Expanded(
            child: SizedBox(
              height: 48,
              child: Obx(
                () => ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: (isSaving.value || !controller.canEditUser(_selectedUser))
                      ? null
                      : _onSave,
                  child: isSaving.value
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'save_changes'.tr,
                            maxLines: 1,
                            style: GoogleFonts.kantumruyPro(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
