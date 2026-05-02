import 'package:freezed_annotation/freezed_annotation.dart';

part 'exam_models.freezed.dart';

enum ExamStatus { available, completed, locked }

enum ExamAccessMode { codeRequired, freeSection, fullExamFreeAttempts, free }

enum ExamTimingMode { perQuestion, wholeExam }

enum SessionStatus { inProgress, submitted, timedOut }

enum PassFail { pass, fail, none }

@freezed
class Exam with _$Exam {
  const factory Exam({
    required String id,
    required String title,
    required String subjectId,
    @Default(0) int durationMinutes,
    @Default(0) int questionCount,
    @Default(0) int attemptsAllowed,
    @Default(0) int attemptsRemaining,
    @Default(0) int freeAttemptsRemaining,
    DateTime? dueDate,
    @Default(ExamAccessMode.codeRequired) ExamAccessMode accessMode,
    @Default(ExamTimingMode.perQuestion) ExamTimingMode timingMode,
    @Default(ExamStatus.available) ExamStatus status,
    @Default(false) bool isSubjectUnlocked,
    @Default(false) bool isAssigned,
    @Default(false) bool hasRetakePermit,
    double? lastScore,
  }) = _Exam;

  factory Exam.fromJson(Map<String, dynamic> json) {
    final id = json['_id'] as String? ?? json['id'] as String?;
    if (id == null || id.isEmpty) {
      throw FormatException('Exam.fromJson: missing "id" in $json');
    }
    final timingMode = _parseTimingMode(json['timingMode'] as String?);
    final questions =
        (json['questions'] as List<dynamic>?)
            ?.map((e) => ExamQuestion.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    final examTimeLimitMinutes = json['examTimeLimitMinutes'] as int?;
    final computedDurationMinutes = _resolveDurationMinutes(
      rawDurationMinutes: json['durationMinutes'] as int?,
      timingMode: timingMode,
      examTimeLimitMinutes: examTimeLimitMinutes,
      questions: questions,
    );

    return _Exam(
      id: id,
      title: json['title'] as String? ?? '',
      subjectId: json['subjectId'] as String? ?? '',
      durationMinutes: computedDurationMinutes,
      questionCount: questions.isNotEmpty
          ? questions.length
          : json['questionCount'] as int? ?? 0,
      attemptsAllowed: json['attemptsAllowed'] as int? ?? 0,
      attemptsRemaining: json['attemptsRemaining'] as int? ?? 0,
      freeAttemptsRemaining: json['freeAttemptsRemaining'] as int? ?? 0,
      dueDate: _parseDate(json['dueDate']) ?? _parseDate(json['availableUntil']),
      accessMode: _parseAccessMode(json['accessMode'] as String?),
      timingMode: timingMode,
      status: _parseExamStatus(json['status'] as String?),
      isSubjectUnlocked: json['isSubjectUnlocked'] as bool? ?? false,
      isAssigned: json['isAssigned'] as bool? ?? false,
      hasRetakePermit: json['hasRetakePermit'] as bool? ?? false,
      lastScore: (json['lastScore'] as num?)?.toDouble(),
    );
  }

  static ExamAccessMode _parseAccessMode(String? value) => switch (value) {
    'full_exam_free_attempts' => ExamAccessMode.fullExamFreeAttempts,
    'free_section' => ExamAccessMode.freeSection,
    'free' => ExamAccessMode.free,
    _ => ExamAccessMode.codeRequired,
  };

  static ExamStatus _parseExamStatus(String? value) => switch (value) {
    'completed' => ExamStatus.completed,
    'locked' => ExamStatus.locked,
    _ => ExamStatus.available,
  };

  static ExamTimingMode _parseTimingMode(String? value) => switch (value) {
    'whole_exam' => ExamTimingMode.wholeExam,
    _ => ExamTimingMode.perQuestion,
  };

  static DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static int _resolveDurationMinutes({
    required int? rawDurationMinutes,
    required ExamTimingMode timingMode,
    required int? examTimeLimitMinutes,
    required List<ExamQuestion> questions,
  }) {
    if (rawDurationMinutes != null && rawDurationMinutes > 0) {
      return rawDurationMinutes;
    }

    if (timingMode == ExamTimingMode.wholeExam) {
      return examTimeLimitMinutes ?? 0;
    }

    final validSeconds = questions.fold<int>(
      0,
      (sum, q) => q.timeLimitSeconds >= 5 ? sum + q.timeLimitSeconds : sum,
    );
    if (validSeconds > 0) return (validSeconds / 60).ceil();
    if (examTimeLimitMinutes != null && examTimeLimitMinutes > 0) {
      return examTimeLimitMinutes;
    }
    return (questions.length * 5 / 60).ceil().clamp(1, 999);
  }
}

extension ExamAccessX on Exam {
  bool get canStartDirectly =>
      hasRetakePermit ||
      isAssigned ||
      isSubjectUnlocked ||
      accessMode == ExamAccessMode.free ||
      ((accessMode == ExamAccessMode.fullExamFreeAttempts ||
              accessMode == ExamAccessMode.freeSection) &&
          freeAttemptsRemaining > 0);

  bool get needsCodeEntry => !canStartDirectly;
}

@freezed
class ExamQuestion with _$ExamQuestion {
  const factory ExamQuestion({
    required String id,
    required String text,
    required List<QuestionOption> options,
    required int timeLimitSeconds,
    required int order,
  }) = _ExamQuestion;

  factory ExamQuestion.fromJson(Map<String, dynamic> json) {
    final id = json['_id'] as String? ?? json['id'] as String?;
    return _ExamQuestion(
      id: id ?? '',
      text: json['text'] as String? ?? '',
      options:
          (json['options'] as List<dynamic>?)
              ?.map((e) => QuestionOption.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      timeLimitSeconds: json['timeLimitSeconds'] as int? ?? 0,
      order: json['order'] as int? ?? 0,
    );
  }
}

@freezed
class QuestionOption with _$QuestionOption {
  const factory QuestionOption({required String label, required String text}) =
      _QuestionOption;

  factory QuestionOption.fromJson(Map<String, dynamic> json) {
    return _QuestionOption(
      label: json['label'] as String? ?? '',
      text: json['text'] as String? ?? '',
    );
  }
}

@freezed
class ExamSession with _$ExamSession {
  const factory ExamSession({
    required String id,
    required String examId,
    required DateTime startedAt,
    required DateTime endsAt,
    @Default({}) Map<String, AnswerValue> answers,
    @Default(SessionStatus.inProgress) SessionStatus status,
  }) = _ExamSession;

  factory ExamSession.fromJson(Map<String, dynamic> json) {
    final id = json['_id'] as String? ?? json['id'] as String?;
    final startedAt =
        DateTime.tryParse(json['startedAt'] as String? ?? '') ?? DateTime.now();
    final timeLimit = json['timeLimitMinutes'] as int? ?? 0;
    final endsAt = startedAt.add(Duration(minutes: timeLimit));
    final answersMap = <String, AnswerValue>{};
    final responses = json['responses'] as List<dynamic>? ?? [];
    for (final r in responses) {
      final rMap = r as Map<String, dynamic>;
      final qId =
          (rMap['questionId'] as String?) ??
          rMap['questionId']?.toString() ??
          '';
      if (qId.isNotEmpty) {
        answersMap[qId] = AnswerValue.fromJson(rMap);
      }
    }
    return _ExamSession(
      id: id ?? '',
      examId: (json['examId'] as String?) ?? '',
      startedAt: startedAt,
      endsAt: endsAt,
      answers: answersMap,
      status: _parseSessionStatus(json['status'] as String?),
    );
  }

  static SessionStatus _parseSessionStatus(String? value) => switch (value) {
    'completed' => SessionStatus.submitted,
    'timed_out' => SessionStatus.timedOut,
    _ => SessionStatus.inProgress,
  };
}

@freezed
class AnswerValue with _$AnswerValue {
  const factory AnswerValue({
    required String selectedOption,
    @Default([]) List<String> selectedOptions,
  }) = _AnswerValue;

  factory AnswerValue.fromJson(Map<String, dynamic> json) {
    final raw = json['selectedOption'];
    String selectedOption;
    List<String> selectedOptions;

    if (raw is String) {
      selectedOption = raw;
      selectedOptions = [raw];
    } else if (raw is List) {
      selectedOptions = raw.map((e) => e.toString()).toList();
      selectedOption = selectedOptions.isNotEmpty
          ? selectedOptions.join(',')
          : '';
    } else {
      selectedOption = '';
      selectedOptions = [];
    }

    return _AnswerValue(
      selectedOption: selectedOption,
      selectedOptions: selectedOptions,
    );
  }
}

@freezed
class ExamScore with _$ExamScore {
  const factory ExamScore({
    required String sessionId,
    required double score,
    @Default(PassFail.none) PassFail passFail,
    @Default([]) List<QuestionReview> perQuestion,
  }) = _ExamScore;

  factory ExamScore.fromJson(Map<String, dynamic> json) {
    return _ExamScore(
      sessionId: (json['sessionId'] as String?) ?? json['_id'] as String? ?? '',
      score:
          (json['scorePercentage'] as num?)?.toDouble() ??
          (json['score'] as num?)?.toDouble() ??
          0.0,
      passFail: json['passFail'] != null
          ? _parsePassFail(json['passFail'] as String)
          : PassFail.none,
      perQuestion:
          (json['perQuestion'] as List<dynamic>?)
              ?.map((e) => QuestionReview.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  static PassFail _parsePassFail(String value) => switch (value) {
    'pass' => PassFail.pass,
    'fail' => PassFail.fail,
    _ => PassFail.none,
  };
}

@freezed
class QuestionReview with _$QuestionReview {
  const factory QuestionReview({
    required String questionId,
    String? studentAnswer,
    String? correctAnswer,
    @Default(false) bool isCorrect,
  }) = _QuestionReview;

  factory QuestionReview.fromJson(Map<String, dynamic> json) {
    return _QuestionReview(
      questionId: json['questionId'] as String? ?? '',
      studentAnswer: json['studentAnswer'] as String?,
      correctAnswer: json['correctAnswer'] as String?,
      isCorrect: json['isCorrect'] as bool? ?? false,
    );
  }
}
