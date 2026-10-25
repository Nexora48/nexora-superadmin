import '../../core/constants/api_endpoints.dart';
import '../models/billing_models.dart';
import '../models/paged.dart';
import '../providers/api_client.dart';

class BillingRepository {
  final ApiClient _api;
  BillingRepository(this._api);

  Map<String, dynamic> _map(dynamic d) => (d as Map).cast<String, dynamic>();

  Future<Subscription> subscription(String societyId) async =>
      Subscription.fromJson(
        _map(await _api.get(ApiEndpoints.subscription(societyId))),
      );

  Future<Subscription> saveSubscription(
    String societyId, {
    required int ratePerUnitPaise,
    required int flatFeePaise,
    required int billingDay,
    required String status,
    required String startsOn,
  }) async => Subscription.fromJson(
    _map(
      await _api.put(
        ApiEndpoints.subscription(societyId),
        body: {
          'rate_per_unit_paise': ratePerUnitPaise,
          'flat_fee_paise': flatFeePaise,
          'billing_day': billingDay,
          'status': status,
          'starts_on': startsOn,
        },
      ),
    ),
  );

  Future<Paged<PlatformInvoice>> invoices({
    String? status,
    String? period,
    int page = 1,
    int pageSize = 15,
  }) async {
    final r = await _api.getPaged(
      ApiEndpoints.platformInvoices,
      query: {
        if (status != null && status.isNotEmpty) 'status': status,
        if (period != null && period.isNotEmpty) 'period': period,
        'page': page,
        'page_size': pageSize,
      },
    );
    return Paged(
      items: (r.data as List)
          .map((e) => PlatformInvoice.fromJson(_map(e)))
          .toList(),
      page: (r.meta['page'] as num?)?.toInt() ?? page,
      pageSize: (r.meta['page_size'] as num?)?.toInt() ?? pageSize,
      total: (r.meta['total'] as num?)?.toInt() ?? 0,
    );
  }

  Future<int> generate(String period) async =>
      (_map(
                await _api.post(
                  ApiEndpoints.platformInvoicesGenerate,
                  body: {'period': period},
                ),
              )['created']
              as num)
          .toInt();

  Future<PlatformInvoice> markPaid(
    String id, {
    required String reference,
    String? paidOn,
  }) async => PlatformInvoice.fromJson(
    _map(
      await _api.post(
        ApiEndpoints.platformInvoicePaid(id),
        body: {'reference': reference, 'paid_on': ?paidOn},
      ),
    ),
  );
}
