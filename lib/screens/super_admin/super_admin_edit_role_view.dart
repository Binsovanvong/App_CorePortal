import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:core_portal/screens/super_admin/super_admin_controller.dart';
import 'package:core_portal/widgets/custom_snackbar.dart';

class SuperAdminEditRoleView extends StatefulWidget {
  final Map<String, dynamic> role;

  const SuperAdminEditRoleView({super.key, required this.role});

  @override
  State<SuperAdminEditRoleView> createState() => _SuperAdminEditRoleViewState();
}

class _SuperAdminEditRoleViewState extends State<SuperAdminEditRoleView> {
  final SuperAdminController controller = Get.find<SuperAdminController>();

  late TextEditingController _nameCtrl;
  late String _code;
  late String _status;

  // Section 02: Selected Groups (អង្គភាព)
  List<String> _selectedGroups = [];
  final TextEditingController _groupSearchCtrl = TextEditingController();
  bool _isGroupPickerOpen = false;

  // Section 03: Selected Applications (កម្មវិធី)
  List<String> _selectedApps = [];
  final TextEditingController _appSearchCtrl = TextEditingController();
  bool _isAppPickerOpen = false;

  // Section 04: Permission Levels (0 = គ្មានសិទ្ធិ, 1 = មើល, 2 = កែប្រែ, 3 = គ្រប់គ្រង)
  int appLevel = 3;
  int auditLevel = 3;
  int accessRuleLevel = 1;
  int permissionLevel = 2;
  int roleLevel = 2;
  int userLevel = 3;

  // Section 05: Selected Users (អ្នកប្រើប្រាស់)
  List<String> _selectedUsers = [];
  final TextEditingController _userSearchCtrl = TextEditingController();
  bool _isUserPickerOpen = false;

  List<String> get _availableGroups {
    if (controller.groupList.isNotEmpty) {
      final list = controller.groupList
          .map((g) => (g['sublabel'] ?? g['code'] ?? g['name'] ?? '').toString())
          .where((s) => s.isNotEmpty && s != '—')
          .toSet()
          .toList();
      if (list.isNotEmpty) return list;
    }
    return const [
      'GDDTM_ADMINS',
      'GDI_ADMINS',
      'GDP_GROUP',
      'GI_ADMINS',
      'GLF_USERS',
      'GNP_ADMINS',
      'GS_ADMINS',
      'LC_ADMINS',
      'PAC_ADMINS',
    ];
  }

  List<String> get _availableApps {
    if (controller.appsList.isNotEmpty) {
      final list = controller.appsList
          .map((a) => (a['titleKh'] ?? a['name'] ?? a['titleEn'] ?? '').toString())
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList();
      if (list.isNotEmpty) return list;
    }
    return const [
      'Portal Core',
      'Document Management System',
      'Audit & Logging System',
      'User Management System',
    ];
  }

  List<String> get _availableUsers {
    if (controller.usersList.isNotEmpty) {
      final list = controller.usersList
          .map((u) => (u['username'] ?? u['name'] ?? u['email'] ?? '').toString())
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList();
      if (list.isNotEmpty) return list;
    }
    return const [
      'bin.sovanvong',
      'admin_user',
      'super_admin',
      'general_admin',
      'audit_officer',
    ];
  }

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.role['name'] ?? 'General Department Admin');
    _code = (widget.role['code'] ?? 'GENERAL_DEPARTMENT_ADMIN').toString();
    _status = (widget.role['status'] ?? 'ACTIVE').toString().toUpperCase();

    // Trigger API fetches safely after the initial frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (controller.groupList.isEmpty) {
          controller.fetchPortalGroupsData();
        }
        if (controller.appsList.isEmpty) {
          controller.fetchDashboardData();
        }
      }
    });

    // Parse role's assigned groups across all API payload keys
    List<String>? parsedGroups;
    for (final key in ['groups', 'groupCodes', 'userGroups', 'portalGroups']) {
      if (widget.role[key] != null && widget.role[key] is List) {
        parsedGroups = (widget.role[key] as List)
            .map((e) => (e is Map ? (e['code'] ?? e['name'] ?? e.toString()) : e.toString()).toString())
            .where((s) => s.isNotEmpty)
            .cast<String>()
            .toList();
        break;
      }
    }
    _selectedGroups = parsedGroups ?? [];

    // Parse role's assigned apps across all API payload keys
    List<String>? parsedApps;
    for (final key in ['applications', 'apps', 'portalApps']) {
      if (widget.role[key] != null && widget.role[key] is List) {
        parsedApps = (widget.role[key] as List)
            .map((e) => (e is Map ? (e['name'] ?? e['titleKh'] ?? e.toString()) : e.toString()).toString())
            .where((s) => s.isNotEmpty)
            .cast<String>()
            .toList();
        break;
      }
    }
    _selectedApps = parsedApps ?? [];

    // Parse role's assigned users across all API payload keys
    List<String>? parsedUsers;
    for (final key in ['users', 'members', 'userList']) {
      if (widget.role[key] != null && widget.role[key] is List) {
        parsedUsers = (widget.role[key] as List)
            .map((e) => (e is Map ? (e['username'] ?? e['name'] ?? e.toString()) : e.toString()).toString())
            .where((s) => s.isNotEmpty)
            .cast<String>()
            .toList();
        break;
      }
    }
    _selectedUsers = parsedUsers ?? [];

    if (widget.role['permissions'] is Map) {
      final Map perms = widget.role['permissions'];
      appLevel = int.tryParse(perms['APPLICATION']?.toString() ?? '') ?? appLevel;
      auditLevel = int.tryParse(perms['AUDIT_LOG']?.toString() ?? perms['AUDIT']?.toString() ?? '') ?? auditLevel;
      accessRuleLevel = int.tryParse(perms['APPLICATION_ACCESS_RULE']?.toString() ?? '') ?? accessRuleLevel;
      permissionLevel = int.tryParse(perms['PERMISSION']?.toString() ?? '') ?? permissionLevel;
      roleLevel = int.tryParse(perms['ROLE']?.toString() ?? '') ?? roleLevel;
      userLevel = int.tryParse(perms['USER']?.toString() ?? '') ?? userLevel;
    } else if (_code == 'PORTAL_SUPER_ADMIN') {
      appLevel = 3;
      auditLevel = 3;
      accessRuleLevel = 3;
      permissionLevel = 3;
      roleLevel = 3;
      userLevel = 3;
    } else if (_code == 'PORTAL_USER') {
      appLevel = 1;
      auditLevel = 1;
      accessRuleLevel = 0;
      permissionLevel = 0;
      roleLevel = 0;
      userLevel = 1;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _groupSearchCtrl.dispose();
    _appSearchCtrl.dispose();
    _userSearchCtrl.dispose();
    super.dispose();
  }

  int getSelectedPermissionsCount() {
    int count = 0;
    count += (appLevel == 0 ? 0 : (appLevel == 3 ? 3 : 1));
    count += (auditLevel == 0 ? 0 : 1);
    count += (accessRuleLevel == 0 ? 0 : 1);
    count += (permissionLevel == 0 ? 0 : (permissionLevel == 3 ? 2 : 1));
    count += (roleLevel == 0 ? 0 : (roleLevel == 1 ? 1 : (roleLevel == 2 ? 2 : 4)));
    count += (userLevel == 0 ? 0 : (userLevel == 1 ? 1 : (userLevel == 2 ? 3 : 5)));
    return count;
  }

  void _selectAllPermissions() {
    setState(() {
      appLevel = 3;
      auditLevel = 3;
      accessRuleLevel = 3;
      permissionLevel = 3;
      roleLevel = 3;
      userLevel = 3;
    });
  }

  void _saveRole() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      CustomSnackbar.showError(message: 'សូមបំពេញឈ្មោះតួនាទី');
      return;
    }

    final permissionsPayload = {
      'APPLICATION': appLevel,
      'AUDIT_LOG': auditLevel,
      'APPLICATION_ACCESS_RULE': accessRuleLevel,
      'PERMISSION': permissionLevel,
      'ROLE': roleLevel,
      'USER': userLevel,
    };

    // Update in-place on widget.role map so caller views update immediately
    widget.role['name'] = name;
    widget.role['status'] = _status;
    widget.role['groups'] = List<String>.from(_selectedGroups);
    widget.role['applications'] = List<String>.from(_selectedApps);
    widget.role['users'] = List<String>.from(_selectedUsers);
    widget.role['permissions'] = permissionsPayload;
    widget.role['perms_count'] = getSelectedPermissionsCount();
    widget.role['groups_count'] = _selectedGroups.length;
    widget.role['users_count'] = _selectedUsers.length;

    final bool success = await controller.updateRoleByCode(
      _code,
      name,
      _code,
      _status,
      groups: _selectedGroups,
      applications: _selectedApps,
      users: _selectedUsers,
      permissions: permissionsPayload,
    );

    if (success) {
      try {
        await controller.fetchRolesData();
      } catch (_) {}
      try {
        await controller.fetchPortalGroupsData();
      } catch (_) {}

      Get.back();
      CustomSnackbar.showSuccess(message: 'បានកែប្រែតួនាទី (PUT/POST) ដោយជោគជ័យ!');
    }
  }

  void _deleteRole() async {
    final bool? confirm = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'លុបតួនាទី',
          style: GoogleFonts.kantumruyPro(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'តើអ្នកប្រាកដជាចង់លុបតួនាទី "$_code" នេះមែនទេ?',
          style: GoogleFonts.kantumruyPro(),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('បោះបង់', style: GoogleFonts.kantumruyPro(color: const Color(0xff64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Get.back(result: true),
            child: Text('លុបតួនាទី', style: GoogleFonts.kantumruyPro(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final bool success = await controller.deleteRoleByCode(_code);
      if (success) {
        Get.back();
        CustomSnackbar.showSuccess(message: 'បានលុបតួនាទីដោយជោគជ័យ (DELETE)!');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 950;

    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xff0F172A)),
          onPressed: () => Get.back(),
        ),
        title: Text(
          'កែប្រែតួនាទី',
          style: GoogleFonts.kantumruyPro(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xff0F172A),
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: Color(0xffEF4444), size: 22),
            tooltip: 'លុបតួនាទី (DELETE API)',
            onPressed: _deleteRole,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
      ),
    );
  }

  // Mobile Native Layout
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtitle
          Text(
            'គ្រប់គ្រងតួនាទី និងសិទ្ធិក្នុងប្រព័ន្ធ',
            style: GoogleFonts.kantumruyPro(
              fontSize: 12,
              color: const Color(0xff64748B),
            ),
          ),
          const SizedBox(height: 16),

          // Section 01: ព័ត៌មានតួនាទី
          _buildSection01RoleInfo(),
          const SizedBox(height: 16),

          // Section 02: កំណត់ក្រុម (អង្គភាព)
          _buildSection02AssignGroups(),
          const SizedBox(height: 16),

          // Section 03: កំណត់កម្មវិធី
          _buildSection03AssignApps(),
          const SizedBox(height: 16),

          // Section 04: កំណត់សិទ្ធិ
          _buildSection04SetPermissions(isDesktop: false),
          const SizedBox(height: 16),

          // Section 05: កំណត់អ្នកប្រើប្រាស់
          _buildSection05AssignUsers(),
          const SizedBox(height: 16),

          // Role Summary
          _buildSummaryCard(),
          const SizedBox(height: 24),

          // Bottom Actions
          _buildActionButtons(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Desktop Side-by-Side Layout
  Widget _buildDesktopLayout() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left Column: Section 01 & Summary & Actions
          SizedBox(
            width: 320,
            child: Column(
              children: [
                _buildSection01RoleInfo(),
                const SizedBox(height: 16),
                _buildSummaryCard(),
                const SizedBox(height: 24),
                _buildActionButtons(),
              ],
            ),
          ),
          const SizedBox(width: 24),

          // Right Column: Section 02, 03, 04, 05
          Expanded(
            child: Column(
              children: [
                _buildSection02AssignGroups(),
                const SizedBox(height: 16),
                _buildSection03AssignApps(),
                const SizedBox(height: 16),
                _buildSection04SetPermissions(isDesktop: true),
                const SizedBox(height: 16),
                _buildSection05AssignUsers(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 01: ព័ត៌មានតួនាទី (Role Information)
  // ---------------------------------------------------------------------------
  Widget _buildSection01RoleInfo() {
    final bool isActive = _status == 'ACTIVE';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '01 ',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xffE29D11),
                ),
              ),
              Text(
                'ព័ត៌មានតួនាទី',
                style: GoogleFonts.kantumruyPro(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Text(
            'ឈ្មោះតួនាទី',
            style: GoogleFonts.kantumruyPro(
              fontSize: 12,
              color: const Color(0xff64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameCtrl,
            style: GoogleFonts.kantumruyPro(fontSize: 13, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                borderSide: const BorderSide(color: Color(0xffE29D11)),
              ),
              fillColor: const Color(0xffF8FAFC),
              filled: true,
            ),
          ),
          const SizedBox(height: 16),

          Text(
            'ស្ថានភាព',
            style: GoogleFonts.kantumruyPro(
              fontSize: 12,
              color: const Color(0xff64748B),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _status = 'ACTIVE'),
                  child: Container(
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xffECFDF5) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isActive ? const Color(0xff10B981) : const Color(0xffE2E8F0),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isActive ? const Color(0xff10B981) : const Color(0xff94A3B8),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'ដំណើរការ',
                          style: GoogleFonts.kantumruyPro(
                            fontSize: 12,
                            color: isActive ? const Color(0xff047857) : const Color(0xff64748B),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _status = 'INACTIVE'),
                  child: Container(
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: !isActive ? const Color(0xffFEF2F2) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: !isActive ? const Color(0xffEF4444) : const Color(0xffE2E8F0),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: !isActive ? const Color(0xffEF4444) : const Color(0xff94A3B8),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'ផ្អាក',
                          style: GoogleFonts.kantumruyPro(
                            fontSize: 12,
                            color: !isActive ? const Color(0xffDC2626) : const Color(0xff64748B),
                            fontWeight: FontWeight.bold,
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

  // ---------------------------------------------------------------------------
  // SECTION 02: កំណត់ក្រុម (អង្គភាព)
  // ---------------------------------------------------------------------------
  Widget _buildSection02AssignGroups() {
    final filtered = _availableGroups.where((g) {
      final q = _groupSearchCtrl.text.toLowerCase();
      return g.toLowerCase().contains(q);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '02 ',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xffE29D11),
                ),
              ),
              Text(
                'កំណត់ក្រុម (អង្គភាព)',
                style: GoogleFonts.kantumruyPro(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'ជ្រើសរើសក្រុមអប្បបរមាមួយ សម្រាប់តួនាទីនេះ។',
            style: GoogleFonts.kantumruyPro(
              fontSize: 11,
              color: const Color(0xff64748B),
            ),
          ),
          const SizedBox(height: 12),

          // Selected Tag Chips
          if (_selectedGroups.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedGroups.map((groupName) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xffFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xffFDE68A)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.corporate_fare_outlined, size: 14, color: Color(0xffD97706)),
                      const SizedBox(width: 6),
                      Text(
                        groupName,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xffB45309),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedGroups.remove(groupName);
                          });
                        },
                        child: const Icon(Icons.close_rounded, size: 14, color: Color(0xffB45309)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 12),

          // Search Field + Expand Button
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _groupSearchCtrl,
                    onChanged: (_) => setState(() {}),
                    style: GoogleFonts.kantumruyPro(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'ស្វែងរកក្រុម (អង្គភាព)...',
                      hintStyle: GoogleFonts.kantumruyPro(
                        fontSize: 11,
                        color: const Color(0xff94A3B8),
                      ),
                      prefixIcon: const Icon(Icons.search_rounded, size: 16, color: Color(0xff94A3B8)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                      fillColor: const Color(0xffF8FAFC),
                      filled: true,
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
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  side: const BorderSide(color: Color(0xffCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  setState(() {
                    _isGroupPickerOpen = !_isGroupPickerOpen;
                  });
                },
                icon: Icon(
                  _isGroupPickerOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: const Color(0xff2563EB),
                ),
                label: Text(
                  _isGroupPickerOpen ? 'បិទ' : 'មើលទាំងអស់',
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff2563EB),
                  ),
                ),
              ),
            ],
          ),

          // Dropdown Group Picker List
          if (_isGroupPickerOpen)
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xffF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xffE2E8F0)),
              ),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: filtered.map((g) {
                  final bool isSel = _selectedGroups.contains(g);
                  return FilterChip(
                    label: Text(
                      g,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: isSel ? Colors.white : const Color(0xff334155),
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSel,
                    selectedColor: const Color(0xffE29D11),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSel ? const Color(0xffE29D11) : const Color(0xffCBD5E1),
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedGroups.add(g);
                        } else {
                          _selectedGroups.remove(g);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 03: កំណត់កម្មវិធី
  // ---------------------------------------------------------------------------
  Widget _buildSection03AssignApps() {
    final filtered = _availableApps.where((a) {
      final q = _appSearchCtrl.text.toLowerCase();
      return a.toLowerCase().contains(q);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '03 ',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xffE29D11),
                ),
              ),
              Text(
                'កំណត់កម្មវិធី',
                style: GoogleFonts.kantumruyPro(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'ជ្រើសរើសកម្មវិធីដែលអនុញ្ញាតឲ្យប្រើប្រាស់សម្រាប់តួនាទីនេះ។',
            style: GoogleFonts.kantumruyPro(
              fontSize: 11,
              color: const Color(0xff64748B),
            ),
          ),
          const SizedBox(height: 12),

          // Selected Tag Chips
          if (_selectedApps.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedApps.map((appName) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xffEFF6FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xffBFDBFE)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.grid_view_rounded, size: 14, color: Color(0xff2563EB)),
                      const SizedBox(width: 6),
                      Text(
                        appName,
                        style: GoogleFonts.kantumruyPro(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xff1D4ED8),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedApps.remove(appName);
                          });
                        },
                        child: const Icon(Icons.close_rounded, size: 14, color: Color(0xff1D4ED8)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 12),

          // Search Field + Expand Button
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _appSearchCtrl,
                    onChanged: (_) => setState(() {}),
                    style: GoogleFonts.kantumruyPro(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'ស្វែងរកកម្មវិធី...',
                      hintStyle: GoogleFonts.kantumruyPro(
                        fontSize: 11,
                        color: const Color(0xff94A3B8),
                      ),
                      prefixIcon: const Icon(Icons.search_rounded, size: 16, color: Color(0xff94A3B8)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                      fillColor: const Color(0xffF8FAFC),
                      filled: true,
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
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  side: const BorderSide(color: Color(0xffCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  setState(() {
                    _isAppPickerOpen = !_isAppPickerOpen;
                  });
                },
                icon: Icon(
                  _isAppPickerOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: const Color(0xff2563EB),
                ),
                label: Text(
                  _isAppPickerOpen ? 'បិទ' : 'មើលទាំងអស់',
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff2563EB),
                  ),
                ),
              ),
            ],
          ),

          // Dropdown App Picker List
          if (_isAppPickerOpen)
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xffF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xffE2E8F0)),
              ),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: filtered.map((app) {
                  final bool isSel = _selectedApps.contains(app);
                  return FilterChip(
                    label: Text(
                      app,
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 11,
                        color: isSel ? Colors.white : const Color(0xff334155),
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSel,
                    selectedColor: const Color(0xff2563EB),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSel ? const Color(0xff2563EB) : const Color(0xffCBD5E1),
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedApps.add(app);
                        } else {
                          _selectedApps.remove(app);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 04: កំណត់សិទ្ធិ (8-Action Permissions Grid Matching Mockup)
  // ---------------------------------------------------------------------------
  final Map<String, Map<String, bool?>> _moduleActionGrid = {
    'APPLICATION': {
      'VIEW': true,
      'CREATE': null,
      'UPDATE': null,
      'MANAGE': false,
      'ASSIGN': true,
      'DISABLE': null,
      'REMOVE': null,
      'RESET PASSWORD': null,
    },
    'AUDIT LOG': {
      'VIEW': true,
      'CREATE': null,
      'UPDATE': null,
      'MANAGE': null,
      'ASSIGN': null,
      'DISABLE': null,
      'REMOVE': null,
      'RESET PASSWORD': null,
    },
    'APPLICATION ACCESS RULE': {
      'VIEW': null,
      'CREATE': null,
      'UPDATE': null,
      'MANAGE': false,
      'ASSIGN': null,
      'DISABLE': null,
      'REMOVE': null,
      'RESET PASSWORD': null,
    },
    'PERMISSION': {
      'VIEW': true,
      'CREATE': null,
      'UPDATE': null,
      'MANAGE': false,
      'ASSIGN': null,
      'DISABLE': null,
      'REMOVE': null,
      'RESET PASSWORD': null,
    },
    'ROLE': {
      'VIEW': true,
      'CREATE': null,
      'UPDATE': null,
      'MANAGE': false,
      'ASSIGN': true,
      'DISABLE': null,
      'REMOVE': true,
      'RESET PASSWORD': null,
    },
    'USER': {
      'VIEW': true,
      'CREATE': true,
      'UPDATE': true,
      'MANAGE': null,
      'ASSIGN': null,
      'DISABLE': true,
      'REMOVE': null,
      'RESET PASSWORD': true,
    },
  };

  Widget _buildSection04SetPermissions({required bool isDesktop}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '04 ',
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xffE29D11),
                          ),
                        ),
                        Text(
                          'កំណត់សិទ្ធិ',
                          style: GoogleFonts.kantumruyPro(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xff1E293B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ជ្រើសរើសកម្រិតចូលប្រើប្រាស់គ្រប់គ្រងសិទ្ធិ។',
                      style: GoogleFonts.kantumruyPro(
                        fontSize: 11,
                        color: const Color(0xff64748B),
                      ),
                      softWrap: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: _selectAllPermissions,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_rounded, size: 16, color: Color(0xffE29D11)),
                      const SizedBox(width: 4),
                      Text(
                        'ជ្រើសរើសទាំងអស់',
                        style: GoogleFonts.kantumruyPro(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xffE29D11),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              width: 890,
              child: Column(
                children: [
                  _buildTableHeaderRowGrid(),
                  const Divider(height: 1, color: Color(0xffEDF2F7)),
                  ..._moduleActionGrid.entries.map((e) => _buildModuleRowGrid(e.key, e.value)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeaderRowGrid() {
    final actions = ['VIEW', 'CREATE', 'UPDATE', 'MANAGE', 'ASSIGN', 'DISABLE', 'REMOVE', 'RESET PASSWORD'];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 210,
            child: Text(
              'សិទ្ធិ',
              style: GoogleFonts.kantumruyPro(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: const Color(0xff64748B),
              ),
            ),
          ),
          ...actions.map((act) {
            final double w = act == 'RESET PASSWORD' ? 120 : 80;
            return SizedBox(
              width: w,
              child: Center(
                child: Text(
                  act,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff475569),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildModuleRowGrid(String moduleName, Map<String, bool?> actionMap) {
    final actions = ['VIEW', 'CREATE', 'UPDATE', 'MANAGE', 'ASSIGN', 'DISABLE', 'REMOVE', 'RESET PASSWORD'];
    final int totalCount = actionMap.values.where((v) => v != null).length;

    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xffEDF2F7))),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 210,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  moduleName,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$totalCount សិទ្ធិ (សរុប)',
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 10,
                    color: const Color(0xff94A3B8),
                  ),
                ),
              ],
            ),
          ),
          ...actions.map((act) {
            final bool? val = actionMap[act];
            final double w = act == 'RESET PASSWORD' ? 120 : 80;

            return SizedBox(
              width: w,
              child: Center(
                child: val == null
                    ? Text(
                        '—',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: const Color(0xffCBD5E1),
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : InkWell(
                        onTap: () {
                          setState(() {
                            actionMap[act] = !(val == true);
                          });
                        },
                        borderRadius: BorderRadius.circular(4),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: (val == true) ? const Color(0xffE29D11) : Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: (val == true) ? const Color(0xffE29D11) : const Color(0xffCBD5E1),
                              width: 1.5,
                            ),
                          ),
                          child: (val == true)
                              ? const Icon(
                                  Icons.check_rounded,
                                  size: 14,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECTION 05: កំណត់អ្នកប្រើប្រាស់
  // ---------------------------------------------------------------------------
  Widget _buildSection05AssignUsers() {
    final filtered = _availableUsers.where((u) {
      final q = _userSearchCtrl.text.toLowerCase();
      return u.toLowerCase().contains(q);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '05 ',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xffE29D11),
                ),
              ),
              Text(
                'កំណត់អ្នកប្រើប្រាស់',
                style: GoogleFonts.kantumruyPro(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'ជ្រើសរើសអ្នកប្រើប្រាស់ដែលត្រូវទទួលបានតួនាទីនេះដោយផ្ទាល់។',
            style: GoogleFonts.kantumruyPro(
              fontSize: 11,
              color: const Color(0xff64748B),
            ),
          ),
          const SizedBox(height: 12),

          // Selected Tag Chips
          if (_selectedUsers.isNotEmpty)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedUsers.map((userName) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xffF3E8FF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xffDDD6FE)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.person_outline_rounded, size: 14, color: Color(0xff7C3AED)),
                      const SizedBox(width: 6),
                      Text(
                        userName,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xff6D28D9),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedUsers.remove(userName);
                          });
                        },
                        child: const Icon(Icons.close_rounded, size: 14, color: Color(0xff6D28D9)),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),

          const SizedBox(height: 12),

          // Search Field + Expand Button
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _userSearchCtrl,
                    onChanged: (_) => setState(() {}),
                    style: GoogleFonts.kantumruyPro(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'ស្វែងរកអ្នកប្រើប្រាស់...',
                      hintStyle: GoogleFonts.kantumruyPro(
                        fontSize: 11,
                        color: const Color(0xff94A3B8),
                      ),
                      prefixIcon: const Icon(Icons.search_rounded, size: 16, color: Color(0xff94A3B8)),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
                      fillColor: const Color(0xffF8FAFC),
                      filled: true,
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
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  side: const BorderSide(color: Color(0xffCBD5E1)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () {
                  setState(() {
                    _isUserPickerOpen = !_isUserPickerOpen;
                  });
                },
                icon: Icon(
                  _isUserPickerOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                  size: 16,
                  color: const Color(0xff2563EB),
                ),
                label: Text(
                  _isUserPickerOpen ? 'បិទ' : 'មើលទាំងអស់',
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff2563EB),
                  ),
                ),
              ),
            ],
          ),

          // Dropdown User Picker List
          if (_isUserPickerOpen)
            Container(
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xffF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xffE2E8F0)),
              ),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: filtered.map((u) {
                  final bool isSel = _selectedUsers.contains(u);
                  return FilterChip(
                    label: Text(
                      u,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: isSel ? Colors.white : const Color(0xff334155),
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSel,
                    selectedColor: const Color(0xff7C3AED),
                    backgroundColor: Colors.white,
                    side: BorderSide(
                      color: isSel ? const Color(0xff7C3AED) : const Color(0xffCBD5E1),
                    ),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedUsers.add(u);
                        } else {
                          _selectedUsers.remove(u);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // HELPER WIDGETS
  // ---------------------------------------------------------------------------

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'សង្ខេបតួនាទី',
            style: GoogleFonts.kantumruyPro(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: const Color(0xff1E293B),
            ),
          ),
          const SizedBox(height: 14),

          // Stat Item 1: Groups
          _buildSummaryStatRow(
            icon: Icons.corporate_fare_outlined,
            color: const Color(0xff3B82F6),
            title: 'ក្រុមដែលបានកំណត់',
            countText: '${_selectedGroups.length} អង្គភាពជ្រើសរើស',
          ),
          const SizedBox(height: 10),

          // Stat Item 2: Apps
          _buildSummaryStatRow(
            icon: Icons.grid_view_rounded,
            color: const Color(0xff8B5CF6),
            title: 'កម្មវិធីដែលបានកំណត់',
            countText: '${_selectedApps.length} កម្មវិធីជ្រើសរើស',
          ),
          const SizedBox(height: 10),

          // Stat Item 3: Permissions
          _buildSummaryStatRow(
            icon: Icons.vpn_key_outlined,
            color: const Color(0xff10B981),
            title: 'សិទ្ធិដែលបានកំណត់',
            countText: '${getSelectedPermissionsCount()} សិទ្ធិជ្រើសរើស',
          ),
          const SizedBox(height: 10),

          // Stat Item 4: Users
          _buildSummaryStatRow(
            icon: Icons.person_outline_rounded,
            color: const Color(0xffE29D11),
            title: 'អ្នកប្រើដែលបានកំណត់',
            countText: '${_selectedUsers.length} នាក់ជ្រើសរើស',
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStatRow({
    required IconData icon,
    required Color color,
    required String title,
    required String countText,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.kantumruyPro(
                  fontSize: 11,
                  color: const Color(0xff64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                countText,
                style: GoogleFonts.kantumruyPro(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff1E293B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: Color(0xffCBD5E1)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Get.back(),
            child: Text(
              'បោះបង់',
              style: GoogleFonts.kantumruyPro(
                fontSize: 13,
                color: const Color(0xff64748B),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xffE29D11),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _saveRole,
            child: Text(
              'រក្សាទុក',
              style: GoogleFonts.kantumruyPro(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
