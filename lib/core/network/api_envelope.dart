class ApiEnvelope<T> {
  final String code;
  final String message;
  final T data;

  const ApiEnvelope({
    required this.code,
    required this.message,
    required this.data,
  });

  bool get isSuccess => code == '00000';

  factory ApiEnvelope.fromJson(
    Map<String, dynamic> json,
    T Function(Object? value) fromData,
  ) {
    return ApiEnvelope<T>(
      code: json['code'] as String? ?? '',
      message: json['message'] as String? ?? '',
      data: fromData(json['data']),
    );
  }
}
