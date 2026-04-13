import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/heart_rate_sample.dart';

class HeartRateApiService {
  static const String apiUrl = 'http://192.168.3.44:5000/api/datos';

  static Future<List<HeartRateSample>> fetchHeartRates() async {
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((e) => HeartRateSample.fromJson(e)).toList();
    } else {
      throw Exception('Error al obtener datos del API');
    }
  }
}
