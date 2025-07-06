import 'package:flutter/material.dart';

class Category {
  final int id;
  final String name;
  final String slug;
  final String imagePath;
  final String? description;

  bool isSelected;
  Color textColor;
  Color selectedColor;

  static const Color defaultSelectedColor = Color(0xFF126E64);
  static const Color defaultTextColor = Colors.white;

  Category({
    required this.id,
    required this.name,
    required this.slug,
    required this.imagePath,
    this.description,
    this.isSelected = false,
    this.textColor = defaultTextColor,
    this.selectedColor = defaultSelectedColor,
  });

  /// Factory constructor to create a Category from JSON.
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      imagePath: json['imagePath'] as String,
      description: json['description'] as String?,
      isSelected: json['isSelected'] as bool? ?? false,
      textColor: _colorFromJson(json['textColor']) ?? defaultTextColor,
      selectedColor: _colorFromJson(json['selectedColor']) ?? defaultSelectedColor,
    );
  }

  /// Converts the Category instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'imagePath': imagePath,
      'description': description,
      'isSelected': isSelected,
      'textColor': _colorToJson(textColor),
      'selectedColor': _colorToJson(selectedColor),
    };
  }

  /// Helper: Convert Color to Hex string.
  static String _colorToJson(Color color) {
    return '#${color.value.toRadixString(16).padLeft(8, '0')}';
  }

  /// Helper: Convert Hex string to Color.
  static Color? _colorFromJson(dynamic colorValue) {
    if (colorValue is String && colorValue.startsWith('#')) {
      return Color(int.parse(colorValue.substring(1), radix: 16));
    }
    return null;
  }

  /// Readable string representation.
  @override
  String toString() {
    return 'Category(id: $id, name: $name, slug: $slug, description: $description, isSelected: $isSelected)';
  }

  /// Equality operator for value comparison.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Category &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              name == other.name &&
              slug == other.slug &&
              imagePath == other.imagePath &&
              description == other.description &&
              isSelected == other.isSelected;

  /// Hash code generator.
  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      slug.hashCode ^
      imagePath.hashCode ^
      description.hashCode ^
      isSelected.hashCode;
}
