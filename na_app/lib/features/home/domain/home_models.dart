import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:na_app/features/subjects/domain/subject_models.dart';
import 'package:na_app/features/exams/domain/exam_models.dart';

part 'home_models.freezed.dart';

int _coerceInt(dynamic v) {
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v) ?? double.tryParse(v)?.toInt() ?? 0;
  return 0;
}

List<int> _coerceIntList(dynamic v) {
  if (v is! List) return List.filled(7, 0);
  final result = <int>[];
  for (final e in v) {
    result.add(_coerceInt(e));
  }
  return result.isEmpty ? List.filled(7, 0) : result;
}

@freezed
class AnalyticsSnapshot with _$AnalyticsSnapshot {
  const factory AnalyticsSnapshot({
    @Default(0) int streakDays,
    @Default(0) int lessonsCompleted,
    @Default(0) int examsTaken,
    @Default([]) List<int> weeklyActivity,
  }) = _AnalyticsSnapshot;

  factory AnalyticsSnapshot.fromJson(Map<String, dynamic> json) {
    return _AnalyticsSnapshot(
      streakDays: _coerceInt(json['streak'] ?? json['streakDays']),
      lessonsCompleted: _coerceInt(json['lessonsCompleted']),
      examsTaken: _coerceInt(json['examsTaken']),
      weeklyActivity: _coerceIntList(json['weeklyActivity']),
    );
  }
}

@freezed
class TodayViewState with _$TodayViewState {
  const factory TodayViewState({
    required String userName,
    required AnalyticsSnapshot analytics,
    required List<Subject> unlockedSubjects,
    required List<Subject> allSubjects,
    required List<Exam> dueTodayExams,
    ResumableLesson? resumableLesson,
  }) = _TodayViewState;
}

@freezed
class ResumableLesson with _$ResumableLesson {
  const factory ResumableLesson({
    required String lessonId,
    required String subjectId,
    required String lessonTitle,
    required String subjectTitle,
    @Default(0.0) double progressPercent,
    String? coverImageUrl,
    int? estimatedMinutes,
  }) = _ResumableLesson;
}