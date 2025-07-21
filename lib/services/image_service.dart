import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';

class ImageService {
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Pick image from gallery or camera
  Future<XFile?> pickImage({
    ImageSource source = ImageSource.gallery,
    int maxWidth = 1024,
    int maxHeight = 1024,
    int imageQuality = 85,
  }) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth.toDouble(),
        maxHeight: maxHeight.toDouble(),
        imageQuality: imageQuality,
      );
      
      if (image != null) {
        // Compress the image
        final compressedImage = await _compressImage(image);
        return compressedImage ?? image;
      }
      
      return image;
    } catch (e) {
      print('Error picking image: $e');
      return null;
    }
  }

  // Compress image to reduce file size
  Future<XFile?> _compressImage(XFile image) async {
    try {
      final String targetPath = '${image.path}_compressed.jpg';
      
      if (kIsWeb) {
        // For web, use different compression approach
        final Uint8List imageBytes = await image.readAsBytes();
        final compressedBytes = await FlutterImageCompress.compressWithList(
          imageBytes,
          minHeight: 512,
          minWidth: 512,
          quality: 85,
          format: CompressFormat.jpeg,
        );
        
        // Create a temporary file for web
        return XFile.fromData(compressedBytes, name: 'compressed_image.jpg');
      } else {
        // For mobile platforms
        final compressedFile = await FlutterImageCompress.compressAndGetFile(
          image.path,
          targetPath,
          minHeight: 512,
          minWidth: 512,
          quality: 85,
          format: CompressFormat.jpeg,
        );
        
        return compressedFile;
      }
    } catch (e) {
      print('Error compressing image: $e');
      return null;
    }
  }

  // Upload image to Firebase Storage
  Future<String?> uploadProfileImage({
    required XFile image,
    required String userId,
    Function(double)? onProgress,
  }) async {
    try {
      final String fileName = 'profile_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final Reference ref = _storage.ref().child('profile_images').child(fileName);
      
      UploadTask uploadTask;
      
      if (kIsWeb) {
        // For web
        final Uint8List imageBytes = await image.readAsBytes();
        uploadTask = ref.putData(
          imageBytes,
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'userId': userId,
              'uploadedAt': DateTime.now().toIso8601String(),
            },
          ),
        );
      } else {
        // For mobile
        final File imageFile = File(image.path);
        uploadTask = ref.putFile(
          imageFile,
          SettableMetadata(
            contentType: 'image/jpeg',
            customMetadata: {
              'userId': userId,
              'uploadedAt': DateTime.now().toIso8601String(),
            },
          ),
        );
      }

      // Listen to upload progress
      if (onProgress != null) {
        uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
          final progress = snapshot.bytesTransferred / snapshot.totalBytes;
          onProgress(progress);
        });
      }

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;
      
      // Get download URL
      final String downloadURL = await snapshot.ref.getDownloadURL();
      
      print('Image uploaded successfully: $downloadURL');
      return downloadURL;
      
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Delete image from Firebase Storage
  Future<bool> deleteProfileImage(String imageUrl) async {
    try {
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      print('Image deleted successfully');
      return true;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }

  // Show image source selection dialog
  Future<ImageSource?> showImageSourceDialog(BuildContext context) async {
    return showDialog<ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  // Get image size in bytes
  Future<int> getImageSize(XFile image) async {
    try {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        return bytes.length;
      } else {
        final file = File(image.path);
        return await file.length();
      }
    } catch (e) {
      print('Error getting image size: $e');
      return 0;
    }
  }

  // Format file size for display
  String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // Validate image file
  bool isValidImageFile(XFile image) {
    final String extension = image.path.toLowerCase().split('.').last;
    final List<String> validExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    return validExtensions.contains(extension);
  }
}