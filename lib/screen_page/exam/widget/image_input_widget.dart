import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';


class ImageInputWidget extends StatefulWidget {
  final ValueChanged<String?> onImageSelected;

  const ImageInputWidget({Key? key, required this.onImageSelected}) : super(key: key);

  @override
  _ImageInputWidgetState createState() => _ImageInputWidgetState();
}

class _ImageInputWidgetState extends State<ImageInputWidget> {
  String? _imagePath;

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
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey[300]!,
                width: 1.5,
              ),
            ),
            child: _imagePath == null
                ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.cloud_upload, size: 40, color: Color(0xFF3A7BD5)),
                SizedBox(height: 8),
                Text(
                  'Tap to upload image',
                  style: TextStyle(color: Color(0xFF3A7BD5)),
                ),
              ],
            )
                : ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                File(_imagePath!),
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _imagePath = pickedFile.path;
      });
      widget.onImageSelected(_imagePath);
    }
  }
}