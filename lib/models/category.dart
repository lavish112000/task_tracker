import 'package:flutter/material.dart';

class Category {
  final String id;
  final String name;
  final int? colorValue;
  const Category({required this.id, required this.name, this.colorValue});

  Color? get color => colorValue != null ? Color(colorValue!) : null;

  Category copyWith({String? id, String? name, int? colorValue}) => Category(
    id: id ?? this.id,
    name: name ?? this.name,
    colorValue: colorValue ?? this.colorValue,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'colorValue': colorValue,
  };

  static Category fromJson(Map<String, dynamic> json) => Category(
    id: json['id'],
    name: json['name'],
    colorValue: json['colorValue'],
  );
}

