import 'package:flutter/material.dart';

class GameResult {
  final String gameName;
  final int score;
  final DateTime date;
  final String category;

  GameResult({
    required this.gameName,
    required this.score,
    required this.date,
    required this.category,
  });

  static final Color defaultColor = Colors.blue;

  Color get color => defaultColor;

  factory GameResult.fromMap(Map<String, dynamic> map) {
    return GameResult(
      gameName: map['gameName'] as String,
      score: map['score'] as int,
      date: DateTime.parse(map['date'] as String),
      category: map['category'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'gameName': gameName,
      'score': score,
      'date': date.toIso8601String(),
      'category': category,
    };
  }
}
