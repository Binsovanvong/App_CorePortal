import 'package:core_portal/screens/home/home_controller.dart';
import 'package:core_portal/screens/admin/admin_controller.dart';
import 'package:core_portal/core/localization/app_translations.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get_storage/get_storage.dart';
import 'package:core_portal/widgets/app_icon.dart';
import 'package:core_portal/widgets/custom_snackbar.dart';
import 'package:core_portal/widgets/empty_apps_widget.dart';
import 'package:core_portal/core/api/services/auth_service.dart';
import 'package:core_portal/core/api/api_client.dart';
import 'package:core_portal/theme/app_colors.dart';
import 'package:core_portal/routes/page_route.dart';
import 'package:core_portal/widgets/portal_top_app_bar.dart';
import 'package:core_portal/widgets/app_detail_dialog.dart';

part 'application_binding.dart';
part 'application_controller.dart';

class ApplicationView extends GetView<ApplicationViewController> {
  const ApplicationView({super.key});

  /// Instant O(1) in-memory cache
  static final Map<String, int> _appUserCountCache = {};

  static void clearUserCountCache() {
    _appUserCountCache.clear();
  }

  static bool hasKhmerCharacters(String str) {
    for (int i = 0; i < str.length; i++) {
      final code = str.codeUnitAt(i);
      if (code >= 0x1780 && code <= 0x17FF) return true;
    }
    return false;
  }

  /// Resolves a deterministic, stable theme (icon & background color) for an application
  /// so that its appearance remains consistent across HomeView, ApplicationView, and when filtering/searching.
  static Map<String, dynamic> resolveAppTheme(Map<String, dynamic> item) {
    if (item['iconBg'] is Color && item['fallbackIcon'] is IconData) {
      return {
        'bg': item['iconBg'] as Color,
        'icon': item['fallbackIcon'] as IconData,
      };
    }

    final String code = (item['code'] ?? '').toString().toUpperCase().trim();
    final String id = (item['id'] ?? '').toString().toUpperCase().trim();
    final String titleKh = (item['titleKh'] ?? item['nameKh'] ?? item['name'] ?? '').toString().toLowerCase();
    final String titleEn = (item['titleEn'] ?? item['nameEn'] ?? item['title'] ?? '').toString().toLowerCase();
    final String dept = (item['department'] ?? item['departmentName'] ?? item['unit'] ?? '').toString().toUpperCase();

    // 1. Complaint System (Blue / Chat bubble)
    if (code.contains('COMPLAINT') || id.contains('COMPLAINT') || titleKh.contains('បណ្តឹង') || titleEn.contains('complaint')) {
      return {
        'bg': const Color(0xFF1E60D5),
        'icon': Icons.chat_bubble_outline_rounded,
      };
    }

    // 2. Single Window Portal / OWSO (Green / Login)
    if (code.contains('OWSO') || code.contains('SINGLE_WINDOW') || id.contains('SINGLE_WINDOW') || id.contains('OWSO') || titleKh.contains('ច្រកចេញចូល') || titleEn.contains('single window')) {
      return {
        'bg': const Color(0xFF107C41),
        'icon': Icons.login_rounded,
      };
    }

    // 3. ANPR / Vehicle / Gate Access (Teal / Car)
    if (code.contains('ANPR') || id.contains('ANPR') || titleKh.contains('ចេញចូលទីស្តីការ') || titleKh.contains('ចេញចូល') || titleEn.contains('anpr') || titleEn.contains('access')) {
      return {
        'bg': const Color(0xFF0F766E),
        'icon': Icons.directions_car_rounded,
      };
    }

    // 4. Prison / GDP (Amber Brown / Shield)
    if (code.contains('PRISON') || code.contains('GDP') || id.contains('PRISON') || dept.contains('GDP') || titleKh.contains('ពន្ធនាគារ') || titleEn.contains('prison')) {
      return {
        'bg': const Color(0xFFB45309),
        'icon': Icons.shield_rounded,
      };
    }

    // 5. Immigration / GDI (Royal Blue / Flight)
    if (code.contains('IMMIGRATION') || code.contains('GDI') || dept.contains('GDI') || titleKh.contains('អន្តោប្រវេសន៍') || titleEn.contains('immigration')) {
      return {
        'bg': const Color(0xFF2563EB),
        'icon': Icons.flight_takeoff_rounded,
      };
    }

    // 6. National Police / GNP (Navy Blue / Police)
    if (code.contains('POLICE') || code.contains('GNP') || dept.contains('GNP') || titleKh.contains('នគរបាល') || titleEn.contains('police')) {
      return {
        'bg': const Color(0xFF1E3A8A),
        'icon': Icons.local_police_rounded,
      };
    }

    // 7. Residence / TMS (Amber / Home)
    if (code.contains('RESIDENCE') || code.contains('TMS') || id.contains('RESIDENCE') || titleKh.contains('ស្នាក់នៅ') || titleEn.contains('residence')) {
      return {
        'bg': const Color(0xFFD97706),
        'icon': Icons.home_rounded,
      };
    }

    // 8. HR / Attendance / Personnel (Slate / People)
    if (code.contains('HR') || code.contains('AMS') || id.contains('HR') || titleKh.contains('បុគ្គលិក') || titleKh.contains('វត្តមាន') || titleEn.contains('hr') || titleEn.contains('attendance')) {
      return {
        'bg': const Color(0xFF1E293B),
        'icon': Icons.people_alt_rounded,
      };
    }

    // 9. Statistics / Analytics (Blue / Bar Chart)
    if (code.contains('STAT') || id.contains('STAT') || titleKh.contains('ស្ថិតិ') || titleEn.contains('stat')) {
      return {
        'bg': const Color(0xFF2563EB),
        'icon': Icons.bar_chart_rounded,
      };
    }

    // 10. Finance / Accounting (Burgundy / Wallet)
    if (code.contains('FINANCE') || id.contains('FINANCE') || titleKh.contains('ហិរញ្ញវត្ថុ') || titleKh.contains('គណនេយ្យ') || titleEn.contains('finance')) {
      return {
        'bg': const Color(0xFF9E2A2B),
        'icon': Icons.account_balance_wallet_rounded,
      };
    }

    // 11. Document / Archives (Green / Description)
    if (code.contains('DOC') || code.contains('DMS') || id.contains('DOC') || titleKh.contains('ឯកសារ') || titleEn.contains('doc')) {
      return {
        'bg': const Color(0xFF107C41),
        'icon': Icons.description_rounded,
      };
    }

    // 12. Google Map (Red / Map)
    if (code.contains('GOOGLE_MAP') || titleKh.contains('ផែនទី') || titleEn.contains('map')) {
      return {
        'bg': const Color(0xFFEA4335),
        'icon': Icons.map_rounded,
      };
    }

    // 13. Google Calendar / Calendar (Blue / Calendar)
    if (code.contains('CALENDAR') || titleKh.contains('ប្រតិទិន') || titleEn.contains('calendar')) {
      return {
        'bg': const Color(0xFF4285F4),
        'icon': Icons.calendar_today_rounded,
      };
    }

    // 14. Certificate / Letter Request (Purple / Verified)
    if (code.contains('CERT') || id.contains('CERT') || titleKh.contains('លិខិត') || titleEn.contains('cert')) {
      return {
        'bg': const Color(0xFF6D28D9),
        'icon': Icons.verified_user_rounded,
      };
    }

    // 15. Security (Amber Brown / Security)
    if (code.contains('SECURITY') || id.contains('SECURITY') || titleKh.contains('សន្តិសុខ') || titleEn.contains('security')) {
      return {
        'bg': const Color(0xFFB45309),
        'icon': Icons.security_rounded,
      };
    }

    // Stable deterministic fallback based on identifier hash
    final String key = (item['id'] ?? item['code'] ?? item['titleKh'] ?? item['titleEn'] ?? 'app').toString();
    final int hash = key.codeUnits.fold<int>(0, (prev, elem) => prev + elem);
    const fallbackThemes = [
      {'bg': Color(0xFF1E293B), 'icon': Icons.apps_rounded},
      {'bg': Color(0xFF107C41), 'icon': Icons.description_rounded},
      {'bg': Color(0xFF2563EB), 'icon': Icons.bar_chart_rounded},
      {'bg': Color(0xFFD97706), 'icon': Icons.security_rounded},
      {'bg': Color(0xFF9E2A2B), 'icon': Icons.account_balance_wallet_rounded},
      {'bg': Color(0xFF6D28D9), 'icon': Icons.verified_user_rounded},
      {'bg': Color(0xFF0F766E), 'icon': Icons.badge_rounded},
    ];
    return fallbackThemes[hash.abs() % fallbackThemes.length];
  }

  static String resolveAppTitle(Map<String, dynamic> item, bool isKh) {
    final String rawTitleKh = (item['titleKh'] ?? item['nameKh'] ?? '').toString().trim();
    final String rawTitleEn = (item['titleEn'] ?? item['nameEn'] ?? '').toString().trim();
    final String rawTitle = (item['title'] ?? item['name'] ?? '').toString().trim();
    final String rawId = (item['id'] ?? '').toString().trim();
    final String rawCode = (item['code'] ?? '').toString().trim();

    final String lookupKey = (rawTitleKh.isNotEmpty
            ? rawTitleKh
            : (rawTitle.isNotEmpty ? rawTitle : rawTitleEn))
        .replaceAll('\n', ' ')
        .trim();
    final String upperCode = rawCode.toUpperCase();
    final String upperId = rawId.toUpperCase();

    // Comprehensive Khmer to English dictionary for Ministry of Interior
    final Map<String, String> khmerToEnglish = {
      'ប្រព័ន្ធទទួលពាក្យបណ្តឹងអនឡាញ': 'Online Complaint System',
      'ប្រព័ន្ធទទួលពាក្យបណ្តឹង អនឡាញ': 'Online Complaint System',
      'ប្រព័ន្ធទទួលពាក្យ បណ្តឹងអនឡាញ': 'Online Complaint System',
      'ប្រព័ន្ធច្រកចេញចូលតែមួយ': 'Single Window Portal',
      'ប្រព័ន្ធច្រកចេញ ចូលតែមួយ': 'Single Window Portal',
      'ប្រព័ន្ធច្រកចេញ-ចូលតែមួយ': 'Single Window Portal',
      'ប្រព័ន្ធស្នើសុំចេញលិខិតស្គាល់': 'ID Letter Request System',
      'ប្រព័ន្ធស្នើសុំចេញលិខិត ស្គាល់': 'ID Letter Request System',
      'ប្រព័ន្ធស្នើសុំលិខិតស្គាល់': 'ID Letter Request System',
      'ប្រព័ន្ធគ្រប់គ្រងឯកសារ': 'Document Management System',
      'ប្រព័ន្ធគ្រប់គ្រងស្នាក់នៅ': 'Residence Management System',
      'ប្រព័ន្ធគ្រប់គ្រងការស្នាក់នៅ': 'Residence Management System',
      'ប្រព័ន្ធគ្រប់គ្រងវត្តមានជនបរទេស': 'Foreigners Present System (FPCS)',
      'ប្រព័ន្ធគ្រប់គ្រងវត្តមានជនបរទេសនៅកម្ពុជា': 'Foreigners Present System (FPCS)',
      'ប្រព័ន្ធគ្រប់គ្រងបុគ្គលិក': 'HR Management System',
      'ប្រព័ន្ធគ្រប់គ្រងធនធានមនុស្ស': 'HR Management System',
      'ប្រព័ន្ធគ្រប់គ្រងឯកសារប័ណ្ណសារ': 'Document Archive System',
      'ប្រព័ន្ធគ្រប់គ្រងប័ណ្ណសារ': 'Document Archive System',
      'ប្រព័ន្ធស្ថិតិ': 'Statistics System',
      'ប្រព័ន្ធហិរញ្ញវត្ថុ': 'Financial System',
      'ប្រព័ន្ធសន្តិសុខ': 'Security System',
      'ប្រព័ន្ធស្នើសុំចេញចូលទីស្តីការក្រសួងមហាផ្ទៃ': 'MOI Access Request System',
      'ប្រព័ន្ធស្នើរសុំចេញចូលទីស្តីការក្រសួងមហាផ្ទៃ': 'MOI Access Request System',
      'ប្រព័ន្ធស្នើសុំចេញចូលទីស្តីការ': 'MOI Access Request System',
      'ប្រព័ន្ធស្នើរសុំចេញចូលទីស្តីការ': 'MOI Access Request System',
      'ប្រព័ន្ធស្វ័យប្រវត្តិកម្មអត្តសញ្ញាណប័ណ្ណ': 'Automated ID Card System',
      'ប្រព័ន្ធគ្រប់គ្រងអត្តសញ្ញាណកម្ម': 'Identification System',
      'ប្រព័ន្ធគ្រប់គ្រងវត្តមាន': 'Attendance System',
      'ប្រព័ន្ធវត្តមាន': 'Attendance System',
      'ប្រព័ន្ធផ្ទៀងផ្ទាត់': 'Verification System',
      'ប្រព័ន្ធរដ្ឋបាល': 'Administration System',
      'ប្រព័ន្ធគ្រប់គ្រងយានយន្ត': 'Vehicle Management System',
      'ប្រព័ន្ធគ្រប់គ្រងទ្រព្យសម្បត្តិ': 'Asset Management System',
      'ប្រព័ន្ធផ្លាស់ប្តូរទិន្នន័យ': 'Data Exchange System',
      'ប្រព័ន្ធតាមដានគម្រោង': 'Project Tracking System',
      'ប្រព័ន្ធព័ត៌មានវិទ្យា': 'IT Information System',
      'ប្រព័ន្ធគ្រប់គ្រងពន្ធនាគារ': 'Prison Management System',
      'ប្រព័ន្ធពន្ធនាគារ': 'Prison Management System',
      'ប្រតិទិនការងារ': 'Work Calendar',
      'ប្រតិទិន': 'Work Calendar',
      'ប្រព័ន្ធគ្រប់គ្រងអន្តោប្រវេសន៍': 'Immigration System',
      'ប្រព័ន្ធអន្តោប្រវេសន៍': 'Immigration System',
      'ប្រព័ន្ធនគរបាលជាតិ': 'National Police System',
      'ប្រព័ន្ធសវនកម្មផ្ទៃក្នុង': 'Internal Audit System',
      'ប្រព័ន្ធសវនកម្ម': 'Internal Audit System',
      'ប្រព័ន្ធអធិការកិច្ច': 'Inspection System',
      'ប្រព័ន្ធភស្តុភារ': 'Logistics System',
      'ប្រព័ន្ធបណ្តុះបណ្តាល': 'Training System',
      'ប្រព័ន្ធគ្រប់គ្រងឃ្លាំង': 'Warehouse Management System',
      'ប្រព័ន្ធគ្រប់គ្រងប័ណ្ណបើកបរ': 'Driving License System',
      'ប្រព័ន្ធចុះបញ្ជីអត្រានុកូលដ្ឋាន': 'Civil Registration System',
      'ប្រព័ន្ធអត្រានុកូលដ្ឋាន': 'Civil Registration System',
      'ប្រព័ន្ធលិខិតឆ្លងដែន': 'Passport System',
      'ប្រព័ន្ធសេវាសាធារណៈ': 'Public Service Portal',
      'ប្រព័ន្ធទំនាក់ទំនង': 'Communication System',
      'ប្រព័ន្ធតាមដានឯកសារ': 'Document Tracking System',
      'ប្រព័ន្ធគណៈរដ្ឋមន្ត្រី': 'E-Cabinet System',
      'ប្រព័ន្ធសុវត្ថិភាពចរាចរណ៍': 'Traffic Safety System',
      'ប្រព័ន្ធចរាចរណ៍': 'Traffic Management System',
      'ប្រព័ន្ធកិច្ចការច្បាប់': 'Legal Affairs System',
      'ការងារទូទៅ': 'General Work System',
      'កម្មវិធីទូទៅ': 'General Application',
      'ប្រព័ន្ធរបាយការណ៍': 'Reporting System',
      'ប្រព័ន្ធគ្រប់គ្រងច្រកទ្វារព្រំដែន (EES)': 'Entry-Exit System (EES)',
      'ប្រព័ន្ធគ្រប់គ្រងច្រកទ្វារព្រំដែន': 'Border Gate Management System (EES)',
      'Google Map': 'Google Map',
      'Google Calendar': 'Google Calendar',
    };

    // English to Khmer dictionary
    final Map<String, String> englishToKhmer = {
      'Online Complaint System': 'ប្រព័ន្ធទទួលពាក្យបណ្តឹងអនឡាញ',
      'Single Window Portal': 'ប្រព័ន្ធច្រកចេញចូលតែមួយ',
      'ID Letter Request System': 'ប្រព័ន្ធស្នើសុំចេញលិខិតស្គាល់',
      'Document Management System': 'ប្រព័ន្ធគ្រប់គ្រងឯកសារ',
      'Document Management': 'ប្រព័ន្ធគ្រប់គ្រងឯកសារ',
      'Residence Management System': 'ប្រព័ន្ធគ្រប់គ្រងស្នាក់នៅ',
      'Residence Management': 'ប្រព័ន្ធគ្រប់គ្រងស្នាក់នៅ',
      'Foreigners Present System (FPCS)': 'ប្រព័ន្ធគ្រប់គ្រងវត្តមានជនបរទេស (FPCS)',
      'Foreigners Present System': 'ប្រព័ន្ធគ្រប់គ្រងវត្តមានជនបរទេស',
      'HR Management System': 'ប្រព័ន្ធគ្រប់គ្រងបុគ្គលិក',
      'HR Management': 'ប្រព័ន្ធគ្រប់គ្រងបុគ្គលិក',
      'Personnel Management': 'ប្រព័ន្ធគ្រប់គ្រងបុគ្គលិក',
      'Document Archive System': 'ប្រព័ន្ធគ្រប់គ្រងឯកសារប័ណ្ណសារ',
      'Document Archive': 'ប្រព័ន្ធគ្រប់គ្រងឯកសារប័ណ្ណសារ',
      'Statistics System': 'ប្រព័ន្ធស្ថិតិ',
      'Financial System': 'ប្រព័ន្ធហិរញ្ញវត្ថុ',
      'Finance System': 'ប្រព័ន្ធហិរញ្ញវត្ថុ',
      'Security System': 'ប្រព័ន្ធសន្តិសុខ',
      'MOI Access Request System': 'ប្រព័ន្ធស្នើសុំចេញចូលទីស្តីការក្រសួងមហាផ្ទៃ',
      'ANPR Access System': 'ប្រព័ន្ធស្នើសុំចេញចូលទីស្តីការក្រសួងមហាផ្ទៃ',
      'Automated ID Card System': 'ប្រព័ន្ធស្វ័យប្រវត្តិកម្មអត្តសញ្ញាណប័ណ្ណ',
      'Identification System': 'ប្រព័ន្ធគ្រប់គ្រងអត្តសញ្ញាណកម្ម',
      'Attendance System': 'ប្រព័ន្ធគ្រប់គ្រងវត្តមាន',
      'Attendance Management System': 'ប្រព័ន្ធគ្រប់គ្រងវត្តមាន',
      'Verification System': 'ប្រព័ន្ធផ្ទៀងផ្ទាត់',
      'Administration System': 'ប្រព័ន្ធរដ្ឋបាល',
      'Vehicle Management System': 'ប្រព័ន្ធគ្រប់គ្រងយានយន្ត',
      'Asset Management System': 'ប្រព័ន្ធគ្រប់គ្រងទ្រព្យសម្បត្តិ',
      'Data Exchange System': 'ប្រព័ន្ធផ្លាស់ប្តូរទិន្នន័យ',
      'Project Tracking System': 'ប្រព័ន្ធតាមដានគម្រោង',
      'IT Information System': 'ប្រព័ន្ធព័ត៌មានវិទ្យា',
      'Prison Management System': 'ប្រព័ន្ធគ្រប់គ្រងពន្ធនាគារ',
      'Work Calendar': 'ប្រតិទិនការងារ',
      'Calendar System': 'ប្រតិទិនការងារ',
      'Calendar': 'ប្រតិទិនការងារ',
      'Immigration System': 'ប្រព័ន្ធគ្រប់គ្រងអន្តោប្រវេសន៍',
      'Immigration Management System': 'ប្រព័ន្ធគ្រប់គ្រងអន្តោប្រវេសន៍',
      'National Police System': 'ប្រព័ន្ធនគរបាលជាតិ',
      'Internal Audit System': 'ប្រព័ន្ធសវនកម្មផ្ទៃក្នុង',
      'Inspection System': 'ប្រព័ន្ធអធិការកិច្ច',
      'Logistics System': 'ប្រព័ន្ធភស្តុភារ',
      'Training System': 'ប្រព័ន្ធបណ្តុះបណ្តាល',
      'Warehouse Management System': 'ប្រព័ន្ធគ្រប់គ្រងឃ្លាំង',
      'Driving License System': 'ប្រព័ន្ធគ្រប់គ្រងប័ណ្ណបើកបរ',
      'Civil Registration System': 'ប្រព័ន្ធចុះបញ្ជីអត្រានុកូលដ្ឋាន',
      'Passport System': 'ប្រព័ន្ធលិខិតឆ្លងដែន',
      'Public Service Portal': 'ប្រព័ន្ធសេវាសាធារណៈ',
      'Public Services Portal': 'ប្រព័ន្ធសេវាសាធារណៈ',
      'Communication System': 'ប្រព័ន្ធទំនាក់ទំនង',
      'Document Tracking System': 'ប្រព័ន្ធតាមដានឯកសារ',
      'E-Cabinet System': 'ប្រព័ន្ធគណៈរដ្ឋមន្ត្រី',
      'Traffic Safety System': 'ប្រព័ន្ធសុវត្ថិភាពចរាចរណ៍',
      'Traffic Management System': 'ប្រព័ន្ធគ្រប់គ្រងចរាចរណ៍',
      'Legal Affairs System': 'ប្រព័ន្ធកិច្ចការច្បាប់',
      'General Work System': 'ការងារទូទៅ',
      'General Application': 'កម្មវិធីទូទៅ',
      'Reporting System': 'ប្រព័ន្ធរបាយការណ៍',
      'Border Gate Management System (EES)': 'ប្រព័ន្ធគ្រប់គ្រងច្រកទ្វារព្រំដែន (EES)',
      'Entry-Exit System (EES)': 'ប្រព័ន្ធគ្រប់គ្រងច្រកទ្វារព្រំដែន (EES)',
      'Google Map': 'ផែនទី Google',
      'Google Calendar': 'ប្រតិទិន Google',
    };

    // Code & Acronym Map
    final Map<String, Map<String, String>> codeMap = {
      'ANPR': {
        'km': 'ប្រព័ន្ធស្នើសុំចេញចូលទីស្តីការក្រសួងមហាផ្ទៃ',
        'en': 'MOI Access Request System',
      },
      'GDDTM_ANPR': {
        'km': 'ប្រព័ន្ធស្នើសុំចេញចូលទីស្តីការក្រសួងមហាផ្ទៃ',
        'en': 'MOI Access Request System',
      },
      'COMPLAINT': {
        'km': 'ប្រព័ន្ធទទួលពាក្យបណ្តឹងអនឡាញ',
        'en': 'Online Complaint System',
      },
      'COMPLAINTS': {
        'km': 'ប្រព័ន្ធទទួលពាក្យបណ្តឹងអនឡាញ',
        'en': 'Online Complaint System',
      },
      'COMPLAINT_SYSTEM': {
        'km': 'ប្រព័ន្ធទទួលពាក្យបណ្តឹងអនឡាញ',
        'en': 'Online Complaint System',
      },
      'OWSO': {
        'km': 'ប្រព័ន្ធច្រកចេញចូលតែមួយ',
        'en': 'Single Window Portal',
      },
      'SINGLE_WINDOW': {
        'km': 'ប្រព័ន្ធច្រកចេញចូលតែមួយ',
        'en': 'Single Window Portal',
      },
      'CERT_REQUEST': {
        'km': 'ប្រព័ន្ធស្នើសុំចេញលិខិតស្គាល់',
        'en': 'ID Letter Request System',
      },
      'CERT_REQUEST_SYSTEM': {
        'km': 'ប្រព័ន្ធស្នើសុំចេញលិខិតស្គាល់',
        'en': 'ID Letter Request System',
      },
      'DOC': {
        'km': 'ប្រព័ន្ធគ្រប់គ្រងឯកសារ',
        'en': 'Document Management System',
      },
      'DOCUMENT': {
        'km': 'ប្រព័ន្ធគ្រប់គ្រងឯកសារ',
        'en': 'Document Management System',
      },
      'DOC_SYSTEM': {
        'km': 'ប្រព័ន្ធគ្រប់គ្រងឯកសារ',
        'en': 'Document Management System',
      },
      'DMS': {
        'km': 'ប្រព័ន្ធគ្រប់គ្រងឯកសារ',
        'en': 'Document Management System',
      },
      'G_DMS': {
        'km': 'ប្រព័ន្ធគ្រប់គ្រងឯកសារ',
        'en': 'Document Management System',
      },
      'RESIDENCE': {
        'km': 'ប្រព័ន្ធគ្រប់គ្រងស្នាក់នៅ',
        'en': 'Residence Management System',
      },
      'RESIDENCE_SYSTEM': {
        'km': 'ប្រព័ន្ធគ្រប់គ្រងស្នាក់នៅ',
        'en': 'Residence Management System',
      },
      'TMS': {
        'km': 'ប្រព័ន្ធគ្រប់គ្រងស្នាក់នៅ',
        'en': 'Residence Management System',
      },
      'FPCS': {
        'km': 'ប្រព័ន្ធគ្រប់គ្រងវត្តមានជនបរទេស (FPCS)',
        'en': 'Foreigners Present System (FPCS)',
      },
      'HR': {
        'km': 'ប្រព័ន្ធគ្រប់គ្រងបុគ្គលិក',
        'en': 'HR Management System',
      },
      'HRMS': {
        'km': 'ប្រព័ន្ធគ្រប់គ្រងបុគ្គលិក',
        'en': 'HR Management System',
      },
      'HR_SYSTEM': {
        'km': 'ប្រព័ន្ធគ្រប់គ្រងបុគ្គលិក',
        'en': 'HR Management System',
      },
      'DOC_ARCHIVE': {
        'km': 'ប្រព័ន្ធគ្រប់គ្រងឯកសារប័ណ្ណសារ',
        'en': 'Document Archive System',
      },
      'DOC_ARCHIVE_SYSTEM': {
        'km': 'ប្រព័ន្ធគ្រប់គ្រងឯកសារប័ណ្ណសារ',
        'en': 'Document Archive System',
      },
      'STAT': {
        'km': 'ប្រព័ន្ធស្ថិតិ',
        'en': 'Statistics System',
      },
      'STATISTICS': {
        'km': 'ប្រព័ន្ធស្ថិតិ',
        'en': 'Statistics System',
      },
      'STAT_SYSTEM': {
        'km': 'ប្រព័ន្ធស្ថិតិ',
        'en': 'Statistics System',
      },
      'FINANCE': {
        'km': 'ប្រព័ន្ធហិរញ្ញវត្ថុ',
        'en': 'Financial System',
      },
      'FINANCIAL': {
        'km': 'ប្រព័ន្ធហិរញ្ញវត្ថុ',
        'en': 'Financial System',
      },
      'FINANCE_SYSTEM': {
        'km': 'ប្រព័ន្ធហិរញ្ញវត្ថុ',
        'en': 'Financial System',
      },
      'SECURITY': {
        'km': 'ប្រព័ន្ធសន្តិសុខ',
        'en': 'Security System',
      },
      'SECURITY_SYSTEM': {
        'km': 'ប្រព័ន្ធសន្តិសុខ',
        'en': 'Security System',
      },
      'EES': {
        'km': 'ប្រព័ន្ធគ្រប់គ្រងច្រកទ្វារព្រំដែន (EES)',
        'en': 'Entry-Exit System (EES)',
      },
      'GDP_PRISONS': {
        'km': 'ប្រព័ន្ធគ្រប់គ្រងពន្ធនាគារ',
        'en': 'Prison Management System',
      },
      'PRISONS': {
        'km': 'ប្រព័ន្ធគ្រប់គ្រងពន្ធនាគារ',
        'en': 'Prison Management System',
      },
      'PRISON': {
        'km': 'ប្រព័ន្ធគ្រប់គ្រងពន្ធនាគារ',
        'en': 'Prison Management System',
      },
      'PMS': {
        'km': 'ប្រព័ន្ធគ្រប់គ្រងពន្ធនាគារ',
        'en': 'Prison Management System',
      },
      'CALENDAR': {
        'km': 'ប្រតិទិនការងារ',
        'en': 'Work Calendar',
      },
      'WORK_CALENDAR': {
        'km': 'ប្រតិទិនការងារ',
        'en': 'Work Calendar',
      },
      'AMS': {
        'km': 'ប្រព័ន្ធគ្រប់គ្រងវត្តមាន',
        'en': 'Attendance System',
      },
      'ATTENDANCE': {
        'km': 'ប្រព័ន្ធគ្រប់គ្រងវត្តមាន',
        'en': 'Attendance System',
      },
      'VMS': {
        'km': 'ប្រព័ន្ធគ្រប់គ្រងយានយន្ត',
        'en': 'Vehicle Management System',
      },
      'VEHICLE': {
        'km': 'ប្រព័ន្ធគ្រប់គ្រងយានយន្ត',
        'en': 'Vehicle Management System',
      },
      'IMMIGRATION': {
        'km': 'ប្រព័ន្ធគ្រប់គ្រងអន្តោប្រវេសន៍',
        'en': 'Immigration System',
      },
      'GDI': {
        'km': 'ប្រព័ន្ធគ្រប់គ្រងអន្តោប្រវេសន៍',
        'en': 'Immigration System',
      },
      'POLICE': {
        'km': 'ប្រព័ន្ធនគរបាលជាតិ',
        'en': 'National Police System',
      },
      'GNP': {
        'km': 'ប្រព័ន្ធនគរបាលជាតិ',
        'en': 'National Police System',
      },
      'AUDIT': {
        'km': 'ប្រព័ន្ធសវនកម្មផ្ទៃក្នុង',
        'en': 'Internal Audit System',
      },
      'GIA': {
        'km': 'ប្រព័ន្ធសវនកម្មផ្ទៃក្នុង',
        'en': 'Internal Audit System',
      },
      'INSPECTION': {
        'km': 'ប្រព័ន្ធអធិការកិច្ច',
        'en': 'Inspection System',
      },
      'GI': {
        'km': 'ប្រព័ន្ធអធិការកិច្ច',
        'en': 'Inspection System',
      },
      'LOGISTICS': {
        'km': 'ប្រព័ន្ធភស្តុភារ',
        'en': 'Logistics System',
      },
      'GLF': {
        'km': 'ប្រព័ន្ធភស្តុភារ និងហិរញ្ញវត្ថុ',
        'en': 'Logistics & Finance System',
      },
      'TRAINING': {
        'km': 'ប្រព័ន្ធបណ្តុះបណ្តាល',
        'en': 'Training System',
      },
      'CRVS': {
        'km': 'ប្រព័ន្ធចុះបញ្ជីអត្រានុកូលដ្ឋាន',
        'en': 'Civil Registration System',
      },
      'PASSPORT': {
        'km': 'ប្រព័ន្ធលិខិតឆ្លងដែន',
        'en': 'Passport System',
      },
      'CABINET': {
        'km': 'ប្រព័ន្ធគណៈរដ្ឋមន្ត្រី',
        'en': 'E-Cabinet System',
      },
      'GOOGLE_MAP': {
        'km': 'ផែនទី Google',
        'en': 'Google Map',
      },
      'GOOGLE_CALENDAR': {
        'km': 'ប្រតិទិន Google',
        'en': 'Google Calendar',
      },
    };

    if (isKh) {
      if (rawTitleKh.isNotEmpty && hasKhmerCharacters(rawTitleKh)) {
        return rawTitleKh;
      }
      if (rawTitle.isNotEmpty && hasKhmerCharacters(rawTitle)) {
        return rawTitle;
      }
      if (englishToKhmer.containsKey(rawTitleEn)) {
        return englishToKhmer[rawTitleEn]!;
      }
      if (englishToKhmer.containsKey(rawTitle)) {
        return englishToKhmer[rawTitle]!;
      }
      for (var entry in englishToKhmer.entries) {
        if (lookupKey.toLowerCase() == entry.key.toLowerCase() ||
            rawTitleEn.toLowerCase() == entry.key.toLowerCase() ||
            rawTitle.toLowerCase() == entry.key.toLowerCase()) {
          return entry.value;
        }
      }
      if (codeMap.containsKey(upperCode)) {
        return codeMap[upperCode]!['km']!;
      }
      if (codeMap.containsKey(upperId)) {
        return codeMap[upperId]!['km']!;
      }
      for (var entry in codeMap.entries) {
        if (upperCode.contains(entry.key) || upperId.contains(entry.key)) {
          return entry.value['km']!;
        }
      }
      return rawTitleKh.isNotEmpty
          ? rawTitleKh
          : (rawTitle.isNotEmpty ? rawTitle : (rawTitleEn.isNotEmpty ? rawTitleEn : 'កម្មវិធី'));
    } else {
      if (rawTitleEn.isNotEmpty &&
          !hasKhmerCharacters(rawTitleEn) &&
          rawTitleEn.toLowerCase() != 'app' &&
          rawTitleEn.toLowerCase() != 'application') {
        return rawTitleEn;
      }

      // 1. Direct dictionary match
      if (khmerToEnglish.containsKey(lookupKey)) {
        return khmerToEnglish[lookupKey]!;
      }
      for (var entry in khmerToEnglish.entries) {
        if (lookupKey == entry.key) {
          return entry.value;
        }
      }

      // 2. Acronym extraction (e.g., "(TMS)", "(AMS)", "(EES)", "(ANPR)")
      String suffixAcronym = '';
      final acronymMatch = RegExp(r'\(([A-Za-z0-9_\-]+)\)').firstMatch(lookupKey);
      if (acronymMatch != null) {
        suffixAcronym = ' (${acronymMatch.group(1)})';
      }

      // 3. Substring matching for longer specific dictionary keys
      for (var entry in khmerToEnglish.entries) {
        if (entry.key.length >= 8 && lookupKey.contains(entry.key)) {
          if (suffixAcronym.isNotEmpty && !entry.value.contains('(')) {
            return '${entry.value}$suffixAcronym';
          }
          return entry.value;
        }
      }

      // 4. Keyword / Topic pattern matching with natural English composition
      if (lookupKey.contains('ពន្ធនាគារ')) return 'Prison Management System$suffixAcronym';
      if (lookupKey.contains('ពាក្យបណ្តឹង')) return 'Online Complaint System$suffixAcronym';
      if (lookupKey.contains('ច្រកចេញ') || lookupKey.contains('តែមួយ')) return 'Single Window Portal$suffixAcronym';
      if (lookupKey.contains('លិខិតស្គាល់') || lookupKey.contains('លិខិតបញ្ជាក់')) return 'ID Letter Request System$suffixAcronym';
      if (lookupKey.contains('ជនបរទេស')) return 'Foreigners Present System (FPCS)';
      if (lookupKey.contains('ប័ណ្ណសារ')) return 'Document Archive System$suffixAcronym';
      if (lookupKey.contains('តាមដានឯកសារ')) return 'Document Tracking System$suffixAcronym';
      if (lookupKey.contains('ឯកសារ')) return 'Document Management System$suffixAcronym';
      if (lookupKey.contains('ស្នាក់នៅ')) return 'Residence Management System$suffixAcronym';
      if (lookupKey.contains('បុគ្គលិក') || lookupKey.contains('ធនធានមនុស្ស')) return 'HR Management System$suffixAcronym';
      if (lookupKey.contains('ស្ថិតិ')) return 'Statistics System$suffixAcronym';
      if (lookupKey.contains('ហិរញ្ញវត្ថុ')) return 'Financial System$suffixAcronym';
      if (lookupKey.contains('សន្តិសុខ')) return 'Security System$suffixAcronym';
      if (lookupKey.contains('ចេញចូល') || lookupKey.contains('ទីស្តីការ')) return 'MOI Access Request System$suffixAcronym';
      if (lookupKey.contains('អត្តសញ្ញាណ')) return 'Automated ID Card System$suffixAcronym';
      if (lookupKey.contains('អន្តោប្រវេសន៍')) return 'Immigration System$suffixAcronym';
      if (lookupKey.contains('នគរបាល')) return 'National Police System$suffixAcronym';
      if (lookupKey.contains('សវនកម្ម')) return 'Internal Audit System$suffixAcronym';
      if (lookupKey.contains('អធិការកិច្ច')) return 'Inspection System$suffixAcronym';
      if (lookupKey.contains('វត្តមាន')) return 'Attendance System$suffixAcronym';
      if (lookupKey.contains('យានយន្ត')) return 'Vehicle Management System$suffixAcronym';
      if (lookupKey.contains('ទ្រព្យសម្បត្តិ')) return 'Asset Management System$suffixAcronym';
      if (lookupKey.contains('រដ្ឋបាល')) return 'Administration System$suffixAcronym';
      if (lookupKey.contains('ផ្ទៀងផ្ទាត់')) return 'Verification System$suffixAcronym';
      if (lookupKey.contains('គម្រោង')) return 'Project Tracking System$suffixAcronym';
      if (lookupKey.contains('ព័ត៌មានវិទ្យា') || lookupKey.contains('បច្ចេកវិទ្យា')) return 'IT Information System$suffixAcronym';
      if (lookupKey.contains('ទិន្នន័យ')) return 'Data Exchange System$suffixAcronym';
      if (lookupKey.contains('ប្រតិទិន')) return 'Work Calendar';
      if (lookupKey.contains('ភស្តុភារ')) return 'Logistics System$suffixAcronym';
      if (lookupKey.contains('បណ្តុះបណ្តាល')) return 'Training System$suffixAcronym';
      if (lookupKey.contains('សេវាសាធារណៈ')) return 'Public Service Portal$suffixAcronym';
      if (lookupKey.contains('អត្រានុកូលដ្ឋាន')) return 'Civil Registration System$suffixAcronym';
      if (lookupKey.contains('លិខិតឆ្លងដែន')) return 'Passport System$suffixAcronym';
      if (lookupKey.contains('គណៈរដ្ឋមន្ត្រី')) return 'E-Cabinet System$suffixAcronym';
      if (lookupKey.contains('ច្រកទ្វារ') || lookupKey.contains('ព្រំដែន')) return 'Border Gate Management System (EES)';
      if (lookupKey.contains('ចរាចរណ៍')) return 'Traffic Safety System$suffixAcronym';
      if (lookupKey.contains('ការងារទូទៅ') || lookupKey.contains('ការងារ')) return 'General Work System';
      if (lookupKey.contains('កិច្ចការច្បាប់') || lookupKey.contains('នីតិកម្ម')) return 'Legal Affairs System$suffixAcronym';
      if (lookupKey.contains('ផ្សព្វផ្សាយ')) return 'Media & News Portal$suffixAcronym';
      if (lookupKey.contains('ស្វ័យប្រវត្តិកម្ម')) return 'Automation System$suffixAcronym';
      if (lookupKey.contains('របាយការណ៍')) return 'Reporting System$suffixAcronym';
      if (lookupKey.contains('កិច្ចប្រជុំ') || lookupKey.contains('ប្រជុំ')) return 'Meeting System$suffixAcronym';
      if (lookupKey.contains('ឃ្លាំង')) return 'Warehouse Management System$suffixAcronym';
      if (lookupKey.contains('ប័ណ្ណបើកបរ')) return 'Driving License System$suffixAcronym';
      if (lookupKey.contains('Google Map')) return 'Google Map';
      if (lookupKey.contains('Google Calendar')) return 'Google Calendar';

      // 5. Code map lookup
      if (codeMap.containsKey(upperCode)) {
        return codeMap[upperCode]!['en']!;
      }
      if (codeMap.containsKey(upperId)) {
        return codeMap[upperId]!['en']!;
      }
      for (var entry in codeMap.entries) {
        if (upperCode == entry.key ||
            upperCode.startsWith('${entry.key}_') ||
            upperCode.startsWith('${entry.key}-') ||
            upperCode.endsWith('_${entry.key}') ||
            upperId == entry.key ||
            upperId.startsWith('${entry.key}_') ||
            upperId.startsWith('${entry.key}-')) {
          return entry.value['en']!;
        }
      }

      if (rawTitle.isNotEmpty && !hasKhmerCharacters(rawTitle)) {
        return rawTitle;
      }
      if (rawTitleEn.isNotEmpty && !hasKhmerCharacters(rawTitleEn)) {
        return rawTitleEn;
      }
      return 'Application';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFFFAF9F6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Top Government Portal Header
            PortalTopAppBar(canPop: canPop),

            // Scrollable Body
            Expanded(
                child: RefreshIndicator(
                  onRefresh: controller.refreshApps,
                  color: AppColors.royalGold,
                  backgroundColor: Colors.white,
                  displacement: 24,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 14),

                          // 2. Screen Title: | កម្មវិធីទាំងអស់
                          _buildScreenTitle(),
                          const SizedBox(height: 14),

                          // 3. Segmented Filter Tabs: ទាំងអស់ | ទូទៅ | តាមអង្គភាព
                          _buildFilterTabs(),
                          const SizedBox(height: 14),

                          // 4. Search Bar with Cancel button
                          _buildSearchBar(),
                          const SizedBox(height: 12),

                          // 5. Total Count Row: សរុប X កម្មវិធី
                          _buildCounterRow(),
                          const SizedBox(height: 14),

                          // 6. 2-Column Grid of Application Cards
                          _buildAppsGrid(context),

                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
  }

  // =========================================================================
  // 2. SCREEN TITLE: | កម្មវិធីទាំងអស់
  // =========================================================================
  Widget _buildScreenTitle() {
    return Obx(() {
      final isKh = LocalizationService.currentLanguageCode.value == 'km';
      return Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 3.5,
            height: 24,
            decoration: BoxDecoration(
              color: AppColors.royalGold,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            isKh ? 'កម្មវិធីទាំងអស់' : 'All Applications',
            style: isKh
                ? GoogleFonts.kantumruyPro(
                    fontSize: 18.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1E293B),
                    height: 1.3,
                  )
                : GoogleFonts.poppins(
                    fontSize: 17.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                    height: 1.3,
                  ),
          ),
        ],
      );
    });
  }

  // =========================================================================
  // 3. SEGMENTED FILTER TABS: ទាំងអស់ | ទូទៅ | តាមអង្គភាព
  // =========================================================================
  Widget _buildFilterTabs() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.warmCream,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.warmCreamBorder, width: 1.2),
      ),
      child: Obx(() {
        final currentTab = controller.selectedFilterTab.value;
        final bool isKh = LocalizationService.currentLanguageCode.value == 'km';

        return Row(
          children: [
            Expanded(
              child: _buildSegmentItem(
                label: isKh ? 'ទាំងអស់' : 'All',
                isSelected: currentTab == 'all',
                onTap: () => controller.setFilterTab('all'),
              ),
            ),
            Expanded(
              child: _buildSegmentItem(
                label: isKh ? 'ទូទៅ' : 'General',
                isSelected: currentTab == 'general',
                onTap: () => controller.setFilterTab('general'),
              ),
            ),
            Expanded(
              child: _buildSegmentItem(
                label: isKh ? 'តាមអង្គភាព' : 'By Department',
                isSelected: currentTab == 'department' || currentTab == 'portal',
                onTap: () => controller.setFilterTab('department'),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildSegmentItem({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final bool isKh = LocalizationService.currentLanguageCode.value == 'km';
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: isKh
                ? GoogleFonts.kantumruyPro(
                    fontSize: 13.0,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppColors.royalGold : const Color(0xFF64748B),
                  )
                : GoogleFonts.poppins(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? AppColors.royalGold : const Color(0xFF64748B),
                  ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // 4. SEARCH BAR WITH "បោះបង់" (CANCEL)
  // =========================================================================
  Widget _buildSearchBar() {
    return Obx(() {
      final isKh = LocalizationService.currentLanguageCode.value == 'km';
      return Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              color: AppColors.royalGold,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller.searchController,
                onChanged: (val) {
                  controller.rxSearchQuery.value = val;
                  controller._filterApps();
                },
                style: isKh
                    ? GoogleFonts.kantumruyPro(
                        fontSize: 13.5,
                        color: const Color(0xFF0F172A),
                      )
                    : GoogleFonts.poppins(
                        fontSize: 13.5,
                        color: const Color(0xFF0F172A),
                      ),
                decoration: InputDecoration(
                  hintText: isKh ? 'ស្វែងរកកម្មវិធី' : 'Search applications...',
                  hintStyle: isKh
                      ? GoogleFonts.kantumruyPro(
                          fontSize: 13.5,
                          color: const Color(0xFF94A3B8),
                        )
                      : GoogleFonts.poppins(
                          fontSize: 13.5,
                          color: const Color(0xFF94A3B8),
                        ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                controller.searchController.clear();
                controller.rxSearchQuery.value = '';
                controller._filterApps();
                FocusManager.instance.primaryFocus?.unfocus();
              },
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Text(
                  isKh ? 'បោះបង់' : 'Cancel',
                  style: isKh
                      ? GoogleFonts.kantumruyPro(
                          fontSize: 13.0,
                          fontWeight: FontWeight.bold,
                          color: AppColors.royalGold,
                        )
                      : GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.royalGold,
                        ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // =========================================================================
  // 5. TOTAL COUNT ROW: សរុប X កម្មវិធី
  // =========================================================================
  Widget _buildCounterRow() {
    return Obx(() {
      final items = _getDisplayApps();
      final int count = items.length;
      final bool isKh = LocalizationService.currentLanguageCode.value == 'km';
      final String appWord = isKh
          ? 'កម្មវិធី'
          : (count == 1 ? 'Application' : 'Applications');

      return Align(
        alignment: Alignment.centerRight,
        child: RichText(
          text: TextSpan(
            style: isKh
                ? GoogleFonts.kantumruyPro(
                    fontSize: 12.5,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  )
                : GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: const Color(0xFF64748B),
                    fontWeight: FontWeight.w500,
                  ),
            children: [
              TextSpan(text: isKh ? "សរុប " : "Total "),
              TextSpan(
                text: count.toString(),
                style: isKh
                    ? GoogleFonts.kantumruyPro(
                        fontWeight: FontWeight.bold,
                        color: AppColors.royalGold,
                        fontSize: 13.0,
                      )
                    : GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        color: AppColors.royalGold,
                        fontSize: 13.0,
                      ),
              ),
              TextSpan(
                text: isKh
                    ? " $appWord"
                    : " $appWord",
              ),
            ],
          ),
        ),
      );
    });
  }

  // =========================================================================
  // 6. 2-COLUMN GRID OF APPLICATION CARDS
  // =========================================================================
  Widget _buildAppsGrid(BuildContext context) {
    return Obx(() {
      final bool isKh = LocalizationService.currentLanguageCode.value == 'km';
      if (controller.isLoading.value && controller.sourceApps.isEmpty) {
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: CircularProgressIndicator(
              color: AppColors.royalGold,
              strokeWidth: 2.5,
            ),
          ),
        );
      }

      final displayList = _getDisplayApps();

      if (displayList.isEmpty) {
        final bool isFilter = controller.isSearchOrFilterActive;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: EmptyAppsWidget(
            isSearch: isFilter,
            title: isFilter
                ? (isKh ? 'រកមិនឃើញកម្មវិធីឡើយ' : 'No applications found')
                : (isKh ? 'អត់ទាន់មានកម្មវិធី' : 'No Applications Yet'),
            subtitle: isFilter
                ? (isKh
                    ? 'សូមព្យាយាមស្វែងរកជាមួយពាក្យគន្លឹះ ឬអង្គភាពផ្សេងទៀត'
                    : 'Try searching with different keywords or department')
                : (isKh
                    ? 'មិនទាន់មានកម្មវិធីត្រូវបានដាក់ឱ្យប្រើប្រាស់នៅឡើយទេ'
                    : 'There are no applications available or assigned yet.'),
            actionText: isFilter
                ? (isKh ? 'សម្អាតតម្រង' : 'Clear Filters')
                : (isKh ? 'ផ្ទុកឡើងវិញ' : 'Refresh'),
            onAction: isFilter ? controller.clearFilters : controller.refreshApps,
          ),
        );
      }

      return LayoutBuilder(
        builder: (context, constraints) {
          final double cardWidth = (constraints.maxWidth - 12) / 2;

          // Chunk into rows of 2
          final List<List<Map<String, dynamic>>> rows = [];
          for (var i = 0; i < displayList.length; i += 2) {
            rows.add(
              displayList.sublist(
                i,
                i + 2 > displayList.length ? displayList.length : i + 2,
              ),
            );
          }

          return Column(
            children: List.generate(rows.length, (rowIndex) {
              final rowItems = rows[rowIndex];

              return Padding(
                padding: EdgeInsets.only(
                  bottom: rowIndex < rows.length - 1 ? 12.0 : 0.0,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: cardWidth,
                      child: _buildConceptAppCard(
                        context,
                        rowItems[0],
                        resolveAppTheme(rowItems[0]),
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (rowItems.length > 1)
                      SizedBox(
                        width: cardWidth,
                        child: _buildConceptAppCard(
                          context,
                          rowItems[1],
                          resolveAppTheme(rowItems[1]),
                        ),
                      )
                    else
                      SizedBox(width: cardWidth),
                  ],
                ),
              );
            }),
          );
        },
      );
    });
  }

  Widget _buildConceptAppCard(
    BuildContext context,
    Map<String, dynamic> item,
    Map<String, dynamic> theme,
  ) {
    final bool isKh = LocalizationService.currentLanguageCode.value == 'km';
    final String title = resolveAppTitle(item, isKh);

    final resolvedTheme = resolveAppTheme(item);
    final Color iconBg = item['iconBg'] is Color
        ? (item['iconBg'] as Color)
        : (resolvedTheme['bg'] as Color);
    final IconData fallbackIcon = item['fallbackIcon'] is IconData
        ? (item['fallbackIcon'] as IconData)
        : (resolvedTheme['icon'] as IconData);

    final storage = GetStorage();
    final String sessionToken = (ApiClient.currentToken ??
            storage.read('token') ??
            storage.read('access_token') ??
            '')
        .toString();

    String? iconUrl;
    final String rawImg = AppIconWidget.extractRawIcon(item);
    if (rawImg.isNotEmpty &&
        rawImg != 'assets/img/about-moi-logo.png' &&
        rawImg != '/assets/img/about-moi-logo.png' &&
        rawImg.toLowerCase() != 'null' &&
        rawImg.toLowerCase() != 'undefined') {
      iconUrl = AppIconWidget.formatIconUrl(rawImg, sessionToken);
    }

    final String rawIconStr = (item["icon"] ?? '').toString().trim();
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

    return GestureDetector(
      onTap: () => showAppDetailDialog(
        context,
        item,
        onLaunch: (appItem, appTitle) => _handleAppLaunch(appItem, appTitle),
      ),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFF1F5F9),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.025),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Squircle Icon & Chevron Circle
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Squircle Icon Box
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: hasImage ? Colors.transparent : iconBg,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(13),
                    child: Center(
                      child: hasImage
                          ? AppIconWidget(
                              iconUrl: iconUrl ?? '',
                              localAsset: itemLocal,
                              fallbackIcon: fallbackIcon,
                              fallbackColor: iconBg,
                              token: sessionToken,
                              size: 44,
                              fit: BoxFit.contain,
                            )
                          : Icon(
                              fallbackIcon,
                              color: Colors.white,
                              size: 22,
                            ),
                    ),
                  ),
                ),

                // Chevron Circle
                Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(
                    color: AppColors.iconBeige,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.royalGold,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Bottom Title (2 lines)
            ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 34),
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: isKh
                    ? GoogleFonts.kantumruyPro(
                        fontSize: 13.0,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1E293B),
                        height: 1.25,
                      )
                    : GoogleFonts.poppins(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF1E293B),
                        height: 1.25,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // DATA & HELPERS
  // =========================================================================
  List<Map<String, dynamic>> _getDisplayApps() {
    if (controller.sourceApps.isNotEmpty || controller.isSearchOrFilterActive) {
      return controller.filteredServices;
    }

    // Graceful fallback concept apps matching the screenshot
    final allMocks = [
      {
        'id': 'complaint_system',
        'titleKh': 'ប្រព័ន្ធទទួលពាក្យបណ្តឹង\nអនឡាញ',
        'titleEn': 'Online Complaint\nSystem',
        'nameKh': 'ប្រព័ន្ធទទួលពាក្យបណ្តឹង អនឡាញ',
        'nameEn': 'Online Complaint System',
        'isGeneral': true,
        'iconBg': const Color(0xFF1E60D5),
        'fallbackIcon': Icons.chat_bubble_outline_rounded,
        'route': 'https://complaint.moi.gov.kh',
      },
      {
        'id': 'single_window_system',
        'titleKh': 'ប្រព័ន្ធច្រកចេញ\nចូលតែមួយ',
        'titleEn': 'Single Window\nPortal',
        'nameKh': 'ប្រព័ន្ធច្រកចេញចូលតែមួយ',
        'nameEn': 'Single Window Portal',
        'isGeneral': true,
        'iconBg': const Color(0xFF107C41),
        'fallbackIcon': Icons.login_rounded,
        'route': 'https://owso.moi.gov.kh',
      },
      {
        'id': 'doc_system',
        'titleKh': 'ប្រព័ន្ធគ្រប់គ្រងឯកសារ',
        'titleEn': 'Document Management',
        'nameKh': 'ប្រព័ន្ធគ្រប់គ្រងឯកសារ',
        'nameEn': 'Document Management System',
        'isGeneral': false,
        'iconBg': const Color(0xFF107C41),
        'fallbackIcon': Icons.description_rounded,
        'route': '',
      },
      {
        'id': 'residence_system',
        'titleKh': 'ប្រព័ន្ធគ្រប់គ្រងស្នាក់នៅ',
        'titleEn': 'Residence Management',
        'nameKh': 'ប្រព័ន្ធគ្រប់គ្រងស្នាក់នៅ',
        'nameEn': 'Residence Management System',
        'isGeneral': false,
        'iconBg': const Color(0xFFD97706),
        'fallbackIcon': Icons.home_rounded,
        'route': '',
      },
      {
        'id': 'hr_system',
        'titleKh': 'ប្រព័ន្ធគ្រប់គ្រងបុគ្គលិក',
        'titleEn': 'HR Management',
        'nameKh': 'ប្រព័ន្ធគ្រប់គ្រងបុគ្គលិក',
        'nameEn': 'HR Management System',
        'isGeneral': false,
        'iconBg': const Color(0xFF1E293B),
        'fallbackIcon': Icons.people_alt_rounded,
        'route': '',
      },
      {
        'id': 'doc_archive_system',
        'titleKh': 'ប្រព័ន្ធគ្រប់គ្រងឯកសារ',
        'titleEn': 'Document Archive',
        'nameKh': 'ប្រព័ន្ធគ្រប់គ្រងឯកសារ',
        'nameEn': 'Document Archive System',
        'isGeneral': false,
        'iconBg': const Color(0xFF107C41),
        'fallbackIcon': Icons.description_rounded,
        'route': '',
      },
      {
        'id': 'stat_system',
        'titleKh': 'ប្រព័ន្ធស្ថិតិ',
        'titleEn': 'Statistics System',
        'nameKh': 'ប្រព័ន្ធស្ថិតិ',
        'nameEn': 'Statistics System',
        'isGeneral': false,
        'iconBg': const Color(0xFF2563EB),
        'fallbackIcon': Icons.bar_chart_rounded,
        'route': '',
      },
      {
        'id': 'finance_system',
        'titleKh': 'ប្រព័ន្ធហិរញ្ញវត្ថុ',
        'titleEn': 'Financial System',
        'nameKh': 'ប្រព័ន្ធហិរញ្ញវត្ថុ',
        'nameEn': 'Financial System',
        'isGeneral': false,
        'iconBg': const Color(0xFF9E2A2B),
        'fallbackIcon': Icons.account_balance_wallet_rounded,
        'route': '',
      },
      {
        'id': 'security_system',
        'titleKh': 'ប្រព័ន្ធសន្តិសុខ',
        'titleEn': 'Security System',
        'nameKh': 'ប្រព័ន្ធសន្តិសុខ',
        'nameEn': 'Security System',
        'isGeneral': false,
        'iconBg': const Color(0xFFB45309),
        'fallbackIcon': Icons.security_rounded,
        'route': '',
      },
    ];

    final currentTab = controller.selectedFilterTab.value;
    if (currentTab == 'general') {
      return allMocks.where((a) => a['isGeneral'] == true).toList();
    } else if (currentTab == 'department' || currentTab == 'portal') {
      return allMocks.where((a) => a['isGeneral'] != true).toList();
    }
    return allMocks;
  }

  void _handleAppLaunch(Map<String, dynamic> item, String title) {
    final String route = (item["appUrl"] ??
            item["launchUrl"] ??
            item["url"] ??
            item["route"] ??
            item["path"] ??
            '')
        .toString()
        .trim();

    if (route.isNotEmpty) {
      try {
        if (Get.isRegistered<HomeController>()) {
          Get.find<HomeController>().addRecentActivity(item);
        }
        final Map<String, dynamic> navigationArgs = {
          'url': route,
          'title': title,
        };
        if (route.startsWith('http://') || route.startsWith('https://')) {
          Get.toNamed(
            AppRoutes.webView,
            arguments: navigationArgs,
          );
          return;
        }
        Get.toNamed(route, arguments: navigationArgs);
      } catch (e) {
        debugPrint("Navigation error: $e");
      }
    } else {
      final bool isKh = LocalizationService.currentLanguageCode.value == 'km';
      CustomSnackbar.showInfo(
        title: isKh ? 'ព័ត៌មាន' : 'Information',
        message: isKh ? 'សេវានេះនឹងដាក់ឱ្យដំណើរការឆាប់ៗនេះ' : 'This service will be available soon',
      );
    }
  }
}
