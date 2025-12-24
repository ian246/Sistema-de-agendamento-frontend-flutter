import 'package:flutter/material.dart';
import 'package:Bcorte/services/api_service.dart';
import 'package:Bcorte/utils/theme.dart';
import 'package:Bcorte/widgets/custom_text_field.dart';
import 'package:Bcorte/widgets/primary_button.dart';

class CreateServiceScreen extends StatefulWidget {
  const CreateServiceScreen({super.key});

  @override
  State<CreateServiceScreen> createState() => _CreateServiceScreenState();
}

class _CreateServiceScreenState extends State<CreateServiceScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;

  Future<void> _createService() async {
    final title = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final priceText = _priceController.text.trim();
    final durationText = _durationController.text.trim();

    if (title.isEmpty ||
        description.isEmpty ||
        priceText.isEmpty ||
        durationText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Preencha todos os campos!"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final price = double.parse(priceText);
      final duration = int.parse(durationText);

      await _apiService.createService(
        title: title,
        description: description,
        price: price,
        duration: duration,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Serviço criado com sucesso!"),
            backgroundColor: AppColors.primary,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erro: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Novo Serviço")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.add_business, size: 80, color: AppColors.primary),
            const SizedBox(height: 32),
            CustomTextField(
              controller: _titleController,
              hintText: "Título do Serviço",
              prefixIcon: Icons.title,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _descriptionController,
              hintText: "Descrição",
              prefixIcon: Icons.description,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _priceController,
              hintText: "Preço (R\$)",
              prefixIcon: Icons.attach_money,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _durationController,
              hintText: "Duração (min)",
              prefixIcon: Icons.timer,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              text: "SALVAR SERVIÇO",
              onPressed: _createService,
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}
