import 'package:freezed_annotation/freezed_annotation.dart';

part 'subject_models.freezed.dart';

@freezed
class Subject with _$Subject {
  const factory Subject({
    required String id,
    required String title,
    String? description,
    String? coverImageUrl,
    @Default(0) int lessonCount,
    @Default(0) int examCount,
    @Default(false) bool isUnlocked,
    @Default(0.0) double progressPercent,
  }) = _Subject;

  factory Subject.fromJson(Map<String, dynamic> json) {
    final id = json['_id'] as String? ?? json['id'] as String?;
    if (id == null || id.isEmpty) {
      throw FormatException('Subject.fromJson: missing "id" in $json');
    }
    return _Subject(
      id: id,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      coverImageUrl:
          json['coverImage'] as String? ?? json['coverImageUrl'] as String?,
      lessonCount: json['lessonCount'] as int? ?? 0,
      examCount: json['examCount'] as int? ?? 0,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      progressPercent:
          ((json['progressPercent'] as num?)?.toDouble() ?? 0.0) * 100,
    );
  }
}

enum LessonStatus { done, active, locked }

@freezed
class Lesson with _$Lesson {
  const factory Lesson({
    required String id,
    required String subjectId,
    required String title,
    required int order,
    @Default(LessonStatus.locked) LessonStatus status,
    @Default(false) bool isCompleted,
    String? description,
    String? mediaAssetId,
    int? estimatedMinutes,
  }) = _Lesson;

  factory Lesson.fromJson(
    Map<String, dynamic> json, {
    required String subjectId,
  }) {
    final id = json['_id'] as String? ?? json['id'] as String?;
    if (id == null || id.isEmpty) {
      throw FormatException('Lesson.fromJson: missing "id" in $json');
    }
    final isCompleted = json['isCompleted'] as bool? ?? false;
    return _Lesson(
      id: id,
      subjectId: subjectId,
      title: json['title'] as String? ?? '',
      order: json['order'] as int? ?? json['index'] as int? ?? 0,
      status: isCompleted
          ? LessonStatus.done
          : _parseStatus(json['status'] as String?),
      isCompleted: isCompleted,
      description: json['description'] as String?,
      mediaAssetId:
          json['mediaId'] as String? ?? json['mediaAssetId'] as String?,
      estimatedMinutes: json['estimatedMinutes'] as int?,
    );
  }

  static LessonStatus _parseStatus(String? value) => switch (value) {
    'done' => LessonStatus.done,
    'locked' => LessonStatus.locked,
    _ => LessonStatus.active,
  };
}
