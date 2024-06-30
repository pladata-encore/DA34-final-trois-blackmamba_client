import 'package:dio/dio.dart';
import 'dart:convert';

class CarService {
  final Dio _dio = Dio();

  Future<Map<String, Map<String, List<Map<String, dynamic>>>>>
      getCarMenuList() async {
    try {
      final response = await _dio.get('http://10.0.2.2:8000/carmenu');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return data.map((key, value) => MapEntry(
            key,
            (value as Map<String, dynamic>).map((key, value) => MapEntry(
                key,
                (value as List<dynamic>)
                    .map((e) => Map<String, dynamic>.from(e as Map))
                    .toList()))));
      } else {
        throw Exception('Failed to load car menu');
      }
    } catch (e) {
      throw Exception('Failed to load car menu: $e');
    }
  }
}
