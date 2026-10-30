import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:core_portal/widgets/app_icon.dart';
import 'package:core_portal/screens/home/home_controller.dart';
import 'package:core_portal/screens/application/application_view.dart';
import 'package:core_portal/core/api/api_config.dart';
import 'package:core_portal/screens/admin/admin_controller.dart';
import 'package:core_portal/widgets/announcement_detail_dialog.dart';
import 'package:core_portal/widgets/app_detail_dialog.dart';
import 'package:core_portal/screens/announcement/announcement_controller.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    Get.testMode = true;
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          return '.';
        });
    await GetStorage.init();
    FlutterSecureStorage.setMockInitialValues({});
  });

  group('AppIconWidget & Icon URL Resolution Tests', () {
    test('extractRawIcon extracts from different API candidate fields', () {
      expect(
        AppIconWidget.extractRawIcon({
          'iconUrl': 'https://example.com/icon.png',
        }),
        'https://example.com/icon.png',
      );
      expect(
        AppIconWidget.extractRawIcon({
          'icon_url': 'portal-app-icons/complaint.png',
        }),
        'portal-app-icons/complaint.png',
      );
      expect(
        AppIconWidget.extractRawIcon({'icon': 'portal-app-icons/anpr.png'}),
        'portal-app-icons/anpr.png',
      );
      expect(
        AppIconWidget.extractRawIcon({'iconPath': 'portal-app-icons/test.png'}),
        'portal-app-icons/test.png',
      );
      expect(
        AppIconWidget.extractRawIcon({'imageUrl': 'portal-app-icons/img.png'}),
        'portal-app-icons/img.png',
      );
      expect(
        AppIconWidget.extractRawIcon({'tileIcon': 'portal-app-icons/tile.png'}),
        'portal-app-icons/tile.png',
      );
      expect(
        AppIconWidget.extractRawIcon({'logo': 'portal-app-icons/logo.png'}),
        'portal-app-icons/logo.png',
      );
      expect(
        AppIconWidget.extractRawIcon({'appIcon': 'portal-app-icons/app.png'}),
        'portal-app-icons/app.png',
      );
      expect(
        AppIconWidget.extractRawIcon({
          'icon': {'url': 'portal-app-icons/nested.png'},
        }),
        'portal-app-icons/nested.png',
      );
      expect(
        AppIconWidget.extractRawIcon({
          'icon': {'path': 'portal-app-icons/nested_path.png'},
        }),
        'portal-app-icons/nested_path.png',
      );
    });

    test('formatIconUrl rewrites backend upload paths and adds token', () {
      final res1 = AppIconWidget.formatIconUrl(
        'portal-app-icons/complaint-123.png',
        'token123',
      );
      expect(
        res1,
        equals(
          '${ApiConfig.baseUrl}/api/mobile/portals/uploads/portal-app-icons/complaint-123.png?token=token123',
        ),
      );

      final res2 = AppIconWidget.formatIconUrl(
        '/uploads/portal-app-icons/anpr.png',
        'token123',
      );
      expect(
        res2,
        equals(
          '${ApiConfig.baseUrl}/api/mobile/portals/uploads/portal-app-icons/anpr.png?token=token123',
        ),
      );

      final res3 = AppIconWidget.formatIconUrl(
        'http://core-gateway:8080/uploads/portal-app-icons/ees.png',
        'token123',
      );
      expect(
        res3,
        equals(
          '${ApiConfig.baseUrl}/api/mobile/portals/uploads/portal-app-icons/ees.png?token=token123',
        ),
      );

      final res4 = AppIconWidget.formatIconUrl(
        r'portal-app-icons\windows-path.png',
        'token123',
      );
      expect(
        res4,
        equals(
          '${ApiConfig.baseUrl}/api/mobile/portals/uploads/portal-app-icons/windows-path.png?token=token123',
        ),
      );

      final res5 = AppIconWidget.formatIconUrl(
        'http://uat-app-core.interior.gov.kh/api/mobile/portals/uploads/api/v1/uploads/portal-app-icons/84ec8874-109c-48e8-9eb8-fc1c20f7a9ae.png',
        'token123',
      );
      expect(
        res5,
        equals(
          '${ApiConfig.baseUrl}/api/mobile/portals/uploads/portal-app-icons/84ec8874-109c-48e8-9eb8-fc1c20f7a9ae.png?token=token123',
        ),
      );

      final res6 = AppIconWidget.formatIconUrl(
        '/api/v1/uploads/portal-app-icons/6acc45da-5795-4b65-aa87-8897e64f942b.png',
        'token123',
      );
      expect(
        res6,
        equals(
          '${ApiConfig.baseUrl}/api/mobile/portals/uploads/portal-app-icons/6acc45da-5795-4b65-aa87-8897e64f942b.png?token=token123',
        ),
      );
    });

    test('formatIconUrl preserves external non-backend URLs', () {
      final externalUrl = 'https://cdn.example.com/icons/logo.svg';
      expect(
        AppIconWidget.formatIconUrl(externalUrl, 'token123'),
        equals(externalUrl),
      );
    });

    test(
      'formatIconUrl ignores MOI logo default and null/undefined values',
      () {
        expect(
          AppIconWidget.formatIconUrl('assets/img/about-moi-logo.png'),
          isEmpty,
        );
        expect(
          AppIconWidget.formatIconUrl('/assets/img/about-moi-logo.png'),
          isEmpty,
        );
        expect(AppIconWidget.formatIconUrl('null'), isEmpty);
        expect(AppIconWidget.formatIconUrl('undefined'), isEmpty);
        expect(AppIconWidget.formatIconUrl(''), isEmpty);
        expect(AppIconWidget.formatIconUrl(null), isEmpty);
      },
    );

    test('extractRelativePath normalizes various backend upload formats', () {
      expect(
        AppIconWidget.extractRelativePath('portal-app-icons/app.png'),
        equals('portal-app-icons/app.png'),
      );
      expect(
        AppIconWidget.extractRelativePath(
          'http://172.30.192.127/api/mobile/portals/uploads/api/v1/uploads/portal-app-icons/app.png',
        ),
        equals('portal-app-icons/app.png'),
      );
      expect(
        AppIconWidget.extractRelativePath('/uploads/portal-app-icons/app.png'),
        equals('portal-app-icons/app.png'),
      );
      expect(
        AppIconWidget.extractRelativePath('app.png'),
        equals('portal-app-icons/app.png'),
      );
      expect(
        AppIconWidget.extractRelativePath('https://example.com/external.png'),
        equals(''),
      );
    });
    test('resolveAppTheme provides consistent, stable fallback icons and colors across filters', () {
      final anprApp = {'code': 'ANPR', 'titleKh': 'ប្រព័ន្ធស្នើសុំចេញចូលទីស្តីការក្រសួងមហាផ្ទៃ'};
      final prisonApp = {'code': 'GDP_PRISONS', 'titleKh': 'ប្រព័ន្ធគ្រប់គ្រងពន្ធនាគារ'};
      final complaintApp = {'code': 'COMPLAINT', 'titleKh': 'ប្រព័ន្ធទទួលពាក្យបណ្តឹងអនឡាញ'};
      final owsoApp = {'code': 'OWSO', 'titleKh': 'ប្រព័ន្ធច្រកចេញចូលតែមួយ'};

      final themeAnpr = ApplicationView.resolveAppTheme(anprApp);
      final themePrison = ApplicationView.resolveAppTheme(prisonApp);
      final themeComplaint = ApplicationView.resolveAppTheme(complaintApp);
      final themeOwso = ApplicationView.resolveAppTheme(owsoApp);

      expect(themeAnpr['icon'], equals(Icons.directions_car_rounded));
      expect(themeAnpr['bg'], equals(const Color(0xFF0F766E)));

      expect(themePrison['icon'], equals(Icons.shield_rounded));
      expect(themePrison['bg'], equals(const Color(0xFFB45309)));

      expect(themeComplaint['icon'], equals(Icons.chat_bubble_outline_rounded));
      expect(themeComplaint['bg'], equals(const Color(0xFF1E60D5)));

      expect(themeOwso['icon'], equals(Icons.login_rounded));
      expect(themeOwso['bg'], equals(const Color(0xFF107C41)));

      // Calling multiple times returns the exact same theme (deterministic)
      expect(ApplicationView.resolveAppTheme(anprApp), equals(themeAnpr));
      expect(ApplicationView.resolveAppTheme(prisonApp), equals(themePrison));
    });
  });

  group('HomeController Home Services Filtering Tests', () {
    test(
      'homeServices excludes general/admin apps and keeps user portal apps',
      () {
        final controller = HomeController();
        controller.services.assignAll([
          {
            'id': 'app1',
            'titleKh': 'ប្រព័ន្ធស្នើសុំចេញចូលទីស្តីការក្រសួងមហាផ្ទៃ',
            'isActive': true,
            'isGeneral': false,
            'category': 'security',
            'department': 'immigration',
          },
          {
            'id': 'app2',
            'titleKh': 'ប្រព័ន្ធទទួលពាក្យបណ្តឹងអនឡាញ',
            'isActive': true,
            'isGeneral': false,
            'category': 'complaints',
            'department': 'inspection',
          },
          {
            'id': 'app3_admin',
            'titleKh': 'កម្មវិធីទូទៅ (Admin App)',
            'isActive': true,
            'isGeneral': true,
            'category': 'general',
            'department': 'general',
          },
          {
            'id': 'app4_khmer_gen',
            'titleKh': 'ការងារទូទៅ',
            'isActive': true,
            'isGeneral': false,
            'category': 'ទូទៅ',
            'department': 'ទូទៅ',
          },
          {
            'id': 'app5_inactive',
            'titleKh': 'Inactive App',
            'isActive': false,
            'isGeneral': false,
            'category': 'security',
            'department': 'immigration',
          },
          {
            'id': 'app6_google_map',
            'titleKh': 'Google Map',
            'titleEn': 'Google Map',
            'code': 'GOOGLE_MAP',
            'isActive': true,
            'isGeneral': false,
            'category': '',
            'department': '',
            'url': 'https://maps.google.com',
          },
          {
            'id': 'app7_google_calendar',
            'titleKh': 'Google Calendar',
            'titleEn': 'Google Calendar',
            'code': 'GOOGLE_CALENDAR',
            'isActive': true,
            'isGeneral': false,
            'category': '',
            'department': '',
            'url': 'https://calendar.google.com',
          },
        ]);

        final homeApps = controller.homeServices;

        // Should ONLY contain app1 (ANPR) and app2 (Complaint), excluding app3, app4, app5, app6 (Google Map), and app7 (Google Calendar)
        expect(homeApps.length, equals(2));
        expect(homeApps[0]['id'], equals('app1'));
        expect(homeApps[1]['id'], equals('app2'));
        expect(homeApps.any((a) => a['id'] == 'app3_admin'), isFalse);
        expect(homeApps.any((a) => a['id'] == 'app4_khmer_gen'), isFalse);
        expect(homeApps.any((a) => a['id'] == 'app5_inactive'), isFalse);
        expect(homeApps.any((a) => a['id'] == 'app6_google_map'), isFalse);
        expect(homeApps.any((a) => a['id'] == 'app7_google_calendar'), isFalse);
      },
    );
  });

  group('ApplicationViewController Hide/Show & Filter Tabs Tests', () {
    test(
      'hide/show toggles displayedServices between collapsed limit and all apps',
      () {
        final appCtrl = ApplicationViewController();
        appCtrl.apiApps.assignAll([
          {
            'id': 'app1',
            'titleKh': 'ប្រព័ន្ធស្នើសុំចេញចូលទីស្តីការក្រសួងមហាផ្ទៃ',
            'isActive': true,
            'isGeneral': false,
          },
          {
            'id': 'app2',
            'titleKh': 'ប្រព័ន្ធទទួលពាក្យបណ្តឹងអនឡាញ',
            'isActive': true,
            'isGeneral': false,
          },
          {
            'id': 'app3',
            'titleKh': 'Google Map',
            'isActive': true,
            'isGeneral': true,
          },
          {
            'id': 'app4',
            'titleKh': 'Google Calendar',
            'isActive': true,
            'isGeneral': true,
          },
        ]);
        appCtrl.searchController.clear();
        appCtrl.clearFilters();

        // When expanded (Show), all 4 items are displayed
        appCtrl.isExpanded.value = true;
        expect(appCtrl.displayedServices.length, equals(4));

        // When collapsed (Hide), only initialItemLimit (2) items are displayed
        appCtrl.toggleExpanded(); // isExpanded becomes false
        expect(appCtrl.isExpanded.value, isFalse);
        expect(
          appCtrl.displayedServices.length,
          equals(ApplicationViewController.initialItemLimit),
        );
        expect(appCtrl.displayedServices.length, equals(2));

        // Toggling back to expanded shows all 4 items
        appCtrl.toggleExpanded();
        expect(appCtrl.isExpanded.value, isTrue);
        expect(appCtrl.displayedServices.length, equals(4));
      },
    );

    test('selectedFilterTab filters portal apps, general apps, and all', () {
      final appCtrl = ApplicationViewController();
      appCtrl.apiApps.assignAll([
        {
          'id': 'app1',
          'titleKh': 'ប្រព័ន្ធស្នើសុំចេញចូលទីស្តីការក្រសួងមហាផ្ទៃ',
          'isActive': true,
          'isGeneral': false,
        },
        {
          'id': 'app2',
          'titleKh': 'ប្រព័ន្ធទទួលពាក្យបណ្តឹងអនឡាញ',
          'isActive': true,
          'isGeneral': false,
        },
        {
          'id': 'app3',
          'titleKh': 'Google Map',
          'isActive': true,
          'isGeneral': true,
        },
        {
          'id': 'app4',
          'titleKh': 'Google Calendar',
          'isActive': true,
          'isGeneral': true,
        },
      ]);
      appCtrl.searchController.clear();
      appCtrl.clearFilters();

      // All tab
      appCtrl.setFilterTab('all');
      expect(appCtrl.filteredServices.length, equals(4));

      // Portal apps tab -> Hides general apps
      appCtrl.setFilterTab('portal');
      expect(appCtrl.filteredServices.length, equals(2));
      expect(
        appCtrl.filteredServices.every((a) => a['isGeneral'] != true),
        isTrue,
      );

      // General apps tab -> Shows only general apps
      appCtrl.setFilterTab('general');
      expect(appCtrl.filteredServices.length, equals(2));
      expect(
        appCtrl.filteredServices.every((a) => a['isGeneral'] == true),
        isTrue,
      );
    });

    test('selectedFilterTab falls back to default general apps when sourceApps has no general apps', () {
      final appCtrl = ApplicationViewController();
      appCtrl.apiApps.assignAll([
        {
          'id': 'app1',
          'titleKh': 'ប្រព័ន្ធស្នើសុំចេញចូលទីស្តីការក្រសួងមហាផ្ទៃ',
          'isActive': true,
          'isGeneral': false,
        },
        {
          'id': 'app2',
          'titleKh': 'ប្រព័ន្ធគ្រប់គ្រងពន្ធនាគារ',
          'isActive': true,
          'isGeneral': false,
        },
      ]);
      appCtrl.searchController.clear();
      appCtrl.clearFilters();

      // General apps tab -> Shows default general apps (matching HomeView)
      appCtrl.setFilterTab('general');
      expect(appCtrl.filteredServices.isNotEmpty, isTrue);
      expect(
        appCtrl.filteredServices.any((a) => a['id'] == 'complaint_system'),
        isTrue,
      );
      expect(
        appCtrl.filteredServices.any((a) => a['id'] == 'single_window_system'),
        isTrue,
      );
      expect(
        appCtrl.filteredServices.every((a) => a['isGeneral'] == true),
        isTrue,
      );

      // Department tab -> Strictly department apps (no general apps)
      appCtrl.setFilterTab('department');
      expect(appCtrl.filteredServices.length, equals(2));
      expect(
        appCtrl.filteredServices.every((a) => a['isGeneral'] != true),
        isTrue,
      );

      // All tab -> Department apps + General apps
      appCtrl.setFilterTab('all');
      expect(appCtrl.filteredServices.length, equals(4));
    });
  });

  group('Admin Department Mapping Tests', () {
    test('formatDepartmentToKhmer maps known acronyms correctly', () {
      expect(
        AdminController.formatDepartmentToKhmer('GDDTM'),
        equals('អគ្គនាយកដ្ឋានបច្ចេកវិទ្យាឌីជីថល និងផ្សព្វផ្សាយអប់រំ'),
      );
      expect(
        AdminController.formatDepartmentToKhmer('GDP'),
        equals('អគ្គនាយកដ្ឋានពន្ធនាគារ'),
      );
      expect(
        AdminController.formatDepartmentToKhmer('GDI'),
        equals('អគ្គនាយកដ្ឋានអន្តោប្រវេសន៍'),
      );
      expect(
        AdminController.formatDepartmentToKhmer('GNP'),
        equals('អគ្គស្នងការដ្ឋាននគរបាលជាតិ'),
      );
      expect(
        AdminController.formatDepartmentToKhmer(null),
        equals('អគ្គនាយកដ្ឋានបច្ចេកវិទ្យាឌីជីថល និងផ្សព្វផ្សាយអប់រំ'),
      );
      expect(
        AdminController.formatDepartmentToKhmer('—'),
        equals('អគ្គនាយកដ្ឋានបច្ចេកវិទ្យាឌីជីថល និងផ្សព្វផ្សាយអប់រំ'),
      );
    });
  });

  group('Home Tiles and Application Admin Apps Separation Tests', () {
    test(
      'ApplicationViewController._normalizeApp extracts ownerOrgCode and title correctly',
      () {
        final appCtrl = ApplicationViewController();
        final normalized = appCtrl.testNormalizeApp({
          'id': 1,
          'code': 'ANPR',
          'nameKh': 'ប្រព័ន្ធស្នើរសុំចេញចូលទីស្តីការក្រសួងមហាផ្ទៃ',
          'title': 'ANPR Access System',
          'ownerOrgCode': 'GDDTM',
          'appUrl': 'https://n4-anpr-uat.interior.gov.kh/admin',
          'iconUrl': 'portal-app-icons/anpr.png',
        });

        expect(normalized['id'], equals('1'));
        expect(normalized['code'], equals('ANPR'));
        expect(normalized['department'], equals('GDDTM'));
        expect(
          normalized['titleKh'],
          equals('ប្រព័ន្ធស្នើរសុំចេញចូលទីស្តីការក្រសួងមហាផ្ទៃ'),
        );
        expect(
          normalized['route'],
          equals('https://n4-anpr-uat.interior.gov.kh/admin'),
        );
      },
    );

    test(
      'ApplicationViewController sourceApps strictly uses admin portal apps without tile injection',
      () {
        final appCtrl = ApplicationViewController();
        appCtrl.apiApps.assignAll([
          {
            'id': 'admin_app_1',
            'code': 'ANPR',
            'titleKh': 'ប្រព័ន្ធស្នើសុំចេញចូលទីស្តីការក្រសួងមហាផ្ទៃ',
            'isActive': true,
            'isGeneral': false,
          },
          {
            'id': 'admin_app_2',
            'code': 'COMPLAINT',
            'titleKh': 'ប្រព័ន្ធទទួលពាក្យបណ្តឹងអនឡាញ',
            'isActive': true,
            'isGeneral': false,
          },
        ]);

        final apps = appCtrl.sourceApps;
        expect(apps.length, equals(2));
        expect(
          apps.map((a) => a['id']).toList(),
          equals(['admin_app_1', 'admin_app_2']),
        );
      },
    );

    test(
      'ApplicationViewController sourceApps isolates apps for GD Admin and excludes other GD apps',
      () async {
        final box = GetStorage();
        await box.write('generalDepartmentCode', 'GDP');
        await box.write('roles', ['GDP_ADMIN']);

        final appCtrl = ApplicationViewController();
        appCtrl.apiApps.assignAll([
          {
            'id': 'gdp_app_1',
            'code': 'GDP_PRISONS',
            'titleKh': 'ប្រព័ន្ធគ្រប់គ្រងពន្ធនាគារ',
            'department': 'GDP',
            'isActive': true,
            'isGeneral': false,
          },
          {
            'id': 'gddtm_app_2',
            'code': 'GDDTM_ANPR',
            'titleKh': 'ប្រព័ន្ធស្នើសុំចេញចូលទីស្តីការ',
            'department': 'GDDTM',
            'isActive': true,
            'isGeneral': false,
          },
          {
            'id': 'general_app_3',
            'code': 'CALENDAR',
            'titleKh': 'ប្រតិទិនការងារ',
            'department': 'general',
            'isActive': true,
            'isGeneral': true,
          },
        ]);

        final apps = appCtrl.sourceApps;
        final ids = apps.map((a) => a['id']).toList();
        expect(ids, contains('gdp_app_1'));
        expect(ids, contains('general_app_3'));
        expect(ids, isNot(contains('gddtm_app_2')));

        // Cleanup
        await box.remove('generalDepartmentCode');
        await box.remove('roles');
      },
    );
  });

  group('Announcement Detail Dialog Tests', () {
    test(
      'formatDetailKhmerDateTime formats ISO dates into official Khmer datetime string',
      () {
        final formatted = formatDetailKhmerDateTime(
          '2026-09-17T05:05:17.736741',
        );
        expect(formatted, contains('ថ្ងៃទី'));
        expect(formatted, contains('កញ្ញា'));
        expect(formatted, contains('ឆ្នាំ'));
        expect(formatted, contains('ម៉ោង'));
      },
    );

    test(
      'formatDetailKhmerDateTime handles empty and invalid dates gracefully',
      () {
        expect(formatDetailKhmerDateTime(''), isEmpty);
        expect(formatDetailKhmerDateTime(null), isEmpty);
        expect(
          formatDetailKhmerDateTime('invalid-date'),
          equals('invalid-date'),
        );
      },
    );
  });

  group('ApplicationView Bilingual App Titles and Translations Tests', () {
    test('resolveAppTitle translates Khmer app titles to English correctly', () {
      expect(
        ApplicationView.resolveAppTitle(
          {'name': 'ប្រព័ន្ធទទួលពាក្យបណ្តឹងអនឡាញ'},
          false,
        ),
        equals('Online Complaint System'),
      );
      expect(
        ApplicationView.resolveAppTitle(
          {'name': 'ប្រព័ន្ធច្រកចេញចូលតែមួយ'},
          false,
        ),
        equals('Single Window Portal'),
      );
      expect(
        ApplicationView.resolveAppTitle(
          {'name': 'ប្រព័ន្ធស្នើសុំចេញលិខិតស្គាល់'},
          false,
        ),
        equals('ID Letter Request System'),
      );
      expect(
        ApplicationView.resolveAppTitle(
          {'name': 'ប្រព័ន្ធគ្រប់គ្រងឯកសារ'},
          false,
        ),
        equals('Document Management System'),
      );
      expect(
        ApplicationView.resolveAppTitle(
          {'name': 'ប្រព័ន្ធគ្រប់គ្រងស្នាក់នៅ'},
          false,
        ),
        equals('Residence Management System'),
      );
      expect(
        ApplicationView.resolveAppTitle(
          {'name': 'ប្រព័ន្ធគ្រប់គ្រងបុគ្គលិក'},
          false,
        ),
        equals('HR Management System'),
      );
      expect(
        ApplicationView.resolveAppTitle(
          {'code': 'ANPR', 'titleKh': 'ប្រព័ន្ធស្នើសុំចេញចូលទីស្តីការក្រសួងមហាផ្ទៃ'},
          false,
        ),
        equals('MOI Access Request System'),
      );
      expect(
        ApplicationView.resolveAppTitle(
          {'name': 'ប្រព័ន្ធគ្រប់គ្រងពន្ធនាគារ'},
          false,
        ),
        equals('Prison Management System'),
      );
      expect(
        ApplicationView.resolveAppTitle(
          {'name': 'ប្រតិទិនការងារ'},
          false,
        ),
        equals('Work Calendar'),
      );
      expect(
        ApplicationView.resolveAppTitle(
          {'name': 'ប្រព័ន្ធគ្រប់គ្រងស្នាក់នៅ (TMS)'},
          false,
        ),
        equals('Residence Management System (TMS)'),
      );
      expect(
        ApplicationView.resolveAppTitle(
          {'name': 'ប្រព័ន្ធគ្រប់គ្រងវត្តមាន (AMS)'},
          false,
        ),
        equals('Attendance System (AMS)'),
      );
      expect(
        ApplicationView.resolveAppTitle(
          {'name': 'ការងារទូទៅ'},
          false,
        ),
        equals('General Work System'),
      );
    });

    test('resolveAppTitle retains Khmer titles when in Khmer mode', () {
      expect(
        ApplicationView.resolveAppTitle(
          {'name': 'ប្រព័ន្ធទទួលពាក្យបណ្តឹងអនឡាញ', 'titleEn': 'Online Complaint System'},
          true,
        ),
        equals('ប្រព័ន្ធទទួលពាក្យបណ្តឹងអនឡាញ'),
      );
      expect(
        ApplicationView.resolveAppTitle(
          {'code': 'ANPR'},
          true,
        ),
        equals('ប្រព័ន្ធស្នើសុំចេញចូលទីស្តីការក្រសួងមហាផ្ទៃ'),
      );
      expect(
        ApplicationView.resolveAppTitle(
          {'name': 'Prison Management System'},
          true,
        ),
        equals('ប្រព័ន្ធគ្រប់គ្រងពន្ធនាគារ'),
      );
      expect(
        ApplicationView.resolveAppTitle(
          {'name': 'Work Calendar'},
          true,
        ),
        equals('ប្រតិទិនការងារ'),
      );
      expect(
        ApplicationView.resolveAppTitle(
          {'name': 'Google Map'},
          true,
        ),
        equals('ផែនទី Google'),
      );
      expect(
        ApplicationView.resolveAppTitle(
          {'name': 'Google Calendar'},
          true,
        ),
        equals('ប្រតិទិន Google'),
      );
    });
  });

  group('Announcement Concept Redesign Tests', () {
    test('conceptFallbackAnnouncements contains 5 items matching concept image', () {
      final list = AnnouncementController.conceptFallbackAnnouncements;
      expect(list.length, equals(5));

      expect(list[0]['title'], equals('ការជូនដំណឹងអំពីការធ្វើបច្ចុប្បន្នភាពប្រព័ន្ធ'));
      expect(list[1]['title'], equals('សេចក្តីណែនាំស្តីពីការស្នើសុំចេញលិខិតស្គាល់'));
      expect(list[2]['title'], equals('កាលវិភាគថែទាំប្រព័ន្ធប្រចាំសប្តាហ៍'));
      expect(list[3]['title'], equals('ការអនុញ្ញាតឱ្យចូលប្រើកម្មវិធីថ្មី'));
      expect(list[4]['title'], equals('សេចក្តីប្រកាសស្តីពីម៉ោងធ្វើការ'));

      expect(list[0]['displayDateKh'], equals('២៧ តុលា ២០២៦ · ម៉ោង ០៩:៣០'));
      expect(list[1]['displayDateKh'], equals('២៦ តុលា ២០២៦ · ម៉ោង ១៥:១០'));
      expect(list[2]['displayDateKh'], equals('២៤ តុលា ២០២៦ · ម៉ោង ១០:០០'));
      expect(list[3]['displayDateKh'], equals('២០ តុលា ២០២៦ · ម៉ោង ០៨:៤៥'));
      expect(list[4]['displayDateKh'], equals('១៨ តុលា ២០២៦ · ម៉ោង ១៤:២០'));
    });

    test('AnnouncementController computes unread count = 2 initially matching concept pill មិនទាន់អាន (2)', () {
      final controller = Get.put(AnnouncementController());
      controller.announcements.clear();
      controller.readAnnouncementIds.clear();

      expect(controller.unreadCount, equals(2));

      // Test filtering
      controller.selectedFilterTab.value = 'all';
      expect(controller.conceptFilteredAnnouncements.length, equals(5));

      controller.selectedFilterTab.value = 'unread';
      expect(controller.conceptFilteredAnnouncements.length, equals(2));

      // Mark first announcement as read
      final firstItem = controller.conceptFilteredAnnouncements.first;
      controller.markAsRead(firstItem);

      expect(controller.unreadCount, equals(1));
      expect(controller.conceptFilteredAnnouncements.length, equals(1));
      Get.delete<AnnouncementController>();
    });
  });
  group('App Detail Dialog Tests', () {
    test('AppDetailDialog accepts app data and resolves values correctly', () {
      final testApp = {
        'id': 'google_calendar',
        'code': 'GOOGLE_CALENDAR',
        'titleKh': 'Google Calendar',
        'titleEn': 'Google Calendar',
        'route': 'https://calendar.google.com/calendar/u/0/r?pli=1',
        'department': 'GDDTM',
        'isActive': true,
      };

      final dialog = AppDetailDialog(app: testApp);
      expect(dialog.app['code'], equals('GOOGLE_CALENDAR'));
      expect(dialog.app['titleKh'], equals('Google Calendar'));
      expect(dialog.app['route'], equals('https://calendar.google.com/calendar/u/0/r?pli=1'));
      expect(dialog.app['department'], equals('GDDTM'));
      expect(dialog.app['isActive'], isTrue);
    });
  });
}
