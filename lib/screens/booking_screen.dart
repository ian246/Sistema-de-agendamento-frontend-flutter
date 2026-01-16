import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/theme.dart';
import '../models/barber_models.dart';
import '../models/service_model.dart';
import '../services/api_service.dart';
import '../services/image_upload_service.dart';

class BookingScreen extends StatefulWidget {
  final Barber barber;
  const BookingScreen({super.key, required this.barber});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final ApiService api = ApiService();
  final ImageUploadService _imageUploadService = ImageUploadService();
  final TextEditingController _cutDescriptionController =
      TextEditingController();
  final ImagePicker _picker = ImagePicker();

  List<ServiceModel> _services = [];
  ServiceModel? _selectedService;
  bool _isLoadingData = true;

  DateTime _selectedDay = DateTime.now();
  String? _selectedTime;
  bool _isSubmitting = false;

  // Novos campos para descrição e foto
  String? _referenceImageUrl;
  bool _isUploadingImage = false;

  // Horários ocupados
  List<String> _busySlots = [];

  final List<String> _timeSlots = [
    "09:00",
    "10:00",
    "11:00",
    "13:00",
    "14:00",
    "15:00",
    "16:00",
    "18:00",
  ];

  @override
  void initState() {
    super.initState();
    _loadServices();
    _loadBusySlots();
  }

  Future<void> _loadServices() async {
    try {
      final list = await api.getServices(widget.barber.id);
      setState(() {
        _services = list;
        _isLoadingData = false;
        if (list.isNotEmpty) _selectedService = list[0];
      });
    } catch (e) {
      setState(() => _isLoadingData = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro ao carregar serviços: $e")),
        );
      }
    }
  }

  Future<void> _loadBusySlots() async {
    try {
      final slots = await api.getProviderBusySlots(
        widget.barber.id,
        _selectedDay,
      );
      if (mounted) {
        setState(() {
          _busySlots = slots;
          // Se o horário selecionado está ocupado, desseleciona
          if (_selectedTime != null && _busySlots.contains(_selectedTime)) {
            _selectedTime = null;
          }
        });
      }
    } catch (e) {
      // Silenciosamente ignora erros - todos slots ficam disponíveis
    }
  }

  void _submitBooking() async {
    if (_selectedTime == null || _selectedService == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Selecione um serviço e um horário!")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Pega o userId salvo no login
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      if (userId == null) throw Exception("Usuário não logado");

      await api.createAppointment(
        clientId: userId,
        providerId: widget.barber.id,
        serviceId: _selectedService!.id,
        date: _selectedDay,
        time: _selectedTime!,
        cutDescription: _cutDescriptionController.text.trim().isNotEmpty
            ? _cutDescriptionController.text.trim()
            : null,
        referenceImageUrl: _referenceImageUrl,
      );

      if (mounted) {
        Navigator.pop(context, {'booked': true, 'time': _selectedTime});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Erro: ${e.toString().replaceAll("Exception:", "")}"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _pickReferenceImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image == null) return;

      setState(() => _isUploadingImage = true);

      final imageUrl = await _imageUploadService.uploadImage(image);

      if (imageUrl != null) {
        setState(() {
          _referenceImageUrl = imageUrl;
        });
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erro ao fazer upload da imagem'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  void _removeReferenceImage() {
    setState(() {
      _referenceImageUrl = null;
    });
  }

  @override
  void dispose() {
    _cutDescriptionController.dispose();
    super.dispose();
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  String _formatWeekday(DateTime date) {
    const weekdays = [
      'Segunda-feira',
      'Terça-feira',
      'Quarta-feira',
      'Quinta-feira',
      'Sexta-feira',
      'Sábado',
      'Domingo',
    ];
    return weekdays[date.weekday - 1];
  }

  void _showProfileImageDialog(BuildContext context) {
    final barber = widget.barber;
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header com nome e botão fechar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (barber.salonName != null &&
                            barber.salonName!.isNotEmpty)
                          Text(
                            barber.salonName!,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        Text(
                          barber.name,
                          style: TextStyle(
                            color: barber.salonName != null
                                ? AppColors.grey
                                : AppColors.white,
                            fontSize: barber.salonName != null ? 14 : 18,
                            fontWeight: barber.salonName != null
                                ? FontWeight.w500
                                : FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.close,
                        color: AppColors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Imagem
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 400),
              decoration: const BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
                child: Image.network(
                  barber.salonImageUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return SizedBox(
                      height: 200,
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
                  errorBuilder: (context, error, stackTrace) => Container(
                    height: 200,
                    color: AppColors.surface,
                    child: const Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 48,
                        color: AppColors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Marcar Horário")),
      body: _isLoadingData
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Column(
              children: [
                // --- CABEÇALHO DO BARBEIRO ---
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(30),
                      bottomRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap:
                            widget.barber.salonImageUrl != null &&
                                widget.barber.salonImageUrl!.isNotEmpty
                            ? () => _showProfileImageDialog(context)
                            : null,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, Color(0xFF1FD89A)],
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundColor: AppColors.background,
                            backgroundImage:
                                widget.barber.salonImageUrl != null &&
                                    widget.barber.salonImageUrl!.isNotEmpty
                                ? NetworkImage(widget.barber.salonImageUrl!)
                                : null,
                            child:
                                widget.barber.salonImageUrl == null ||
                                    widget.barber.salonImageUrl!.isEmpty
                                ? Text(
                                    widget.barber.name.isNotEmpty
                                        ? widget.barber.name[0]
                                        : "?",
                                    style: const TextStyle(
                                      fontSize: 24,
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Nome do salão (se existir)
                      if (widget.barber.salonName != null &&
                          widget.barber.salonName!.isNotEmpty)
                        Text(
                          widget.barber.salonName!,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      Text(
                        widget.barber.name,
                        style: TextStyle(
                          fontSize:
                              widget.barber.salonName != null &&
                                  widget.barber.salonName!.isNotEmpty
                              ? 16
                              : 22,
                          fontWeight:
                              widget.barber.salonName != null &&
                                  widget.barber.salonName!.isNotEmpty
                              ? FontWeight.w500
                              : FontWeight.bold,
                          color:
                              widget.barber.salonName != null &&
                                  widget.barber.salonName!.isNotEmpty
                              ? AppColors.grey
                              : AppColors.white,
                        ),
                      ),
                      Text(
                        widget.barber.specialty,
                        style: const TextStyle(color: AppColors.grey),
                      ),
                    ],
                  ),
                ),

                // --- FORMULÁRIO ---
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- 1. SELEÇÃO DE SERVIÇO ---
                        _buildSectionHeader(
                          icon: Icons.content_cut,
                          title: "Selecione o Serviço",
                        ),
                        const SizedBox(height: 16),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: _services.isEmpty
                              ? Center(
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.content_cut_outlined,
                                        size: 48,
                                        color: AppColors.grey.withOpacity(0.5),
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        "Nenhum serviço disponível",
                                        style: TextStyle(
                                          color: AppColors.grey,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Wrap(
                                  spacing: 12,
                                  runSpacing: 12,
                                  children: _services.map((service) {
                                    final isSelected =
                                        _selectedService?.id == service.id;
                                    return AnimatedContainer(
                                      duration: const Duration(
                                        milliseconds: 200,
                                      ),
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: () {
                                            setState(
                                              () => _selectedService =
                                                  isSelected ? null : service,
                                            );
                                          },
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 12,
                                            ),
                                            decoration: BoxDecoration(
                                              gradient: isSelected
                                                  ? const LinearGradient(
                                                      colors: [
                                                        AppColors.primary,
                                                        Color(0xFFFFD700),
                                                      ],
                                                    )
                                                  : null,
                                              color: isSelected
                                                  ? null
                                                  : AppColors.background,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: isSelected
                                                    ? AppColors.primary
                                                    : AppColors.grey
                                                          .withOpacity(0.2),
                                                width: 2,
                                              ),
                                              boxShadow: isSelected
                                                  ? [
                                                      BoxShadow(
                                                        color: AppColors.primary
                                                            .withOpacity(0.3),
                                                        blurRadius: 12,
                                                        offset: const Offset(
                                                          0,
                                                          4,
                                                        ),
                                                      ),
                                                    ]
                                                  : null,
                                            ),
                                            child: Text(
                                              "${service.title} - R\$ ${service.price}",
                                              style: TextStyle(
                                                color: isSelected
                                                    ? Colors.black
                                                    : AppColors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                        ),
                        const SizedBox(height: 40),

                        // --- 2. DATA ---
                        _buildSectionHeader(
                          icon: Icons.calendar_today,
                          title: "Escolha a Data",
                        ),
                        const SizedBox(height: 16),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime.now(),
                                lastDate: DateTime(2027),
                                builder: (context, child) {
                                  return Theme(
                                    data: ThemeData.dark().copyWith(
                                      colorScheme: const ColorScheme.dark(
                                        primary: AppColors.primary,
                                        onPrimary: Colors.black,
                                        surface: AppColors.surface,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setState(() => _selectedDay = picked);
                                _loadBusySlots();
                              }
                            },
                            borderRadius: BorderRadius.circular(24),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: AppColors.primary.withOpacity(0.3),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.1),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _formatWeekday(_selectedDay),
                                        style: const TextStyle(
                                          color: AppColors.grey,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "${_selectedDay.day}/${_selectedDay.month}/${_selectedDay.year}",
                                        style: const TextStyle(
                                          color: AppColors.white,
                                          fontSize: 22,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.edit_calendar,
                                      color: AppColors.primary,
                                      size: 28,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // --- 3. HORÁRIOS ---
                        _buildSectionHeader(
                          icon: Icons.access_time,
                          title: "Selecione o Horário",
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            alignment: WrapAlignment.center,
                            children: _timeSlots.map((time) {
                              final isSelected = _selectedTime == time;
                              final isBusy = _busySlots.contains(time);
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: isBusy
                                        ? null
                                        : () {
                                            setState(
                                              () => _selectedTime = isSelected
                                                  ? null
                                                  : time,
                                            );
                                          },
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 14,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: isBusy
                                            ? null
                                            : (isSelected
                                                  ? const LinearGradient(
                                                      colors: [
                                                        AppColors.primary,
                                                        Color(0xFFFFD700),
                                                      ],
                                                    )
                                                  : null),
                                        color: isBusy
                                            ? Colors.red.withOpacity(0.15)
                                            : (isSelected
                                                  ? null
                                                  : AppColors.background),
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: isBusy
                                              ? Colors.red.withOpacity(0.5)
                                              : (isSelected
                                                    ? AppColors.primary
                                                    : AppColors.grey
                                                          .withOpacity(0.2)),
                                          width: 2,
                                        ),
                                        boxShadow: isSelected && !isBusy
                                            ? [
                                                BoxShadow(
                                                  color: AppColors.primary
                                                      .withOpacity(0.3),
                                                  blurRadius: 12,
                                                  offset: const Offset(0, 4),
                                                ),
                                              ]
                                            : null,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (isBusy) ...[
                                            Icon(
                                              Icons.block,
                                              color: Colors.red.withOpacity(
                                                0.7,
                                              ),
                                              size: 16,
                                            ),
                                            const SizedBox(width: 6),
                                          ],
                                          Text(
                                            time,
                                            style: TextStyle(
                                              color: isBusy
                                                  ? Colors.red.withOpacity(0.7)
                                                  : (isSelected
                                                        ? Colors.black
                                                        : AppColors.white),
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              decoration: isBusy
                                                  ? TextDecoration.lineThrough
                                                  : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // --- 4. DESCRIÇÃO E FOTO DE REFERÊNCIA ---
                        _buildSectionHeader(
                          icon: Icons.description_outlined,
                          title: "Descreva o Corte (Opcional)",
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Como você quer o corte?",
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Descreva detalhes do corte desejado para o profissional saber exatamente o que você quer.",
                                style: TextStyle(
                                  color: AppColors.grey,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _cutDescriptionController,
                                maxLines: 4,
                                style: const TextStyle(color: AppColors.white),
                                decoration: InputDecoration(
                                  hintText:
                                      "Ex: Quero um degradê baixo, com a parte de cima mais volumosa e puxada para o lado...",
                                  hintStyle: TextStyle(
                                    color: AppColors.grey.withOpacity(0.5),
                                    fontSize: 14,
                                  ),
                                  filled: true,
                                  fillColor: AppColors.background,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: AppColors.primary,
                                      width: 2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // --- 5. FOTO DE REFERÊNCIA ---
                        _buildSectionHeader(
                          icon: Icons.add_photo_alternate_outlined,
                          title: "Foto de Referência (Opcional)",
                        ),
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              if (_referenceImageUrl == null) ...[
                                // Botão para adicionar foto
                                GestureDetector(
                                  onTap: _isUploadingImage
                                      ? null
                                      : _pickReferenceImage,
                                  child: Container(
                                    width: double.infinity,
                                    height: 150,
                                    decoration: BoxDecoration(
                                      color: AppColors.background,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: AppColors.primary.withOpacity(
                                          0.3,
                                        ),
                                        width: 2,
                                        style: BorderStyle.solid,
                                      ),
                                    ),
                                    child: _isUploadingImage
                                        ? const Center(
                                            child: CircularProgressIndicator(
                                              color: AppColors.primary,
                                            ),
                                          )
                                        : Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.all(
                                                  16,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.primary
                                                      .withOpacity(0.1),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(
                                                  Icons
                                                      .add_photo_alternate_outlined,
                                                  color: AppColors.primary,
                                                  size: 32,
                                                ),
                                              ),
                                              const SizedBox(height: 12),
                                              const Text(
                                                "Toque para adicionar foto",
                                                style: TextStyle(
                                                  color: AppColors.primary,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              const Text(
                                                "Mostre ao profissional o corte desejado",
                                                style: TextStyle(
                                                  color: AppColors.grey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ] else ...[
                                // Preview da foto selecionada
                                Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Image.network(
                                        _referenceImageUrl!,
                                        width: double.infinity,
                                        height: 200,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null)
                                            return child;
                                          return SizedBox(
                                            height: 200,
                                            child: Center(
                                              child: CircularProgressIndicator(
                                                value:
                                                    loadingProgress
                                                            .expectedTotalBytes !=
                                                        null
                                                    ? loadingProgress
                                                              .cumulativeBytesLoaded /
                                                          loadingProgress
                                                              .expectedTotalBytes!
                                                    : null,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          );
                                        },
                                        errorBuilder:
                                            (
                                              context,
                                              error,
                                              stackTrace,
                                            ) => Container(
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
                                    // Botão de remover
                                    Positioned(
                                      top: 8,
                                      right: 8,
                                      child: GestureDetector(
                                        onTap: _removeReferenceImage,
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.red.withOpacity(0.9),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.check_circle,
                                      color: AppColors.primary,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    const Text(
                                      "Foto adicionada com sucesso!",
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),

                // --- RODAPÉ COM PREÇO DINÂMICO ---
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Total Estimado:",
                            style: TextStyle(
                              color: AppColors.grey,
                              fontSize: 16,
                            ),
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              _selectedService != null
                                  ? "R\$ ${_selectedService!.price.toStringAsFixed(2)}"
                                  : "R\$ 0,00",
                              key: ValueKey(_selectedService?.id),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              (_selectedTime == null ||
                                  _selectedService == null ||
                                  _isSubmitting)
                              ? null
                              : _submitBooking,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.black,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "CONFIRMAR AGENDAMENTO",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
