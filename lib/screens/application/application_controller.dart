part of 'application_view.dart'; // 👈 Connects back to the parent file above. No imports allowed here!

class ApplicationViewController extends GetxController {
  // Safely access or put HomeController
  final HomeController homeController = Get.isRegistered<HomeController>()
      ? Get.find<HomeController>()
      : Get.put(HomeController());
  final AuthService _authService = AuthService();

  final searchController = TextEditingController();
  final rxSearchQuery = ''.obs;
  final selectedSubCategory = 'all_units'.tr.obs;
  final selectedSort = 'newest'.obs; // 'newest', 'oldest', 'name_az', 'name_za'
  final selectedStatus = 'all'.obs;
  final selectedFilterTab = 'all'.obs; // 'all', 'portal', 'general'
  final filteredServices = <Map<String, dynamic>>[].obs;
  final apiApps = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final isExpanded = true.obs;
  static const int initialItemLimit = 2;

  void toggleExpanded() {
    isExpanded.value = !isExpanded.value;
  }

  void setFilterTab(String tab) {
    selectedFilterTab.value = tab;
    _filterApps();
  }

  bool get isSearchOrFilterActive {
    final hasSearch = rxSearchQuery.value.trim().isNotEmpty;
    final hasDept = selectedSubCategory.value != 'all_units'.tr &&
        selectedSubCategory.value != 'អង្គភាពទាំងអស់' &&
        selectedSubCategory.value != 'ទាំងអស់' &&
        selectedSubCategory.value != 'all';
    final hasStatus = selectedStatus.value != 'all';
    final hasFilterTab = selectedFilterTab.value != 'all';
    return hasSearch || hasDept || hasStatus || hasFilterTab;
  }

  void clearFilters() {
    searchController.clear();
    rxSearchQuery.value = '';
    selectedFilterTab.value = 'all';
    selectedSubCategory.value = 'all_units'.tr;
    selectedStatus.value = 'all';
    _filterApps();
  }

  List<Map<String, dynamic>> get displayedServices {
    final isSearching = rxSearchQuery.value.trim().isNotEmpty;
    if (isExpanded.value || isSearching) {
      return filteredServices;
    }
    return filteredServices.take(initialItemLimit).toList();
  }

  /// Normalizes any raw map from backend endpoints into a clean, consistent schema
  Map<String, dynamic> _normalizeApp(dynamic raw, [String? token]) {
    if (raw is! Map) return {};
    final Map<String, dynamic> app = Map<String, dynamic>.from(raw);

    final String id = (app['id'] ?? app['_id'] ?? '').toString().trim();
    final String code = (app['code'] ?? '').toString().trim();

    final String titleKh = (app['nameKh'] ??
            app['title_kh'] ??
            app['titleKh'] ??
            app['name'] ??
            app['titleEn'] ??
            'កម្មវិធី')
        .toString()
        .trim();

    final String titleEn = (app['nameEn'] ??
            app['title_en'] ??
            app['titleEn'] ??
            app['name'] ??
            app['titleKh'] ??
            'App')
        .toString()
        .trim();

    final String rawIcon = AppIconWidget.extractRawIcon(app);

    String cleanRaw = rawIcon;
    if (cleanRaw == 'assets/img/about-moi-logo.png' ||
        cleanRaw == '/assets/img/about-moi-logo.png' ||
        cleanRaw.toLowerCase() == 'null' ||
        cleanRaw.toLowerCase() == 'undefined') {
      cleanRaw = '';
    }

    String iconUrl = '';
    String iconPath = '';

    if (cleanRaw.isNotEmpty) {
      final cleanLower = cleanRaw.toLowerCase();
      final bool isLocal = cleanLower.startsWith('assets/') ||
          cleanLower.startsWith('asset/') ||
          cleanLower.startsWith('/assets/') ||
          cleanLower.startsWith('/asset/') ||
          cleanLower.startsWith('images/') ||
          cleanLower.startsWith('/images/');

      if (isLocal) {
        iconPath = cleanRaw.startsWith('/') ? cleanRaw.substring(1) : cleanRaw;
        if (!iconPath.startsWith('assets/')) {
          iconPath = 'assets/$iconPath';
        }
      } else {
        iconUrl = AppIconWidget.formatIconUrl(cleanRaw, token);
      }
    }

    final String rawLocal = (app['icon'] ?? '').toString().trim();
    if (iconPath.isEmpty &&
        rawLocal.isNotEmpty &&
        rawLocal != 'assets/img/about-moi-logo.png' &&
        rawLocal != '/assets/img/about-moi-logo.png') {
      iconPath = rawLocal;
    }

    String route = (app['launchUrl'] ??
            app['appUrl'] ??
            app['url'] ??
            app['route'] ??
            app['path'] ??
            '')
        .toString()
        .trim();

    if (route.isNotEmpty &&
        !route.startsWith('http://') &&
        !route.startsWith('https://')) {
      if (route.contains('.com') ||
          route.contains('.gov.kh') ||
          route.contains('.org') ||
          route.contains('www.')) {
        route = 'https://$route';
      }
    }

    final dynamic rawActive =
        app['isActive'] ?? app['is_active'] ?? app['active'] ?? app['enabled'];
    final dynamic rawStatus = app['status'];
    bool isActive = true;
    if (rawStatus != null) {
      final s = rawStatus.toString().trim().toUpperCase();
      if (s == 'INACTIVE' ||
          s == 'DISABLED' ||
          s == 'OFF' ||
          s == '0' ||
          s == 'FALSE') {
        isActive = false;
      }
    } else if (rawActive != null) {
      if (rawActive is bool) {
        isActive = rawActive;
      } else if (rawActive is num) {
        isActive = rawActive != 0;
      } else {
        final s = rawActive.toString().trim().toLowerCase();
        if (s == 'false' ||
            s == '0' ||
            s == 'inactive' ||
            s == 'disabled' ||
            s == 'off') {
          isActive = false;
        }
      }
    }

    final String cat = (app['category'] ?? app['subCategory'] ?? '').toString().trim().toLowerCase();
    final String subCat = (app['subCategory'] ?? '').toString().trim().toLowerCase();
    final String dept = (app['department'] ??
            app['unit'] ??
            app['departmentName'] ??
            app['generalDepartmentName'] ??
            app['generalDepartmentCode'] ??
            '')
        .toString()
        .trim();
    final String unit = (app['unit'] ?? '').toString().trim().toLowerCase();
    final String deptName = (app['departmentName'] ?? '').toString().trim().toLowerCase();

    final bool isGen = app['isGeneral'] == true ||
        app['is_general'] == true ||
        cat == 'general' ||
        cat == 'ទូទៅ' ||
        subCat == 'general' ||
        subCat == 'ទូទៅ' ||
        dept.toLowerCase() == 'general' ||
        dept.toLowerCase() == 'ទូទៅ' ||
        unit == 'general' ||
        unit == 'ទូទៅ' ||
        deptName == 'general' ||
        deptName == 'ទូទៅ';

    final String desc = (app['description'] ??
            app['desc'] ??
            app['descriptionKh'] ??
            '')
        .toString()
        .trim();

    final accessRules =
        app['accessRules'] ?? app['access_rules'] ?? app['rules'] ?? [];

    return {
      'id': id,
      'code': code,
      'titleKh': titleKh,
      'nameKh': titleKh,
      'titleEn': titleEn,
      'nameEn': titleEn,
      'name': titleKh,
      'icon': iconPath,
      'iconUrl': iconUrl,
      'url': route,
      'route': route,
      'launchUrl': route,
      'appUrl': route,
      'isActive': isActive,
      'isGeneral': isGen,
      'category': app['category'] ?? app['subCategory'] ?? '',
      'subCategory': app['subCategory'] ?? '',
      'status': rawStatus?.toString() ?? (isActive ? 'ACTIVE' : 'INACTIVE'),
      'department': dept,
      'unit': dept,
      'departmentName': dept,
      'description': desc,
      'desc': desc,
      'accessRules': accessRules,
    };
  }

  List<Map<String, dynamic>> get sourceApps {
    final List<Map<String, dynamic>> all = [];
    final Set<String> seen = {};

    void addApps(List<dynamic> list) {
      for (var raw in list) {
        final app = _normalizeApp(raw);
        if (app.isEmpty) continue;
        final id = (app['id'] ?? '').toString().trim();
        final code = (app['code'] ?? '').toString().trim();
        final title = (app['titleKh'] ?? app['titleEn'] ?? '').toString().trim();
        final key = id.isNotEmpty
            ? 'id:$id'
            : (code.isNotEmpty ? 'code:$code' : 'title:$title');
        if (key.isNotEmpty && !seen.contains(key)) {
          seen.add(key);
          all.add(app);
        }
      }
    }

    if (apiApps.isNotEmpty) {
      addApps(apiApps);
    }
    addApps(homeController.services);

    if (Get.isRegistered<AdminController>()) {
      addApps(Get.find<AdminController>().appsList);
    }

    final cached = GetStorage().read('cached_portal_services') ??
        GetStorage().read('cached_admin_apps_list');
    if (cached is List && cached.isNotEmpty) {
      addApps(cached);
    }

    return all.isNotEmpty ? all : homeController.services;
  }

  List<String> get availableUnits {
    final Set<String> groups = {};

    // 1. If AdminController is available, get all admin groups
    if (Get.isRegistered<AdminController>()) {
      final adminGroups = Get.find<AdminController>().adminGroups;
      for (var g in adminGroups) {
        if (g != 'all_units'.tr && g != 'អង្គភាពទាំងអស់' && g.isNotEmpty) {
          groups.add(g);
        }
      }
    }

    // 2. Dynamic group categories from all apps
    for (var app in sourceApps) {
      final rawRules = app['accessRules'] is List
          ? app['accessRules']
          : (app['rules'] is List ? app['rules'] : []);
      for (var r in rawRules) {
        if (r is Map) {
          final val = (r['ruleValue'] ?? r['value'] ?? r['target'] ?? '')
              .toString()
              .trim();
          if (val.isNotEmpty &&
              val.toLowerCase() != 'all' &&
              val != 'ទាំងអស់') {
            groups.add(val);
          }
        }
      }

      final cat = (app['department'] ??
              app['unit'] ??
              app['departmentName'] ??
              app['category'] ??
              app['subCategory'] ??
              '')
          .toString()
          .trim();
      if (cat.isNotEmpty && cat.toLowerCase() != 'all' && cat != 'ទាំងអស់') {
        groups.add(cat);
      }
    }

    // 3. Fallbacks if empty
    if (groups.isEmpty) {
      groups.addAll(['GDDTM', 'GDI', 'GNP', 'GDP', 'GIA']);
    }

    final sorted = groups.toList();
    sorted.sort();
    return ['all_units'.tr, ...sorted];
  }

  @override
  void onInit() {
    super.onInit();

    // Trigger admin fetch if available to ensure all department apps are loaded
    if (Get.isRegistered<AdminController>()) {
      final adminCtrl = Get.find<AdminController>();
      if (adminCtrl.appsList.isEmpty && !adminCtrl.isLoading.value) {
        adminCtrl.fetchDashboardData();
      }
      ever(adminCtrl.appsList, (_) => _filterApps());
    }

    // Listener for search input
    searchController.addListener(() {
      rxSearchQuery.value = searchController.text.trim();
    });

    // Listen to changes
    everAll([
      apiApps,
      homeController.services,
      rxSearchQuery,
      selectedFilterTab,
      selectedSubCategory,
      selectedSort,
      selectedStatus,
    ], (_) {
      _filterApps();
    });

    _filterApps();

    // Fetch fresh data from API directly
    fetchAppsFromApi();
  }

  Future<void> fetchAppsFromApi() async {
    await AuthService.waitForAuth();
    final token = await ApiClient.getAccessToken();
    if (token == null || token.isEmpty) return;

    try {
      if (sourceApps.isEmpty) {
        isLoading.value = true;
      }

      final List<dynamic> rawApps = [];
      final Set<String> seenAppKeys = {};

      void addAppIfNew(dynamic app, {bool isGeneral = false}) {
        if (app is Map) {
          final id = (app['id'] ?? app['_id'] ?? '').toString().trim();
          final code = (app['code'] ?? '').toString().trim();
          final name = (app['nameKh'] ??
                  app['title_kh'] ??
                  app['titleKh'] ??
                  app['name'] ??
                  '')
              .toString()
              .trim();
          final key = id.isNotEmpty
              ? 'id:$id'
              : (code.isNotEmpty ? 'code:$code' : 'name:$name');
          if (key.isNotEmpty && !seenAppKeys.contains(key)) {
            seenAppKeys.add(key);
            final copy = Map<String, dynamic>.from(app);
            if (isGeneral) {
              copy['isGeneral'] = true;
            }
            rawApps.add(copy);
          }
        }
      }

      // Fetch portal apps, user tiles, and admin apps concurrently
      final responses = await Future.wait([
        _authService.fetchPortalApps().catchError((e) {
          debugPrint("ApplicationViewController fetchPortalApps error: $e");
          return null;
        }),
        _authService.fetchApps().catchError((e) {
          debugPrint("ApplicationViewController fetchApps tiles error: $e");
          return null;
        }),
        _authService.fetchAdminApps().catchError((e) {
          debugPrint("ApplicationViewController fetchAdminApps error: $e");
          return null;
        }),
      ]);

      final portalAppsRes = responses[0];
      final tilesRes = responses[1];
      final adminAppsRes = responses[2];

      if (portalAppsRes != null) {
        List list = [];
        if (portalAppsRes is List) {
          list = portalAppsRes;
        } else if (portalAppsRes is Map) {
          final data = portalAppsRes['data'] ??
              portalAppsRes['value'] ??
              portalAppsRes['items'] ??
              portalAppsRes['content'] ??
              portalAppsRes['apps'] ??
              [];
          if (data is List) list = data;
        }
        for (var item in list) {
          addAppIfNew(item, isGeneral: false);
        }
      }

      if (tilesRes != null) {
        List list = [];
        if (tilesRes is List) {
          list = tilesRes;
        } else if (tilesRes is Map) {
          final data = tilesRes['data'] ??
              tilesRes['value'] ??
              tilesRes['items'] ??
              tilesRes['content'] ??
              tilesRes['tiles'] ??
              tilesRes['apps'] ??
              [];
          if (data is List) list = data;
        }
        for (var item in list) {
          addAppIfNew(item, isGeneral: false);
        }
      }

      if (adminAppsRes != null) {
        List list = [];
        if (adminAppsRes is List) {
          list = adminAppsRes;
        } else if (adminAppsRes is Map) {
          final data = adminAppsRes['data'] ??
              adminAppsRes['value'] ??
              adminAppsRes['items'] ??
              adminAppsRes['content'] ??
              adminAppsRes['apps'] ??
              [];
          if (data is List) list = data;
        }
        for (var item in list) {
          addAppIfNew(item, isGeneral: true);
        }
      }

      if (rawApps.isNotEmpty) {
        final List<Map<String, dynamic>> parsed = [];
        for (var app in rawApps) {
          final normalized = _normalizeApp(app, token);
          if (normalized.isNotEmpty) {
            parsed.add(normalized);
          }
        }
        apiApps.assignAll(parsed);
        if (homeController.services.isEmpty) {
          final nonGeneral = parsed.where((a) => a['isGeneral'] != true).toList();
          if (nonGeneral.isNotEmpty) {
            homeController.services.assignAll(nonGeneral);
          }
        }
      }
    } catch (e) {
      debugPrint("ApplicationViewController fetchAppsFromApi error: $e");
    } finally {
      isLoading.value = false;
      _filterApps();
    }
  }

  void _filterApps() {
    List<Map<String, dynamic>> result = List.from(sourceApps);

    // Filter tab: all, portal, general
    if (selectedFilterTab.value == 'portal') {
      result = result.where((app) => app['isGeneral'] != true).toList();
    } else if (selectedFilterTab.value == 'general') {
      result = result.where((app) => app['isGeneral'] == true).toList();
    }

    // Search query filter
    if (rxSearchQuery.isNotEmpty) {
      final query = rxSearchQuery.value.toLowerCase();
      result = result.where((app) {
        final String titleKh = (app['titleKh'] ?? app['nameKh'] ?? '').toString().toLowerCase();
        final String titleEn = (app['titleEn'] ?? app['nameEn'] ?? '').toString().toLowerCase();
        final String code = (app['code'] ?? '').toString().toLowerCase();
        final String desc = (app['description'] ?? app['desc'] ?? '').toString().toLowerCase();
        return titleKh.contains(query) ||
            titleEn.contains(query) ||
            code.contains(query) ||
            desc.contains(query);
      }).toList();
    }

    // General Department / Unit filter
    if (selectedSubCategory.value != 'all_units'.tr && selectedSubCategory.value != 'អង្គភាពទាំងអស់' &&
        selectedSubCategory.value != 'sub_category'.tr && selectedSubCategory.value != 'ប្រភេទរង' &&
        selectedSubCategory.value != 'ទាំងអស់' &&
        selectedSubCategory.value != 'all') {
      final target = selectedSubCategory.value.toLowerCase();
      result = result.where((app) {
        final String kh = (app['titleKh'] ?? app['nameKh'] ?? '').toString().toLowerCase();
        final String en = (app['titleEn'] ?? app['nameEn'] ?? '').toString().toLowerCase();
        final String code = (app['code'] ?? '').toString().toLowerCase();
        final String dept = (app['department'] ??
                app['unit'] ??
                app['departmentName'] ??
                app['category'] ??
                app['subCategory'] ??
                '')
            .toString()
            .toLowerCase();

        if (dept.contains(target) ||
            target.contains(dept) ||
            kh.contains(target) ||
            en.contains(target) ||
            code.contains(target)) {
          return true;
        }

        final rawRules = app['accessRules'] is List
            ? app['accessRules']
            : (app['rules'] is List ? app['rules'] : []);
        for (var r in rawRules) {
          if (r is Map) {
            final String rVal =
                (r['ruleValue'] ?? r['value'] ?? r['target'] ?? '')
                    .toString()
                    .toLowerCase();
            if (rVal.contains(target) || target.contains(rVal)) {
              return true;
            }
          }
        }
        return false;
      }).toList();
    }

    // Status filter
    if (selectedStatus.value == 'active') {
      result = result.where((app) {
        final active = app['isActive'] ??
            app['is_active'] ??
            app['active'] ??
            app['enabled'];
        final status = (app['status'] ?? '').toString().toUpperCase();
        if (status == 'INACTIVE' || status == 'DISABLED' || status == '0') {
          return false;
        }
        return active == true || active == 1 || active == 'true' || active == null;
      }).toList();
    } else if (selectedStatus.value == 'inactive') {
      result = result.where((app) {
        final active = app['isActive'] ??
            app['is_active'] ??
            app['active'] ??
            app['enabled'];
        final status = (app['status'] ?? '').toString().toUpperCase();
        return active == false ||
            active == 0 ||
            active == 'false' ||
            status == 'INACTIVE' ||
            status == 'DISABLED';
      }).toList();
    }

    // Sort order
    if (selectedSort.value == 'name_az') {
      result.sort((a, b) {
        final nameA = (a['titleKh'] ?? a['titleEn'] ?? '').toString();
        final nameB = (b['titleKh'] ?? b['titleEn'] ?? '').toString();
        return nameA.compareTo(nameB);
      });
    } else if (selectedSort.value == 'name_za') {
      result.sort((a, b) {
        final nameA = (a['titleKh'] ?? a['titleEn'] ?? '').toString();
        final nameB = (b['titleKh'] ?? b['titleEn'] ?? '').toString();
        return nameB.compareTo(nameA);
      });
    } else if (selectedSort.value == 'oldest') {
      result.sort((a, b) {
        final idA = int.tryParse(a['id']?.toString() ?? '') ?? 0;
        final idB = int.tryParse(b['id']?.toString() ?? '') ?? 0;
        return idA.compareTo(idB);
      });
    } else if (selectedSort.value == 'newest') {
      result.sort((a, b) {
        final idA = int.tryParse(a['id']?.toString() ?? '') ?? 0;
        final idB = int.tryParse(b['id']?.toString() ?? '') ?? 0;
        return idB.compareTo(idA);
      });
    }

    filteredServices.assignAll(result);
  }

  Future<void> refreshApps() async {
    try {
      if (Get.isRegistered<AdminController>()) {
        await Get.find<AdminController>().fetchDashboardData();
      }
      await homeController.fetchPortalApps();
      await fetchAppsFromApi();
    } catch (_) {}
    _filterApps();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
