import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get_storage/get_storage.dart';
import 'package:core_portal/core/api/api_client.dart';
import 'package:core_portal/core/api/services/auth_service.dart';
import 'package:core_portal/screens/admin/admin_controller.dart';
import 'package:core_portal/widgets/custom_snackbar.dart';
import 'package:core_portal/widgets/app_icon.dart';
import 'package:core_portal/screens/admin/admin_edit_user_groups_view.dart';

class AdminEditGroupView extends StatefulWidget {
  final Map<String, dynamic> group;
  final Map<String, dynamic>? user;

  const AdminEditGroupView({
    super.key,
    required this.group,
    this.user,
  });

  @override
  State<AdminEditGroupView> createState() => _AdminEditGroupViewState();
}

class _AdminEditGroupViewState extends State<AdminEditGroupView> {
  late AdminController controller;

  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late String _status;

  // Search queries for sections
  final RxString appSearchQuery = ''.obs;
  final RxString userSearchQuery = ''.obs;

  // Users dropdown toggle
  bool isUsersDropdownOpen = false;
  bool isSaving = false;

  // Selected items using RxSet
  final RxSet<String> selectedApps = <String>{}.obs;
  final RxSet<String> selectedUsers = <String>{}.obs;

  // Reactive live lists for Apps & Users from API
  final RxList<Map<String, String>> apiAppsList = <Map<String, String>>[].obs;
  final RxList<Map<String, String>> apiUsersList = <Map<String, String>>[].obs;
  final RxBool isLoadingApps = false.obs;

  String _normalizeString(String s) {
    String res = s.trim().toLowerCase();
    if (res.startsWith('/')) res = res.substring(1);
    return res.replaceAll('/', '-');
  }

  bool isAppSelected(Map<String, String> app) {
    final id = app['id'] ?? '';
    final code = app['code'] ?? '';
    final name = app['name'] ?? '';
    return selectedApps.contains(id) ||
        selectedApps.contains(code) ||
        selectedApps.contains(name) ||
        (code.isNotEmpty && selectedApps.contains(code.toUpperCase())) ||
        (name.isNotEmpty && selectedApps.contains(name.toLowerCase()));
  }

  void toggleApp(Map<String, String> app) {
    final id = app['id'] ?? '';
    final code = app['code'] ?? '';
    final name = app['name'] ?? '';
    if (isAppSelected(app)) {
      selectedApps.remove(id);
      selectedApps.remove(code);
      selectedApps.remove(name);
      selectedApps.remove(code.toUpperCase());
      selectedApps.remove(name.toLowerCase());
    } else {
      final toAdd = id.isNotEmpty ? id : (name.isNotEmpty ? name : code);
      if (toAdd.isNotEmpty) selectedApps.add(toAdd);
    }
  }

  bool isUserSelected(String username, [String? id, String? name]) {
    final uLow = username.trim().toLowerCase();
    final idLow = (id ?? '').trim().toLowerCase();
    final nameLow = (name ?? '').trim().toLowerCase();

    for (final s in selectedUsers) {
      final sLow = s.trim().toLowerCase();
      if (sLow == uLow ||
          (idLow.isNotEmpty && sLow == idLow) ||
          (nameLow.isNotEmpty && sLow == nameLow)) {
        return true;
      }
    }
    return false;
  }

  void toggleUser(String username, [String? id, String? name]) {
    if (isUserSelected(username, id, name)) {
      final toRemove = <String>{};
      final uLow = username.trim().toLowerCase();
      final idLow = (id ?? '').trim().toLowerCase();
      final nameLow = (name ?? '').trim().toLowerCase();

      for (final s in selectedUsers) {
        final sLow = s.trim().toLowerCase();
        if (sLow == uLow ||
            (idLow.isNotEmpty && sLow == idLow) ||
            (nameLow.isNotEmpty && sLow == nameLow)) {
          toRemove.add(s);
        }
      }
      selectedUsers.removeAll(toRemove);
    } else {
      final toAdd = username.isNotEmpty ? username : (id ?? name ?? '');
      if (toAdd.isNotEmpty) selectedUsers.add(toAdd);
    }
  }

  // ─── API Icon URL & Asset Resolution ─────────────────────────────────────
  String _resolveIconUrl(String rawIcon) {
    return AppIconWidget.formatIconUrl(rawIcon);
  }

  // ─── 1. Load Applications using GET /admin/portal-apps ────────────────────
  Future<void> _loadApps() async {
    isLoadingApps.value = true;
    final List<Map<String, String>> list = [];

    void addAppsFrom(List source) {
      for (final a in source) {
        if (a is! Map) continue;
        final String id = (a['id'] ?? a['appId'] ?? '').toString().trim();
        final String code =
            (a['code'] ?? a['appCode'] ?? a['name'] ?? '').toString().trim();
        final String nameKh = (a['titleKh'] ??
                a['nameKh'] ??
                a['name'] ??
                a['title'] ??
                code)
            .toString()
            .trim();
        final String nameEn = (a['titleEn'] ?? a['nameEn'] ?? '').toString().trim();
        final String icon = (a['icon'] ?? a['logo'] ?? '').toString().trim();
        final String iconUrl = (a['iconUrl'] ?? a['logoUrl'] ?? '').toString().trim();

        if (nameKh.isNotEmpty || code.isNotEmpty) {
          final existing = list.any((item) =>
              (id.isNotEmpty && item['id'] == id) ||
              (code.isNotEmpty && item['code'] == code));
          if (!existing) {
            list.add({
              'id': id,
              'code': code,
              'name': nameKh.isNotEmpty ? nameKh : code,
              'nameEn': nameEn,
              'icon': icon,
              'iconUrl': iconUrl.isNotEmpty ? iconUrl : _resolveIconUrl(icon),
            });
          }
        }
      }
    }

    if (controller.appsList.isNotEmpty) {
      addAppsFrom(controller.appsList);
    }

    final cachedApps = GetStorage().read('cached_admin_apps_list');
    if (cachedApps is List) {
      addAppsFrom(cachedApps);
    }

    if (list.isNotEmpty) {
      apiAppsList.assignAll(list);
    }

    try {
      dynamic res;
      try {
        final r = await ApiClient.dio.get('/admin/portal-apps');
        res = r.data;
      } catch (e) {
        debugPrint("GET /admin/portal-apps warning: $e");
        try {
          res = await AuthService().fetchPortalApps();
        } catch (_) {}
      }

      List rawApps = [];
      if (res != null) {
        if (res is List) {
          rawApps = res;
        } else if (res is Map) {
          rawApps = res['data'] ??
              res['items'] ??
              res['value'] ??
              res['content'] ??
              [];
        }
      }

      if (rawApps.isNotEmpty) {
        addAppsFrom(rawApps);
        apiAppsList.assignAll(list);
      }
    } catch (e) {
      debugPrint("Error fetching portal-apps in AdminEditGroupView: $e");
    } finally {
      isLoadingApps.value = false;
    }
  }

  // ─── 2. Load Users using GET /admin/user-profiles?page=0&size=100 ──────────
  Future<void> _loadUsers() async {
    final List<Map<String, String>> list = [];

    void addUsersFrom(List source) {
      for (final u in source) {
        if (u is! Map) continue;
        final String username = (u['username'] ?? '').toString().trim();
        final String name = (u['displayName'] ??
                u['display_name'] ??
                u['fullName'] ??
                u['nameKh'] ??
                u['name'] ??
                username)
            .toString()
            .trim();
        final String id = (u['id'] ??
                u['keycloakUserId'] ??
                u['userId'] ??
                username)
            .toString()
            .trim();
        final String email = (u['email'] ?? '').toString().trim();

        final String display = (name.isNotEmpty && name != username)
            ? '$name ($username)'
            : (username.isNotEmpty ? username : id);

        if (display.isNotEmpty) {
          final existing = list.any((item) =>
              (id.isNotEmpty && item['id'] == id) ||
              (username.isNotEmpty && item['username'] == username));
          if (!existing) {
            list.add({
              'id': id,
              'username': username.isNotEmpty ? username : id,
              'name': name.isNotEmpty ? name : username,
              'display': display,
              'email': email,
            });
          }
        }
      }
    }

    if (controller.usersList.isNotEmpty) {
      addUsersFrom(controller.usersList);
    }

    final cachedUsers = GetStorage().read('cached_admin_users_list');
    if (cachedUsers is List) {
      addUsersFrom(cachedUsers);
    }

    if (list.isNotEmpty) {
      apiUsersList.assignAll(list);
    }

    try {
      dynamic res;
      try {
        final r = await ApiClient.dio.get('/admin/user-profiles?page=0&size=100');
        res = r.data;
      } catch (e) {
        debugPrint("GET /admin/user-profiles?page=0&size=100 warning: $e");
        try {
          final r = await ApiClient.dio.get('/admin/user-profiles');
          res = r.data;
        } catch (_) {}
      }

      List rawUsers = [];
      if (res != null) {
        if (res is List) {
          rawUsers = res;
        } else if (res is Map) {
          final data = res['content'] ??
              res['value'] ??
              res['items'] ??
              res['data'] ??
              res['users'];
          if (data is List) rawUsers = data;
        }
      }

      if (rawUsers.isNotEmpty) {
        addUsersFrom(rawUsers);
        apiUsersList.assignAll(list);
      }
    } catch (e) {
      debugPrint("Error fetching user-profiles in AdminEditGroupView: $e");
    }
  }

  // ─── 3. Load Groups using GET /admin/portal-groups/created-by-me ──────────
  Future<void> _loadGroups() async {
    try {
      final res = await AuthService().fetchPortalGroupsCreatedByMe();
      List rawList = [];
      if (res is List) {
        rawList = res;
      } else if (res is Map) {
        rawList = res['data'] ?? res['items'] ?? res['value'] ?? [];
      }
      final parsed = rawList.map<Map<String, dynamic>>((g) {
        final Map<String, dynamic> item =
            g is Map ? Map<String, dynamic>.from(g) : {};
        return {
          'id': item['id']?.toString(),
          'name': (item['name'] ?? item['code'] ?? '—').toString().trim(),
          'sublabel': (item['code'] ?? item['sublabel'] ?? '').toString().trim(),
          'code': (item['code'] ?? '').toString().trim(),
          'status': item['status'] ?? 'ACTIVE',
          'description': item['description'] ?? item['desc'],
        };
      }).toList();

      if (parsed.isNotEmpty) {
        controller.groupList.assignAll(parsed);
      }
    } catch (e) {
      debugPrint("Error fetching created-by-me in AdminEditGroupView: $e");
    }
  }

  // ─── 4 & 5. Load Roles and Group Roles ───────────────────────────────────
  Future<void> _loadRolesAndGroupRoles() async {
    try {
      await Future.wait([
        ApiClient.dio.get('/admin/portal-roles').catchError((_) => ApiClient.dio.get('')),
        ApiClient.dio.get('/admin/portal-group-roles').catchError((_) => ApiClient.dio.get('')),
      ]);
    } catch (_) {}
  }

  List<Map<String, String>> get allAppsList {
    if (apiAppsList.isNotEmpty) return apiAppsList;
    return [];
  }

  List<Map<String, String>> get allUsersList {
    if (apiUsersList.isNotEmpty) return apiUsersList;
    return [];
  }

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<AdminController>()) {
      controller = Get.find<AdminController>();
    } else {
      controller = Get.put(AdminController());
    }

    final initialName = (widget.group['name'] ?? widget.group['code'] ?? '').toString();
    final initialDesc = (widget.group['description'] ?? widget.group['desc'] ?? '').toString();
    _nameCtrl = TextEditingController(text: initialName);
    _descCtrl = TextEditingController(text: initialDesc);
    _status = (widget.group['status'] ?? 'ACTIVE').toString().toUpperCase();

    // Pre-populate Selected Apps
    final appKeys = ['selectedApps', 'apps', 'applications', 'portalApplications'];
    for (final k in appKeys) {
      final val = widget.group[k];
      if (val is List && val.isNotEmpty) {
        for (final a in val) {
          if (a is String && a.isNotEmpty) {
            selectedApps.add(a);
          } else if (a is Map) {
            final appCode = (a['code'] ?? a['id'] ?? a['name'] ?? '').toString();
            if (appCode.isNotEmpty) selectedApps.add(appCode);
          }
        }
        break;
      }
    }

    // Pre-populate Selected Users
    final userKeys = ['selectedUsers', 'users', 'members'];
    for (final k in userKeys) {
      final val = widget.group[k];
      if (val is List && val.isNotEmpty) {
        for (final u in val) {
          if (u is String && u.isNotEmpty) {
            selectedUsers.add(u);
          } else if (u is Map) {
            final uName = (u['username'] ?? u['id'] ?? u['name'] ?? '').toString();
            if (uName.isNotEmpty) selectedUsers.add(uName);
          }
        }
        break;
      }
    }

    // Check userGroupsMap in controller
    final groupCode = (widget.group['code'] ?? widget.group['sublabel'] ?? initialName).toString();
    final dynamic cachedMembers = controller.userGroupsMap[groupCode] ??
        controller.userGroupsMap[initialName] ??
        controller.userGroupsMap[groupCode.toUpperCase()];
    if (cachedMembers is List) {
      for (final m in cachedMembers) {
        if (m != null && m.toString().trim().isNotEmpty) {
          selectedUsers.add(m.toString().trim());
        }
      }
    }

    if (widget.user != null) {
      final uName = (widget.user!['username'] ?? widget.user!['id'] ?? '').toString().trim();
      if (uName.isNotEmpty && !selectedUsers.contains(uName)) {
        selectedUsers.add(uName);
      }
    }

    // Trigger background loads
    _loadApps();
    _loadUsers();
    _loadGroups();
    _loadRolesAndGroupRoles();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _updateGroup() async {
    final newName = _nameCtrl.text.trim();
    if (newName.isEmpty) {
      CustomSnackbar.showError(message: 'please_enter_group_name'.tr);
      return;
    }

    final newCode = _normalizeString(newName)
        .toUpperCase()
        .replaceAll('-', '_')
        .replaceAll(' ', '_');
    final newDesc = _descCtrl.text.trim();

    final currentId = (widget.group['id'] ?? '').toString();
    final currentCode = (widget.group['code'] ?? widget.group['sublabel'] ?? '').toString();
    final currentName = (widget.group['name'] ?? '').toString();
    final targetIdOrCode = currentId.isNotEmpty
        ? currentId
        : (currentCode.isNotEmpty ? currentCode : (newCode.isNotEmpty ? newCode : currentName));

    setState(() => isSaving = true);

    final payload = {
      'name': newName,
      'code': newCode,
      'sublabel': newCode,
      'description': newDesc,
      'status': _status,
      'applications': selectedApps.toList(),
      'users': selectedUsers.toList(),
      'members': selectedUsers.length,
      'membersCount': selectedUsers.length,
    };

    // 1. Send HTTP PUT request to backend API (/admin/portal-groups/$id)
    try {
      await AuthService().updateAdminGroup(targetIdOrCode, payload);
    } catch (e) {
      debugPrint("PUT updateAdminGroup warning ($e), updating local state...");
    }

    // 2. Assign selected users to this group via /admin/portal-groups/user-groups
    if (selectedUsers.isNotEmpty) {
      for (final uName in selectedUsers) {
        final matched = allUsersList.firstWhereOrNull(
          (u) => u['username'] == uName || u['name'] == uName,
        );
        final uid = (matched?['id']?.isNotEmpty == true) ? matched!['id']! : uName;
        try {
          await AuthService().assignUserGroups(uid, [newCode]);
        } catch (e) {
          debugPrint("assignUserGroups warning ($uid -> $newCode): $e");
        }
      }
    }

    // 3. Update controller.groupList live state
    final updatedGroupMap = {
      ...widget.group,
      'id': currentId.isNotEmpty ? currentId : DateTime.now().millisecondsSinceEpoch.toString(),
      'name': newName,
      'sublabel': newCode.toUpperCase(),
      'code': newCode.toUpperCase(),
      'desc': newDesc,
      'description': newDesc,
      'status': _status,
      'members': selectedUsers.length,
      'membersCount': selectedUsers.length,
      'usersCount': selectedUsers.length,
      'selectedApps': selectedApps.toList(),
      'apps': selectedApps.toList(),
      'applications': selectedApps.toList(),
      'selectedUsers': selectedUsers.toList(),
      'users': selectedUsers.toList(),
    };

    final idx = controller.groupList.indexWhere((g) =>
        (currentId.isNotEmpty && g['id'] == currentId) ||
        g['name'] == currentName ||
        g['code'] == currentCode ||
        g['name'] == newName);

    if (idx != -1) {
      controller.groupList[idx] = updatedGroupMap;
    } else {
      controller.groupList.insert(0, updatedGroupMap);
    }
    controller.groupList.refresh();

    // 4. Update userGroupsMap for this group
    final targetGroupKeys = [
      newCode.toUpperCase(),
      newName,
      _normalizeString(newCode),
      if (currentCode.isNotEmpty) currentCode,
      if (currentName.isNotEmpty) currentName,
    ];
    for (final gk in targetGroupKeys) {
      controller.userGroupsMap[gk] = selectedUsers.toList();
    }
    controller.userGroupsMap.refresh();

    // 5. Update local cache storage
    try {
      final box = GetStorage();
      box.write('cached_admin_group_list', controller.groupList.toList());
      box.write('cached_user_groups_map', controller.userGroupsMap);
    } catch (_) {}

    // 6. Refresh created-by-me immediately from API
    await _loadGroups();

    // Clear form inputs and reset update_screen
    setState(() {
      isSaving = false;
      _nameCtrl.clear();
      _descCtrl.clear();
      _status = 'ACTIVE';
    });
    selectedApps.clear();
    selectedUsers.clear();

    // Load dialog (Clean Success Pop-up Dialog)
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
                    'edit_success'.tr,
                    style: GoogleFonts.kantumruyPro(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Subtitle description
                  Text(
                    'unit_updated_success_desc'.tr,
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
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.groups_rounded,
                            color: Color(0xFF2563EB),
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                newName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              if (newCode.isNotEmpty)
                                Text(
                                  newCode.toUpperCase(),
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
                            color: const Color(0xFFDCFCE7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'success'.tr,
                            style: GoogleFonts.kantumruyPro(
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF16A34A),
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
                        'confirm'.tr,
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

    // Clear update_screen and navigate back to edit group view
    if (mounted) {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop(updatedGroupMap);
      } else {
        Get.off(() => AdminEditUserGroupsView(user: widget.user ?? {}));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar / Header
            _buildHeader(),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildUnitInfoCard(),
                        const SizedBox(height: 14),
                        _buildAppsSection(),
                        const SizedBox(height: 14),
                        _buildUsersSection(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Sticky Action Bar
            _buildBottomStickyBar(),
          ],
        ),
      ),
    );
  }

  // ─── Header: Circular Back Button + Title + Breadcrumbs ───────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Row(
            children: [
              // Circular Back Button matching design concept
              InkWell(
                onTap: () => Get.back(),
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xffEFF6FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: Color(0xff0F172A),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Title and Breadcrumbs
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'edit_group_unit_title'.tr,
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xff0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          'group_user_management_nav'.tr,
                          style: GoogleFonts.kantumruyPro(
                            fontSize: 12,
                            color: const Color(0xff64748B),
                          ),
                        ),
                        Text(
                          'edit_info_nav'.tr,
                          style: GoogleFonts.kantumruyPro(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xff2563EB),
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
      ),
    );
  }

  // ─── 01. ព័ត៌មានអង្គភាព (Card 01) ──────────────────────────────────────────
  Widget _buildUnitInfoCard() {
    return Container(
      padding: const EdgeInsets.all(18),
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
          // Header: 01 ព័ត៌មានអង្គភាព
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xffEFF6FF),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '01',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff2563EB),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'unit_info'.tr,
                style: GoogleFonts.kantumruyPro(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ឈ្មោះក្រុម (អង្គភាព)
          Text(
            'group_unit_name'.tr,
            style: GoogleFonts.kantumruyPro(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xff0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xffE2E8F0)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: const BoxDecoration(
                    border: Border(
                      right: BorderSide(color: Color(0xffE2E8F0)),
                    ),
                  ),
                  child: const Icon(
                    Icons.apartment_rounded,
                    color: Color(0xff94A3B8),
                    size: 20,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    onChanged: (_) => setState(() {}),
                    style: GoogleFonts.kantumruyPro(
                      fontSize: 13.5,
                      color: const Color(0xff0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: 'enter_group_name_hint'.tr,
                      hintStyle: GoogleFonts.kantumruyPro(
                        fontSize: 13,
                        color: const Color(0xff94A3B8),
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ការពិពណ៌នា
          Text(
            'description'.tr,
            style: GoogleFonts.kantumruyPro(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xff0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xffE2E8F0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 14, top: 12, right: 10),
                  child: Icon(
                    Icons.description_outlined,
                    color: Color(0xff94A3B8),
                    size: 20,
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _descCtrl,
                    maxLines: 4,
                    maxLength: 255,
                    onChanged: (_) => setState(() {}),
                    style: GoogleFonts.kantumruyPro(
                      fontSize: 13,
                      color: const Color(0xff0F172A),
                    ),
                    decoration: InputDecoration(
                      hintText: 'enter_unit_desc_hint'.tr,
                      hintStyle: GoogleFonts.kantumruyPro(
                        fontSize: 13,
                        color: const Color(0xff94A3B8),
                      ),
                      counterText: '',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.only(
                        top: 12,
                        bottom: 12,
                        right: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${_descCtrl.text.length} / 255',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: const Color(0xff94A3B8),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ស្ថានភាព (Status Selection)
          Text(
            'status'.tr,
            style: GoogleFonts.kantumruyPro(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: const Color(0xff0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              // ដំណើរការ
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _status = 'ACTIVE'),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _status == 'ACTIVE'
                          ? const Color(0xffEFF6FF)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _status == 'ACTIVE'
                            ? const Color(0xff3B82F6)
                            : const Color(0xffE2E8F0),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _status == 'ACTIVE'
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: _status == 'ACTIVE'
                              ? const Color(0xff2563EB)
                              : const Color(0xff94A3B8),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'available'.tr,
                          style: GoogleFonts.kantumruyPro(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _status == 'ACTIVE'
                                ? const Color(0xff2563EB)
                                : const Color(0xff64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // ផ្អាក
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _status = 'INACTIVE'),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _status == 'INACTIVE'
                          ? const Color(0xffEFF6FF)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _status == 'INACTIVE'
                            ? const Color(0xff3B82F6)
                            : const Color(0xffE2E8F0),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _status == 'INACTIVE'
                              ? Icons.radio_button_checked
                              : Icons.radio_button_off,
                          color: _status == 'INACTIVE'
                              ? const Color(0xff2563EB)
                              : const Color(0xff94A3B8),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'suspended'.tr,
                          style: GoogleFonts.kantumruyPro(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: _status == 'INACTIVE'
                                ? const Color(0xff2563EB)
                                : const Color(0xff64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── App Icon Builder matching Application Screen Style ───────────────────
  Widget _buildAppIconWidget(Map<String, String> app, int index) {
    final code = (app['code'] ?? '').toUpperCase();
    final name = (app['name'] ?? '').toLowerCase();
    final iconUrl = app['iconUrl'] ?? '';
    final localAsset = app['icon'] ?? 'assets/img/about-moi-logo.png';


    if (code.contains('GOOGLE_MAP') || name.contains('google map')) {
      return Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: Color(0xFFEA4335),
                size: 26,
              ),
              Positioned(
                top: 8,
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (code.contains('GOOGLE_CALENDAR') || name.contains('google calendar')) {
      return Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0xFF1A73E8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            '28',
            style: GoogleFonts.roboto(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.all(3.5),
            child: AppIconWidget(
              iconUrl: iconUrl,
              localAsset: localAsset.isNotEmpty
                  ? localAsset
                  : 'assets/img/about-moi-logo.png',
              size: 30,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }

  // ─── 02. កម្មវិធី (Card 02) ────────────────────────────────────────────────
  Widget _buildAppsSection() {
    final apps = allAppsList;

    return Container(
      padding: const EdgeInsets.all(18),
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
          // Section Title & Badge
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xffEFF6FF),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '02',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff2563EB),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'application'.tr,
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff0F172A),
                  ),
                ),
              ),
              Obx(() => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xffEFF6FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${'selected'.tr} ${selectedApps.length}',
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xff2563EB),
                      ),
                    ),
                  )),
            ],
          ),
          const SizedBox(height: 14),

          // Search Field for Apps
          Container(
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xffF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xffE2E8F0)),
            ),
            child: TextField(
              onChanged: (v) => appSearchQuery.value = v,
              style: GoogleFonts.kantumruyPro(fontSize: 13),
              decoration: InputDecoration(
                hintText: 'search_apps_hint'.tr,
                hintStyle: GoogleFonts.kantumruyPro(
                  fontSize: 12.5,
                  color: const Color(0xff94A3B8),
                ),
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  size: 18,
                  color: Color(0xff94A3B8),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // App Grid List
          Obx(() {
            if (isLoadingApps.value && apps.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              );
            }

            final query = appSearchQuery.value.trim().toLowerCase();
            final filtered = apps.where((a) {
              final name = (a['name'] ?? '').toLowerCase();
              final code = (a['code'] ?? '').toLowerCase();
              return name.contains(query) || code.contains(query);
            }).toList();

            if (filtered.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'no_matching_apps'.tr,
                    style: GoogleFonts.kantumruyPro(
                      fontSize: 12,
                      color: const Color(0xff94A3B8),
                    ),
                  ),
                ),
              );
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final app = filtered[index];
                return Obx(() {
                  final isChecked = isAppSelected(app);

                  return InkWell(
                    onTap: () => toggleApp(app),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isChecked
                            ? const Color(0xffF0F7FF)
                            : const Color(0xffFAFAFA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isChecked
                              ? const Color(0xff93C5FD)
                              : const Color(0xffE2E8F0),
                          width: isChecked ? 1.4 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          _buildAppIconWidget(app, index),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  app['name'] ?? '',
                                  style: GoogleFonts.kantumruyPro(
                                    fontSize: 13,
                                    fontWeight: isChecked
                                        ? FontWeight.bold
                                        : FontWeight.w600,
                                    color: const Color(0xff0F172A),
                                  ),
                                ),
                                if ((app['code'] ?? '').isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    app['code']!,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: const Color(0xff64748B),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: isChecked
                                  ? const Color(0xff2563EB)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: isChecked
                                    ? const Color(0xff2563EB)
                                    : const Color(0xffCBD5E1),
                                width: 1.5,
                              ),
                            ),
                            child: isChecked
                                ? const Icon(
                                    Icons.check_rounded,
                                    size: 16,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  );
                });
              },
            );
          }),
        ],
      ),
    );
  }

  // ─── 03. អ្នកប្រើប្រាស់ (Card 03) ──────────────────────────────────────────
  Widget _buildUsersSection() {
    final users = allUsersList;

    return Container(
      padding: const EdgeInsets.all(18),
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
          // Header: 03 អ្នកប្រើប្រាស់ + Badge
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xffEFF6FF),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '03',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff2563EB),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'users'.tr,
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff0F172A),
                  ),
                ),
              ),
              Obx(() => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xffEFF6FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${'selected'.tr} ${selectedUsers.length}',
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xff2563EB),
                      ),
                    ),
                  )),
            ],
          ),
          const SizedBox(height: 14),

          // Selected Users Pills
          Obx(() {
            if (selectedUsers.isEmpty) return const SizedBox.shrink();

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xffF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xffE2E8F0)),
              ),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selectedUsers.map((u) {
                  final matched = allUsersList.firstWhereOrNull(
                    (user) =>
                        user['username'] == u ||
                        user['name'] == u ||
                        user['id'] == u,
                  );
                  final displayName = matched?['display'] ?? u;

                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xffEFF6FF),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xffBFDBFE)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.person_rounded,
                          size: 14,
                          color: Color(0xff2563EB),
                        ),
                        const SizedBox(width: 6),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 160),
                          child: Text(
                            displayName,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.kantumruyPro(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xff1E40AF),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () => toggleUser(u),
                          borderRadius: BorderRadius.circular(10),
                          child: const Padding(
                            padding: EdgeInsets.all(2),
                            child: Icon(
                              Icons.close_rounded,
                              size: 14,
                              color: Color(0xff64748B),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            );
          }),

          // Dropdown Input trigger
          InkWell(
            onTap: () =>
                setState(() => isUsersDropdownOpen = !isUsersDropdownOpen),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isUsersDropdownOpen
                      ? const Color(0xff2563EB)
                      : const Color(0xffE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.person_search_rounded,
                    color: Color(0xff94A3B8),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'search_users_hint'.tr,
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 13,
                        color: const Color(0xff94A3B8),
                      ),
                    ),
                  ),
                  Icon(
                    isUsersDropdownOpen
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: const Color(0xff64748B),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Dropdown user list
          if (isUsersDropdownOpen) ...[
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(maxHeight: 260),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xffE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: TextField(
                      onChanged: (v) => userSearchQuery.value = v,
                      style: GoogleFonts.kantumruyPro(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'search_user_name_or_username'.tr,
                        hintStyle: GoogleFonts.kantumruyPro(
                          fontSize: 12,
                          color: const Color(0xff94A3B8),
                        ),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          size: 16,
                          color: Color(0xff94A3B8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        filled: true,
                        fillColor: const Color(0xffF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xffE2E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xffE2E8F0)),
                        ),
                      ),
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xffF1F5F9)),
                  Expanded(
                    child: Obx(() {
                      final query = userSearchQuery.value.trim().toLowerCase();
                      final filtered = users.where((u) {
                        final display = (u['display'] ?? '').toLowerCase();
                        final username = (u['username'] ?? '').toLowerCase();
                        final email = (u['email'] ?? '').toLowerCase();
                        return display.contains(query) ||
                            username.contains(query) ||
                            email.contains(query);
                      }).toList();

                      if (filtered.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'no_matching_users'.tr,
                              style: GoogleFonts.kantumruyPro(
                                fontSize: 12,
                                color: const Color(0xff94A3B8),
                              ),
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (ctx, idx) =>
                            const Divider(height: 1, color: Color(0xffF8FAFC)),
                        itemBuilder: (context, index) {
                          final user = filtered[index];
                          final uName = user['username']!;
                          final id = user['id'];
                          final name = user['name'];

                          return Obx(() {
                            final isChecked = isUserSelected(uName, id, name);
                            return InkWell(
                              onTap: () => toggleUser(uName, id, name),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: const Color(0xffEFF6FF),
                                      child: Text(
                                        uName.isNotEmpty
                                            ? uName[0].toUpperCase()
                                            : 'U',
                                        style: GoogleFonts.poppins(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: const Color(0xff2563EB),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            user['display']!,
                                            style: GoogleFonts.kantumruyPro(
                                              fontSize: 13,
                                              fontWeight: isChecked
                                                  ? FontWeight.bold
                                                  : FontWeight.w600,
                                              color: isChecked
                                                  ? const Color(0xff0F172A)
                                                  : const Color(0xff334155),
                                            ),
                                          ),
                                          if (user['email']!.isNotEmpty)
                                            Text(
                                              user['email']!,
                                              style: GoogleFonts.poppins(
                                                fontSize: 10.5,
                                                color: const Color(0xff64748B),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: isChecked
                                            ? const Color(0xff2563EB)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: isChecked
                                              ? const Color(0xff2563EB)
                                              : const Color(0xff94A3B8),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: isChecked
                                          ? const Icon(
                                              Icons.check_rounded,
                                              size: 14,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          });
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Bottom Action Bar (ត្រឡប់ & រក្សាទុកការកែប្រែ) ───────────────────────
  Widget _buildBottomStickyBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xffE2E8F0))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Row(
            children: [
              // ត្រឡប់ Button
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Get.back(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(
                      color: Color(0xffCBD5E1),
                      width: 1.2,
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'back'.tr,
                      maxLines: 1,
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xff0F172A),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // រក្សាទុកការកែប្រែ Button
              Expanded(
                child: ElevatedButton(
                  onPressed: isSaving ? null : _updateGroup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff2563EB),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isSaving
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
}
