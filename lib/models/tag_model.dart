import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A free-form label that can be attached to any transaction in addition
/// to its category — e.g. "Cursor", "German Class", "Work Trip". Used by
/// Smart Search and the Tags management screen.
class TagModel {
  final String id;
  final String name;
  final int colorIndex;

  TagModel({required this.id, required this.name, required this.colorIndex});

  Color get color => AppColors.catColors[colorIndex % AppColors.catColors.length];

  Map<String, dynamic> toMap() => {'id': id, 'name': name, 'colorIndex': colorIndex};

  factory TagModel.fromMap(Map<String, dynamic> map) => TagModel(
        id: map['id'] as String,
        name: map['name'] as String,
        colorIndex: map['colorIndex'] as int,
      );
}