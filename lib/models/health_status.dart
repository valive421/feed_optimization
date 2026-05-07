enum HealthStatus {
  connected,
  error,
}

class HealthCheckResult {
  const HealthCheckResult({
    required this.status,
    this.message,
  });

  final HealthStatus status;
  final String? message;

  bool get isConnected => status == HealthStatus.connected;

  factory HealthCheckResult.connected() {
    return const HealthCheckResult(status: HealthStatus.connected);
  }

  factory HealthCheckResult.error(String message) {
    return HealthCheckResult(status: HealthStatus.error, message: message);
  }
}
