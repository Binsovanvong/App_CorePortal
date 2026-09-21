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

class AdminCreateGroupView extends StatefulWidget {
  final Map<String, dynamic>? initialUser;
  final String? initialName;

  const AdminCreateGroupView({
    super.key,
    this.initialUser,
    this.initialName,
  });

  @override
  State<AdminCreateGroupView> createState() => _AdminCreateGroupViewState();
}

class _AdminCreateGroupViewState extends State<AdminCreateGroupView> {
  late AdminController controller;

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();
  String _status = 'ACTIVE';

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

  String _resolveLocalAsset(String rawIcon) {
    final icon = rawIcon.trim();
    if (icon.isEmpty) return 'assets/img/about-moi-logo.png';

    final cleanLower = icon.toLowerCase();
    if (cleanLower.startsWith('assets/') ||
        cleanLower.startsWith('asset/') ||
        cleanLower.startsWith('/assets/') ||
        cleanLower.startsWith('/asset/')) {
      return icon.startsWith('/') ? icon.substring(1) : icon;
    }

    return 'assets/img/about-moi-logo.png';
  }

  Map<String, String>? _parseAppItem(dynamic item) {
    if (item is! Map) return null;

    final String name = (item['titleKh'] ??
            item['nameKh'] ??
            item['title_kh'] ??
            item['name_kh'] ??
            item['name'] ??
            item['appName'] ??
            item['titleEn'] ??
            item['nameEn'] ??
            'App')
        .toString()
        .trim();

    final String code = (item['code'] ??
            item['appCode'] ??
            item['app_code'] ??
            item['id'] ??
            item['_id'] ??
            'APP')
        .toString()
        .trim();

    final String id = (item['id'] ?? item['_id'] ?? code).toString().trim();

    final String rawIcon = (item['iconUrl'] ??
            item['icon_url'] ??
            item['icon'] ??
            item['logo'] ??
            '')
        .toString()
        .trim();

    final String iconUrl = _resolveIconUrl(rawIcon);
    final String localAsset = _resolveLocalAsset(rawIcon);

    return {
      'id': id.isNotEmpty ? id : code,
      'name': name.isNotEmpty ? name : code,
      'code': code.toUpperCase(),
      'icon': localAsset,
      'iconUrl': iconUrl,
    };
  }

  // ─── 1. Load Apps using GET /admin/portal-apps (Matching Trace) ───────────
  Future<void> _loadApps() async {
    final List<Map<String, String>> initialList = [];

    // Check controller.appsList
    for (final a in controller.appsList) {
      final parsed = _parseAppItem(a);
      if (parsed != null && !initialList.any((x) => x['code'] == parsed['code'])) {
        initialList.add(parsed);
      }
    }

    // Check cached storage
    final cached = GetStorage().read('cached_admin_apps_list') ??
        GetStorage().read('cached_portal_services');
    if (cached is List) {
      for (final a in cached) {
        final parsed = _parseAppItem(a);
        if (parsed != null && !initialList.any((x) => x['code'] == parsed['code'])) {
          initialList.add(parsed);
        }
      }
    }

    if (initialList.isNotEmpty) {
      apiAppsList.assignAll(initialList);
    }

    try {
      isLoadingApps.value = apiAppsList.isEmpty;

      // Direct call to /admin/portal-apps (Primary Endpoint in Trace)
      dynamic response;
      try {
        final r = await ApiClient.dio.get('/admin/portal-apps');
        response = r.data;
      } catch (e) {
        debugPrint("GET /admin/portal-apps warning ($e), trying AuthService...");
        try {
          response = await AuthService().fetchAdminApps();
        } catch (_) {}
      }

      if (response == null) {
        try {
          response = await AuthService().fetchPortalApps();
        } catch (_) {}
      }

      List rawList = [];
      if (response != null) {
        if (response is List) {
          rawList = response;
        } else if (response is Map) {
          final data = response['data'] ??
              response['value'] ??
              response['items'] ??
              response['content'] ??
              response['apps'] ??
              [];
          if (data is List) rawList = data;
        }
      }

      if (rawList.isNotEmpty) {
        final List<Map<String, String>> fetched = [];
        for (final item in rawList) {
          final parsed = _parseAppItem(item);
          if (parsed != null && !fetched.any((x) => x['code'] == parsed['code'])) {
            fetched.add(parsed);
          }
        }
        if (fetched.isNotEmpty) {
          apiAppsList.assignAll(fetched);
          controller.appsList.assignAll(
            rawList.map((e) => Map<String, dynamic>.from(e is Map ? e : {})).toList(),
          );
          GetStorage().write('cached_admin_apps_list', rawList);
        }
      }
    } catch (e) {
      debugPrint("Error loading portal-apps: $e");
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

    // Direct call to /admin/user-profiles?page=0&size=100 (Endpoint in Trace)
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
              res['data'] ??
              res['items'] ??
              res['results'] ??
              [];
          if (data is List) rawUsers = data;
        }
      }

      if (rawUsers.isNotEmpty) {
        addUsersFrom(rawUsers);
        if (list.isNotEmpty) {
          apiUsersList.assignAll(list);
          controller.usersList.assignAll(
            rawUsers.map((e) => Map<String, dynamic>.from(e is Map ? e : {})).toList(),
          );
          GetStorage().write('cached_admin_users_list', rawUsers);
        }
      }
    } catch (e) {
      debugPrint("Error loading user-profiles: $e");
    }
  }

  // ─── 3. Load Groups using GET /admin/portal-groups/created-by-me ──────────
  Future<void> _loadGroups() async {
    try {
      final r = await ApiClient.dio.get('/admin/portal-groups/created-by-me');
      if (r.data != null) {
        List items = [];
        if (r.data is List) {
          items = r.data;
        } else if (r.data is Map) {
          final d = r.data['data'] ?? r.data['value'] ?? r.data['items'] ?? [];
          if (d is List) items = d;
        }
        if (items.isNotEmpty) {
          final parsed = items.map<Map<String, dynamic>>((g) {
            if (g is Map) return Map<String, dynamic>.from(g);
            return {'name': g.toString()};
          }).toList();
          controller.groupList.assignAll(parsed);
          GetStorage().write('cached_admin_group_list', parsed);
        }
      }
    } catch (e) {
      debugPrint("GET /admin/portal-groups/created-by-me warning: $e");
      try {
        await controller.fetchPortalGroupsCreatedByMe();
      } catch (_) {}
    }
  }

  // ─── 4. Load Roles & Group Roles (portal-roles & portal-group-roles) ───────
  Future<void> _loadRolesAndGroupRoles() async {
    try {
      // Endpoint 4: /admin/portal-roles
      try {
        final rolesRes = await ApiClient.dio.get('/admin/portal-roles');
        if (rolesRes.data != null) {
          debugPrint("LOADED /admin/portal-roles: ${rolesRes.data != null}");
        }
      } catch (_) {
        try {
          await AuthService().fetchPortalRoles();
        } catch (_) {}
      }

      // Endpoint 5: /admin/portal-group-roles
      try {
        final groupRolesRes = await ApiClient.dio.get('/admin/portal-group-roles');
        if (groupRolesRes.data != null) {
          debugPrint("LOADED /admin/portal-group-roles: ${groupRolesRes.data != null}");
        }
      } catch (_) {
        try {
          await AuthService().fetchPortalGroupRoles();
        } catch (_) {}
      }
    } catch (e) {
      debugPrint("Error loading roles/group-roles: $e");
    }
  }

  // Fallback Apps getter
  List<Map<String, String>> get allAppsList {
    if (apiAppsList.isNotEmpty) {
      return apiAppsList;
    }

    // If cache/API hasn't responded yet, pull from controller
    final List<Map<String, String>> result = [];
    for (final app in controller.appsList) {
      final parsed = _parseAppItem(app);
      if (parsed != null) result.add(parsed);
    }

    return result;
  }

  List<Map<String, String>> get allUsersList {
    if (apiUsersList.isNotEmpty) {
      return apiUsersList;
    }

    final List<Map<String, String>> list = [];
    final users = controller.usersList;
    for (final u in users) {
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

    return list;
  }

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<AdminController>()) {
      controller = Get.find<AdminController>();
    } else {
      controller = Get.put(AdminController());
    }

    if (widget.initialName != null && widget.initialName!.isNotEmpty) {
      _nameCtrl.text = widget.initialName!;
    }

    if (widget.initialUser != null) {
      final uName = (widget.initialUser!['username'] ??
              widget.initialUser!['id'] ??
              '')
          .toString()
          .trim();
      if (uName.isNotEmpty) {
        selectedUsers.add(uName);
      }
    }

    // Immediately trigger all 5 endpoint loads matching trace:
    // 1. portal-apps
    _loadApps();
    // 2. user-profiles?page=0&size=100
    _loadUsers();
    // 3. created-by-me
    _loadGroups();
    // 4 & 5. portal-roles and portal-group-roles
    _loadRolesAndGroupRoles();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _createGroup() async {
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

    setState(() => isSaving = true);

    final generatedId = DateTime.now().millisecondsSinceEpoch.toString();
    final payload = {
      'id': generatedId,
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

    // 1. Send HTTP POST request to backend API (/admin/portal-groups)
    try {
      await AuthService().createAdminGroup(payload);
    } catch (e) {
      debugPrint("POST createAdminGroup warning ($e), updating local state...");
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

    // 3. Add to controller.groupList live state
    final newGroupMap = {
      'id': generatedId,
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

    controller.groupList.insert(0, newGroupMap);
    controller.groupList.refresh();

    // 4. Update userGroupsMap for this new group
    final targetGroupKeys = [
      newCode.toUpperCase(),
      newName,
      _normalizeString(newCode),
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

    // Clear form inputs and reset create_screen
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
                    'create_success'.tr,
                    style: GoogleFonts.kantumruyPro(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Subtitle description
                  Text(
                    'unit_created_success_desc'.tr,
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

    // Clear create_screen and navigate back to edit group view
    if (mounted) {
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop(newGroupMap);
      } else {
        Get.off(() => AdminEditUserGroupsView(user: widget.initialUser ?? {}));
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
                      'create_group_unit_title'.tr,
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
                          'create_new'.tr,
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

  // ─── 01. ព័ត៌មានអង្គភាព (Card 01 matching concept) ─────────────────────────
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

          // ស្ថានភាព (Status Selection with Blue Active style)
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


    // Special brand styling for Google Map
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

    // Special brand styling for Google Calendar
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

    // Real Application Logo with Squircle Background like application_view.dart
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

  // ─── 02. ក្រុមដែលអាចប្រើ (Card 02 matching concept) ──────────────────────────
  Widget _buildAppsSection() {
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
          // Header: 02 ក្រុមដែលអាចប្រើ
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Color(0xffFEF3C7),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '02',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xffD97706),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'usable_groups'.tr,
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xff0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'select_apps_for_unit_desc'.tr,
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 12,
                        color: const Color(0xff64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search Field: ស្វែងរកក្រុម...
          TextField(
            onChanged: (val) => appSearchQuery.value = val,
            style: GoogleFonts.kantumruyPro(
              fontSize: 13,
              color: const Color(0xff0F172A),
            ),
            decoration: InputDecoration(
              hintText: 'search_group_hint'.tr,
              hintStyle: GoogleFonts.kantumruyPro(
                fontSize: 13,
                color: const Color(0xff94A3B8),
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                size: 20,
                color: Color(0xff94A3B8),
              ),
              filled: true,
              fillColor: Colors.white,
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
                borderSide:
                    const BorderSide(color: Color(0xff2563EB), width: 1.4),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),

          // App List Container matching concept
          Obx(() {
            if (isLoadingApps.value && apiAppsList.isEmpty) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 30),
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                ),
              );
            }

            final query = appSearchQuery.value.toLowerCase().trim();
            final apps = allAppsList;
            final filtered = apps.where((app) {
              return app['name']!.toLowerCase().contains(query) ||
                  app['code']!.toLowerCase().contains(query) ||
                  app['id']!.toLowerCase().contains(query);
            }).toList();

            if (filtered.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'no_apps_found'.tr,
                    style: GoogleFonts.kantumruyPro(
                      fontSize: 13,
                      color: const Color(0xff94A3B8),
                    ),
                  ),
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xffE2E8F0)),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filtered.length,
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xffF1F5F9),
                ),
                itemBuilder: (context, index) {
                  final app = filtered[index];
                  return Obx(() {
                    final isChecked = isAppSelected(app);
                    return InkWell(
                      onTap: () => toggleApp(app),
                      borderRadius: index == 0
                          ? const BorderRadius.vertical(top: Radius.circular(12))
                          : (index == filtered.length - 1
                              ? const BorderRadius.vertical(
                                  bottom: Radius.circular(12))
                              : BorderRadius.zero),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Row(
                          children: [
                            _buildAppIconWidget(app, index),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    app['name']!,
                                    style: GoogleFonts.kantumruyPro(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xff0F172A),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    app['code']!,
                                    style: GoogleFonts.poppins(
                                      fontSize: 10.5,
                                      color: const Color(0xff64748B),
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Square Checkbox matching concept
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
                                      Icons.check,
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
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── 03. អ្នកប្រើប្រាស់ក្នុងក្រុម (Card 03 matching concept) ────────────────
  Widget _buildUsersSection() {
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
          // Header: 03 អ្នកប្រើប្រាស់ក្នុងក្រុម
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'group_users'.tr,
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xff0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'select_users_for_group_desc'.tr,
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 12,
                        color: const Color(0xff64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Search Field + "មើលទាំងអស់" Button Row matching concept
          Row(
            children: [
              Expanded(
                child: TextField(
                  onChanged: (val) {
                    userSearchQuery.value = val;
                    if (val.isNotEmpty && !isUsersDropdownOpen) {
                      setState(() => isUsersDropdownOpen = true);
                    }
                  },
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 13,
                    color: const Color(0xff0F172A),
                  ),
                  decoration: InputDecoration(
                    hintText: 'search_users_hint'.tr,
                    hintStyle: GoogleFonts.kantumruyPro(
                      fontSize: 13,
                      color: const Color(0xff94A3B8),
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      size: 20,
                      color: Color(0xff94A3B8),
                    ),
                    filled: true,
                    fillColor: Colors.white,
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
                      borderSide:
                          const BorderSide(color: Color(0xff2563EB), width: 1.4),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // "∨ មើលទាំងអស់" Button matching concept
              InkWell(
                onTap: () =>
                    setState(() => isUsersDropdownOpen = !isUsersDropdownOpen),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xffEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xffBFDBFE)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isUsersDropdownOpen
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: const Color(0xff2563EB),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isUsersDropdownOpen ? 'close_list'.tr : 'view_all'.tr,
                        style: GoogleFonts.kantumruyPro(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xff2563EB),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Selected users chips preview
          Obx(() {
            if (selectedUsers.isEmpty) {
              return const SizedBox.shrink();
            }

            return Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: selectedUsers.map((username) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xffEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xffBFDBFE)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.person_outline_rounded,
                          size: 14,
                          color: Color(0xff2563EB),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          username,
                          style: GoogleFonts.poppins(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xff1E40AF),
                          ),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () => selectedUsers.remove(username),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: Color(0xff2563EB),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            );
          }),

          // Expandable User Checklist
          if (isUsersDropdownOpen) ...[
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 280),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xffE2E8F0)),
              ),
              child: Obx(() {
                final query = userSearchQuery.value.toLowerCase().trim();
                final users = allUsersList;
                final filtered = users.where((u) {
                  return u['username']!.toLowerCase().contains(query) ||
                      u['name']!.toLowerCase().contains(query) ||
                      u['display']!.toLowerCase().contains(query) ||
                      u['email']!.toLowerCase().contains(query);
                }).toList();

                if (filtered.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'no_users_found'.tr,
                        style: GoogleFonts.kantumruyPro(
                          fontSize: 13,
                          color: const Color(0xff94A3B8),
                        ),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) => const Divider(
                    height: 1,
                    thickness: 1,
                    color: Color(0xffF1F5F9),
                  ),
                  itemBuilder: (context, index) {
                    final user = filtered[index];
                    final uName = user['username']!;
                    final id = user['id'];
                    final name = user['name'];

                    return Obx(() {
                      final isChecked = isUserSelected(uName, id, name);
                      return InkWell(
                        onTap: () => toggleUser(uName, id, name),
                        borderRadius: index == 0
                            ? const BorderRadius.vertical(
                                top: Radius.circular(12))
                            : (index == filtered.length - 1
                                ? const BorderRadius.vertical(
                                    bottom: Radius.circular(12))
                                : BorderRadius.zero),
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                        Icons.check,
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
        ],
      ),
    );
  }

  // ─── Bottom Action Bar (ត្រឡប់ & បង្កើតក្រុម matching concept) ───────────────
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
              // ត្រឡប់ Button matching concept
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

              // បង្កើតក្រុម Button matching concept
              Expanded(
                child: ElevatedButton(
                  onPressed: isSaving ? null : _createGroup,
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
                            'create_group'.tr,
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
