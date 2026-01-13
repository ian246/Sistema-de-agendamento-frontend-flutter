import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import '../../models/service_model.dart';
import '../../services/provider_service.dart';
import 'provider/create_service_screen.dart';
import '../../utils/theme.dart';

class ProviderHomeScreen extends StatefulWidget {
  const ProviderHomeScreen({super.key});

  @override
  State<ProviderHomeScreen> createState() => _ProviderHomeScreenState();
}

class _ProviderHomeScreenState extends State<ProviderHomeScreen> {
  final _providerService = ProviderService();
  late Future<List<ServiceModel>> _servicesFuture;
  String _providerEmail = '';

  @override
  void initState() {
    super.initState();
    _loadProviderInfo();
    _loadServices();
  }

  Future<void> _loadProviderInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _providerEmail = prefs.getString('userEmail') ?? '';
    });
  }

  void _loadServices() {
    setState(() {
      _servicesFuture = _providerService.getMyServices();
    });
  }

  Future<void> _deleteService(String id) async {
    try {
      await _providerService.deleteService(id);
      _loadServices(); // Recarrega a lista
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Serviço removido!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao deletar: $e')));
      }
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Meus Serviços"),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: FutureBuilder<List<ServiceModel>>(
        future: _servicesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Erro: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.work_off_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Nenhum serviço cadastrado para\n$_providerEmail',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Clique no + para adicionar seu primeiro serviço!',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          final services = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.content_cut, color: Colors.white),
                  ),
                  title: Text(
                    service.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "R\$ ${service.price.toStringAsFixed(2)} • ${service.duration} min",
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text("Excluir Serviço?"),
                        content: const Text("Essa ação não pode ser desfeita."),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text("Cancelar"),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                              _deleteService(service.id);
                            },
                            child: const Text(
                              "Excluir",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () async {
          // Vai para a tela de criar e espera voltar
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateServiceScreen(),
            ),
          );
          // Se voltou com "true" (criou serviço), atualiza a lista
          if (result == true) {
            _loadServices();
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
