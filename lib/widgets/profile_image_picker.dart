import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/image_service.dart';

class ProfileImagePicker extends StatefulWidget {
  final String? initialImageUrl;
  final Function(String?) onImageChanged;
  final double size;
  final bool enabled;

  const ProfileImagePicker({
    Key? key,
    this.initialImageUrl,
    required this.onImageChanged,
    this.size = 120,
    this.enabled = true,
  }) : super(key: key);

  @override
  State<ProfileImagePicker> createState() => _ProfileImagePickerState();
}

class _ProfileImagePickerState extends State<ProfileImagePicker>
    with SingleTickerProviderStateMixin {
  final ImageService _imageService = ImageService();
  
  String? _currentImageUrl;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _currentImageUrl = widget.initialImageUrl;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    if (!widget.enabled || _isUploading) return;

    try {
      // Show image source selection
      final ImageSource? source = await _imageService.showImageSourceDialog(context);
      if (source == null) return;

      // Pick image
      final XFile? image = await _imageService.pickImage(source: source);
      if (image == null) return;

      // Validate image
      if (!_imageService.isValidImageFile(image)) {
        _showErrorSnackBar('Please select a valid image file');
        return;
      }

      // Check file size (limit to 5MB)
      final int fileSize = await _imageService.getImageSize(image);
      if (fileSize > 5 * 1024 * 1024) {
        _showErrorSnackBar('Image size should be less than 5MB');
        return;
      }

      setState(() {
        _isUploading = true;
        _uploadProgress = 0.0;
      });

      // Upload image
      final String? imageUrl = await _imageService.uploadProfileImage(
        image: image,
        userId: 'current_user_id', // Replace with actual user ID
        onProgress: (progress) {
          setState(() {
            _uploadProgress = progress;
          });
        },
      );

      if (imageUrl != null) {
        setState(() {
          _currentImageUrl = imageUrl;
          _isUploading = false;
        });
        
        widget.onImageChanged(imageUrl);
        
        _showSuccessSnackBar('Profile photo updated successfully!');
      } else {
        setState(() {
          _isUploading = false;
        });
        _showErrorSnackBar('Failed to upload image. Please try again.');
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      _showErrorSnackBar('Error: ${e.toString()}');
    }
  }

  Future<void> _removeImage() async {
    if (!widget.enabled || _isUploading) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Photo'),
        content: const Text('Are you sure you want to remove your profile photo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Delete from storage if there's an existing image
      if (_currentImageUrl != null) {
        await _imageService.deleteProfileImage(_currentImageUrl!);
      }

      setState(() {
        _currentImageUrl = null;
      });
      
      widget.onImageChanged(null);
      _showSuccessSnackBar('Profile photo removed');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTapDown: (_) => _animationController.forward(),
        onTapUp: (_) => _animationController.reverse(),
        onTapCancel: () => _animationController.reverse(),
        onTap: widget.enabled ? _pickAndUploadImage : null,
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Stack(
                children: [
                  // Main image container
                  Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Theme.of(context).primaryColor,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: _buildImageContent(),
                    ),
                  ),
                  
                  // Upload progress indicator
                  if (_isUploading)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.7),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 40,
                                height: 40,
                                child: CircularProgressIndicator(
                                  value: _uploadProgress,
                                  strokeWidth: 3,
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${(_uploadProgress * 100).toInt()}%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  
                  // Edit/Camera icon
                  if (widget.enabled && !_isUploading)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).primaryColor,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  
                  // Remove button (when image exists)
                  if (_currentImageUrl != null && widget.enabled && !_isUploading)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _removeImage,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.red,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildImageContent() {
    if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: _currentImageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey[200],
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorWidget: (context, url, error) => _buildPlaceholder(),
      );
    } else {
      return _buildPlaceholder();
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      color: Colors.grey[100],
      child: Icon(
        Icons.person,
        size: widget.size * 0.5,
        color: Colors.grey[400],
      ),
    );
  }
}