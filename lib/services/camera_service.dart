import 'dart:io';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'supabase_service.dart';

class CameraService {
  static final ImagePicker _picker = ImagePicker();
  
  static Future<File?> captureReceipt() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      
      if (image != null) {
        return File(image.path);
      }
    } catch (e) {
      print('Error capturing receipt: $e');
    }
    return null;
  }
  
  static Future<File?> pickReceiptFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      
      if (image != null) {
        return File(image.path);
      }
    } catch (e) {
      print('Error picking receipt: $e');
    }
    return null;
  }
  
  static Future<bool> uploadAndProcessReceipt(File imageFile) async {
    try {
      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'receipt_$timestamp.jpg';
      
      // Upload to Supabase Storage
      final success = await SupabaseService.uploadReceipt(
        filePath: imageFile.path,
        fileName: fileName,
      );
      
      if (success) {
        // Create receipt record for processing
        await SupabaseService.client.from('receipts').insert({
          'receipt_url': 'receipts/uploads/$fileName',
          'processing_status': 'pending',
          'source': 'mobile',
          'created_at': DateTime.now().toIso8601String(),
        });
        
        return true;
      }
    } catch (e) {
      print('Error uploading receipt: $e');
    }
    return false;
  }
  
  static Future<List<CameraDescription>> getAvailableCameras() async {
    try {
      return await availableCameras();
    } catch (e) {
      print('Error getting cameras: $e');
      return [];
    }
  }
}