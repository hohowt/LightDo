import 'package:flutter/material.dart';

class Tag {
  const Tag({required this.name, required this.color});

  final String name;
  final Color color;

  Map<String, dynamic> toJson() => {
        'name': name,
        'color': color.toARGB32(),
      };

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      name: json['name'] as String,
      color: Color(json['color'] as int),
    );
  }

  static const List<Color> presetColors = [
    Color(0xFF3B82F6),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFF06B6D4),
    Color(0xFF6B7280),
  ];

  static Color colorForTag(String name) {
    final index = name.hashCode.abs() % presetColors.length;
    return presetColors[index];
  }
}

class TagStore {
  List<Tag> tags;

  TagStore({List<Tag>? tags}) : tags = tags ?? _defaultTags();

  static List<Tag> _defaultTags() => const [
        Tag(name: '工作', color: Color(0xFF3B82F6)),
        Tag(name: '个人', color: Color(0xFF10B981)),
        Tag(name: '紧急', color: Color(0xFFEF4444)),
        Tag(name: '学习', color: Color(0xFF8B5CF6)),
      ];

  Tag? find(String name) {
    try {
      return tags.firstWhere((t) => t.name == name);
    } catch (_) {
      return null;
    }
  }

  Color colorFor(String name) {
    return find(name)?.color ?? Tag.colorForTag(name);
  }

  void add(Tag tag) {
    if (find(tag.name) != null) return;
    tags.add(tag);
  }

  void remove(String name) {
    tags.removeWhere((t) => t.name == name);
  }

  List<Map<String, dynamic>> toJson() =>
      tags.map((t) => t.toJson()).toList(growable: false);

  factory TagStore.fromJson(List<dynamic>? json) {
    if (json == null) return TagStore();
    return TagStore(
      tags: json
          .map((e) => Tag.fromJson(e as Map<String, dynamic>))
          .toList(growable: true),
    );
  }
}
