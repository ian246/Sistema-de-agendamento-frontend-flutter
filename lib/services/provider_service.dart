import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/service_model.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class ProviderService {
  String get baseUrl {
    final url = kIsWeb
        ? dotenv.env['API_URL_WEB']
        : dotenv.env['API_URL_ANDROID'];

    if (url == null || url.isEmpty) {
      throw Exception('URL da API não configurada! Verifique o arquivo .env');
    }

    // Append /api/services to the base URL
    return '$url/api/services';
  }

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // 1. Listar Meus Serviços
  Future<List<ServiceModel>> getMyServices() async {
    final headers = await _getHeaders();
    final url = baseUrl; // Ensure we handle the property access correctly
    final response = await http.get(Uri.parse('$url/me'), headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(response.body);
      return body.map((e) => ServiceModel.fromJson(e)).toList();
    } else {
      throw Exception('Erro ao buscar serviços: ${response.body}');
    }
  }

  // 2. Criar Serviço
  Future<void> createService(ServiceModel service) async {
    final headers = await _getHeaders();
    final url = baseUrl;
    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: jsonEncode(service.toJson()),
    );

    if (response.statusCode != 201) {
      throw Exception('Erro ao criar serviço: ${response.body}');
    }
  }

  // 3. Deletar Serviço
  Future<void> deleteService(String id) async {
    final headers = await _getHeaders();
    final url = baseUrl;
    final response = await http.delete(Uri.parse('$url/$id'), headers: headers);

    if (response.statusCode != 200) {
      throw Exception('Erro ao deletar serviço.');
    }
  }
}
