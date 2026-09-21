import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void showSuperAdminViewRoleModal(BuildContext context, Map<String, dynamic> role) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SuperAdminViewRoleDialogContent(role: role),
    ),
  );
}

class SuperAdminViewRoleDialogContent extends StatefulWidget {
  final Map<String, dynamic> role;

  const SuperAdminViewRoleDialogContent({super.key, required this.role});

  @override
  State<SuperAdminViewRoleDialogContent> createState() => _SuperAdminViewRoleDialogContentState();
}

class _SuperAdminViewRoleDialogContentState extends State<SuperAdminViewRoleDialogContent> {

  List<String> _getGroups() {
    if (widget.role['groups'] is List) {
      return (widget.role['groups'] as List)
          .map((e) => (e is Map ? (e['code'] ?? e['name'] ?? e.toString()) : e.toString()).toString())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [];
  }

  List<String> _getApps() {
    if (widget.role['applications'] is List) {
      return (widget.role['applications'] as List)
          .map((e) => (e is Map ? (e['name'] ?? e['titleKh'] ?? e.toString()) : e.toString()).toString())
          .where((s) => s.isNotEmpty)
          .toList();
    } else if (widget.role['apps'] is List) {
      return (widget.role['apps'] as List)
          .map((e) => (e is Map ? (e['name'] ?? e['titleKh'] ?? e.toString()) : e.toString()).toString())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [];
  }

  List<String> _getPerms() {
    if (widget.role['permissions'] is Map) {
      final Map perms = widget.role['permissions'];
      final List<String> result = [];
      perms.forEach((key, val) {
        if (val is List && val.isNotEmpty) {
          for (final act in val) {
            result.add('${key}_$act');
          }
        } else if (val is int && val > 0) {
          result.add('${key}_LEVEL_$val');
        }
      });
      if (result.isNotEmpty) return result;
    }
    return ['PORTAL_APP_READ'];
  }

  List<String> _getUsers() {
    if (widget.role['users'] is List) {
      return (widget.role['users'] as List)
          .map((e) => (e is Map ? (e['username'] ?? e['name'] ?? e.toString()) : e.toString()).toString())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final String name = widget.role['name'] ?? 'Portal User';
    final String code = widget.role['code'] ?? 'PORTAL_USER';
    final String status = (widget.role['status'] ?? 'ACTIVE').toString().toUpperCase();
    final bool isActive = status == 'ACTIVE';
    final String description = widget.role['description'] ?? 'Can use the portal as themselves';

    final groups = _getGroups();
    final apps = _getApps();
    final perms = _getPerms();
    final users = _getUsers();

    final mediaWidth = MediaQuery.of(context).size.width;
    final isDesktop = mediaWidth > 850;

    return Container(
      width: isDesktop ? 920 : double.infinity,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // -------------------------------------------------------------------
          // 1. TOP HEADER BAR
          // -------------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xff7C3AED),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.verified_user_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ព័ត៌មានតួនាទី',
                        style: GoogleFonts.kantumruyPro(
                          fontSize: 11,
                          color: const Color(0xff64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        name,
                        style: GoogleFonts.kantumruyPro(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xff1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
                InkWell(
                  onTap: () => Navigator.of(context).pop(),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xffF1F5F9),
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xffE2E8F0)),
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 20,
                      color: Color(0xff64748B),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xffEDF2F7)),

          // -------------------------------------------------------------------
          // 2. MAIN SPLIT BODY AREA
          // -------------------------------------------------------------------
          Flexible(
            child: SingleChildScrollView(
              child: isDesktop
                  ? IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Left Sidebar Tree View
                          SizedBox(
                            width: 280,
                            child: _buildTreeSidebar(name, groups, apps, perms, users),
                          ),
                          const VerticalDivider(width: 1, color: Color(0xffEDF2F7)),
                          // Right Details View
                          Expanded(
                            child: _buildRightDetailsContent(
                                name, code, status, isActive, description, groups, apps, perms, users),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      children: [
                        _buildTreeSidebar(name, groups, apps, perms, users),
                        const Divider(height: 1, color: Color(0xffEDF2F7)),
                        _buildRightDetailsContent(
                            name, code, status, isActive, description, groups, apps, perms, users),
                      ],
                    ),
            ),
          ),

          const Divider(height: 1, color: Color(0xffEDF2F7)),

          // -------------------------------------------------------------------
          // 3. BOTTOM ACTION FOOTER
          // -------------------------------------------------------------------
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(100, 44),
                    backgroundColor: const Color(0xffE29D11),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'បិទ',
                    style: GoogleFonts.kantumruyPro(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
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

  // ---------------------------------------------------------------------------
  // LEFT SIDEBAR TREE VIEW (រចនាសម្ព័ន្ធតួនាទី)
  // ---------------------------------------------------------------------------
  Widget _buildTreeSidebar(
    String roleName,
    List<String> groups,
    List<String> apps,
    List<String> perms,
    List<String> users,
  ) {
    return Container(
      color: const Color(0xffFAFAFA),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'រចនាសម្ព័ន្ធតួនាទី',
                style: GoogleFonts.kantumruyPro(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff1E293B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xffE2E8F0)),
                ),
                child: Text(
                  '1',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff64748B),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Root Tree Node
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xffF3E8FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xff7C3AED)),
                const SizedBox(width: 4),
                const Icon(Icons.verified_user_outlined, size: 16, color: Color(0xff7C3AED)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    roleName,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xff6D28D9),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '1',
                    style: GoogleFonts.poppins(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xff7C3AED),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Tree Children Branches
          Padding(
            padding: const EdgeInsets.only(left: 14, top: 8),
            child: Column(
              children: [
                _buildTreeNode(
                  icon: Icons.people_outline_rounded,
                  label: 'ក្រុមដែលបានកំណត់',
                  count: groups.length,
                  iconColor: const Color(0xff2563EB),
                ),
                _buildTreeNode(
                  icon: Icons.grid_view_rounded,
                  label: 'កម្មវិធីដែលបានកំណត់',
                  count: apps.length,
                  iconColor: const Color(0xffD97706),
                ),
                _buildTreeNode(
                  icon: Icons.key_outlined,
                  label: 'សិទ្ធិដែលបានកំណត់',
                  count: perms.length,
                  iconColor: const Color(0xff9333EA),
                  children: perms.map((p) => _buildLeafNode(p)).toList(),
                ),
                _buildTreeNode(
                  icon: Icons.person_outline_rounded,
                  label: 'អ្នកប្រើដែលបានកំណត់',
                  count: users.length,
                  iconColor: const Color(0xff059669),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTreeNode({
    required IconData icon,
    required String label,
    required int count,
    required Color iconColor,
    List<Widget>? children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('┊', style: TextStyle(color: Colors.grey.shade400, fontSize: 16)),
            Text('── ', style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
            Icon(children != null ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_right_rounded,
                size: 16, color: Colors.grey.shade500),
            const SizedBox(width: 4),
            Icon(icon, size: 15, color: iconColor),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.kantumruyPro(
                  fontSize: 11,
                  color: const Color(0xff334155),
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.poppins(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xff475569),
                ),
              ),
            ),
          ],
        ),
        if (children != null && children.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Column(children: children),
          ),
      ],
    );
  }

  Widget _buildLeafNode(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('┊', style: TextStyle(color: Colors.grey.shade300, fontSize: 14)),
          Text('── ', style: TextStyle(color: Colors.grey.shade300, fontSize: 12)),
          const Icon(Icons.search_rounded, size: 13, color: Color(0xff94A3B8)),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: const Color(0xff64748B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // RIGHT SIDE DETAILS CONTENT
  // ---------------------------------------------------------------------------
  Widget _buildRightDetailsContent(
    String name,
    String code,
    String status,
    bool isActive,
    String description,
    List<String> groups,
    List<String> apps,
    List<String> perms,
    List<String> users,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. TOP 4 STAT CARDS ROW
          Row(
            children: [
              Expanded(
                child: _buildTopStatCard(
                  icon: Icons.people_outline_rounded,
                  iconBg: const Color(0xffEFF6FF),
                  iconColor: const Color(0xff2563EB),
                  label: 'ក្រុមដែលបានកំ...',
                  countText: '${groups.length}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTopStatCard(
                  icon: Icons.grid_view_rounded,
                  iconBg: const Color(0xffFEF3C7),
                  iconColor: const Color(0xffD97706),
                  label: 'កម្មវិធីដែលបានកំ...',
                  countText: '${apps.length}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTopStatCard(
                  icon: Icons.key_outlined,
                  iconBg: const Color(0xffF3E8FF),
                  iconColor: const Color(0xff9333EA),
                  label: 'សិទ្ធិដែលបានកំ...',
                  countText: '${perms.length}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildTopStatCard(
                  icon: Icons.person_outline_rounded,
                  iconBg: const Color(0xffD1FAE5),
                  iconColor: const Color(0xff059669),
                  label: 'អ្នកប្រើដែលបានកំ...',
                  countText: '${users.length}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 2. MIDDLE ROW: DESCRIPTION & STATUS
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Container(
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
                        'ការពិពណ៌នា',
                        style: GoogleFonts.kantumruyPro(
                          fontSize: 11,
                          color: const Color(0xff94A3B8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xff1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Container(
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
                        'ស្ថានភាព',
                        style: GoogleFonts.kantumruyPro(
                          fontSize: 11,
                          color: const Color(0xff94A3B8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isActive ? const Color(0xff10B981) : const Color(0xffEF4444),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isActive ? 'ដំណើរការ' : 'ផ្អាក',
                            style: GoogleFonts.kantumruyPro(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isActive ? const Color(0xff047857) : const Color(0xffDC2626),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 3. DETAILED LIST SECTIONS
          _buildDetailSectionCard(
            title: 'ក្រុមដែលបានកំណត់',
            count: groups.length,
            icon: Icons.people_outline_rounded,
            iconBg: const Color(0xffEFF6FF),
            iconColor: const Color(0xff2563EB),
            items: groups,
            emptyMessage: 'មិនទាន់មានក្រុមដែលបានកំណត់',
            chipBg: const Color(0xffEFF6FF),
            chipTextColor: const Color(0xff1D4ED8),
          ),
          const SizedBox(height: 12),

          _buildDetailSectionCard(
            title: 'កម្មវិធីដែលបានកំណត់',
            count: apps.length,
            icon: Icons.grid_view_rounded,
            iconBg: const Color(0xffFEF3C7),
            iconColor: const Color(0xffD97706),
            items: apps,
            emptyMessage: 'មិនទាន់មានកម្មវិធីដែលបានកំណត់',
            chipBg: const Color(0xffFFFBEB),
            chipTextColor: const Color(0xffB45309),
          ),
          const SizedBox(height: 12),

          _buildDetailSectionCard(
            title: 'សិទ្ធិដែលបានកំណត់',
            count: perms.length,
            icon: Icons.key_outlined,
            iconBg: const Color(0xffF3E8FF),
            iconColor: const Color(0xff9333EA),
            items: perms,
            emptyMessage: 'មិនទាន់មានសិទ្ធិដែលបានកំណត់',
            chipBg: const Color(0xffFAF5FF),
            chipTextColor: const Color(0xff7E22CE),
            showCheckIcon: true,
          ),
          const SizedBox(height: 12),

          _buildDetailSectionCard(
            title: 'អ្នកប្រើដែលបានកំណត់',
            count: users.length,
            icon: Icons.person_outline_rounded,
            iconBg: const Color(0xffD1FAE5),
            iconColor: const Color(0xff059669),
            items: users,
            emptyMessage: 'មិនទាន់មានអ្នកប្រើដែលបានកំណត់',
            chipBg: const Color(0xffECFDF5),
            chipTextColor: const Color(0xff047857),
          ),
        ],
      ),
    );
  }

  Widget _buildTopStatCard({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required String countText,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 10,
                    color: const Color(0xff64748B),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  countText,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailSectionCard({
    required String title,
    required int count,
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required List<String> items,
    required String emptyMessage,
    required Color chipBg,
    required Color chipTextColor,
    bool showCheckIcon = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff1E293B),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xffF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xff475569),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  emptyMessage,
                  style: GoogleFonts.kantumruyPro(
                    fontSize: 12,
                    color: const Color(0xff94A3B8),
                  ),
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: items.map((itemStr) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: chipBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: chipTextColor.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (showCheckIcon) ...[
                        Icon(Icons.check_rounded, size: 14, color: chipTextColor),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        itemStr,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: chipTextColor,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
