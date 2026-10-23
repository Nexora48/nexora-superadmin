class HealthStatus {
  final String status;
  final String service;

  const HealthStatus({required this.status, required this.service});

  factory HealthStatus.fromJson(Map<String, dynamic> json) => HealthStatus(
        status: '${json['status']}',
        service: '${json['service']}',
      );

  bool get isOk => status == 'ok';
}
