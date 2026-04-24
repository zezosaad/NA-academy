// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exam_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$Exam {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get subjectId => throw _privateConstructorUsedError;
  int get durationMinutes => throw _privateConstructorUsedError;
  int get questionCount => throw _privateConstructorUsedError;
  int get attemptsAllowed => throw _privateConstructorUsedError;
  int get attemptsRemaining => throw _privateConstructorUsedError;
  DateTime? get dueDate => throw _privateConstructorUsedError;
  ExamStatus get status => throw _privateConstructorUsedError;
  double? get lastScore => throw _privateConstructorUsedError;

  /// Create a copy of Exam
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExamCopyWith<Exam> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExamCopyWith<$Res> {
  factory $ExamCopyWith(Exam value, $Res Function(Exam) then) =
      _$ExamCopyWithImpl<$Res, Exam>;
  @useResult
  $Res call({
    String id,
    String title,
    String subjectId,
    int durationMinutes,
    int questionCount,
    int attemptsAllowed,
    int attemptsRemaining,
    DateTime? dueDate,
    ExamStatus status,
    double? lastScore,
  });
}

/// @nodoc
class _$ExamCopyWithImpl<$Res, $Val extends Exam>
    implements $ExamCopyWith<$Res> {
  _$ExamCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Exam
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? subjectId = null,
    Object? durationMinutes = null,
    Object? questionCount = null,
    Object? attemptsAllowed = null,
    Object? attemptsRemaining = null,
    Object? dueDate = freezed,
    Object? status = null,
    Object? lastScore = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            subjectId: null == subjectId
                ? _value.subjectId
                : subjectId // ignore: cast_nullable_to_non_nullable
                      as String,
            durationMinutes: null == durationMinutes
                ? _value.durationMinutes
                : durationMinutes // ignore: cast_nullable_to_non_nullable
                      as int,
            questionCount: null == questionCount
                ? _value.questionCount
                : questionCount // ignore: cast_nullable_to_non_nullable
                      as int,
            attemptsAllowed: null == attemptsAllowed
                ? _value.attemptsAllowed
                : attemptsAllowed // ignore: cast_nullable_to_non_nullable
                      as int,
            attemptsRemaining: null == attemptsRemaining
                ? _value.attemptsRemaining
                : attemptsRemaining // ignore: cast_nullable_to_non_nullable
                      as int,
            dueDate: freezed == dueDate
                ? _value.dueDate
                : dueDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as ExamStatus,
            lastScore: freezed == lastScore
                ? _value.lastScore
                : lastScore // ignore: cast_nullable_to_non_nullable
                      as double?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ExamImplCopyWith<$Res> implements $ExamCopyWith<$Res> {
  factory _$$ExamImplCopyWith(
    _$ExamImpl value,
    $Res Function(_$ExamImpl) then,
  ) = __$$ExamImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    String subjectId,
    int durationMinutes,
    int questionCount,
    int attemptsAllowed,
    int attemptsRemaining,
    DateTime? dueDate,
    ExamStatus status,
    double? lastScore,
  });
}

/// @nodoc
class __$$ExamImplCopyWithImpl<$Res>
    extends _$ExamCopyWithImpl<$Res, _$ExamImpl>
    implements _$$ExamImplCopyWith<$Res> {
  __$$ExamImplCopyWithImpl(_$ExamImpl _value, $Res Function(_$ExamImpl) _then)
    : super(_value, _then);

  /// Create a copy of Exam
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? subjectId = null,
    Object? durationMinutes = null,
    Object? questionCount = null,
    Object? attemptsAllowed = null,
    Object? attemptsRemaining = null,
    Object? dueDate = freezed,
    Object? status = null,
    Object? lastScore = freezed,
  }) {
    return _then(
      _$ExamImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        subjectId: null == subjectId
            ? _value.subjectId
            : subjectId // ignore: cast_nullable_to_non_nullable
                  as String,
        durationMinutes: null == durationMinutes
            ? _value.durationMinutes
            : durationMinutes // ignore: cast_nullable_to_non_nullable
                  as int,
        questionCount: null == questionCount
            ? _value.questionCount
            : questionCount // ignore: cast_nullable_to_non_nullable
                  as int,
        attemptsAllowed: null == attemptsAllowed
            ? _value.attemptsAllowed
            : attemptsAllowed // ignore: cast_nullable_to_non_nullable
                  as int,
        attemptsRemaining: null == attemptsRemaining
            ? _value.attemptsRemaining
            : attemptsRemaining // ignore: cast_nullable_to_non_nullable
                  as int,
        dueDate: freezed == dueDate
            ? _value.dueDate
            : dueDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as ExamStatus,
        lastScore: freezed == lastScore
            ? _value.lastScore
            : lastScore // ignore: cast_nullable_to_non_nullable
                  as double?,
      ),
    );
  }
}

/// @nodoc

class _$ExamImpl implements _Exam {
  const _$ExamImpl({
    required this.id,
    required this.title,
    required this.subjectId,
    this.durationMinutes = 0,
    this.questionCount = 0,
    this.attemptsAllowed = 0,
    this.attemptsRemaining = 0,
    this.dueDate,
    this.status = ExamStatus.available,
    this.lastScore,
  });

  @override
  final String id;
  @override
  final String title;
  @override
  final String subjectId;
  @override
  @JsonKey()
  final int durationMinutes;
  @override
  @JsonKey()
  final int questionCount;
  @override
  @JsonKey()
  final int attemptsAllowed;
  @override
  @JsonKey()
  final int attemptsRemaining;
  @override
  final DateTime? dueDate;
  @override
  @JsonKey()
  final ExamStatus status;
  @override
  final double? lastScore;

  @override
  String toString() {
    return 'Exam(id: $id, title: $title, subjectId: $subjectId, durationMinutes: $durationMinutes, questionCount: $questionCount, attemptsAllowed: $attemptsAllowed, attemptsRemaining: $attemptsRemaining, dueDate: $dueDate, status: $status, lastScore: $lastScore)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExamImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.subjectId, subjectId) ||
                other.subjectId == subjectId) &&
            (identical(other.durationMinutes, durationMinutes) ||
                other.durationMinutes == durationMinutes) &&
            (identical(other.questionCount, questionCount) ||
                other.questionCount == questionCount) &&
            (identical(other.attemptsAllowed, attemptsAllowed) ||
                other.attemptsAllowed == attemptsAllowed) &&
            (identical(other.attemptsRemaining, attemptsRemaining) ||
                other.attemptsRemaining == attemptsRemaining) &&
            (identical(other.dueDate, dueDate) || other.dueDate == dueDate) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.lastScore, lastScore) ||
                other.lastScore == lastScore));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    subjectId,
    durationMinutes,
    questionCount,
    attemptsAllowed,
    attemptsRemaining,
    dueDate,
    status,
    lastScore,
  );

  /// Create a copy of Exam
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExamImplCopyWith<_$ExamImpl> get copyWith =>
      __$$ExamImplCopyWithImpl<_$ExamImpl>(this, _$identity);
}

abstract class _Exam implements Exam {
  const factory _Exam({
    required final String id,
    required final String title,
    required final String subjectId,
    final int durationMinutes,
    final int questionCount,
    final int attemptsAllowed,
    final int attemptsRemaining,
    final DateTime? dueDate,
    final ExamStatus status,
    final double? lastScore,
  }) = _$ExamImpl;

  @override
  String get id;
  @override
  String get title;
  @override
  String get subjectId;
  @override
  int get durationMinutes;
  @override
  int get questionCount;
  @override
  int get attemptsAllowed;
  @override
  int get attemptsRemaining;
  @override
  DateTime? get dueDate;
  @override
  ExamStatus get status;
  @override
  double? get lastScore;

  /// Create a copy of Exam
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExamImplCopyWith<_$ExamImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$ExamQuestion {
  String get id => throw _privateConstructorUsedError;
  String get text => throw _privateConstructorUsedError;
  List<QuestionOption> get options => throw _privateConstructorUsedError;
  int get timeLimitSeconds => throw _privateConstructorUsedError;
  int get order => throw _privateConstructorUsedError;

  /// Create a copy of ExamQuestion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExamQuestionCopyWith<ExamQuestion> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExamQuestionCopyWith<$Res> {
  factory $ExamQuestionCopyWith(
    ExamQuestion value,
    $Res Function(ExamQuestion) then,
  ) = _$ExamQuestionCopyWithImpl<$Res, ExamQuestion>;
  @useResult
  $Res call({
    String id,
    String text,
    List<QuestionOption> options,
    int timeLimitSeconds,
    int order,
  });
}

/// @nodoc
class _$ExamQuestionCopyWithImpl<$Res, $Val extends ExamQuestion>
    implements $ExamQuestionCopyWith<$Res> {
  _$ExamQuestionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ExamQuestion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? text = null,
    Object? options = null,
    Object? timeLimitSeconds = null,
    Object? order = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            text: null == text
                ? _value.text
                : text // ignore: cast_nullable_to_non_nullable
                      as String,
            options: null == options
                ? _value.options
                : options // ignore: cast_nullable_to_non_nullable
                      as List<QuestionOption>,
            timeLimitSeconds: null == timeLimitSeconds
                ? _value.timeLimitSeconds
                : timeLimitSeconds // ignore: cast_nullable_to_non_nullable
                      as int,
            order: null == order
                ? _value.order
                : order // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ExamQuestionImplCopyWith<$Res>
    implements $ExamQuestionCopyWith<$Res> {
  factory _$$ExamQuestionImplCopyWith(
    _$ExamQuestionImpl value,
    $Res Function(_$ExamQuestionImpl) then,
  ) = __$$ExamQuestionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String text,
    List<QuestionOption> options,
    int timeLimitSeconds,
    int order,
  });
}

/// @nodoc
class __$$ExamQuestionImplCopyWithImpl<$Res>
    extends _$ExamQuestionCopyWithImpl<$Res, _$ExamQuestionImpl>
    implements _$$ExamQuestionImplCopyWith<$Res> {
  __$$ExamQuestionImplCopyWithImpl(
    _$ExamQuestionImpl _value,
    $Res Function(_$ExamQuestionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ExamQuestion
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? text = null,
    Object? options = null,
    Object? timeLimitSeconds = null,
    Object? order = null,
  }) {
    return _then(
      _$ExamQuestionImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        text: null == text
            ? _value.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String,
        options: null == options
            ? _value._options
            : options // ignore: cast_nullable_to_non_nullable
                  as List<QuestionOption>,
        timeLimitSeconds: null == timeLimitSeconds
            ? _value.timeLimitSeconds
            : timeLimitSeconds // ignore: cast_nullable_to_non_nullable
                  as int,
        order: null == order
            ? _value.order
            : order // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class _$ExamQuestionImpl implements _ExamQuestion {
  const _$ExamQuestionImpl({
    required this.id,
    required this.text,
    required final List<QuestionOption> options,
    required this.timeLimitSeconds,
    required this.order,
  }) : _options = options;

  @override
  final String id;
  @override
  final String text;
  final List<QuestionOption> _options;
  @override
  List<QuestionOption> get options {
    if (_options is EqualUnmodifiableListView) return _options;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_options);
  }

  @override
  final int timeLimitSeconds;
  @override
  final int order;

  @override
  String toString() {
    return 'ExamQuestion(id: $id, text: $text, options: $options, timeLimitSeconds: $timeLimitSeconds, order: $order)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExamQuestionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.text, text) || other.text == text) &&
            const DeepCollectionEquality().equals(other._options, _options) &&
            (identical(other.timeLimitSeconds, timeLimitSeconds) ||
                other.timeLimitSeconds == timeLimitSeconds) &&
            (identical(other.order, order) || other.order == order));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    text,
    const DeepCollectionEquality().hash(_options),
    timeLimitSeconds,
    order,
  );

  /// Create a copy of ExamQuestion
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExamQuestionImplCopyWith<_$ExamQuestionImpl> get copyWith =>
      __$$ExamQuestionImplCopyWithImpl<_$ExamQuestionImpl>(this, _$identity);
}

abstract class _ExamQuestion implements ExamQuestion {
  const factory _ExamQuestion({
    required final String id,
    required final String text,
    required final List<QuestionOption> options,
    required final int timeLimitSeconds,
    required final int order,
  }) = _$ExamQuestionImpl;

  @override
  String get id;
  @override
  String get text;
  @override
  List<QuestionOption> get options;
  @override
  int get timeLimitSeconds;
  @override
  int get order;

  /// Create a copy of ExamQuestion
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExamQuestionImplCopyWith<_$ExamQuestionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$QuestionOption {
  String get label => throw _privateConstructorUsedError;
  String get text => throw _privateConstructorUsedError;

  /// Create a copy of QuestionOption
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $QuestionOptionCopyWith<QuestionOption> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QuestionOptionCopyWith<$Res> {
  factory $QuestionOptionCopyWith(
    QuestionOption value,
    $Res Function(QuestionOption) then,
  ) = _$QuestionOptionCopyWithImpl<$Res, QuestionOption>;
  @useResult
  $Res call({String label, String text});
}

/// @nodoc
class _$QuestionOptionCopyWithImpl<$Res, $Val extends QuestionOption>
    implements $QuestionOptionCopyWith<$Res> {
  _$QuestionOptionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of QuestionOption
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? label = null, Object? text = null}) {
    return _then(
      _value.copyWith(
            label: null == label
                ? _value.label
                : label // ignore: cast_nullable_to_non_nullable
                      as String,
            text: null == text
                ? _value.text
                : text // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$QuestionOptionImplCopyWith<$Res>
    implements $QuestionOptionCopyWith<$Res> {
  factory _$$QuestionOptionImplCopyWith(
    _$QuestionOptionImpl value,
    $Res Function(_$QuestionOptionImpl) then,
  ) = __$$QuestionOptionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String label, String text});
}

/// @nodoc
class __$$QuestionOptionImplCopyWithImpl<$Res>
    extends _$QuestionOptionCopyWithImpl<$Res, _$QuestionOptionImpl>
    implements _$$QuestionOptionImplCopyWith<$Res> {
  __$$QuestionOptionImplCopyWithImpl(
    _$QuestionOptionImpl _value,
    $Res Function(_$QuestionOptionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of QuestionOption
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? label = null, Object? text = null}) {
    return _then(
      _$QuestionOptionImpl(
        label: null == label
            ? _value.label
            : label // ignore: cast_nullable_to_non_nullable
                  as String,
        text: null == text
            ? _value.text
            : text // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$QuestionOptionImpl implements _QuestionOption {
  const _$QuestionOptionImpl({required this.label, required this.text});

  @override
  final String label;
  @override
  final String text;

  @override
  String toString() {
    return 'QuestionOption(label: $label, text: $text)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QuestionOptionImpl &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.text, text) || other.text == text));
  }

  @override
  int get hashCode => Object.hash(runtimeType, label, text);

  /// Create a copy of QuestionOption
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$QuestionOptionImplCopyWith<_$QuestionOptionImpl> get copyWith =>
      __$$QuestionOptionImplCopyWithImpl<_$QuestionOptionImpl>(
        this,
        _$identity,
      );
}

abstract class _QuestionOption implements QuestionOption {
  const factory _QuestionOption({
    required final String label,
    required final String text,
  }) = _$QuestionOptionImpl;

  @override
  String get label;
  @override
  String get text;

  /// Create a copy of QuestionOption
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$QuestionOptionImplCopyWith<_$QuestionOptionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$ExamSession {
  String get id => throw _privateConstructorUsedError;
  String get examId => throw _privateConstructorUsedError;
  DateTime get startedAt => throw _privateConstructorUsedError;
  DateTime get endsAt => throw _privateConstructorUsedError;
  Map<String, AnswerValue> get answers => throw _privateConstructorUsedError;
  SessionStatus get status => throw _privateConstructorUsedError;

  /// Create a copy of ExamSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExamSessionCopyWith<ExamSession> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExamSessionCopyWith<$Res> {
  factory $ExamSessionCopyWith(
    ExamSession value,
    $Res Function(ExamSession) then,
  ) = _$ExamSessionCopyWithImpl<$Res, ExamSession>;
  @useResult
  $Res call({
    String id,
    String examId,
    DateTime startedAt,
    DateTime endsAt,
    Map<String, AnswerValue> answers,
    SessionStatus status,
  });
}

/// @nodoc
class _$ExamSessionCopyWithImpl<$Res, $Val extends ExamSession>
    implements $ExamSessionCopyWith<$Res> {
  _$ExamSessionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ExamSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? examId = null,
    Object? startedAt = null,
    Object? endsAt = null,
    Object? answers = null,
    Object? status = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            examId: null == examId
                ? _value.examId
                : examId // ignore: cast_nullable_to_non_nullable
                      as String,
            startedAt: null == startedAt
                ? _value.startedAt
                : startedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            endsAt: null == endsAt
                ? _value.endsAt
                : endsAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
            answers: null == answers
                ? _value.answers
                : answers // ignore: cast_nullable_to_non_nullable
                      as Map<String, AnswerValue>,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as SessionStatus,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ExamSessionImplCopyWith<$Res>
    implements $ExamSessionCopyWith<$Res> {
  factory _$$ExamSessionImplCopyWith(
    _$ExamSessionImpl value,
    $Res Function(_$ExamSessionImpl) then,
  ) = __$$ExamSessionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String examId,
    DateTime startedAt,
    DateTime endsAt,
    Map<String, AnswerValue> answers,
    SessionStatus status,
  });
}

/// @nodoc
class __$$ExamSessionImplCopyWithImpl<$Res>
    extends _$ExamSessionCopyWithImpl<$Res, _$ExamSessionImpl>
    implements _$$ExamSessionImplCopyWith<$Res> {
  __$$ExamSessionImplCopyWithImpl(
    _$ExamSessionImpl _value,
    $Res Function(_$ExamSessionImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ExamSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? examId = null,
    Object? startedAt = null,
    Object? endsAt = null,
    Object? answers = null,
    Object? status = null,
  }) {
    return _then(
      _$ExamSessionImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        examId: null == examId
            ? _value.examId
            : examId // ignore: cast_nullable_to_non_nullable
                  as String,
        startedAt: null == startedAt
            ? _value.startedAt
            : startedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        endsAt: null == endsAt
            ? _value.endsAt
            : endsAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        answers: null == answers
            ? _value._answers
            : answers // ignore: cast_nullable_to_non_nullable
                  as Map<String, AnswerValue>,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as SessionStatus,
      ),
    );
  }
}

/// @nodoc

class _$ExamSessionImpl implements _ExamSession {
  const _$ExamSessionImpl({
    required this.id,
    required this.examId,
    required this.startedAt,
    required this.endsAt,
    final Map<String, AnswerValue> answers = const {},
    this.status = SessionStatus.inProgress,
  }) : _answers = answers;

  @override
  final String id;
  @override
  final String examId;
  @override
  final DateTime startedAt;
  @override
  final DateTime endsAt;
  final Map<String, AnswerValue> _answers;
  @override
  @JsonKey()
  Map<String, AnswerValue> get answers {
    if (_answers is EqualUnmodifiableMapView) return _answers;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_answers);
  }

  @override
  @JsonKey()
  final SessionStatus status;

  @override
  String toString() {
    return 'ExamSession(id: $id, examId: $examId, startedAt: $startedAt, endsAt: $endsAt, answers: $answers, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExamSessionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.examId, examId) || other.examId == examId) &&
            (identical(other.startedAt, startedAt) ||
                other.startedAt == startedAt) &&
            (identical(other.endsAt, endsAt) || other.endsAt == endsAt) &&
            const DeepCollectionEquality().equals(other._answers, _answers) &&
            (identical(other.status, status) || other.status == status));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    examId,
    startedAt,
    endsAt,
    const DeepCollectionEquality().hash(_answers),
    status,
  );

  /// Create a copy of ExamSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExamSessionImplCopyWith<_$ExamSessionImpl> get copyWith =>
      __$$ExamSessionImplCopyWithImpl<_$ExamSessionImpl>(this, _$identity);
}

abstract class _ExamSession implements ExamSession {
  const factory _ExamSession({
    required final String id,
    required final String examId,
    required final DateTime startedAt,
    required final DateTime endsAt,
    final Map<String, AnswerValue> answers,
    final SessionStatus status,
  }) = _$ExamSessionImpl;

  @override
  String get id;
  @override
  String get examId;
  @override
  DateTime get startedAt;
  @override
  DateTime get endsAt;
  @override
  Map<String, AnswerValue> get answers;
  @override
  SessionStatus get status;

  /// Create a copy of ExamSession
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExamSessionImplCopyWith<_$ExamSessionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$AnswerValue {
  String get selectedOption => throw _privateConstructorUsedError;

  /// Create a copy of AnswerValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AnswerValueCopyWith<AnswerValue> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AnswerValueCopyWith<$Res> {
  factory $AnswerValueCopyWith(
    AnswerValue value,
    $Res Function(AnswerValue) then,
  ) = _$AnswerValueCopyWithImpl<$Res, AnswerValue>;
  @useResult
  $Res call({String selectedOption});
}

/// @nodoc
class _$AnswerValueCopyWithImpl<$Res, $Val extends AnswerValue>
    implements $AnswerValueCopyWith<$Res> {
  _$AnswerValueCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AnswerValue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? selectedOption = null}) {
    return _then(
      _value.copyWith(
            selectedOption: null == selectedOption
                ? _value.selectedOption
                : selectedOption // ignore: cast_nullable_to_non_nullable
                      as String,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AnswerValueImplCopyWith<$Res>
    implements $AnswerValueCopyWith<$Res> {
  factory _$$AnswerValueImplCopyWith(
    _$AnswerValueImpl value,
    $Res Function(_$AnswerValueImpl) then,
  ) = __$$AnswerValueImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String selectedOption});
}

/// @nodoc
class __$$AnswerValueImplCopyWithImpl<$Res>
    extends _$AnswerValueCopyWithImpl<$Res, _$AnswerValueImpl>
    implements _$$AnswerValueImplCopyWith<$Res> {
  __$$AnswerValueImplCopyWithImpl(
    _$AnswerValueImpl _value,
    $Res Function(_$AnswerValueImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AnswerValue
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? selectedOption = null}) {
    return _then(
      _$AnswerValueImpl(
        selectedOption: null == selectedOption
            ? _value.selectedOption
            : selectedOption // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$AnswerValueImpl implements _AnswerValue {
  const _$AnswerValueImpl({required this.selectedOption});

  @override
  final String selectedOption;

  @override
  String toString() {
    return 'AnswerValue(selectedOption: $selectedOption)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AnswerValueImpl &&
            (identical(other.selectedOption, selectedOption) ||
                other.selectedOption == selectedOption));
  }

  @override
  int get hashCode => Object.hash(runtimeType, selectedOption);

  /// Create a copy of AnswerValue
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AnswerValueImplCopyWith<_$AnswerValueImpl> get copyWith =>
      __$$AnswerValueImplCopyWithImpl<_$AnswerValueImpl>(this, _$identity);
}

abstract class _AnswerValue implements AnswerValue {
  const factory _AnswerValue({required final String selectedOption}) =
      _$AnswerValueImpl;

  @override
  String get selectedOption;

  /// Create a copy of AnswerValue
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AnswerValueImplCopyWith<_$AnswerValueImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$ExamScore {
  String get sessionId => throw _privateConstructorUsedError;
  double get score => throw _privateConstructorUsedError;
  PassFail get passFail => throw _privateConstructorUsedError;
  List<QuestionReview> get perQuestion => throw _privateConstructorUsedError;

  /// Create a copy of ExamScore
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ExamScoreCopyWith<ExamScore> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ExamScoreCopyWith<$Res> {
  factory $ExamScoreCopyWith(ExamScore value, $Res Function(ExamScore) then) =
      _$ExamScoreCopyWithImpl<$Res, ExamScore>;
  @useResult
  $Res call({
    String sessionId,
    double score,
    PassFail passFail,
    List<QuestionReview> perQuestion,
  });
}

/// @nodoc
class _$ExamScoreCopyWithImpl<$Res, $Val extends ExamScore>
    implements $ExamScoreCopyWith<$Res> {
  _$ExamScoreCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ExamScore
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sessionId = null,
    Object? score = null,
    Object? passFail = null,
    Object? perQuestion = null,
  }) {
    return _then(
      _value.copyWith(
            sessionId: null == sessionId
                ? _value.sessionId
                : sessionId // ignore: cast_nullable_to_non_nullable
                      as String,
            score: null == score
                ? _value.score
                : score // ignore: cast_nullable_to_non_nullable
                      as double,
            passFail: null == passFail
                ? _value.passFail
                : passFail // ignore: cast_nullable_to_non_nullable
                      as PassFail,
            perQuestion: null == perQuestion
                ? _value.perQuestion
                : perQuestion // ignore: cast_nullable_to_non_nullable
                      as List<QuestionReview>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ExamScoreImplCopyWith<$Res>
    implements $ExamScoreCopyWith<$Res> {
  factory _$$ExamScoreImplCopyWith(
    _$ExamScoreImpl value,
    $Res Function(_$ExamScoreImpl) then,
  ) = __$$ExamScoreImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String sessionId,
    double score,
    PassFail passFail,
    List<QuestionReview> perQuestion,
  });
}

/// @nodoc
class __$$ExamScoreImplCopyWithImpl<$Res>
    extends _$ExamScoreCopyWithImpl<$Res, _$ExamScoreImpl>
    implements _$$ExamScoreImplCopyWith<$Res> {
  __$$ExamScoreImplCopyWithImpl(
    _$ExamScoreImpl _value,
    $Res Function(_$ExamScoreImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ExamScore
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sessionId = null,
    Object? score = null,
    Object? passFail = null,
    Object? perQuestion = null,
  }) {
    return _then(
      _$ExamScoreImpl(
        sessionId: null == sessionId
            ? _value.sessionId
            : sessionId // ignore: cast_nullable_to_non_nullable
                  as String,
        score: null == score
            ? _value.score
            : score // ignore: cast_nullable_to_non_nullable
                  as double,
        passFail: null == passFail
            ? _value.passFail
            : passFail // ignore: cast_nullable_to_non_nullable
                  as PassFail,
        perQuestion: null == perQuestion
            ? _value._perQuestion
            : perQuestion // ignore: cast_nullable_to_non_nullable
                  as List<QuestionReview>,
      ),
    );
  }
}

/// @nodoc

class _$ExamScoreImpl implements _ExamScore {
  const _$ExamScoreImpl({
    required this.sessionId,
    required this.score,
    this.passFail = PassFail.none,
    final List<QuestionReview> perQuestion = const [],
  }) : _perQuestion = perQuestion;

  @override
  final String sessionId;
  @override
  final double score;
  @override
  @JsonKey()
  final PassFail passFail;
  final List<QuestionReview> _perQuestion;
  @override
  @JsonKey()
  List<QuestionReview> get perQuestion {
    if (_perQuestion is EqualUnmodifiableListView) return _perQuestion;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_perQuestion);
  }

  @override
  String toString() {
    return 'ExamScore(sessionId: $sessionId, score: $score, passFail: $passFail, perQuestion: $perQuestion)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ExamScoreImpl &&
            (identical(other.sessionId, sessionId) ||
                other.sessionId == sessionId) &&
            (identical(other.score, score) || other.score == score) &&
            (identical(other.passFail, passFail) ||
                other.passFail == passFail) &&
            const DeepCollectionEquality().equals(
              other._perQuestion,
              _perQuestion,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    sessionId,
    score,
    passFail,
    const DeepCollectionEquality().hash(_perQuestion),
  );

  /// Create a copy of ExamScore
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ExamScoreImplCopyWith<_$ExamScoreImpl> get copyWith =>
      __$$ExamScoreImplCopyWithImpl<_$ExamScoreImpl>(this, _$identity);
}

abstract class _ExamScore implements ExamScore {
  const factory _ExamScore({
    required final String sessionId,
    required final double score,
    final PassFail passFail,
    final List<QuestionReview> perQuestion,
  }) = _$ExamScoreImpl;

  @override
  String get sessionId;
  @override
  double get score;
  @override
  PassFail get passFail;
  @override
  List<QuestionReview> get perQuestion;

  /// Create a copy of ExamScore
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ExamScoreImplCopyWith<_$ExamScoreImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$QuestionReview {
  String get questionId => throw _privateConstructorUsedError;
  String? get studentAnswer => throw _privateConstructorUsedError;
  String? get correctAnswer => throw _privateConstructorUsedError;
  bool get isCorrect => throw _privateConstructorUsedError;

  /// Create a copy of QuestionReview
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $QuestionReviewCopyWith<QuestionReview> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QuestionReviewCopyWith<$Res> {
  factory $QuestionReviewCopyWith(
    QuestionReview value,
    $Res Function(QuestionReview) then,
  ) = _$QuestionReviewCopyWithImpl<$Res, QuestionReview>;
  @useResult
  $Res call({
    String questionId,
    String? studentAnswer,
    String? correctAnswer,
    bool isCorrect,
  });
}

/// @nodoc
class _$QuestionReviewCopyWithImpl<$Res, $Val extends QuestionReview>
    implements $QuestionReviewCopyWith<$Res> {
  _$QuestionReviewCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of QuestionReview
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? questionId = null,
    Object? studentAnswer = freezed,
    Object? correctAnswer = freezed,
    Object? isCorrect = null,
  }) {
    return _then(
      _value.copyWith(
            questionId: null == questionId
                ? _value.questionId
                : questionId // ignore: cast_nullable_to_non_nullable
                      as String,
            studentAnswer: freezed == studentAnswer
                ? _value.studentAnswer
                : studentAnswer // ignore: cast_nullable_to_non_nullable
                      as String?,
            correctAnswer: freezed == correctAnswer
                ? _value.correctAnswer
                : correctAnswer // ignore: cast_nullable_to_non_nullable
                      as String?,
            isCorrect: null == isCorrect
                ? _value.isCorrect
                : isCorrect // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$QuestionReviewImplCopyWith<$Res>
    implements $QuestionReviewCopyWith<$Res> {
  factory _$$QuestionReviewImplCopyWith(
    _$QuestionReviewImpl value,
    $Res Function(_$QuestionReviewImpl) then,
  ) = __$$QuestionReviewImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String questionId,
    String? studentAnswer,
    String? correctAnswer,
    bool isCorrect,
  });
}

/// @nodoc
class __$$QuestionReviewImplCopyWithImpl<$Res>
    extends _$QuestionReviewCopyWithImpl<$Res, _$QuestionReviewImpl>
    implements _$$QuestionReviewImplCopyWith<$Res> {
  __$$QuestionReviewImplCopyWithImpl(
    _$QuestionReviewImpl _value,
    $Res Function(_$QuestionReviewImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of QuestionReview
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? questionId = null,
    Object? studentAnswer = freezed,
    Object? correctAnswer = freezed,
    Object? isCorrect = null,
  }) {
    return _then(
      _$QuestionReviewImpl(
        questionId: null == questionId
            ? _value.questionId
            : questionId // ignore: cast_nullable_to_non_nullable
                  as String,
        studentAnswer: freezed == studentAnswer
            ? _value.studentAnswer
            : studentAnswer // ignore: cast_nullable_to_non_nullable
                  as String?,
        correctAnswer: freezed == correctAnswer
            ? _value.correctAnswer
            : correctAnswer // ignore: cast_nullable_to_non_nullable
                  as String?,
        isCorrect: null == isCorrect
            ? _value.isCorrect
            : isCorrect // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$QuestionReviewImpl implements _QuestionReview {
  const _$QuestionReviewImpl({
    required this.questionId,
    this.studentAnswer,
    this.correctAnswer,
    this.isCorrect = false,
  });

  @override
  final String questionId;
  @override
  final String? studentAnswer;
  @override
  final String? correctAnswer;
  @override
  @JsonKey()
  final bool isCorrect;

  @override
  String toString() {
    return 'QuestionReview(questionId: $questionId, studentAnswer: $studentAnswer, correctAnswer: $correctAnswer, isCorrect: $isCorrect)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QuestionReviewImpl &&
            (identical(other.questionId, questionId) ||
                other.questionId == questionId) &&
            (identical(other.studentAnswer, studentAnswer) ||
                other.studentAnswer == studentAnswer) &&
            (identical(other.correctAnswer, correctAnswer) ||
                other.correctAnswer == correctAnswer) &&
            (identical(other.isCorrect, isCorrect) ||
                other.isCorrect == isCorrect));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    questionId,
    studentAnswer,
    correctAnswer,
    isCorrect,
  );

  /// Create a copy of QuestionReview
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$QuestionReviewImplCopyWith<_$QuestionReviewImpl> get copyWith =>
      __$$QuestionReviewImplCopyWithImpl<_$QuestionReviewImpl>(
        this,
        _$identity,
      );
}

abstract class _QuestionReview implements QuestionReview {
  const factory _QuestionReview({
    required final String questionId,
    final String? studentAnswer,
    final String? correctAnswer,
    final bool isCorrect,
  }) = _$QuestionReviewImpl;

  @override
  String get questionId;
  @override
  String? get studentAnswer;
  @override
  String? get correctAnswer;
  @override
  bool get isCorrect;

  /// Create a copy of QuestionReview
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$QuestionReviewImplCopyWith<_$QuestionReviewImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
