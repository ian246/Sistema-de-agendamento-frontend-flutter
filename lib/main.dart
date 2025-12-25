import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:Bcorte/utils/theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Importante!
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  // Preserva o splash screen
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Carrega as variáveis de ambiente
  await dotenv.load(fileName: ".env");

  // Inicializa o Supabase (pode manter, caso use recursos de realtime depois)
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  // --- VERIFICAÇÃO DE LOGIN (AQUI ESTÁ A MÁGICA) ---
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('accessToken');
  // Se tiver token, o usuário está logado
  final bool isLoggedIn = token != null && token.isNotEmpty;
  // --------------------------------------------------

  // Aguarda 2 segundos (efeito visual do splash)
  await Future.delayed(const Duration(seconds: 2));

  // Remove o splash
  FlutterNativeSplash.remove();

  // Passamos o status do login para o MyApp
  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn; // Recebe a informação

  // Construtor atualizado para receber o isLoggedIn
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Corte & Estilo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      // Se estiver logado vai pra Home, senão vai pro Login
      home: isLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}
