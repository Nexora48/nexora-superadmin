import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/platform_models.dart';
import '../../../data/providers/api_client.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/repositories/platform_repository.dart';
import '../../../routes/app_pages.dart';

class SocietiesController extends GetxController {
  final PlatformRepository _repo = PlatformRepository(ApiClient.to);

  static const filters = ['All', 'Active', 'Trial', 'Suspended'];
  static const int perPage = 10;

  final selectedFilter = 'All'.obs;
  final currentPage = 1.obs;
  final total = 0.obs;
  final searchCtrl = TextEditingController();
  Timer? _debounce;

  final RxList<SocietyRow> items = <SocietyRow>[].obs;
  final isLoading = true.obs;
  // society counts for the summary tiles: all, active, trial, suspended
  final RxList<int> counts = <int>[0, 0, 0, 0].obs;
  final error = ''.obs;

  int get totalPages => (total.value / perPage).ceil().clamp(1, 1 << 30);

  @override
  void onInit() {
    super.onInit();
    ever(selectedFilter, (_) {
      currentPage.value = 1;
      load();
    });
    load();
    loadCounts();
  }

  @override
  void onClose() {
    _debounce?.cancel();
    searchCtrl.dispose();
    super.onClose();
  }

  Future<void> load() async {
    isLoading.value = items.isEmpty;
    error.value = '';
    try {
      final f = selectedFilter.value;
      final page = await _repo.societies(
        q: searchCtrl.text.trim(),
        status: f == 'All' ? null : f.toLowerCase(),
        page: currentPage.value,
        pageSize: perPage,
      );
      total.value = page.total;
      items.assignAll(page.items);
    } on ApiException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  /// One tiny request per status: only the totals are used.
  Future<void> loadCounts() async {
    try {
      final r = await Future.wait([
        _repo.societies(q: '', status: null, page: 1, pageSize: 1),
        _repo.societies(q: '', status: 'active', page: 1, pageSize: 1),
        _repo.societies(q: '', status: 'trial', page: 1, pageSize: 1),
        _repo.societies(q: '', status: 'suspended', page: 1, pageSize: 1),
      ]);
      counts.assignAll([for (final p in r) p.total]);
    } on ApiException {
      // the tiles are cosmetic
    }
  }

  void onSearchChanged(String _) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      currentPage.value = 1;
      load();
    });
  }

  void goToPage(int p) {
    if (p >= 1 && p <= totalPages) {
      currentPage.value = p;
      load();
    }
  }

  Future<void> openDetail(String id) async {
    await Get.toNamed(Routes.societyDetail, arguments: id);
    load();
  }

  Future<void> openCreate() async {
    await Get.toNamed(Routes.societyCreate);
    load();
  }
}
