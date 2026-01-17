import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import '../../models/service_model.dart';
import '../../services/provider_service.dart';
import 'provider/create_service_screen.dart';
import 'provider/edit_service_screen.dart';
import 'provider/edit_profile_screen.dart';
import 'provider/provider_schedule_screen.dart';
import '../../utils/theme.dart';

class ProviderHomeScreen extends StatefulWidget {
  const ProviderHomeScreen({super.key});

  @override
  State<ProviderHomeScreen> createState() => _ProviderHomeScreenState();
}

class _ProviderHomeScreenState extends State<ProviderHomeScreen>
    with SingleTickerProviderStateMixin {
  final _providerService = ProviderService();
  TabController? _tabController;
  int _currentTabIndex = 0;

  Future<List<ServiceModel>>? _servicesFuture;
  Future<List<Map<String, dynamic>>>? _appointmentsFuture;
  String _providerName = '';
  String _salonName = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController!.addListener(() {
      setState(() {
        _currentTabIndex = _tabController!.index;
      });
    });
    _loadProviderInfo();
    _loadData();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _loadProviderInfo() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final profile = await _providerService.getMyProfile();
      setState(() {
        _providerName = profile.name;
        _salonName = profile.salonName ?? '';
      });
    } catch (e) {
      setState(() {
        _providerName = prefs.getString('userName') ?? 'Provider';
      });
    }
  }

  void _loadData() {
    setState(() {
      _servicesFuture = _providerService.getMyServices();
      _appointmentsFuture = _providerService.getMyAppointments();
    });
  }

  Future<void> _deleteService(String id) async {
    try {
      await _providerService.deleteService(id);
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Serviço removido com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String message = e.toString().replaceAll('Exception: ', '');

        // Improve checking for specific backend errors
        if (message.contains('foreign key constraint') ||
            message.contains('appointments_service_id_fkey')) {
          message =
              'Não é possível excluir um serviço que possui agendamentos associados.';
        } else if (message.contains('update or delete on table')) {
          message = 'Não é possível excluir este serviço no momento.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
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

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'confirmed':
      case 'confirmado':
        return const Color(0xFF22C55E);
      case 'pending':
      case 'pendente':
        return const Color(0xFFF59E0B);
      case 'cancelled':
      case 'cancelado':
        return Colors.red;
      default:
        return AppColors.grey;
    }
  }

  String _getStatusLabel(String? status) {
    switch (status?.toLowerCase()) {
      case 'confirmed':
        return 'Confirmado';
      case 'pending':
        return 'Pendente';
      case 'cancelled':
        return 'Cancelado';
      default:
        return status ?? 'Pendente';
    }
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'confirmed':
      case 'confirmado':
        return Icons.check_circle;
      case 'pending':
      case 'pendente':
        return Icons.schedule;
      case 'cancelled':
      case 'cancelado':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  void _showAppointmentDetails(Map<String, dynamic> appointment) {
    final client = appointment['client'] ?? {};
    final service = appointment['service'] ?? {};
    final startTime = DateTime.tryParse(appointment['start_time'] ?? '');

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.grey.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppColors.primary,
                      child: Text(
                        (client['full_name'] ?? 'C')[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            client['full_name'] ?? 'Cliente',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                appointment['status'],
                              ).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getStatusIcon(appointment['status']),
                                  size: 14,
                                  color: _getStatusColor(appointment['status']),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _getStatusLabel(appointment['status']),
                                  style: TextStyle(
                                    color: _getStatusColor(
                                      appointment['status'],
                                    ),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(color: AppColors.grey),
                const SizedBox(height: 16),
                _buildDetailItem(
                  icon: Icons.content_cut,
                  label: 'Serviço',
                  value: service['title'] ?? service['name'] ?? 'Não informado',
                ),
                const SizedBox(height: 16),
                _buildDetailItem(
                  icon: Icons.attach_money,
                  label: 'Valor',
                  value:
                      'R\$ ${(appointment['price'] ?? 0).toStringAsFixed(2)}',
                  valueColor: AppColors.primary,
                ),
                const SizedBox(height: 16),
                _buildDetailItem(
                  icon: Icons.calendar_today,
                  label: 'Data e Horário',
                  value: startTime != null
                      ? '${startTime.day.toString().padLeft(2, '0')}/${startTime.month.toString().padLeft(2, '0')}/${startTime.year} às ${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}'
                      : 'Não informada',
                ),
                const SizedBox(height: 16),
                _buildDetailItem(
                  icon: Icons.phone_outlined,
                  label: 'Telefone',
                  value: client['phone'] ?? 'Não informado',
                ),
                const SizedBox(height: 16),
                _buildDetailItem(
                  icon: Icons.email_outlined,
                  label: 'Email',
                  value: client['email'] ?? 'Não informado',
                ),
                // --- MOTIVO DO CANCELAMENTO (SE CANCELADO) ---
                if ((appointment['status']?.toLowerCase() == 'cancelled' ||
                        appointment['status']?.toLowerCase() == 'cancelado') &&
                    appointment['cancellation_reason'] != null &&
                    (appointment['cancellation_reason'] as String)
                        .isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Divider(color: AppColors.grey),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.cancel_outlined,
                          color: Colors.red,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Motivo do cancelamento:',
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Text(
                      appointment['cancellation_reason'],
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],

                // --- DESCRIÇÃO DO CORTE ---
                if (appointment['cut_description'] != null &&
                    (appointment['cut_description'] as String).isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Divider(color: AppColors.grey),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.description_outlined,
                          color: Colors.orange,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'O que o cliente deseja:',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.withOpacity(0.3)),
                    ),
                    child: Text(
                      appointment['cut_description'],
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
                // --- FOTO DE REFERÊNCIA ---
                if (appointment['reference_image_url'] != null &&
                    (appointment['reference_image_url'] as String)
                        .isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.photo_library_outlined,
                          color: Colors.blue,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Foto de referência:',
                        style: TextStyle(
                          color: Colors.blue,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => _showReferenceImageFullScreen(
                      context,
                      appointment['reference_image_url'],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        appointment['reference_image_url'],
                        width: double.infinity,
                        height: 200,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return SizedBox(
                            height: 200,
                            child: Center(
                              child: CircularProgressIndicator(
                                value:
                                    loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                    : null,
                                color: AppColors.primary,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          height: 200,
                          color: AppColors.background,
                          child: const Center(
                            child: Icon(
                              Icons.broken_image_outlined,
                              color: AppColors.grey,
                              size: 48,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Toque na imagem para ampliar',
                    style: TextStyle(color: AppColors.grey, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 24),

                // Botão de Cancelar para agendamentos confirmados ou pendentes
                if (appointment['status']?.toLowerCase() != 'cancelled' &&
                    appointment['status']?.toLowerCase() != 'cancelado')
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 24),
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showCancellationOptionsDialog(appointment['id']);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Cancelar Agendamento'),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showReferenceImageFullScreen(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.close,
                      color: AppColors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return SizedBox(
                    height: 300,
                    child: Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                            : null,
                        color: AppColors.primary,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: AppColors.grey, fontSize: 12),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  color: valueColor ?? AppColors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // App Bar com gradiente
          SliverAppBar(
            expandedHeight: 140,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.surface, AppColors.background],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Olá, $_providerName! 👋',
                                    style: const TextStyle(
                                      color: AppColors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (_salonName.isNotEmpty)
                                    Text(
                                      _salonName,
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 14,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            // Ações
                            IconButton(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const EditProfileScreen(),
                                  ),
                                );
                                if (result == true) {
                                  _loadProviderInfo();
                                }
                              },
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.person_outline,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: _logout,
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.logout,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.grey,
              tabs: [
                Tab(
                  icon: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _appointmentsFuture,
                    builder: (context, snapshot) {
                      int pendingCount = 0;
                      if (snapshot.hasData) {
                        pendingCount = snapshot.data!
                            .where(
                              (a) =>
                                  a['status']?.toLowerCase() == 'pending' ||
                                  a['status']?.toLowerCase() == 'pendente',
                            )
                            .length;
                      }
                      return Badge(
                        label: Text('$pendingCount'),
                        isLabelVisible: pendingCount > 0,
                        backgroundColor: Colors.red,
                        child: const Icon(Icons.calendar_today),
                      );
                    },
                  ),
                  text: 'Agenda',
                ),
                const Tab(icon: Icon(Icons.content_cut), text: 'Serviços'),
                const Tab(
                  icon: Icon(Icons.cancel_presentation),
                  text: 'Cancelados',
                ),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            // Tab Agenda
            _buildAgendaTab(showCancelled: false),
            // Tab Serviços
            _buildServicesTab(),
            // Tab Cancelados
            _buildAgendaTab(showCancelled: true),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: () async {
          if (_currentTabIndex == 1) {
            // Criar serviço
            final result = await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const CreateServiceScreen(),
              ),
            );
            if (result == true) {
              _loadData();
            }
          } else {
            // Ver agenda completa
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const ProviderScheduleScreen(),
              ),
            );
          }
        },
        child: Icon(
          _currentTabIndex == 1 ? Icons.add : Icons.calendar_month,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildAgendaTab({required bool showCancelled}) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _appointmentsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Erro ao carregar agenda',
                  style: const TextStyle(color: AppColors.white, fontSize: 18),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tentar Novamente'),
                ),
              ],
            ),
          );
        }

        final allAppointments = snapshot.data ?? [];

        // Filtra baseado na aba (Show Cancelled or Not)
        final appointments = allAppointments.where((apt) {
          final status = apt['status']?.toLowerCase() ?? '';
          final isCancelled = status == 'cancelled' || status == 'cancelado';
          return showCancelled ? isCancelled : !isCancelled;
        }).toList();

        if (appointments.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.event_available,
                  size: 80,
                  color: AppColors.grey.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Nenhum agendamento',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Quando clientes marcarem horários,\neles aparecerão aqui!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.grey),
                ),
              ],
            ),
          );
        }

        // Ordena por data
        appointments.sort((a, b) {
          final dateA =
              DateTime.tryParse(a['start_time'] ?? '') ?? DateTime.now();
          final dateB =
              DateTime.tryParse(b['start_time'] ?? '') ?? DateTime.now();
          return dateA.compareTo(dateB);
        });

        // Agrupa por data
        final groupedAppointments = <String, List<Map<String, dynamic>>>{};
        for (final apt in appointments) {
          final date = DateTime.tryParse(apt['start_time'] ?? '');
          if (date != null) {
            final key =
                '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
            groupedAppointments.putIfAbsent(key, () => []);
            groupedAppointments[key]!.add(apt);
          }
        }

        return RefreshIndicator(
          onRefresh: () async => _loadData(),
          color: AppColors.primary,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groupedAppointments.length,
            itemBuilder: (context, index) {
              final date = groupedAppointments.keys.elementAt(index);
              final dayAppointments = groupedAppointments[date]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header da data
                  Container(
                    margin: EdgeInsets.only(
                      bottom: 12,
                      top: index > 0 ? 16 : 0,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '📅 $date',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  // Cards de agendamento
                  ...dayAppointments.map(
                    (appointment) => _buildAppointmentCard(appointment),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _updateAppointmentStatus(
    String id,
    String status, {
    String? cancellationReason,
  }) async {
    try {
      await _providerService.updateAppointmentStatus(
        id,
        status,
        cancellationReason: cancellationReason,
      );
      _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              status == 'confirmed'
                  ? 'Agendamento confirmado!'
                  : 'Agendamento recusado',
            ),
            backgroundColor: status == 'confirmed' ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showCancellationOptionsDialog(String appointmentId) {
    final reasonController = TextEditingController();
    String selectedReason = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final options = [
            'Imprevisto pessoal',
            'Cliente desistiu',
            'Cliente não compareceu',
            'Outro',
          ];

          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: const Text(
              'Cancelar Agendamento',
              style: TextStyle(color: AppColors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Selecione o motivo:',
                  style: TextStyle(color: AppColors.grey),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: options.map((option) {
                    final isSelected = selectedReason == option;
                    return ChoiceChip(
                      label: Text(option),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          selectedReason = selected ? option : '';
                          if (option != 'Outro') {
                            reasonController.text = option;
                          } else {
                            reasonController.text = '';
                          }
                        });
                      },
                      selectedColor: Colors.red.withOpacity(0.2),
                      backgroundColor: AppColors.background,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.red : AppColors.grey,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? Colors.red : Colors.transparent,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (selectedReason == 'Outro' ||
                    (selectedReason.isNotEmpty &&
                        !options.contains(selectedReason))) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: reasonController,
                    style: const TextStyle(color: AppColors.white),
                    decoration: InputDecoration(
                      hintText: 'Digite o motivo...',
                      hintStyle: TextStyle(
                        color: AppColors.grey.withOpacity(0.5),
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    maxLines: 2,
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Voltar',
                  style: TextStyle(color: AppColors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  final reason = reasonController.text.trim();
                  if (reason.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Por favor, informe um motivo.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }
                  Navigator.pop(ctx);
                  _updateAppointmentStatus(
                    appointmentId,
                    'cancelled',
                    cancellationReason: reason,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirmar Cancelamento'),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    final client = appointment['client'] ?? {};
    final service = appointment['service'] ?? {};
    final status = appointment['status'] as String?;
    final startTime = DateTime.tryParse(appointment['start_time'] ?? '');

    final timeString = startTime != null
        ? '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}'
        : '--:--';

    final isPending =
        (status?.toLowerCase() == 'pending' ||
        status?.toLowerCase() == 'pendente');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getStatusColor(status).withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showAppointmentDetails(appointment),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    // Horário
                    Container(
                      width: 60,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withOpacity(0.2),
                            AppColors.primary.withOpacity(0.05),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            timeString,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Info do cliente
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: AppColors.primary.withOpacity(
                                  0.2,
                                ),
                                child: Text(
                                  (client['full_name'] ?? 'C')[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      client['full_name'] ?? 'Cliente',
                                      style: const TextStyle(
                                        color: AppColors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.content_cut,
                                          size: 12,
                                          color: AppColors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            service['title'] ??
                                                service['name'] ??
                                                'Serviço',
                                            style: const TextStyle(
                                              color: AppColors.grey,
                                              fontSize: 13,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Status
                    Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(status).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                _getStatusIcon(status),
                                size: 14,
                                color: _getStatusColor(status),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _getStatusLabel(status),
                                style: TextStyle(
                                  color: _getStatusColor(status),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!isPending) ...[
                          const SizedBox(height: 8),
                          Icon(
                            Icons.chevron_right,
                            color: AppColors.grey.withOpacity(0.5),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
                if (isPending) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () =>
                              _showCancellationOptionsDialog(appointment['id']),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Recusar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _updateAppointmentStatus(
                            appointment['id'],
                            'confirmed',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Aceitar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildServicesTab() {
    return FutureBuilder<List<ServiceModel>>(
      future: _servicesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Erro: ${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.grey),
                ),
              ],
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.content_cut_outlined,
                  size: 80,
                  color: AppColors.grey.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Nenhum serviço cadastrado',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Clique no + para adicionar\nseu primeiro serviço!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.grey),
                ),
              ],
            ),
          );
        }

        final services = snapshot.data!;

        return RefreshIndicator(
          onRefresh: () async => _loadData(),
          color: AppColors.primary,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withOpacity(0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.content_cut, color: Colors.black),
                  ),
                  title: Text(
                    service.title,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'R\$ ${service.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 14,
                              color: AppColors.grey,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${service.duration} min',
                              style: const TextStyle(
                                color: AppColors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        // Use Flexible to prevent overflow
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.calendar_today,
                                  size: 14,
                                  color: Colors.blue,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    '${service.appointmentCount} agendamentos',
                                    style: const TextStyle(
                                      color: Colors.blue,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Botão Editar
                      IconButton(
                        onPressed: () => _editService(service),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.edit_outlined,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                      ),
                      // Botão Excluir
                      IconButton(
                        onPressed: () => _showDeleteConfirmation(service),
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _editService(ServiceModel service) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditServiceScreen(service: service),
      ),
    );
    if (result == true) {
      _loadData();
    }
  }

  void _showDeleteConfirmation(ServiceModel service) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Excluir Serviço?',
          style: TextStyle(color: AppColors.white),
        ),
        content: Text(
          'Deseja realmente excluir "${service.title}"?\n\nEssa ação não pode ser desfeita.',
          style: const TextStyle(color: AppColors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Cancelar',
              style: TextStyle(color: AppColors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteService(service.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}
