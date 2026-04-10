class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  @override
  String toString() => "API ERROR $statusCode: $message";
}

class UnauthorizedException extends ApiException {
  UnauthorizedException() : super(401, "Unauthorized");
}

class NotFoundException extends ApiException {
  NotFoundException() : super(404, "Not Found");
}

class ServerException extends ApiException {
  ServerException() : super(500, "Server Error");
}
