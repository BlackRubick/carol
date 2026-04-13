import 'dart:convert';
import 'package:http/http.dart' as http;

class InfartoPredictionService {
  static const String apiUrl = 'http://192.168.3.44:5000/api/prediccion_infarto';

  static Future<bool> fetchInfartoRisk() async {
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['riesgo_infarto'] == true;
    } else {
      throw Exception('Error al obtener predicción de infarto');
    }
  }
}
