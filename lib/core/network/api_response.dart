/// Uniform result wrapper so repositories/controllers never touch raw Dio
/// exceptions. Success carries [data]; failure carries [message].
class ApiResponse<T> {
  final T? data;
  final String? message;
  final bool success;

  const ApiResponse._({this.data, this.message, required this.success});

  factory ApiResponse.success(T data) =>
      ApiResponse._(data: data, success: true);

  factory ApiResponse.failure(String message) =>
      ApiResponse._(message: message, success: false);
}
