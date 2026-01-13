import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart'
    show kIsWeb; // Para saber se é Web ou App

class AuthService {
  // Pega a URL correta dependendo de onde está rodando
  String get baseUrl {
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

  // --- LOGIN ---
  Future<void> signIn({required String email, required String password}) async {
    try {
      final url = Uri.parse('$baseUrl/api/auth/login');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Sucesso! Salva o token e dados do usuário no celular
        print("Login Success: $data"); // DEBUG LOG
        final token = data['token'];
        final user = data['user'];
        final userId = user['id'];
        final email = user['email'] ?? '';
        final name = user['name'] ?? '';
        // Role agora vem direto do login (backend atualizado)
        final role = user['role'] ?? 'client';

        print("Role detectado: $role"); // DEBUG

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('accessToken', token);
        await prefs.setString('userId', userId);
        await prefs.setString('userEmail', email);
        await prefs.setString('userName', name);
        await prefs.setString('userRole', role);
      } else {
        // Erro vindo da API (Ex: Senha incorreta)
        throw Exception(data['error'] ?? 'Erro ao fazer login');
      }
    } on FormatException catch (e) {
      throw Exception('URL da API mal formatada: ${e.message}');
    } on http.ClientException catch (e) {
      throw Exception(
        'Erro de conexão: Verifique se a URL está correta e se há conexão com a internet. URL: $baseUrl',
      );
    } catch (_) {
      // Repassa o erro para a tela mostrar o SnackBar
      rethrow;
    }
  }

  // --- CADASTRO ---
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
    required String phone, // Novo campo
  }) async {
    final url = Uri.parse('$baseUrl/api/auth/register');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'name': fullName,
          'role': role,
          'phone': phone, // Enviando telefone
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Sucesso no cadastro
      } else {
        throw Exception(data['error'] ?? 'Erro ao cadastrar');
      }
    } catch (e) {
      rethrow;
    }
  }

  // --- LOGOUT ---
  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    await prefs.remove('userId');
    await prefs.remove('userEmail');
    await prefs.remove('userName');
  }

  // --- OBTER DADOS DO USUÁRIO ---
  Future<Map<String, String>> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'userId': prefs.getString('userId') ?? '',
      'email': prefs.getString('userEmail') ?? 'Email não disponível',
      'name': prefs.getString('userName') ?? 'Cliente',
    };
  }
}
