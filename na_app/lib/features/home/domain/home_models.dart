import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:na_app/features/subjects/domain/subject_models.dart';
import 'package:na_app/features/exams/domain/exam_models.dart';

part 'home_models.freezed.dart';

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
      streakDays: json['streak'] as int? ?? json['streakDays'] as int? ?? 0,
      lessonsCompleted: json['lessonsCompleted'] as int? ?? 0,
      examsTaken: json['examsTaken'] as int? ?? 0,
      weeklyActivity: (json['weeklyActivity'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          List.filled(7, 0),
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