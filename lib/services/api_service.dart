import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
// Certifique-se de importar seus models corretos
import '../models/barber_models.dart';
import '../models/appointment_models.dart';
import '../models/service_model.dart'; // <--- Importe o novo model

class ApiService {
  static String get _baseUrl {
    final url = kIsWeb
        ? dotenv.env['API_URL_WEB']
        : dotenv.env['API_URL_ANDROID'];

    if (url == null || url.isEmpty) {
      throw Exception('URL da API não configurada! Verifique o arquivo .env');
    }

    // Valida se a URL tem o protocolo
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      throw Exception(
        'URL da API inválida: "$url". Deve começar com http:// ou https://',
      );
    }

    return url;
  }

  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(
        seconds: 60,
      ), // Aumentado para Render free tier
      receiveTimeout: const Duration(seconds: 60),
    ),
  );

  // --- 1. BUSCAR BARBEIROS ---
  Future<List<Barber>> getBarbers() async {
    try {
      final response = await _dio.get('/api/profiles/providers');
      List<dynamic> data = response.data;
      return data.map((json) => Barber.fromJson(json)).toList();
    } on DioException catch (e) {
      print("Erro ao buscar barbeiros: $e");

      // Mensagens de erro mais específicas
      if (e.type == DioExceptionType.connectionTimeout) {
        throw Exception(
          "Tempo de conexão esgotado.\n\n"
          "Se o servidor está no Render (plano gratuito),\n"
          "pode levar até 60s para acordar.\n"
          "Tente novamente em alguns segundos.",
        );
      } else if (e.type == DioExceptionType.receiveTimeout) {
        throw Exception(
          "Servidor demorou muito para responder.\nTente novamente.",
        );
      } else if (e.type == DioExceptionType.connectionError) {
        throw Exception(
          "Não foi possível conectar ao servidor.\n\n"
          "Verifique:\n"
          "• O backend está rodando?\n"
          "• A URL está correta? ($_baseUrl)\n"
          "• Você está conectado à internet?",
        );
      } else if (e.response?.statusCode == 404) {
        throw Exception(
          "Endpoint não encontrado.\nVerifique se a rota /profiles/providers existe no backend.",
        );
      } else if (e.response?.statusCode == 500) {
        throw Exception(
          "Erro interno do servidor.\nVerifique os logs do backend.",
        );
      } else {
        throw Exception(
          "Erro ao conectar com o servidor.\n${e.message ?? 'Erro desconhecido'}",
        );
      }
    } catch (e) {
      print("Erro inesperado ao buscar barbeiros: $e");
      throw Exception("Erro inesperado: $e");
    }
  }

  // --- 2. BUSCAR SERVIÇOS (NOVO!) ---
  Future<List<BarberService>> getServices() async {
    try {
      final response = await _dio.get(
        '/api/services',
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
        '/api/appointments',
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
      final response = await _dio.get('/api/appointments/client/$clientId');
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
        '/api/services',
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
