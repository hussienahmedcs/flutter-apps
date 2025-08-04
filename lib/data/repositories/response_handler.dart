class Result<T> {
  final bool success;
  final String message;
  final T? data;

  Result({required this.success, required this.message, this.data});

  factory Result.success(T? data, {String message = "Success"}) => Result(success: true, message: message, data: data);

  factory Result.error(String message) => Result(success: false, message: message);
}
