import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:core_portal/core/api/api_client.dart';
import 'package:core_portal/core/localization/app_translations.dart';
import 'package:core_portal/screens/application/application_view.dart';
import 'package:core_portal/widgets/app_icon.dart';
import 'package:core_portal/theme/app_colors.dart';

/// Opens the Application Detail dialog matching the official modal design
void showAppDetailDialog(
  BuildContext context,
  Map<String, dynamic> app, {
  void Function(Map<String, dynamic> item, String title)? onLaunch,
}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => AppDetailDialog(
      app: app,
      onLaunch: onLaunch,
    ),
  );
}

class AppDetailDialog extends StatelessWidget {
  final Map<String, dynamic> app;
  final void Function(Map<String, dynamic> item, String title)? onLaunch;

  const AppDetailDialog({
    super.key,
    required this.app,
    this.onLaunch,
  });

  @override
  Widget build(BuildContext context) {
    final bool isKh = LocalizationService.currentLanguageCode.value == 'km';
    final String title = ApplicationView.resolveAppTitle(app, isKh);

    final String code = (app['code'] ?? app['id'] ?? '').toString().trim();
    final String route = (app['route'] ??
            app['appUrl'] ??
            app['launchUrl'] ??
            app['url'] ??
            '')
        .toString()
        .trim();

    final String deptRaw = (app['department'] ??
            app['departmentName'] ??
            app['unit'] ??
            app['generalDepartmentCode'] ??
            app['ownerOrgCode'] ??
            '')
        .toString()
        .trim();
    final String dept = (deptRaw.isNotEmpty && deptRaw != '—' && deptRaw != 'null')
        ? deptRaw
        : 'GDDTM';

    final dynamic rawActive = app['isActive'] ?? app['is_active'];
    final dynamic rawStatus = app['status'];
    bool isActive = true;
    if (rawStatus != null) {
      final s = rawStatus.toString().trim().toUpperCase();
      if (s == 'INACTIVE' || s == 'DISABLED' || s == 'OFF' || s == '0' || s == 'FALSE') {
        isActive = false;
      }
    } else if (rawActive != null) {
      if (rawActive is bool) {
        isActive = rawActive;
      } else {
        final s = rawActive.toString().trim().toLowerCase();
        if (s == 'false' || s == '0' || s == 'inactive') {
          isActive = false;
        }
      }
    }

    final resolvedTheme = ApplicationView.resolveAppTheme(app);
    final Color iconBg = app['iconBg'] is Color
        ? (app['iconBg'] as Color)
        : (resolvedTheme['bg'] as Color);
    final IconData fallbackIcon = app['fallbackIcon'] is IconData
        ? (app['fallbackIcon'] as IconData)
        : (resolvedTheme['icon'] as IconData);

    final storage = GetStorage();
    final String sessionToken = (ApiClient.currentToken ??
            storage.read('token') ??
            storage.read('access_token') ??
            '')
        .toString();

    String? iconUrl;
    final String rawImg = AppIconWidget.extractRawIcon(app);
    if (rawImg.isNotEmpty &&
        rawImg != 'assets/img/about-moi-logo.png' &&
        rawImg != '/assets/img/about-moi-logo.png' &&
        rawImg.toLowerCase() != 'null' &&
        rawImg.toLowerCase() != 'undefined') {
      iconUrl = AppIconWidget.formatIconUrl(rawImg, sessionToken);
    }

    final String rawIconStr = (app["icon"] ?? '').toString().trim();
    final bool isLocalPath = rawIconStr.toLowerCase().startsWith('assets/') ||
        rawIconStr.toLowerCase().startsWith('/assets/') ||
        rawIconStr.toLowerCase().startsWith('images/') ||
        rawIconStr.toLowerCase().startsWith('/images/');
    final String itemLocal = (isLocalPath &&
            rawIconStr != 'assets/img/about-moi-logo.png' &&
            rawIconStr != '/assets/img/about-moi-logo.png')
        ? rawIconStr
        : '';

    final bool hasImage = (iconUrl != null && iconUrl.trim().isNotEmpty) || itemLocal.isNotEmpty;

    // Resolve icon asset filename
    String fileName = '';
    if (rawImg.isNotEmpty) {
      final clean = rawImg.split('?').first;
      fileName = clean.contains('/') ? clean.split('/').last : clean;
    }
    if (fileName.isEmpty && itemLocal.isNotEmpty) {
      fileName = itemLocal.split('/').last;
    }
    if (fileName.isEmpty) {
      final safeCode = code.isNotEmpty ? code.toLowerCase() : 'app';
      fileName = '${safeCode}_icon.png';
    }

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: AppColors.warmCreamBorder,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // =============================================================
              // HEADER: App Icon + Overline + App Title + Circular Close Button
              // =============================================================
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 16, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Squircle App Icon (52x52)
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: hasImage ? Colors.transparent : iconBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Center(
                          child: hasImage
                              ? AppIconWidget(
                                  iconUrl: iconUrl ?? '',
                                  localAsset: itemLocal,
                                  fallbackIcon: fallbackIcon,
                                  fallbackColor: iconBg,
                                  token: sessionToken,
                                  size: 52,
                                  fit: BoxFit.contain,
                                )
                              : Icon(
                                  fallbackIcon,
                                  color: Colors.white,
                                  size: 28,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Title & Overline
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'ព័ត៌មានលម្អិតកម្មវិធី',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.kantumruyPro(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.royalGold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.kantumruyPro(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Circular Close Button
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: AppColors.warmCreamBorder,
                            width: 1.2,
                          ),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 19,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Thin Divider
              const Divider(height: 1, thickness: 1, color: AppColors.warmCreamBorder),

              // =============================================================
              // BODY ROWS (Scrollable if height exceeds screen)
              // =============================================================
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ROW 1: Code (កូដ)
                      _buildDetailRow(
                        iconBox: _buildIconBox(
                          icon: Icons.grid_view_rounded,
                          bgColor: const Color(0xFFF8FAFC),
                          iconColor: const Color(0xFF64748B),
                        ),
                        label: isKh ? 'កូដ' : 'Code',
                        valueWidget: Text(
                          code.isNotEmpty ? code : '—',
                          style: GoogleFonts.kantumruyPro(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),

                      // ROW 2: URL
                      _buildDetailRow(
                        iconBox: _buildIconBox(
                          icon: Icons.link_rounded,
                          bgColor: const Color(0xFFF8FAFC),
                          iconColor: const Color(0xFF64748B),
                        ),
                        label: 'URL',
                        valueWidget: route.isNotEmpty
                            ? GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pop();
                                  if (onLaunch != null) {
                                    onLaunch!(app, title);
                                  } else {
                                    _defaultLaunch(app, title);
                                  }
                                },
                                behavior: HitTestBehavior.opaque,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        route,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.end,
                                        style: GoogleFonts.kantumruyPro(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.royalGold,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    const Icon(
                                      Icons.north_east_rounded,
                                      size: 14,
                                      color: AppColors.royalGold,
                                    ),
                                  ],
                                ),
                              )
                            : Text(
                                '—',
                                style: GoogleFonts.kantumruyPro(
                                  fontSize: 14,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                      ),

                      // ROW 3: Department (អង្គភាព)
                      _buildDetailRow(
                        iconBox: _buildIconBox(
                          icon: Icons.account_tree_outlined,
                          bgColor: const Color(0xFFFFFBEB),
                          iconColor: const Color(0xFFD97706),
                        ),
                        label: isKh ? 'អង្គភាព' : 'Department',
                        valueWidget: Text(
                          dept,
                          style: GoogleFonts.kantumruyPro(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),

                      // ROW 4: Status (ស្ថានភាព)
                      _buildDetailRow(
                        iconBox: _buildIconBox(
                          icon: Icons.check_circle_outline_rounded,
                          bgColor: const Color(0xFFECFDF5),
                          iconColor: const Color(0xFF10B981),
                        ),
                        label: isKh ? 'ស្ថានភាព' : 'Status',
                        valueWidget: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6.5,
                                height: 6.5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isActive
                                      ? const Color(0xFF16A34A)
                                      : const Color(0xFFDC2626),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                isActive
                                    ? (isKh ? 'កំពុងដំណើរការ' : 'Active')
                                    : (isKh ? 'អសកម្ម' : 'Inactive'),
                                style: GoogleFonts.kantumruyPro(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.bold,
                                  color: isActive
                                      ? const Color(0xFF15803D)
                                      : const Color(0xFFB91C1C),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ROW 5: Application (កម្មវិធី)
                      _buildDetailRow(
                        iconBox: _buildIconBox(
                          icon: Icons.grid_view_rounded,
                          bgColor: const Color(0xFFF5F3FF),
                          iconColor: const Color(0xFF8B5CF6),
                        ),
                        label: isKh ? 'កម្មវិធី' : 'Application',
                        valueWidget: Text(
                          title,
                          style: GoogleFonts.kantumruyPro(
                            fontSize: 14.5,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                      ),

                      // ROW 6: Icon Asset (ឯកសាររូបតំណាង)
                      _buildDetailRow(
                        showDivider: false,
                        iconBox: _buildIconBox(
                          icon: Icons.insert_drive_file_outlined,
                          bgColor: const Color(0xFFF0F9FF),
                          iconColor: const Color(0xFF64748B),
                        ),
                        label: isKh ? 'ឯកសាររូបតំណាង' : 'Icon Asset',
                        valueWidget: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            // Square thumbnail preview
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: hasImage ? Colors.transparent : iconBg,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.warmCreamBorder,
                                  width: 1.0,
                                ),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Center(
                                  child: hasImage
                                      ? AppIconWidget(
                                          iconUrl: iconUrl ?? '',
                                          localAsset: itemLocal,
                                          fallbackIcon: fallbackIcon,
                                          fallbackColor: iconBg,
                                          token: sessionToken,
                                          size: 38,
                                          fit: BoxFit.contain,
                                        )
                                      : Icon(
                                          fallbackIcon,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),

                            // Filename & Allowed Types
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    fileName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.kantumruyPro(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'JPG, PNG, GIF, WEBP',
                                    style: GoogleFonts.kantumruyPro(
                                      fontSize: 11,
                                      color: const Color(0xFF94A3B8),
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
              ),

              // =============================================================
              // BOTTOM ACTION: Launch Application Button
              // =============================================================
              if (route.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: SizedBox(
                    height: 46,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.royalGold,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        if (onLaunch != null) {
                          onLaunch!(app, title);
                        } else {
                          _defaultLaunch(app, title);
                        }
                      },
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: Text(
                        isKh ? 'បើកដំណើរការកម្មវិធី' : 'Launch Application',
                        style: GoogleFonts.kantumruyPro(
                          fontSize: 14.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                )
              else
                const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  static void _defaultLaunch(Map<String, dynamic> item, String title) {
    final String route = (item["appUrl"] ??
            item["launchUrl"] ??
            item["url"] ??
            item["route"] ??
            item["path"] ??
            '')
        .toString()
        .trim();

    if (route.isNotEmpty) {
      final Map<String, dynamic> args = {
        'url': route,
        'title': title,
      };
      if (route.startsWith('http://') || route.startsWith('https://')) {
        Get.toNamed(
          '/web-view',
          arguments: args,
        );
        return;
      }
      Get.toNamed(route, arguments: args);
    }
  }

  Widget _buildIconBox({
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
  }) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 19,
          color: iconColor,
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required Widget iconBox,
    required String label,
    required Widget valueWidget,
    bool showDivider = true,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Icon box
              iconBox,
              const SizedBox(width: 12),

              // Left Label
              Text(
                label,
                style: GoogleFonts.kantumruyPro(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(width: 16),

              // Right Value
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: valueWidget,
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          const Divider(
            height: 1,
            thickness: 1,
            color: AppColors.warmCreamBorder,
          ),
      ],
    );
  }
}
