// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'home_models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$AnalyticsSnapshot {
  int get streakDays => throw _privateConstructorUsedError;
  int get lessonsCompleted => throw _privateConstructorUsedError;
  int get examsTaken => throw _privateConstructorUsedError;
  List<int> get weeklyActivity => throw _privateConstructorUsedError;

  /// Create a copy of AnalyticsSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AnalyticsSnapshotCopyWith<AnalyticsSnapshot> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AnalyticsSnapshotCopyWith<$Res> {
  factory $AnalyticsSnapshotCopyWith(
    AnalyticsSnapshot value,
    $Res Function(AnalyticsSnapshot) then,
  ) = _$AnalyticsSnapshotCopyWithImpl<$Res, AnalyticsSnapshot>;
  @useResult
  $Res call({
    int streakDays,
    int lessonsCompleted,
    int examsTaken,
    List<int> weeklyActivity,
  });
}

/// @nodoc
class _$AnalyticsSnapshotCopyWithImpl<$Res, $Val extends AnalyticsSnapshot>
    implements $AnalyticsSnapshotCopyWith<$Res> {
  _$AnalyticsSnapshotCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AnalyticsSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? streakDays = null,
    Object? lessonsCompleted = null,
    Object? examsTaken = null,
    Object? weeklyActivity = null,
  }) {
    return _then(
      _value.copyWith(
            streakDays: null == streakDays
                ? _value.streakDays
                : streakDays // ignore: cast_nullable_to_non_nullable
                      as int,
            lessonsCompleted: null == lessonsCompleted
                ? _value.lessonsCompleted
                : lessonsCompleted // ignore: cast_nullable_to_non_nullable
                      as int,
            examsTaken: null == examsTaken
                ? _value.examsTaken
                : examsTaken // ignore: cast_nullable_to_non_nullable
                      as int,
            weeklyActivity: null == weeklyActivity
                ? _value.weeklyActivity
                : weeklyActivity // ignore: cast_nullable_to_non_nullable
                      as List<int>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AnalyticsSnapshotImplCopyWith<$Res>
    implements $AnalyticsSnapshotCopyWith<$Res> {
  factory _$$AnalyticsSnapshotImplCopyWith(
    _$AnalyticsSnapshotImpl value,
    $Res Function(_$AnalyticsSnapshotImpl) then,
  ) = __$$AnalyticsSnapshotImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    int streakDays,
    int lessonsCompleted,
    int examsTaken,
    List<int> weeklyActivity,
  });
}

/// @nodoc
class __$$AnalyticsSnapshotImplCopyWithImpl<$Res>
    extends _$AnalyticsSnapshotCopyWithImpl<$Res, _$AnalyticsSnapshotImpl>
    implements _$$AnalyticsSnapshotImplCopyWith<$Res> {
  __$$AnalyticsSnapshotImplCopyWithImpl(
    _$AnalyticsSnapshotImpl _value,
    $Res Function(_$AnalyticsSnapshotImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AnalyticsSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? streakDays = null,
    Object? lessonsCompleted = null,
    Object? examsTaken = null,
    Object? weeklyActivity = null,
  }) {
    return _then(
      _$AnalyticsSnapshotImpl(
        streakDays: null == streakDays
            ? _value.streakDays
            : streakDays // ignore: cast_nullable_to_non_nullable
                  as int,
        lessonsCompleted: null == lessonsCompleted
            ? _value.lessonsCompleted
            : lessonsCompleted // ignore: cast_nullable_to_non_nullable
                  as int,
        examsTaken: null == examsTaken
            ? _value.examsTaken
            : examsTaken // ignore: cast_nullable_to_non_nullable
                  as int,
        weeklyActivity: null == weeklyActivity
            ? _value._weeklyActivity
            : weeklyActivity // ignore: cast_nullable_to_non_nullable
                  as List<int>,
      ),
    );
  }
}

/// @nodoc

class _$AnalyticsSnapshotImpl implements _AnalyticsSnapshot {
  const _$AnalyticsSnapshotImpl({
    this.streakDays = 0,
    this.lessonsCompleted = 0,
    this.examsTaken = 0,
    final List<int> weeklyActivity = const [],
  }) : _weeklyActivity = weeklyActivity;

  @override
  @JsonKey()
  final int streakDays;
  @override
  @JsonKey()
  final int lessonsCompleted;
  @override
  @JsonKey()
  final int examsTaken;
  final List<int> _weeklyActivity;
  @override
  @JsonKey()
  List<int> get weeklyActivity {
    if (_weeklyActivity is EqualUnmodifiableListView) return _weeklyActivity;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_weeklyActivity);
  }

  @override
  String toString() {
    return 'AnalyticsSnapshot(streakDays: $streakDays, lessonsCompleted: $lessonsCompleted, examsTaken: $examsTaken, weeklyActivity: $weeklyActivity)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AnalyticsSnapshotImpl &&
            (identical(other.streakDays, streakDays) ||
                other.streakDays == streakDays) &&
            (identical(other.lessonsCompleted, lessonsCompleted) ||
                other.lessonsCompleted == lessonsCompleted) &&
            (identical(other.examsTaken, examsTaken) ||
                other.examsTaken == examsTaken) &&
            const DeepCollectionEquality().equals(
              other._weeklyActivity,
              _weeklyActivity,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    streakDays,
    lessonsCompleted,
    examsTaken,
    const DeepCollectionEquality().hash(_weeklyActivity),
  );

  /// Create a copy of AnalyticsSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AnalyticsSnapshotImplCopyWith<_$AnalyticsSnapshotImpl> get copyWith =>
      __$$AnalyticsSnapshotImplCopyWithImpl<_$AnalyticsSnapshotImpl>(
        this,
        _$identity,
      );
}

abstract class _AnalyticsSnapshot implements AnalyticsSnapshot {
  const factory _AnalyticsSnapshot({
    final int streakDays,
    final int lessonsCompleted,
    final int examsTaken,
    final List<int> weeklyActivity,
  }) = _$AnalyticsSnapshotImpl;

  @override
  int get streakDays;
  @override
  int get lessonsCompleted;
  @override
  int get examsTaken;
  @override
  List<int> get weeklyActivity;

  /// Create a copy of AnalyticsSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AnalyticsSnapshotImplCopyWith<_$AnalyticsSnapshotImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$TodayViewState {
  String get userName => throw _privateConstructorUsedError;
  AnalyticsSnapshot get analytics => throw _privateConstructorUsedError;
  List<Subject> get unlockedSubjects => throw _privateConstructorUsedError;
  List<Subject> get allSubjects => throw _privateConstructorUsedError;
  List<Exam> get dueTodayExams => throw _privateConstructorUsedError;
  ResumableLesson? get resumableLesson => throw _privateConstructorUsedError;

  /// Create a copy of TodayViewState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $TodayViewStateCopyWith<TodayViewState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TodayViewStateCopyWith<$Res> {
  factory $TodayViewStateCopyWith(
    TodayViewState value,
    $Res Function(TodayViewState) then,
  ) = _$TodayViewStateCopyWithImpl<$Res, TodayViewState>;
  @useResult
  $Res call({
    String userName,
    AnalyticsSnapshot analytics,
    List<Subject> unlockedSubjects,
    List<Subject> allSubjects,
    List<Exam> dueTodayExams,
    ResumableLesson? resumableLesson,
  });

  $AnalyticsSnapshotCopyWith<$Res> get analytics;
}

/// @nodoc
class _$TodayViewStateCopyWithImpl<$Res, $Val extends TodayViewState>
    implements $TodayViewStateCopyWith<$Res> {
  _$TodayViewStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of TodayViewState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userName = null,
    Object? analytics = null,
    Object? unlockedSubjects = null,
    Object? allSubjects = null,
    Object? dueTodayExams = null,
    Object? resumableLesson = freezed,
  }) {
    return _then(
      _value.copyWith(
            userName: null == userName
                ? _value.userName
                : userName // ignore: cast_nullable_to_non_nullable
                      as String,
            analytics: null == analytics
                ? _value.analytics
                : analytics // ignore: cast_nullable_to_non_nullable
                      as AnalyticsSnapshot,
            unlockedSubjects: null == unlockedSubjects
                ? _value.unlockedSubjects
                : unlockedSubjects // ignore: cast_nullable_to_non_nullable
                      as List<Subject>,
            allSubjects: null == allSubjects
                ? _value.allSubjects
                : allSubjects // ignore: cast_nullable_to_non_nullable
                      as List<Subject>,
            dueTodayExams: null == dueTodayExams
                ? _value.dueTodayExams
                : dueTodayExams // ignore: cast_nullable_to_non_nullable
                      as List<Exam>,
            resumableLesson: freezed == resumableLesson
                ? _value.resumableLesson
                : resumableLesson // ignore: cast_nullable_to_non_nullable
                      as ResumableLesson?,
          )
          as $Val,
    );
  }

  /// Create a copy of TodayViewState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AnalyticsSnapshotCopyWith<$Res> get analytics {
    return $AnalyticsSnapshotCopyWith<$Res>(_value.analytics, (value) {
      return _then(_value.copyWith(analytics: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$TodayViewStateImplCopyWith<$Res>
    implements $TodayViewStateCopyWith<$Res> {
  factory _$$TodayViewStateImplCopyWith(
    _$TodayViewStateImpl value,
    $Res Function(_$TodayViewStateImpl) then,
  ) = __$$TodayViewStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String userName,
    AnalyticsSnapshot analytics,
    List<Subject> unlockedSubjects,
    List<Subject> allSubjects,
    List<Exam> dueTodayExams,
    ResumableLesson? resumableLesson,
  });

  @override
  $AnalyticsSnapshotCopyWith<$Res> get analytics;
}

/// @nodoc
class __$$TodayViewStateImplCopyWithImpl<$Res>
    extends _$TodayViewStateCopyWithImpl<$Res, _$TodayViewStateImpl>
    implements _$$TodayViewStateImplCopyWith<$Res> {
  __$$TodayViewStateImplCopyWithImpl(
    _$TodayViewStateImpl _value,
    $Res Function(_$TodayViewStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of TodayViewState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userName = null,
    Object? analytics = null,
    Object? unlockedSubjects = null,
    Object? allSubjects = null,
    Object? dueTodayExams = null,
    Object? resumableLesson = freezed,
  }) {
    return _then(
      _$TodayViewStateImpl(
        userName: null == userName
            ? _value.userName
            : userName // ignore: cast_nullable_to_non_nullable
                  as String,
        analytics: null == analytics
            ? _value.analytics
            : analytics // ignore: cast_nullable_to_non_nullable
                  as AnalyticsSnapshot,
        unlockedSubjects: null == unlockedSubjects
            ? _value._unlockedSubjects
            : unlockedSubjects // ignore: cast_nullable_to_non_nullable
                  as List<Subject>,
        allSubjects: null == allSubjects
            ? _value._allSubjects
            : allSubjects // ignore: cast_nullable_to_non_nullable
                  as List<Subject>,
        dueTodayExams: null == dueTodayExams
            ? _value._dueTodayExams
            : dueTodayExams // ignore: cast_nullable_to_non_nullable
                  as List<Exam>,
        resumableLesson: freezed == resumableLesson
            ? _value.resumableLesson
            : resumableLesson // ignore: cast_nullable_to_non_nullable
                  as ResumableLesson?,
      ),
    );
  }
}

/// @nodoc

class _$TodayViewStateImpl implements _TodayViewState {
  const _$TodayViewStateImpl({
    required this.userName,
    required this.analytics,
    required final List<Subject> unlockedSubjects,
    required final List<Subject> allSubjects,
    required final List<Exam> dueTodayExams,
    this.resumableLesson,
  }) : _unlockedSubjects = unlockedSubjects,
       _allSubjects = allSubjects,
       _dueTodayExams = dueTodayExams;

  @override
  final String userName;
  @override
  final AnalyticsSnapshot analytics;
  final List<Subject> _unlockedSubjects;
  @override
  List<Subject> get unlockedSubjects {
    if (_unlockedSubjects is EqualUnmodifiableListView)
      return _unlockedSubjects;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_unlockedSubjects);
  }

  final List<Subject> _allSubjects;
  @override
  List<Subject> get allSubjects {
    if (_allSubjects is EqualUnmodifiableListView) return _allSubjects;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_allSubjects);
  }

  final List<Exam> _dueTodayExams;
  @override
  List<Exam> get dueTodayExams {
    if (_dueTodayExams is EqualUnmodifiableListView) return _dueTodayExams;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_dueTodayExams);
  }

  @override
  final ResumableLesson? resumableLesson;

  @override
  String toString() {
    return 'TodayViewState(userName: $userName, analytics: $analytics, unlockedSubjects: $unlockedSubjects, allSubjects: $allSubjects, dueTodayExams: $dueTodayExams, resumableLesson: $resumableLesson)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TodayViewStateImpl &&
            (identical(other.userName, userName) ||
                other.userName == userName) &&
            (identical(other.analytics, analytics) ||
                other.analytics == analytics) &&
            const DeepCollectionEquality().equals(
              other._unlockedSubjects,
              _unlockedSubjects,
            ) &&
            const DeepCollectionEquality().equals(
              other._allSubjects,
              _allSubjects,
            ) &&
            const DeepCollectionEquality().equals(
              other._dueTodayExams,
              _dueTodayExams,
            ) &&
            (identical(other.resumableLesson, resumableLesson) ||
                other.resumableLesson == resumableLesson));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    userName,
    analytics,
    const DeepCollectionEquality().hash(_unlockedSubjects),
    const DeepCollectionEquality().hash(_allSubjects),
    const DeepCollectionEquality().hash(_dueTodayExams),
    resumableLesson,
  );

  /// Create a copy of TodayViewState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$TodayViewStateImplCopyWith<_$TodayViewStateImpl> get copyWith =>
      __$$TodayViewStateImplCopyWithImpl<_$TodayViewStateImpl>(
        this,
        _$identity,
      );
}

abstract class _TodayViewState implements TodayViewState {
  const factory _TodayViewState({
    required final String userName,
    required final AnalyticsSnapshot analytics,
    required final List<Subject> unlockedSubjects,
    required final List<Subject> allSubjects,
    required final List<Exam> dueTodayExams,
    final ResumableLesson? resumableLesson,
  }) = _$TodayViewStateImpl;

  @override
  String get userName;
  @override
  AnalyticsSnapshot get analytics;
  @override
  List<Subject> get unlockedSubjects;
  @override
  List<Subject> get allSubjects;
  @override
  List<Exam> get dueTodayExams;
  @override
  ResumableLesson? get resumableLesson;

  /// Create a copy of TodayViewState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$TodayViewStateImplCopyWith<_$TodayViewStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
