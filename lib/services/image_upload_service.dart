import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ImageUploadService {
  final ImagePicker _picker = ImagePicker();

  // Nome do bucket no Supabase Storage
  static const String _bucketName = 'salon-images';

  /// Seleciona uma imagem da galeria
  /// Retorna o arquivo selecionado ou null se cancelado
  Future<XFile?> pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      print('Erro ao selecionar imagem: $e');
      return null;
    }
  }

  /// Tira uma foto com a câmera
  /// Retorna o arquivo capturado ou null se cancelado
  Future<XFile?> pickImageFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      print('Erro ao capturar imagem: $e');
      return null;
    }
  }

  /// Faz upload da imagem para o Supabase Storage
  /// Retorna a URL pública da imagem ou null em caso de erro
  Future<String?> uploadImage(XFile imageFile) async {
    try {
      final supabase = Supabase.instance.client;
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId') ?? 'unknown';

      // Determina o content type e extensão de forma robusta (funciona no Web)
      String contentType;
      String fileExtension;

      // Primeiro tenta usar o mimeType do XFile (mais confiável no Web)
      if (imageFile.mimeType != null && imageFile.mimeType!.isNotEmpty) {
        contentType = imageFile.mimeType!;
        // Extrai extensão do mimeType (ex: 'image/jpeg' -> 'jpeg')
        fileExtension = contentType.split('/').last;
      } else {
        // Fallback: tenta extrair do path (funciona em mobile)
        final pathParts = imageFile.path.split('.');
        if (pathParts.length > 1 && !pathParts.last.contains('/')) {
          fileExtension = pathParts.last.toLowerCase();
          contentType = 'image/$fileExtension';
        } else {
          // Default para jpeg se não conseguir determinar
          fileExtension = 'jpeg';
          contentType = 'image/jpeg';
        }
      }

      final fileName =
          '${userId}_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final filePath = 'salons/$fileName';

      // Lê os bytes do arquivo
      final bytes = await imageFile.readAsBytes();

      // Faz o upload para o Supabase Storage
      await supabase.storage
          .from(_bucketName)
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(contentType: contentType, upsert: true),
          );

      // Obtém a URL pública
      final publicUrl = supabase.storage
          .from(_bucketName)
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      print('Erro ao fazer upload: $e');
      return null;
    }
  }

  /// Verifica se uma URL é uma imagem válida
  bool isValidImageUrl(String url) {
    if (url.isEmpty) return false;

    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return false;

    // Verifica se é http ou https
    if (uri.scheme != 'http' && uri.scheme != 'https') return false;

    // Verifica extensão comum de imagem (opcional, mas útil)
    final path = uri.path.toLowerCase();
    final imageExtensions = ['.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp'];

    // Se termina com extensão de imagem, é válido
    for (final ext in imageExtensions) {
      if (path.endsWith(ext)) return true;
    }

    // URLs que não terminam com extensão podem ainda ser imagens (CDNs, etc)
    // Então permitimos se for uma URL válida
    return true;
  }
}
