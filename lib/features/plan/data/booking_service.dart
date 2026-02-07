import 'package:dio/dio.dart';

class BookingService {
  BookingService({required this.baseUrl, required Dio dio}) : _dio = dio;

  final String baseUrl;
  final Dio _dio;

  Future<String> getBookingUrl({
    required String type, 
    required Map<String, dynamic> payload,
  }) async {
    final resp = await _dio.post(
      '$baseUrl/v1/book/link',
      data: {'type': type, 'payload': payload},
    );

    final data = resp.data as Map;
    return data['url'] as String;
  }
}
