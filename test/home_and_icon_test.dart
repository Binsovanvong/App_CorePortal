import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:core_portal/widgets/app_icon.dart';
import 'package:core_portal/screens/home/home_controller.dart';
import 'package:core_portal/screens/application/application_view.dart';
import 'package:core_portal/core/api/api_config.dart';
import 'package:core_portal/screens/admin/admin_controller.dart';

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
  });

  group('AppIconWidget & Icon URL Resolution Tests', () {
    test('extractRawIcon extracts from different API candidate fields', () {
      expect(AppIconWidget.extractRawIcon({'iconUrl': 'https://example.com/icon.png'}), 'https://example.com/icon.png');
      expect(AppIconWidget.extractRawIcon({'icon_url': 'portal-app-icons/complaint.png'}), 'portal-app-icons/complaint.png');
      expect(AppIconWidget.extractRawIcon({'icon': 'portal-app-icons/anpr.png'}), 'portal-app-icons/anpr.png');
      expect(AppIconWidget.extractRawIcon({'iconPath': 'portal-app-icons/test.png'}), 'portal-app-icons/test.png');
      expect(AppIconWidget.extractRawIcon({'imageUrl': 'portal-app-icons/img.png'}), 'portal-app-icons/img.png');
      expect(AppIconWidget.extractRawIcon({'tileIcon': 'portal-app-icons/tile.png'}), 'portal-app-icons/tile.png');
      expect(AppIconWidget.extractRawIcon({'logo': 'portal-app-icons/logo.png'}), 'portal-app-icons/logo.png');
      expect(AppIconWidget.extractRawIcon({'appIcon': 'portal-app-icons/app.png'}), 'portal-app-icons/app.png');
      expect(AppIconWidget.extractRawIcon({'icon': {'url': 'portal-app-icons/nested.png'}}), 'portal-app-icons/nested.png');
      expect(AppIconWidget.extractRawIcon({'icon': {'path': 'portal-app-icons/nested_path.png'}}), 'portal-app-icons/nested_path.png');
    });

    test('formatIconUrl rewrites backend upload paths and adds token', () {
      final res1 = AppIconWidget.formatIconUrl('portal-app-icons/complaint-123.png', 'token123');
      expect(res1, equals('${ApiConfig.baseUrl}/api/mobile/portals/uploads/portal-app-icons/complaint-123.png?token=token123'));

      final res2 = AppIconWidget.formatIconUrl('/uploads/portal-app-icons/anpr.png', 'token123');
      expect(res2, equals('${ApiConfig.baseUrl}/api/mobile/portals/uploads/portal-app-icons/anpr.png?token=token123'));

      final res3 = AppIconWidget.formatIconUrl('http://core-gateway:8080/uploads/portal-app-icons/ees.png', 'token123');
      expect(res3, equals('${ApiConfig.baseUrl}/api/mobile/portals/uploads/portal-app-icons/ees.png?token=token123'));

      final res4 = AppIconWidget.formatIconUrl(r'portal-app-icons\windows-path.png', 'token123');
      expect(res4, equals('${ApiConfig.baseUrl}/api/mobile/portals/uploads/portal-app-icons/windows-path.png?token=token123'));

      final res5 = AppIconWidget.formatIconUrl('http://uat-app-core.interior.gov.kh/api/mobile/portals/uploads/api/v1/uploads/portal-app-icons/84ec8874-109c-48e8-9eb8-fc1c20f7a9ae.png', 'token123');
      expect(res5, equals('${ApiConfig.baseUrl}/api/mobile/portals/uploads/portal-app-icons/84ec8874-109c-48e8-9eb8-fc1c20f7a9ae.png?token=token123'));
    });

    test('formatIconUrl preserves external non-backend URLs', () {
      final externalUrl = 'https://cdn.example.com/icons/logo.svg';
      expect(AppIconWidget.formatIconUrl(externalUrl, 'token123'), equals(externalUrl));
    });

    test('formatIconUrl ignores MOI logo default and null/undefined values', () {
      expect(AppIconWidget.formatIconUrl('assets/img/about-moi-logo.png'), isEmpty);
      expect(AppIconWidget.formatIconUrl('/assets/img/about-moi-logo.png'), isEmpty);
      expect(AppIconWidget.formatIconUrl('null'), isEmpty);
      expect(AppIconWidget.formatIconUrl('undefined'), isEmpty);
      expect(AppIconWidget.formatIconUrl(''), isEmpty);
      expect(AppIconWidget.formatIconUrl(null), isEmpty);
    });
  });

  group('HomeController Home Services Filtering Tests', () {
    test('homeServices excludes general/admin apps and keeps user portal apps', () {
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
    });
  });

  group('ApplicationViewController Hide/Show & Filter Tabs Tests', () {
    test('hide/show toggles displayedServices between collapsed limit and all apps', () {
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
      expect(appCtrl.displayedServices.length, equals(ApplicationViewController.initialItemLimit));
      expect(appCtrl.displayedServices.length, equals(2));

      // Toggling back to expanded shows all 4 items
      appCtrl.toggleExpanded();
      expect(appCtrl.isExpanded.value, isTrue);
      expect(appCtrl.displayedServices.length, equals(4));
    });

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
      expect(appCtrl.filteredServices.every((a) => a['isGeneral'] != true), isTrue);

      // General apps tab -> Shows only general apps
      appCtrl.setFilterTab('general');
      expect(appCtrl.filteredServices.length, equals(2));
      expect(appCtrl.filteredServices.every((a) => a['isGeneral'] == true), isTrue);
    });
  });

  group('Admin Department Mapping Tests', () {
    test('formatDepartmentToKhmer maps known acronyms correctly', () {
      expect(AdminController.formatDepartmentToKhmer('GDDTM'),
          equals('អគ្គនាយកដ្ឋានបច្ចេកវិទ្យាឌីជីថល និងផ្សព្វផ្សាយអប់រំ'));
      expect(AdminController.formatDepartmentToKhmer('GDP'),
          equals('អគ្គនាយកដ្ឋានពន្ធនាគារ'));
      expect(AdminController.formatDepartmentToKhmer('GDI'),
          equals('អគ្គនាយកដ្ឋានអន្តោប្រវេសន៍'));
      expect(AdminController.formatDepartmentToKhmer('GNP'),
          equals('អគ្គស្នងការដ្ឋាននគរបាលជាតិ'));
      expect(AdminController.formatDepartmentToKhmer(null),
          equals('អគ្គនាយកដ្ឋានបច្ចេកវិទ្យាឌីជីថល និងផ្សព្វផ្សាយអប់រំ'));
      expect(AdminController.formatDepartmentToKhmer('—'),
          equals('អគ្គនាយកដ្ឋានបច្ចេកវិទ្យាឌីជីថល និងផ្សព្វផ្សាយអប់រំ'));
    });
  });
}

