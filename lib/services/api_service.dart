import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
// Certifique-se de importar seus models corretos
import '../models/barber_models.dart';
import '../models/appointment_models.dart';
import '../models/service_model.dart'; // <--- Importe o novo model

class ApiService {
  static final String _baseUrl = kIsWeb
      ? dotenv.env['API_URL_WEB'] ?? 'http://localhost:3000/api'
      : dotenv.env['API_URL_ANDROID'] ?? 'http://10.0.2.2:3000/api';

  final Dio _dio = Dio(BaseOptions(baseUrl: _baseUrl));

  // --- 1. BUSCAR BARBEIROS ---
  Future<List<Barber>> getBarbers() async {
    try {
      final response = await _dio.get('/profiles/providers');
      List<dynamic> data = response.data;
      return data.map((json) => Barber.fromJson(json)).toList();
    } catch (e) {
      print("Erro ao buscar barbeiros: $e");
      throw Exception("Falha na conexão com o servidor");
    }
  }

  // --- 2. BUSCAR SERVIÇOS (NOVO!) ---
  Future<List<BarberService>> getServices() async {
    try {
      final response = await _dio.get(
        '/services',
      ); // Chama sua rota GET /services
      List<dynamic> data = response.data;
      return data.map((json) => BarberService.fromJson(json)).toList();
    } catch (e) {
      throw Exception("Erro ao buscar serviços: $e");
    }
  }

  // --- 3. CRIAR AGENDAMENTO (Atualizado com clientId dinâmico) ---
  Future<Map<String, dynamic>> createAppointment({
    required String clientId, // <--- Agora pedimos o ID do cliente
    required String providerId,
    required String serviceId,
    required DateTime date,
    required String time,
  }) async {
    try {
      final timeParts = time.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);

      final fullDateTime = DateTime(
        date.year,
        date.month,
        date.day,
        hour,
        minute,
      );

      final response = await _dio.post(
        '/appointments',
        data: {
          "client_id": clientId, // <--- Usa o ID real, não o fixo
          "provider_id": providerId,
          "service_id": serviceId,
          "start_time": fullDateTime.toIso8601String(),
        },
      );

      return response.data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        throw Exception("Horário indisponível! O barbeiro já está ocupado.");
      }
      throw Exception("Erro ao agendar: ${e.response?.data}");
    }
  }

  // --- 4. MEUS AGENDAMENTOS ---
  Future<List<Appointment>> getMyAppointments(String clientId) async {
    try {
      final response = await _dio.get('/appointments/client/$clientId');
      List<dynamic> data = response.data;
      return data.map((json) => Appointment.fromJson(json)).toList();
    } catch (e) {
      throw Exception("Erro: $e");
    }
  }

  // --- 5. CRIAR SERVIÇO ---
  Future<void> createService({
    required String title,
    required String description,
    required double price,
    required int duration,
  }) async {
    try {
      await _dio.post(
        '/services',
        data: {
          "title": title,
          "description": description,
          "price": price,
          "duration": duration,
        },
      );
    } catch (e) {
      throw Exception("Erro ao criar serviço: $e");
    }
  }
}
