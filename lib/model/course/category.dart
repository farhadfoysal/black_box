import 'package:flutter/material.dart';

class Category {
  final int id;
  final String name;
  final String slug;
  final String? imagePath;
  final IconData? icon;

  Category({
    required this.id,
    required this.name,
    required this.slug,
    this.imagePath,
    this.icon,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      imagePath: json['imagePath'],
      icon: json['icon'] != null ? iconFromString(json['icon']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'imagePath': imagePath,
    'icon': icon != null ? iconToString(icon!) : null,
  };

  static IconData? iconFromString(String iconName) {
    return _iconMap[iconName];
  }

  static String? iconToString(IconData iconData) {
    final match = _iconMap.entries
        .firstWhere(
          (entry) => entry.value == iconData,
      orElse: () => const MapEntry('', Icons.help_outline), // use a default valid icon
    );

    return match.key.isEmpty ? null : match.key;
  }


  static const Map<String, IconData> _iconMap = {
    'language': Icons.language,
    'translate': Icons.translate,
    'calculate': Icons.calculate,
    'science': Icons.science,
    'bubble_chart': Icons.bubble_chart,
    'speed': Icons.speed,
    'biotech': Icons.biotech,
    'computer': Icons.computer,
    'account_balance': Icons.account_balance,
    'menu_book': Icons.menu_book,
    'public': Icons.public,
    'edit_note': Icons.edit_note,
    'library_books': Icons.library_books,
    'record_voice_over': Icons.record_voice_over,
    'mic': Icons.mic,
    'campaign': Icons.campaign,
    'fact_check': Icons.fact_check,
    'looks_one': Icons.looks_one,
    'looks_two': Icons.looks_two,
    'looks_3': Icons.looks_3,
    'looks_4': Icons.looks_4,
    'looks_5': Icons.looks_5,
    'filter_6': Icons.filter_6,
    'filter_7': Icons.filter_7,
    'filter_8': Icons.filter_8,
    'filter_9': Icons.filter_9,
    'filter_9_plus': Icons.filter_9_plus,
    'school': Icons.school,
    'school_outlined': Icons.school_outlined,
    'assignment': Icons.assignment,
    'assignment_turned_in': Icons.assignment_turned_in,
    'code': Icons.code,
    'electrical_services': Icons.electrical_services,
    'business_center': Icons.business_center,
    'account_balance_wallet': Icons.account_balance_wallet,
    'gavel': Icons.gavel,
    'local_hospital': Icons.local_hospital,
    'work': Icons.work,
    'badge': Icons.badge,
    'memory': Icons.memory,
    'build': Icons.build,
    'palette': Icons.palette,
    'monetization_on': Icons.monetization_on,
    'show_chart': Icons.show_chart,
    'receipt_long': Icons.receipt_long,
  };
}
