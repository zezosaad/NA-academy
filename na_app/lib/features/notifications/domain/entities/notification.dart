import 'package:equatable/equatable.dart';

class Notification extends Equatable {
  final String id;
  final String title;
  final String body;
  final String? data;
  final String? senderName;
  final DateTime createdAt;
  final DateTime? readAt;

  const Notification({
    required this.id,
    required this.title,
    required this.body,
    this.data,
    this.senderName,
    required this.createdAt,
    this.readAt,
  });

  bool get isRead => readAt != null;

  @override
  List<Object?> get props => [id, title, body, data, senderName, createdAt, readAt];
}
