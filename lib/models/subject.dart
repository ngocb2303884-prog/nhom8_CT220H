import 'package:flutter/material.dart';

class Subject {
  final int? id;
  final String name;
  final String teacher;
  final String room;
  final int colorValue;
  final int credits;

  const Subject({
    this.id,
    required this.name,
    required this.teacher,
    required this.room,
    this.colorValue = 0xFF2196F3,
    this.credits = 3,
  });

  Color get color => Color(colorValue);

  Subject copyWith({
    int? id, String? name, String? teacher,
    String? room, int? colorValue, int? credits,
  }) {
    return Subject(
      id: id ?? this.id,
      name: name ?? this.name,
      teacher: teacher ?? this.teacher,
      room: room ?? this.room,
      colorValue: colorValue ?? this.colorValue,
      credits: credits ?? this.credits,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'teacher': teacher,
    'room': room,
    'color_value': colorValue,
    'credits': credits,
  };

  factory Subject.fromMap(Map<String, dynamic> m) => Subject(
    id: m['id'] as int?,
    name: m['name'] as String,
    teacher: m['teacher'] as String,
    room: m['room'] as String,
    colorValue: m['color_value'] as int,
    credits: m['credits'] as int,
  );
}