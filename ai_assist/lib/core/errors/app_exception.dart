import 'package:dio/dio.dart';

/// A user-safe error. Screens display [message] directly; the raw technical
/// detail ([debugDetail]) is only ever written to logs, never shown in the
/// UI (spec §44: "Never show raw exceptions to the user").
class AppException implements Exception {
  final String message;
  final String? debugDetail;
  final int? statusCode;

  const AppException(this.message, {this.debugDetail, this.statusCode});

  factory AppException.fromDioException(DioException e) {
    final status = e.response?.statusCode;
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionError:
        return AppException('No internet connection.',
            debugDetail: e.message, statusCode: status);
      default:
        break;
    }
    if (status == 401) {
      return AppException(
          'Your OpenRouter API key was rejected. Check it in Settings -> AI Configuration.',
          debugDetail: e.message, statusCode: status);
    }
    if (status == 429) {
      return AppException('AI service rate limit reached. Please try again shortly.',
          debugDetail: e.message, statusCode: status);
    }
    if (status != null && status >= 500) {
      return AppException('AI service is temporarily unavailable.',
          debugDetail: e.message, statusCode: status);
    }
    return AppException('Something went wrong. Please try again.',
        debugDetail: e.message, statusCode: status);
  }

  @override
  String toString() => message;
}
