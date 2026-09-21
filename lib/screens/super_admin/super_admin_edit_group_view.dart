import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get_storage/get_storage.dart';
import 'package:core_portal/core/api/services/auth_service.dart';
import 'package:core_portal/screens/super_admin/super_admin_controller.dart';
import 'package:core_portal/screens/admin/admin_controller.dart';
import 'package:core_portal/widgets/custom_snackbar.dart';
import 'package:core_portal/widgets/app_icon.dart';

class SuperAdminEditGroupView extends StatefulWidget {
  final Map<String, dynamic> group;

  const SuperAdminEditGroupView({super.key, required this.group});

  @override
  State<SuperAdminEditGroupView> createState() =>
      _SuperAdminEditGroupViewState();
}

class _SuperAdminEditGroupViewState extends State<SuperAdminEditGroupView> {
  late dynamic controller;

  late TextEditingController _nameCtrl;
  late TextEditingController _codeCtrl;
  late TextEditingController _descCtrl;
  late String _status;

  // Search queries for sections
  final appSearchQuery = ''.obs;
  final roleSearchQuery = ''.obs;
  final userSearchQuery = ''.obs;

  // Expansion toggles
  bool isAppsExpanded = true;
  bool isRolesExpanded = true;
  bool isUsersExpanded = true;
  bool isUsersDropdownOpen = false;

  // Selected items using RxSet
  final RxSet<String> selectedApps = <String>{}.obs;
  final RxSet<String> selectedRoles = <String>{}.obs;
  final RxSet<String> selectedUsers = <String>{}.obs;

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

  bool isRoleSelected(String roleName, [String? roleCode]) {
    final rNameLow = roleName.trim().toLowerCase();
    final rCodeLow = (roleCode ?? '').trim().toLowerCase();

    return selectedRoles.contains(roleName) ||
        selectedRoles.contains(roleName.toUpperCase()) ||
        selectedRoles.contains(rNameLow) ||
        (roleCode != null &&
            roleCode.isNotEmpty &&
            (selectedRoles.contains(roleCode) ||
                selectedRoles.contains(roleCode.toUpperCase()) ||
                selectedRoles.contains(rCodeLow)));
  }

  void toggleRole(String roleName, [String? roleCode]) {
    if (isRoleSelected(roleName, roleCode)) {
      selectedRoles.remove(roleName);
      selectedRoles.remove(roleName.toUpperCase());
      selectedRoles.remove(roleName.toLowerCase());
      if (roleCode != null && roleCode.isNotEmpty) {
        selectedRoles.remove(roleCode);
        selectedRoles.remove(roleCode.toUpperCase());
        selectedRoles.remove(roleCode.toLowerCase());
      }
    } else {
      selectedRoles.add(roleName);
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

  // Dynamic API data getters
  List<Map<String, String>> get allAppsList {
    final List<Map<String, String>> result = [];
    final apps = controller.appsList;
    if (apps is List) {
      for (final app in apps) {
        final name = (app['titleKh'] ??
                app['titleEn'] ??
                app['name'] ??
                app['appName'] ??
                'App')
            .toString();
        final code =
            (app['code'] ?? app['appCode'] ?? app['id'] ?? 'APP').toString();
        final id = (app['id'] ?? code).toString();
        final icon = (app['icon'] ?? '').toString();
        final iconUrl = (app['iconUrl'] ?? '').toString();
        result.add({
          'id': id,
          'name': name,
          'code': code,
          'icon': icon,
          'iconUrl': iconUrl,
        });
      }
    }
    return result;
  }

  List<Map<String, String>> get allRolesList {
    final List<Map<String, String>> list = [];
    final roles = controller.rolesList;
    if (roles is List) {
      for (final r in roles) {
        final String name =
            (r['name'] ?? r['roleName'] ?? r['title'] ?? '').toString();
        final String code =
            (r['code'] ?? r['roleCode'] ?? name).toString().toUpperCase();
        if (name.isNotEmpty) {
          final existing = list.any((item) => item['name'] == name);
          if (!existing) {
            list.add({'name': name, 'code': code});
          }
        }
      }
    }
    return list;
  }

  List<Map<String, String>> get allUsersList {
    final List<Map<String, String>> list = [];
    final users = controller.usersList;
    if (users is List) {
      for (final u in users) {
        final String username = (u['username'] ?? '').toString().trim();
        final String name = (u['name'] ??
                u['fullName'] ??
                u['nameKh'] ??
                u['displayName'] ??
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
    return list;
  }

  String _getGroupDescriptionKh(Map<String, dynamic> group) {
    final apiDesc = group['description'] ?? group['desc'] ?? group['details'];
    if (apiDesc != null && apiDesc.toString().trim().isNotEmpty) {
      return apiDesc.toString();
    }

    final String name = (group['name'] ?? group['groupName'] ?? '').toString().trim();
    final String code = (group['sublabel'] ?? group['code'] ?? '').toString().trim().toUpperCase();

    const Map<String, String> deptMap = {
      'GDDTM': 'អគ្គនាយកដ្ឋានបច្ចេកវិទ្យាឌីជីថល និងផ្សព្វផ្សាយអប់រំ',
      'GDI': 'អគ្គនាយកដ្ឋានអន្តោប្រវេសន៍',
      'GDP': 'អគ្គនាយកដ្ឋានពន្ធនាគារ',
      'GDHR': 'អគ្គនាយកដ្ឋានធនធានមនុស្ស',
      'GI': 'អគ្គាធិការដ្ឋាន',
      'GIA': 'អគ្គនាយកដ្ឋានសវនកម្មផ្ទៃក្នុង',
      'GID': 'អគ្គនាយកដ្ឋានអត្តសញ្ញាណកម្ម',
      'GLF': 'អគ្គនាយកដ្ឋានភស្តុភារ និងហិរញ្ញវត្ថុ',
      'GNP': 'អគ្គស្នងការដ្ឋាននគរបាលជាតិ',
      'GS': 'អគ្គលេខាធិការដ្ឋាន',
      'LC': 'ក្រុមប្រឹក្សានីតិកម្ម',
      'PAC': 'បណ្ឌិត្យសភានគរបាលកម្ពុជា',
    };

    String prefix = '';
    for (final key in deptMap.keys) {
      if (code.startsWith(key) || name.toUpperCase().startsWith(key)) {
        prefix = key;
        break;
      }
    }

    final String deptNameKh = deptMap[prefix] ?? 'ប្រព័ន្ធគ្រប់គ្រង';
    final bool isAdmin = code.contains('ADMIN') || name.toLowerCase().contains('admin');

    if (isAdmin) {
      return 'ក្រុមអ្នកគ្រប់គ្រងសម្រាប់ $deptNameKh';
    } else {
      return 'ក្រុមអ្នកប្រើប្រាស់សម្រាប់ $deptNameKh';
    }
  }

  @override
  void initState() {
    super.initState();
    if (Get.isRegistered<SuperAdminController>()) {
      controller = Get.find<SuperAdminController>();
    } else if (Get.isRegistered<AdminController>()) {
      controller = Get.find<AdminController>();
    } else {
      controller = Get.put(SuperAdminController());
    }

    final name = (widget.group['name'] ?? 'GDDTM').toString();
    final code =
        (widget.group['sublabel'] ?? widget.group['code'] ?? name).toString();
    _nameCtrl = TextEditingController(text: name);
    _codeCtrl = TextEditingController(text: code);

    final descText = (widget.group['desc'] ??
            widget.group['description'] ??
            _getGroupDescriptionKh(widget.group))
        .toString();
    _descCtrl = TextEditingController(text: descText);
    _status = (widget.group['status'] ?? 'ACTIVE').toString().toUpperCase();

    _loadGroupSelections();

    // Trigger API fetches safely and refresh selections
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        if (controller.appsList.isEmpty) {
          try {
            await controller.fetchDashboardData();
          } catch (_) {}
        }
        if (controller.rolesList.isEmpty) {
          try {
            await controller.fetchRolesData();
          } catch (_) {}
        }
        if (controller.groupList.isEmpty) {
          try {
            await controller.fetchPortalGroupsData();
          } catch (_) {}
        }
        if (mounted) {
          _loadGroupSelections();
          setState(() {});
        }
      }
    });
  }

  void _loadGroupSelections() {
    final String rawName =
        (widget.group['name'] ?? widget.group['groupName'] ?? '').toString().trim();
    final String rawCode = (widget.group['sublabel'] ??
            widget.group['code'] ??
            widget.group['groupCode'] ??
            rawName)
        .toString()
        .trim();
    final String rawId = (widget.group['id'] ?? '').toString().trim();

    final normName = _normalizeString(rawName);
    final normCode = _normalizeString(rawCode);
    final normId = _normalizeString(rawId);

    final Set<String> targetKeys = {
      if (rawName.isNotEmpty) rawName.toLowerCase(),
      if (rawCode.isNotEmpty) rawCode.toLowerCase(),
      if (normName.isNotEmpty) normName,
      if (normCode.isNotEmpty) normCode,
      if (normId.isNotEmpty) normId,
      if (rawCode.isNotEmpty) rawCode.toUpperCase(),
      if (rawName.isNotEmpty) rawName.toUpperCase(),
    };

    // 1. LOAD APPS
    selectedApps.clear();
    final appKeysToCheck = [
      'selectedApps',
      'apps',
      'applications',
      'portalApplications',
      'portalApps'
    ];
    bool appsFoundInGroup = false;
    for (final k in appKeysToCheck) {
      final val = widget.group[k];
      if (val is List && val.isNotEmpty) {
        for (var a in val) {
          if (a is String && a.isNotEmpty) {
            selectedApps.add(a);
            appsFoundInGroup = true;
          } else if (a is Map) {
            final appIdent = (a['id'] ??
                    a['code'] ??
                    a['appCode'] ??
                    a['name'] ??
                    a['titleKh'] ??
                    a['titleEn'] ??
                    '')
                .toString();
            if (appIdent.isNotEmpty) {
              selectedApps.add(appIdent);
              appsFoundInGroup = true;
            }
          }
        }
        if (appsFoundInGroup) break;
      }
    }

    if (!appsFoundInGroup && controller.appsList is List) {
      for (var app in controller.appsList) {
        final rules =
            app['accessRules'] ?? app['access_rules'] ?? app['rules'] ?? [];
        if (rules is List) {
          for (var r in rules) {
            final rVal = (r['ruleValue'] ??
                    r['value'] ??
                    r['target'] ??
                    r['rule_value'] ??
                    '')
                .toString()
                .trim();
            final rValLow = rVal.toLowerCase();
            final rValNorm = _normalizeString(rVal);
            if (rVal.isNotEmpty &&
                (targetKeys.contains(rValLow) ||
                    targetKeys.contains(rValNorm) ||
                    (normCode.isNotEmpty &&
                        (rValNorm == normCode || rValLow.contains(normCode))))) {
              final appId =
                  (app['id'] ?? app['code'] ?? app['titleKh'] ?? app['name'] ?? '')
                      .toString();
              if (appId.isNotEmpty) selectedApps.add(appId);
            }
          }
        }
      }
    }

    // 2. LOAD ROLES
    selectedRoles.clear();
    final roleKeysToCheck = [
      'selectedRoles',
      'roles',
      'portalRoles',
      'groupRoles'
    ];
    bool rolesFoundInGroup = false;
    for (final k in roleKeysToCheck) {
      final val = widget.group[k];
      if (val is List && val.isNotEmpty) {
        for (var r in val) {
          if (r is String && r.isNotEmpty) {
            selectedRoles.add(r);
            rolesFoundInGroup = true;
          } else if (r is Map) {
            final rIdent = (r['name'] ??
                    r['roleName'] ??
                    r['code'] ??
                    r['roleCode'] ??
                    '')
                .toString();
            if (rIdent.isNotEmpty) {
              selectedRoles.add(rIdent);
              rolesFoundInGroup = true;
            }
          }
        }
        if (rolesFoundInGroup) break;
      }
    }

    if (!rolesFoundInGroup && controller.portalGroupRoles is List) {
      for (var gr in controller.portalGroupRoles) {
        final grGroup = (gr['groupCode'] ??
                gr['groupId'] ??
                gr['group_code'] ??
                gr['group_id'] ??
                '')
            .toString()
            .trim();
        final grGroupLow = grGroup.toLowerCase();
        final grGroupNorm = _normalizeString(grGroup);
        if (grGroup.isNotEmpty &&
            (targetKeys.contains(grGroupLow) ||
                targetKeys.contains(grGroupNorm))) {
          final rName = (gr['roleName'] ??
                  gr['role_name'] ??
                  gr['roleCode'] ??
                  gr['role_code'] ??
                  '')
              .toString();
          if (rName.isNotEmpty) selectedRoles.add(rName);
        }
      }
    }

    // 3. LOAD USERS
    selectedUsers.clear();
    final userKeysToCheck = ['selectedUsers', 'users', 'members', 'userList'];
    bool usersFoundInGroup = false;
    for (final k in userKeysToCheck) {
      final val = widget.group[k];
      if (val is List && val.isNotEmpty) {
        for (var u in val) {
          if (u is String && u.isNotEmpty) {
            selectedUsers.add(u);
            usersFoundInGroup = true;
          } else if (u is Map) {
            final uIdent = (u['username'] ??
                    u['name'] ??
                    u['fullName'] ??
                    u['id'] ??
                    '')
                .toString();
            if (uIdent.isNotEmpty) {
              selectedUsers.add(uIdent);
              usersFoundInGroup = true;
            }
          }
        }
        if (usersFoundInGroup) break;
      }
    }

    if (!usersFoundInGroup) {
      final Set<String> assignedIds = {};
      if (controller.userGroupsMap is Map) {
        for (var entry in controller.userGroupsMap.entries) {
          final k = entry.key.toString().trim().toLowerCase();
          final nk = _normalizeString(k);
          if (targetKeys.contains(k) || targetKeys.contains(nk)) {
            assignedIds.addAll(List<String>.from(entry.value));
          }
        }
      }

      if (controller.usersList is List) {
        for (var u in controller.usersList) {
          final uId = (u['id'] ??
                  u['keycloakUserId'] ??
                  u['userId'] ??
                  '')
              .toString()
              .trim();
          final uName = (u['username'] ??
                  u['name'] ??
                  u['fullName'] ??
                  '')
              .toString()
              .trim();
          if (uId.isEmpty && uName.isEmpty) continue;

          bool isMatched = (uId.isNotEmpty && assignedIds.contains(uId)) ||
              (uName.isNotEmpty && assignedIds.contains(uName));

          if (!isMatched) {
            final List? userGroups = u['groups'] ??
                u['userGroups'] ??
                u['portalGroups'] ??
                u['groupCodes'];
            if (userGroups != null) {
              for (var g in userGroups) {
                final gStr = (g is Map
                        ? (g['code'] ?? g['groupCode'] ?? g['name'] ?? '')
                        : g.toString())
                    .trim();
                if (gStr.isNotEmpty) {
                  final gLow = gStr.toLowerCase();
                  final gNorm = _normalizeString(gStr);
                  if (targetKeys.contains(gLow) || targetKeys.contains(gNorm)) {
                    isMatched = true;
                    break;
                  }
                }
              }
            }
          }

          if (!isMatched) {
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
                  final bCode =
                      _normalizeString((emp['bureauCode'] ?? '').toString());
                  final dCode = _normalizeString(
                      (emp['departmentCode'] ?? '').toString());
                  final gCodeEmp = _normalizeString(
                      (emp['generalDepartmentCode'] ?? '').toString());

                  if (isBureauGroup && bCode.isNotEmpty) {
                    if (targetKeys.contains(bCode) ||
                        normCode == bCode ||
                        normName == bCode) {
                      isMatched = true;
                      break;
                    }
                  } else if (isDeptGroup && dCode.isNotEmpty) {
                    if (targetKeys.contains(dCode) ||
                        normCode == dCode ||
                        normName == dCode) {
                      isMatched = true;
                      break;
                    }
                  } else if (isGenDeptGroup && gCodeEmp.isNotEmpty) {
                    if (targetKeys.contains(gCodeEmp) ||
                        normCode == gCodeEmp ||
                        normName == gCodeEmp) {
                      isMatched = true;
                      break;
                    }
                  }
                }
              }
            }
          }

          if (isMatched) {
            final keyToAdd = uName.isNotEmpty ? uName : uId;
            if (keyToAdd.isNotEmpty) selectedUsers.add(keyToAdd);
          }
        }
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _codeCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  bool isSaving = false;

  void _saveGroup() async {
    final newName = _nameCtrl.text.trim();
    if (newName.isEmpty) {
      CustomSnackbar.showError(message: 'សូមបញ្ចូលឈ្មោះក្រុម (អង្គភាព)!');
      return;
    }

    final newCode = _codeCtrl.text.trim();
    final newDesc = _descCtrl.text.trim();

    final String oldCode = (widget.group['sublabel'] ??
            widget.group['code'] ??
            widget.group['name'] ??
            '')
        .toString();
    final String oldName = (widget.group['name'] ?? '').toString();
    final dynamic oldId = widget.group['id'];
    final String targetIdOrCode = (oldId != null && oldId.toString().isNotEmpty
            ? oldId.toString()
            : (oldCode.isNotEmpty ? oldCode : (newCode.isNotEmpty ? newCode : newName)))
        .toString();

    setState(() => isSaving = true);

    final payload = {
      'name': newName,
      'code': newCode.isNotEmpty ? newCode : newName,
      'sublabel': newCode.isNotEmpty ? newCode : newName,
      'description': newDesc,
      'status': _status,
      'applications': selectedApps.toList(),
      'roles': selectedRoles.toList(),
      'users': selectedUsers.toList(),
      'members': selectedUsers.length,
      'membersCount': selectedUsers.length,
    };

    // 1. Send HTTP PUT request to backend API
    try {
      if (controller is SuperAdminController) {
        await (controller as SuperAdminController)
            .updateGroupByCode(targetIdOrCode, payload);
      } else {
        await AuthService().updateAdminGroup(targetIdOrCode, payload);
      }
    } catch (e) {
      debugPrint("PUT updateAdminGroup warning ($e), updating local state...");
    }

    // 2. Update widget.group map
    setState(() {
      widget.group['name'] = newName;
      widget.group['sublabel'] = newCode.isNotEmpty ? newCode : newName;
      widget.group['code'] = newCode.isNotEmpty ? newCode : newName;
      widget.group['desc'] = newDesc;
      widget.group['description'] = newDesc;
      widget.group['status'] = _status;
      widget.group['members'] = selectedUsers.length;
      widget.group['membersCount'] = selectedUsers.length;
      widget.group['usersCount'] = selectedUsers.length;
      widget.group['selectedApps'] = selectedApps.toList();
      widget.group['apps'] = selectedApps.toList();
      widget.group['applications'] = selectedApps.toList();
      widget.group['selectedRoles'] = selectedRoles.toList();
      widget.group['roles'] = selectedRoles.toList();
      widget.group['selectedUsers'] = selectedUsers.toList();
      widget.group['users'] = selectedUsers.toList();
      isSaving = false;
    });

    // 3. Update matching entry in controller.groupList live state
    final idx = controller.groupList.indexWhere((g) =>
        (oldId != null && g['id'] == oldId) ||
        (oldCode.isNotEmpty &&
            (g['code'] == oldCode || g['sublabel'] == oldCode)) ||
        (oldName.isNotEmpty && g['name'] == oldName) ||
        (newCode.isNotEmpty &&
            (g['code'] == newCode || g['sublabel'] == newCode)) ||
        (newName.isNotEmpty && g['name'] == newName));

    if (idx != -1) {
      controller.groupList[idx] = Map<String, dynamic>.from(widget.group);
      controller.groupList.refresh();
    } else {
      controller.groupList.add(Map<String, dynamic>.from(widget.group));
      controller.groupList.refresh();
    }

    // 4. Update userGroupsMap for this group code/name
    final targetGroupKeys = [
      if (newCode.isNotEmpty) newCode,
      if (newName.isNotEmpty) newName,
      if (oldCode.isNotEmpty) oldCode,
      if (oldName.isNotEmpty) oldName,
      if (newCode.isNotEmpty) _normalizeString(newCode),
      if (oldCode.isNotEmpty) _normalizeString(oldCode),
    ];
    for (final gk in targetGroupKeys) {
      controller.userGroupsMap[gk] = selectedUsers.toList();
    }
    controller.userGroupsMap.refresh();

    // 5. Update local cache storage
    try {
      final box = GetStorage();
      box.write('cached_group_list', controller.groupList.toList());
      box.write('cached_user_groups_map', controller.userGroupsMap);
    } catch (_) {}

    if (Get.isRegistered<SuperAdminController>()) {
      Get.find<SuperAdminController>().auditLogs.insert(0, {
        'title': 'កែប្រែអង្គភាព',
        'desc': 'បានកែប្រែព័ត៌មានអង្គភាព: $newName (PUT)',
        'time': 'មុននេះបន្តិច',
        'status': 'success',
      });
    }

    CustomSnackbar.showSuccess(message: 'បានកែប្រែអង្គភាព (PUT) ដោយជោគជ័យ!');
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: _buildHeader(),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: isDesktop
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Column (Unit Info & Overview)
                        SizedBox(
                          width: 330,
                          child: Column(
                            children: [
                              _buildUnitInfoCard(),
                              const SizedBox(height: 16),
                              _buildSummaryCard(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        // Right Column (Configurations)
                        Expanded(
                          child: Column(
                            children: [
                              _buildAppsSection(),
                              const SizedBox(height: 16),
                              _buildRolesSection(),
                              const SizedBox(height: 16),
                              _buildUsersSection(),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Column(
                      children: [
                        _buildUnitInfoCard(),
                        const SizedBox(height: 16),
                        _buildSummaryCard(),
                        const SizedBox(height: 16),
                        _buildAppsSection(),
                        const SizedBox(height: 16),
                        _buildRolesSection(),
                        const SizedBox(height: 16),
                        _buildUsersSection(),
                      ],
                    ),
            ),
          ),
          _buildBottomStickyBar(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xffE2E8F0))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: SafeArea(
        child: Row(
          children: [
            InkWell(
              onTap: () => Get.back(),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xffE2E8F0)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Color(0xff0F172A),
                  size: 18,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'កែប្រែក្រុម (អង្គភាព)',
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff0F172A),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'គ្រប់គ្រងក្រុម និងតួនាទី',
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 12,
                        color: const Color(0xff64748B),
                      ),
                    ),
                    const Text(
                      ' / ',
                      style: TextStyle(color: Color(0xff94A3B8), fontSize: 12),
                    ),
                    Text(
                      _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'GDDTM',
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
          ],
        ),
      ),
    );
  }

  Widget _buildUnitInfoCard() {
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
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xffFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '01',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xffD97706),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'ព័ត៌មានអង្គភាព',
                style: GoogleFonts.kantumruyPro(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'ឈ្មោះក្រុម (អង្គភាព)',
            style: GoogleFonts.kantumruyPro(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xff475569),
            ),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _nameCtrl,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: const Color(0xff0F172A),
            ),
            decoration: InputDecoration(
              hintText: 'បញ្ចូលឈ្មោះក្រុម...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xffE2E8F0)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'កូដក្រុម (អត្តសញ្ញាណ)',
                style: GoogleFonts.kantumruyPro(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xff475569),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xffF1F5F9),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xffE2E8F0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.lock_outline_rounded,
                      size: 11,
                      color: Color(0xff64748B),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      'មិនអាចកែប្រែបាន',
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xff64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _codeCtrl,
            readOnly: true,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xff64748B),
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xffF8FAFC),
              hintText: 'កូដក្រុម...',
              suffixIcon: const Icon(
                Icons.lock_rounded,
                size: 16,
                color: Color(0xff94A3B8),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xffE2E8F0)),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: Color(0xffE2E8F0)),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'កូដសម្គាល់ក្រុមមិនអាចកែប្រែបានទេ ដើម្បីរក្សាស្ថិរភាពប្រព័ន្ធ Keycloak',
            style: GoogleFonts.kantumruyPro(
              fontSize: 11,
              color: const Color(0xff94A3B8),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'ការពិពណ៌នា',
            style: GoogleFonts.kantumruyPro(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xff475569),
            ),
          ),
          const SizedBox(height: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextField(
                controller: _descCtrl,
                maxLines: 3,
                maxLength: 255,
                onChanged: (_) => setState(() {}),
                style: GoogleFonts.kantumruyPro(
                  fontSize: 12,
                  color: const Color(0xff334155),
                ),
                decoration: InputDecoration(
                  hintText: 'បញ្ចូលការពិពណ៌នាបន្ថែម...',
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xffE2E8F0)),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(
                    Icons.edit_note_rounded,
                    size: 14,
                    color: Color(0xff94A3B8),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${_descCtrl.text.length} / 255',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: const Color(0xff94A3B8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'ស្ថានភាព',
            style: GoogleFonts.kantumruyPro(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: const Color(0xff475569),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _status = 'ACTIVE'),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _status == 'ACTIVE'
                          ? const Color(0xffECFDF5)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _status == 'ACTIVE'
                            ? const Color(0xffA7F3D0)
                            : const Color(0xffE2E8F0),
                        width: _status == 'ACTIVE' ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _status == 'ACTIVE'
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_off_rounded,
                          size: 14,
                          color: _status == 'ACTIVE'
                              ? const Color(0xff047857)
                              : const Color(0xff94A3B8),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '• ដំណើរការ',
                          style: GoogleFonts.kantumruyPro(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _status == 'ACTIVE'
                                ? const Color(0xff047857)
                                : const Color(0xff64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _status = 'INACTIVE'),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: _status == 'INACTIVE'
                          ? const Color(0xffFEE2E2)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _status == 'INACTIVE'
                            ? const Color(0xffFECACA)
                            : const Color(0xffE2E8F0),
                        width: _status == 'INACTIVE' ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _status == 'INACTIVE'
                              ? Icons.cancel_rounded
                              : Icons.radio_button_off_rounded,
                          size: 14,
                          color: _status == 'INACTIVE'
                              ? const Color(0xffB91C1C)
                              : const Color(0xff94A3B8),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'ផ្អាក',
                          style: GoogleFonts.kantumruyPro(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _status == 'INACTIVE'
                                ? const Color(0xffB91C1C)
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

  Widget _buildSummaryCard() {
    return Obx(
      () => Container(
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
              'សរុបរួម',
              style: GoogleFonts.kantumruyPro(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: const Color(0xff0F172A),
              ),
            ),
            const SizedBox(height: 16),
            _buildSummaryItem(
              icon: Icons.apps_rounded,
              iconBg: const Color(0xffFEF3C7),
              iconColor: const Color(0xffD97706),
              title: 'កម្មវិធីដែលអាចប្រើ',
              countText: '${selectedApps.length} បានជ្រើសរើស',
            ),
            const SizedBox(height: 12),
            _buildSummaryItem(
              icon: Icons.shield_outlined,
              iconBg: const Color(0xffF3E8FF),
              iconColor: const Color(0xff9333EA),
              title: 'តួនាទីដែលបានកំណត់',
              countText: '${selectedRoles.length} បានជ្រើសរើស',
            ),
            const SizedBox(height: 12),
            _buildSummaryItem(
              icon: Icons.person_outline_rounded,
              iconBg: const Color(0xffDBEAFE),
              iconColor: const Color(0xff2563EB),
              title: 'អ្នកប្រើប្រាស់ក្នុងក្រុម',
              countText: '${selectedUsers.length} បានជ្រើសរើស',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String countText,
  }) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: iconBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.kantumruyPro(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xff0F172A),
              ),
            ),
            Text(
              countText,
              style: GoogleFonts.kantumruyPro(
                fontSize: 11,
                color: const Color(0xff64748B),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAppsSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: Column(
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xffFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '02',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
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
                              'កម្មវិធីដែលអាចប្រើ',
                              style: GoogleFonts.kantumruyPro(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xff0F172A),
                              ),
                            ),
                            Text(
                              'ជ្រើសរើសកម្មវិធីដែលសមាជិកក្រុមនេះអាចចូលប្រើបាន',
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
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xffE2E8F0)),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar with toggle button
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (val) => appSearchQuery.value = val,
                        decoration: InputDecoration(
                          hintText: 'ស្វែងរកកម្មវិធី...',
                          hintStyle: GoogleFonts.kantumruyPro(
                            fontSize: 12,
                            color: const Color(0xff94A3B8),
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 18,
                            color: Color(0xff64748B),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xffE2E8F0)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () => setState(() => isAppsExpanded = !isAppsExpanded),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xffF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xffE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isAppsExpanded
                                  ? Icons.close_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 14,
                              color: const Color(0xff64748B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isAppsExpanded ? 'បិទបញ្ជី' : 'បើកបញ្ជី',
                              style: GoogleFonts.kantumruyPro(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xff64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                if (isAppsExpanded) ...[
                  const SizedBox(height: 16),

                  // Results count tag
                  Obx(() {
                    final query = appSearchQuery.value.toLowerCase().trim();
                    final filtered = allAppsList.where((app) {
                      return app['name']!.toLowerCase().contains(query) ||
                          app['code']!.toLowerCase().contains(query) ||
                          app['id']!.toLowerCase().contains(query);
                    }).toList();

                    return Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xffF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${filtered.length} លទ្ធផល',
                            style: GoogleFonts.kantumruyPro(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xff475569),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),

                  const SizedBox(height: 12),

                  // Grid of Apps
                  Obx(() {
                    final query = appSearchQuery.value.toLowerCase().trim();
                    final filtered = allAppsList.where((app) {
                      return app['name']!.toLowerCase().contains(query) ||
                          app['code']!.toLowerCase().contains(query) ||
                          app['id']!.toLowerCase().contains(query);
                    }).toList();

                    if (filtered.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            'រកមិនឃើញកម្មវិធី',
                            style: GoogleFonts.kantumruyPro(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      );
                    }

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount = 3;
                        if (constraints.maxWidth < 600) {
                          crossAxisCount = 1;
                        } else if (constraints.maxWidth < 900) {
                          crossAxisCount = 2;
                        }

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            mainAxisExtent: 64,
                          ),
                          itemBuilder: (context, index) {
                            final app = filtered[index];
                            return Obx(() {
                              final isChecked = isAppSelected(app);

                              return InkWell(
                                onTap: () => toggleApp(app),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isChecked
                                        ? const Color(0xffFFFBEB)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isChecked
                                          ? const Color(0xffD97706)
                                          : const Color(0xffE2E8F0),
                                      width: isChecked ? 1.5 : 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(6),
                                        child: AppIconWidget(
                                          iconUrl: app['iconUrl'] ?? '',
                                          localAsset: app['icon'] ?? '',
                                          size: 28,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              app['name'] ?? '',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.kantumruyPro(
                                                fontSize: 12,
                                                fontWeight: isChecked
                                                    ? FontWeight.bold
                                                    : FontWeight.w600,
                                                color: const Color(0xff0F172A),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              app['code'] ?? '',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.poppins(
                                                fontSize: 10,
                                                color: isChecked
                                                    ? const Color(0xffD97706)
                                                    : const Color(0xff64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            });
                          },
                        );
                      },
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRolesSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: Column(
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xffFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '03',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
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
                              'តួនាទីដែលបានកំណត់',
                              style: GoogleFonts.kantumruyPro(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xff0F172A),
                              ),
                            ),
                            Text(
                              'ជ្រើសរើសតួនាទីដែលសមស្របសម្រាប់ក្រុមនេះ',
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
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xffE2E8F0)),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar with toggle button
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        onChanged: (val) => roleSearchQuery.value = val,
                        decoration: InputDecoration(
                          hintText: 'ស្វែងរកតួនាទី...',
                          hintStyle: GoogleFonts.kantumruyPro(
                            fontSize: 12,
                            color: const Color(0xff94A3B8),
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 18,
                            color: Color(0xff64748B),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xffE2E8F0)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () => setState(() => isRolesExpanded = !isRolesExpanded),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xffF8FAFC),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xffE2E8F0)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isRolesExpanded
                                  ? Icons.close_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 14,
                              color: const Color(0xff64748B),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isRolesExpanded ? 'បិទបញ្ជី' : 'បើកបញ្ជី',
                              style: GoogleFonts.kantumruyPro(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xff64748B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                if (isRolesExpanded) ...[
                  const SizedBox(height: 16),

                  // Results count tag
                  Obx(() {
                    final query = roleSearchQuery.value.toLowerCase().trim();
                    final filtered = allRolesList.where((role) {
                      return role['name']!.toLowerCase().contains(query) ||
                          role['code']!.toLowerCase().contains(query);
                    }).toList();

                    return Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xffF1F5F9),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${filtered.length} លទ្ធផល',
                            style: GoogleFonts.kantumruyPro(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xff475569),
                            ),
                          ),
                        ),
                      ],
                    );
                  }),

                  const SizedBox(height: 12),

                  // Grid of Roles
                  Obx(() {
                    final query = roleSearchQuery.value.toLowerCase().trim();
                    final filtered = allRolesList.where((role) {
                      return role['name']!.toLowerCase().contains(query) ||
                          role['code']!.toLowerCase().contains(query);
                    }).toList();

                    if (filtered.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            'រកមិនឃើញតួនាទី',
                            style: GoogleFonts.kantumruyPro(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      );
                    }

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        int crossAxisCount = 3;
                        if (constraints.maxWidth < 600) {
                          crossAxisCount = 1;
                        } else if (constraints.maxWidth < 900) {
                          crossAxisCount = 2;
                        }

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            mainAxisExtent: 64,
                          ),
                          itemBuilder: (context, index) {
                            final role = filtered[index];
                            final roleName = role['name'] ?? '';
                            final roleCode = role['code'] ?? '';

                            return Obx(() {
                              final isChecked = isRoleSelected(roleName, roleCode);

                              return InkWell(
                                onTap: () => toggleRole(roleName, roleCode),
                                borderRadius: BorderRadius.circular(10),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isChecked
                                        ? const Color(0xffFFFBEB)
                                        : Colors.white,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isChecked
                                          ? const Color(0xffD97706)
                                          : const Color(0xffE2E8F0),
                                      width: isChecked ? 1.5 : 1.0,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: const Color(0xffF3E8FF),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Icon(
                                          Icons.shield_outlined,
                                          size: 16,
                                          color: Color(0xff9333EA),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              roleName,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: isChecked
                                                    ? FontWeight.bold
                                                    : FontWeight.w600,
                                                color: const Color(0xff0F172A),
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              roleCode,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: GoogleFonts.poppins(
                                                fontSize: 10,
                                                color: isChecked
                                                    ? const Color(0xffD97706)
                                                    : const Color(0xff64748B),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            });
                          },
                        );
                      },
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsersSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xffFEF3C7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '04',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
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
                              'អ្នកប្រើប្រាស់ក្នុងក្រុម',
                              style: GoogleFonts.kantumruyPro(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xff0F172A),
                              ),
                            ),
                            Text(
                              'ជ្រើសរើសអ្នកប្រើប្រាស់ដែលត្រូវបញ្ចូលក្នុងក្រុមនេះ',
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
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Color(0xffE2E8F0)),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selected User Yellow Chips
                Obx(() {
                  if (selectedUsers.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        'មិនទាន់មានអ្នកប្រើប្រាស់ត្រូវបានជ្រើសរើសនៅឡើយទេ',
                        style: GoogleFonts.kantumruyPro(
                          fontSize: 12,
                          color: const Color(0xff94A3B8),
                        ),
                      ),
                    );
                  }

                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: selectedUsers.map((username) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xffFFFBEB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xffFDE68A)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.person_outline_rounded,
                              size: 14,
                              color: Color(0xffD97706),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              username,
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xff92400E),
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: () => selectedUsers.remove(username),
                              child: const Icon(
                                Icons.close_rounded,
                                size: 14,
                                color: Color(0xffD97706),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                }),

                const SizedBox(height: 16),

                // Search Bar with "មើលទាំងអស់" toggle button
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
                        decoration: InputDecoration(
                          hintText: 'ស្វែងរកអ្នកប្រើប្រាស់...',
                          hintStyle: GoogleFonts.kantumruyPro(
                            fontSize: 12,
                            color: const Color(0xff94A3B8),
                          ),
                          prefixIcon: const Icon(
                            Icons.search_rounded,
                            size: 18,
                            color: Color(0xff64748B),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: Color(0xffE2E8F0)),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    InkWell(
                      onTap: () =>
                          setState(() => isUsersDropdownOpen = !isUsersDropdownOpen),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xffEFF6FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xffBFDBFE)),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isUsersDropdownOpen
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 16,
                              color: const Color(0xff2563EB),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isUsersDropdownOpen ? 'បិទបញ្ជី' : 'មើលទាំងអស់',
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
                  ],
                ),

                // Expandable User Checkbox List
                if (isUsersDropdownOpen) ...[
                  const SizedBox(height: 12),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 280),
                    decoration: BoxDecoration(
                      color: const Color(0xffF8FAFC),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xffE2E8F0)),
                    ),
                    child: Obx(() {
                      final query = userSearchQuery.value.toLowerCase().trim();
                      final filtered = allUsersList.where((u) {
                        return u['username']!.toLowerCase().contains(query) ||
                            u['name']!.toLowerCase().contains(query) ||
                            u['display']!.toLowerCase().contains(query) ||
                            u['email']!.toLowerCase().contains(query);
                      }).toList();

                      if (filtered.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'រកមិនឃើញអ្នកប្រើប្រាស់',
                              style: GoogleFonts.kantumruyPro(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.all(8),
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 4),
                        itemBuilder: (context, index) {
                          final user = filtered[index];
                          final username = user['username'] ?? '';
                          final id = user['id'] ?? '';
                          final name = user['name'] ?? '';
                          final display = user['display'] ?? username;
                          final email = user['email'] ?? '';

                          return Obx(() {
                            final isChecked = isUserSelected(username, id, name);

                            return InkWell(
                              onTap: () => toggleUser(username, id, name),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isChecked
                                      ? const Color(0xffFFFBEB)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isChecked
                                        ? const Color(0xffD97706)
                                        : const Color(0xffE2E8F0),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: isChecked
                                            ? const Color(0xffD97706)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: isChecked
                                              ? const Color(0xffD97706)
                                              : const Color(0xffCBD5E1),
                                        ),
                                      ),
                                      child: isChecked
                                          ? const Icon(
                                              Icons.check_rounded,
                                              size: 12,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 10),
                                    const Icon(
                                      Icons.person_outline_rounded,
                                      size: 16,
                                      color: Color(0xff64748B),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            display,
                                            style: GoogleFonts.poppins(
                                              fontSize: 12,
                                              fontWeight: isChecked
                                                  ? FontWeight.bold
                                                  : FontWeight.w500,
                                              color: const Color(0xff0F172A),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (email.isNotEmpty)
                                      Text(
                                        email,
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          color: const Color(0xff94A3B8),
                                        ),
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
          ),
        ],
      ),
    );
  }

  Widget _buildBottomStickyBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xffE2E8F0))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            OutlinedButton(
              onPressed: () => Get.back(),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                side: const BorderSide(color: Color(0xffE2E8F0)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'បោះបង់',
                style: GoogleFonts.kantumruyPro(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff64748B),
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: isSaving ? null : _saveGroup,
              icon: isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
              label: Text(
                isSaving ? 'កំពុងរក្សាទុក...' : 'រក្សាទុកការផ្លាស់ប្តូរ',
                style: GoogleFonts.kantumruyPro(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffF59E0B),
                disabledBackgroundColor: const Color(0xffF59E0B).withOpacity(0.6),
                minimumSize: const Size(0, 44),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
