import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class ImageInputWidget extends StatefulWidget {
  final ValueChanged<String?> onImageSelected;

  const ImageInputWidget({Key? key, required this.onImageSelected}) : super(key: key);

  @override
  State<ImageInputWidget> createState() => _ImageInputWidgetState();
}

class _ImageInputWidgetState extends State<ImageInputWidget> {
  String? _imagePath;
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Upload Image Answer',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2C3E50),
          ),
        ),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: _showImageSourceOptions,
          child: Container(
            height: 150,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: _imagePath == null
                ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.cloud_upload, size: 40, color: Color(0xFF3A7BD5)),
                SizedBox(height: 10),
                Text('Tap to upload image', style: TextStyle(color: Color(0xFF3A7BD5))),
              ],
            )
                : ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                File(_imagePath!),
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showImageSourceOptions() async {
    final source = await showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: const Text('Choose where to pick the image from.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.camera),
            child: const Text('Camera'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, ImageSource.gallery),
            child: const Text('Gallery'),
          ),
        ],
      ),
    );

    if (source != null) {
      await _pickImage(source);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    // Handle permission based on platform and source
    final cameraStatus = await Permission.camera.request();
    final storageStatus = Platform.isAndroid
        ? await Permission.storage.request()
        : await Permission.photos.request();

    if ((source == ImageSource.camera && cameraStatus.isGranted) ||
        (source == ImageSource.gallery && storageStatus.isGranted)) {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _imagePath = pickedFile.path;
        });
        widget.onImageSelected(_imagePath);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Permission denied. Cannot pick image.')),
      );
    }
  }
}
