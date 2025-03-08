import 'package:http/http.dart';

class HttpRequestException implements Exception {
  final String? message;
  final Response? response;
  final StreamedResponse? streamedResponse;

  int get statusCode => response?.statusCode ?? streamedResponse!.statusCode;

  HttpRequestException({this.message, this.response, this.streamedResponse})
    : assert(response != null || streamedResponse != null);

  @override
  String toString() {
    final request = response?.request ?? streamedResponse!.request;
    final statusCode = response?.statusCode ?? streamedResponse!.statusCode;
    return "Http ${request!.method} ${request.url} failed with $statusCode: $message";
  }
}

class ExamNotFoundException implements Exception {
  final String examId;
  ExamNotFoundException( {required this.examId,});

  @override
  String toString() {
    return "找不到Id为$examId的测评方案";
  }
}