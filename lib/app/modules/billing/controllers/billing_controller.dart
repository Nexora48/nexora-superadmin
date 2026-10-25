import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/utils/money.dart';
import '../../../data/models/billing_models.dart';
import '../../../data/models/platform_models.dart';
import '../../../data/providers/api_client.dart';
import '../../../data/providers/api_exception.dart';
import '../../../data/repositories/billing_repository.dart';
import '../../../data/repositories/platform_repository.dart';

class BillingController extends GetxController {
  final BillingRepository _repo = BillingRepository(ApiClient.to);
  final PlatformRepository _platform = PlatformRepository(ApiClient.to);

  static const int perPage = 15;
  static const statusFilters = {'All': '', 'Open': 'issued', 'Paid': 'paid'};

  final RxInt tab = 0.obs; // 0 invoices, 1 subscriptions
  final RxString statusFilter = 'All'.obs;
  final RxString period = ''.obs; // '' = every month
  final RxList<PlatformInvoice> invoices = <PlatformInvoice>[].obs;
  final RxInt page = 1.obs;
  final RxInt total = 0.obs;
  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;
  final RxString notice = ''.obs;

  // subscriptions tab: every society with its plan
  final RxList<SocietyRow> societies = <SocietyRow>[].obs;
  final RxMap<String, Subscription> subscriptions =
      <String, Subscription>{}.obs;
  final RxBool loadingSubs = true.obs;

  // dialogs
  final RxBool busy = false.obs;
  final RxString dialogError = ''.obs;
  final rateCtrl = TextEditingController();
  final flatCtrl = TextEditingController();
  final dayCtrl = TextEditingController();
  final RxBool subActive = true.obs;
  final referenceCtrl = TextEditingController();

  int get pages => total.value == 0 ? 1 : (total.value / perPage).ceil();

  List<String> get periods {
    final n = DateTime.now();
    return [
      for (var i = 1; i >= -11; i--)
        DateTime(n.year, n.month + i).toIso8601String().substring(0, 7),
    ];
  }

  @override
  void onInit() {
    super.onInit();
    ever(statusFilter, (_) {
      page.value = 1;
      load();
    });
    ever(period, (_) {
      page.value = 1;
      load();
    });
    load();
    loadSubscriptions();
  }

  @override
  void onClose() {
    rateCtrl.dispose();
    flatCtrl.dispose();
    dayCtrl.dispose();
    referenceCtrl.dispose();
    super.onClose();
  }

  Future<void> load() async {
    isLoading.value = invoices.isEmpty;
    error.value = '';
    try {
      final r = await _repo.invoices(
        status: statusFilters[statusFilter.value],
        period: period.value,
        page: page.value,
        pageSize: perPage,
      );
      invoices.assignAll(r.items);
      total.value = r.total;
    } on ApiException catch (e) {
      error.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadSubscriptions() async {
    try {
      final p = await _platform.societies(pageSize: 100);
      societies.assignAll(p.items);
      for (final s in p.items) {
        try {
          subscriptions[s.id] = await _repo.subscription(s.id);
        } on ApiException {
          // a society without a plan simply shows "not set"
        }
      }
    } on ApiException catch (e) {
      error.value = e.message;
    } finally {
      loadingSubs.value = false;
    }
  }

  void goToPage(int p) {
    if (p < 1 || p > pages) return;
    page.value = p;
    load();
  }

  void _flash(String text) {
    notice.value = text;
    Future.delayed(const Duration(seconds: 4), () {
      if (notice.value == text) notice.value = '';
    });
  }

  Future<bool> _run(Future<void> Function() action) async {
    if (busy.value) return false;
    busy.value = true;
    dialogError.value = '';
    try {
      await action();
      return true;
    } on ApiException catch (e) {
      dialogError.value = e.message;
      return false;
    } finally {
      busy.value = false;
    }
  }

  Future<bool> generate(String p) => _run(() async {
    final n = await _repo.generate(p);
    _flash(
      n == 0
          ? 'Every active society already has an invoice for ${periodLabel(p)}'
          : 'Created $n invoice${n == 1 ? '' : 's'} for ${periodLabel(p)}',
    );
    period.value = p;
    await load();
  });

  void openSubscription(SocietyRow s) {
    final sub = subscriptions[s.id];
    dialogError.value = '';
    rateCtrl.text = sub == null || sub.ratePerUnitPaise == 0
        ? ''
        : (sub.ratePerUnitPaise / 100).toString();
    flatCtrl.text = sub == null || sub.flatFeePaise == 0
        ? ''
        : (sub.flatFeePaise / 100).toString();
    dayCtrl.text = '${sub?.billingDay ?? 1}';
    subActive.value = sub?.active ?? false;
  }

  Future<bool> saveSubscription(SocietyRow s) {
    final rate = parseRupeesOrZero(rateCtrl.text);
    final flat = parseRupeesOrZero(flatCtrl.text);
    final day = int.tryParse(dayCtrl.text.trim());
    if (rate == null || flat == null || day == null) {
      dialogError.value =
          'Enter the amounts in rupees and the billing day as a number.';
      return Future.value(false);
    }
    return _run(() async {
      subscriptions[s.id] = await _repo.saveSubscription(
        s.id,
        ratePerUnitPaise: rate,
        flatFeePaise: flat,
        billingDay: day,
        status: subActive.value ? 'active' : 'paused',
        startsOn:
            subscriptions[s.id]?.startsOn ??
            DateTime.now().toIso8601String().substring(0, 10),
      );
      _flash('Subscription saved for ${s.name}');
    });
  }

  Future<bool> markPaid(PlatformInvoice i) {
    referenceCtrl.text = referenceCtrl.text.trim();
    return _run(() async {
      await _repo.markPaid(i.id, reference: referenceCtrl.text.trim());
      _flash('${i.number} marked as paid');
      await load();
    });
  }
}
