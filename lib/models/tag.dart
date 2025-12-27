import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Predefined color palette for tags - designed to complement the olive theme
class TagColors {
  static const List<Color> palette = [
    Color(0xFF7A9E8C), // Sage green
    Color(0xFFC4785A), // Terracotta
    Color(0xFFC4A85A), // Gold
    Color(0xFF8B7EC8), // Purple
    Color(0xFF5A9EC4), // Blue
    Color(0xFFC45A8B), // Pink
    Color(0xFF5AC4A8), // Teal
    Color(0xFFC49E5A), // Amber
    Color(0xFF9E7AC4), // Lavender
    Color(0xFF5AC4C4), // Cyan
  ];

  static Color getColor(int index) {
    return palette[index % palette.length];
  }
}

class Tag {
  final String id;
  String name;
  int colorIndex;

  Tag({
    required this.id,
    required this.name,
    required this.colorIndex,
  });

  Color get color => TagColors.getColor(colorIndex);

  Tag copyWith({
    String? id,
    String? name,
    int? colorIndex,
  }) {
    return Tag(
      id: id ?? this.id,
      name: name ?? this.name,
      colorIndex: colorIndex ?? this.colorIndex,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'colorIndex': colorIndex,
    };
  }

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] as String,
      name: json['name'] as String,
      colorIndex: json['colorIndex'] as int,
    );
  }

  static String generateId() => _uuid.v4();

  static String encodeList(List<Tag> tags) {
    return jsonEncode(tags.map((t) => t.toJson()).toList());
  }

  static List<Tag> decodeList(String jsonString) {
    final List<dynamic> jsonList = jsonDecode(jsonString);
    return jsonList.map((json) => Tag.fromJson(json)).toList();
  }
}
