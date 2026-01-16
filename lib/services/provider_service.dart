import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/service_model.dart';
import '../models/barber_models.dart';
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

    return url;
  }

  String get servicesUrl => '$baseUrl/api/services';

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('accessToken');
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ========== PROFILE METHODS ==========

  // Buscar perfil do provider logado
  Future<Barber> getMyProfile() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/api/profiles/me'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Barber.fromJson(data);
    } else {
      throw Exception('Erro ao buscar perfil: ${response.body}');
    }
  }

  // Atualizar perfil do provider
  // Usa um parâmetro opcional para indicar se a imagem deve ser removida
  Future<void> updateProfile({
    String? salonName,
    String? address,
    String? phone,
    String? salonImageUrl,
    bool clearSalonImage = false,
  }) async {
    final headers = await _getHeaders();
    final body = <String, dynamic>{};

    if (salonName != null) body['salon_name'] = salonName;
    if (address != null) body['address'] = address;
    if (phone != null) body['phone'] = phone;
    if (salonImageUrl != null) {
      body['salon_image_url'] = salonImageUrl;
    } else if (clearSalonImage) {
      body['salon_image_url'] = '';
    }

    final response = await http.put(
      Uri.parse('$baseUrl/api/profiles/me'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao atualizar perfil: ${response.body}');
    }
  }

  // ========== APPOINTMENTS METHODS ==========

  // Buscar agendamentos do provider logado
  Future<List<Map<String, dynamic>>> getMyAppointments() async {
    final headers = await _getHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl/api/appointments/provider/me'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.cast<Map<String, dynamic>>();
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception('Erro ao buscar agendamentos: ${response.body}');
    }
  }

  // ========== SERVICES METHODS ==========

  // 1. Listar Meus Serviços
  Future<List<ServiceModel>> getMyServices() async {
    final headers = await _getHeaders();
    final url = servicesUrl;

    final response = await http.get(Uri.parse('$url/me'), headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(response.body);
      return body.map((e) => ServiceModel.fromJson(e)).toList();
    } else if (response.statusCode == 404) {
      return [];
    } else {
      throw Exception('Erro ao buscar serviços: ${response.body}');
    }
  }

  // 2. Criar Serviço
  Future<void> createService(ServiceModel service) async {
    final headers = await _getHeaders();
    final url = servicesUrl;
    final payload = jsonEncode(service.toJson());

    final response = await http.post(
      Uri.parse(url),
      headers: headers,
      body: payload,
    );

    if (response.statusCode != 201) {
      throw Exception('Erro ao criar serviço: ${response.body}');
    }
  }

  // 3. Atualizar Serviço
  Future<void> updateService(String id, ServiceModel service) async {
    final headers = await _getHeaders();
    final url = '$servicesUrl/$id';
    final payload = jsonEncode(service.toJson());

    final response = await http.put(
      Uri.parse(url),
      headers: headers,
      body: payload,
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao atualizar serviço: ${response.body}');
    }
  }

  // 4. Deletar Serviço
  Future<void> deleteService(String id) async {
    final headers = await _getHeaders();
    final url = '$servicesUrl/$id';

    final response = await http.delete(Uri.parse(url), headers: headers);

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Erro ao deletar serviço: ${response.body}');
    }
  }

  // 4. Buscar Serviços de um Provider Específico (Para o Cliente)
  Future<List<ServiceModel>> getServicesByProviderId(String providerId) async {
    final headers = await _getHeaders();
    final url = servicesUrl;

    final response = await http.get(
      Uri.parse('$url/provider/$providerId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> body = jsonDecode(response.body);
      return body.map((e) => ServiceModel.fromJson(e)).toList();
    } else {
      throw Exception('Erro ao buscar serviços do barbeiro: ${response.body}');
    }
  }
}
