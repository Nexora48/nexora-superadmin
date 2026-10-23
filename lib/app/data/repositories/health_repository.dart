import '../../core/constants/api_endpoints.dart';
import '../models/health_status.dart';
import '../providers/api_client.dart';

class HealthRepository {
  final ApiClient _api;
  HealthRepository(this._api);

  Future<HealthStatus> check() async {
    final data = await _api.getRoot(ApiEndpoints.health);
    return HealthStatus.fromJson((data as Map).cast<String, dynamic>());
  }
}
