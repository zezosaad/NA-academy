// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification_recipient_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

RecipientStateDto _$RecipientStateDtoFromJson(Map<String, dynamic> json) {
  return _RecipientStateDto.fromJson(json);
}

/// @nodoc
mixin _$RecipientStateDto {
  String get userId => throw _privateConstructorUsedError;
  String get userName => throw _privateConstructorUsedError;
  String get state => throw _privateConstructorUsedError;
  String? get failureReason => throw _privateConstructorUsedError;
  String? get deliveredAt => throw _privateConstructorUsedError;
  String? get readAt => throw _privateConstructorUsedError;

  /// Serializes this RecipientStateDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RecipientStateDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RecipientStateDtoCopyWith<RecipientStateDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecipientStateDtoCopyWith<$Res> {
  factory $RecipientStateDtoCopyWith(
    RecipientStateDto value,
    $Res Function(RecipientStateDto) then,
  ) = _$RecipientStateDtoCopyWithImpl<$Res, RecipientStateDto>;
  @useResult
  $Res call({
    String userId,
    String userName,
    String state,
    String? failureReason,
    String? deliveredAt,
    String? readAt,
  });
}

/// @nodoc
class _$RecipientStateDtoCopyWithImpl<$Res, $Val extends RecipientStateDto>
    implements $RecipientStateDtoCopyWith<$Res> {
  _$RecipientStateDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RecipientStateDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? userName = null,
    Object? state = null,
    Object? failureReason = freezed,
    Object? deliveredAt = freezed,
    Object? readAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            userId: null == userId
                ? _value.userId
                : userId // ignore: cast_nullable_to_non_nullable
                      as String,
            userName: null == userName
                ? _value.userName
                : userName // ignore: cast_nullable_to_non_nullable
                      as String,
            state: null == state
                ? _value.state
                : state // ignore: cast_nullable_to_non_nullable
                      as String,
            failureReason: freezed == failureReason
                ? _value.failureReason
                : failureReason // ignore: cast_nullable_to_non_nullable
                      as String?,
            deliveredAt: freezed == deliveredAt
                ? _value.deliveredAt
                : deliveredAt // ignore: cast_nullable_to_non_nullable
                      as String?,
            readAt: freezed == readAt
                ? _value.readAt
                : readAt // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$RecipientStateDtoImplCopyWith<$Res>
    implements $RecipientStateDtoCopyWith<$Res> {
  factory _$$RecipientStateDtoImplCopyWith(
    _$RecipientStateDtoImpl value,
    $Res Function(_$RecipientStateDtoImpl) then,
  ) = __$$RecipientStateDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String userId,
    String userName,
    String state,
    String? failureReason,
    String? deliveredAt,
    String? readAt,
  });
}

/// @nodoc
class __$$RecipientStateDtoImplCopyWithImpl<$Res>
    extends _$RecipientStateDtoCopyWithImpl<$Res, _$RecipientStateDtoImpl>
    implements _$$RecipientStateDtoImplCopyWith<$Res> {
  __$$RecipientStateDtoImplCopyWithImpl(
    _$RecipientStateDtoImpl _value,
    $Res Function(_$RecipientStateDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of RecipientStateDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? userId = null,
    Object? userName = null,
    Object? state = null,
    Object? failureReason = freezed,
    Object? deliveredAt = freezed,
    Object? readAt = freezed,
  }) {
    return _then(
      _$RecipientStateDtoImpl(
        userId: null == userId
            ? _value.userId
            : userId // ignore: cast_nullable_to_non_nullable
                  as String,
        userName: null == userName
            ? _value.userName
            : userName // ignore: cast_nullable_to_non_nullable
                  as String,
        state: null == state
            ? _value.state
            : state // ignore: cast_nullable_to_non_nullable
                  as String,
        failureReason: freezed == failureReason
            ? _value.failureReason
            : failureReason // ignore: cast_nullable_to_non_nullable
                  as String?,
        deliveredAt: freezed == deliveredAt
            ? _value.deliveredAt
            : deliveredAt // ignore: cast_nullable_to_non_nullable
                  as String?,
        readAt: freezed == readAt
            ? _value.readAt
            : readAt // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$RecipientStateDtoImpl implements _RecipientStateDto {
  const _$RecipientStateDtoImpl({
    required this.userId,
    required this.userName,
    required this.state,
    this.failureReason,
    this.deliveredAt,
    this.readAt,
  });

  factory _$RecipientStateDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$RecipientStateDtoImplFromJson(json);

  @override
  final String userId;
  @override
  final String userName;
  @override
  final String state;
  @override
  final String? failureReason;
  @override
  final String? deliveredAt;
  @override
  final String? readAt;

  @override
  String toString() {
    return 'RecipientStateDto(userId: $userId, userName: $userName, state: $state, failureReason: $failureReason, deliveredAt: $deliveredAt, readAt: $readAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecipientStateDtoImpl &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.userName, userName) ||
                other.userName == userName) &&
            (identical(other.state, state) || other.state == state) &&
            (identical(other.failureReason, failureReason) ||
                other.failureReason == failureReason) &&
            (identical(other.deliveredAt, deliveredAt) ||
                other.deliveredAt == deliveredAt) &&
            (identical(other.readAt, readAt) || other.readAt == readAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    userId,
    userName,
    state,
    failureReason,
    deliveredAt,
    readAt,
  );

  /// Create a copy of RecipientStateDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RecipientStateDtoImplCopyWith<_$RecipientStateDtoImpl> get copyWith =>
      __$$RecipientStateDtoImplCopyWithImpl<_$RecipientStateDtoImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$RecipientStateDtoImplToJson(this);
  }
}

abstract class _RecipientStateDto implements RecipientStateDto {
  const factory _RecipientStateDto({
    required final String userId,
    required final String userName,
    required final String state,
    final String? failureReason,
    final String? deliveredAt,
    final String? readAt,
  }) = _$RecipientStateDtoImpl;

  factory _RecipientStateDto.fromJson(Map<String, dynamic> json) =
      _$RecipientStateDtoImpl.fromJson;

  @override
  String get userId;
  @override
  String get userName;
  @override
  String get state;
  @override
  String? get failureReason;
  @override
  String? get deliveredAt;
  @override
  String? get readAt;

  /// Create a copy of RecipientStateDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RecipientStateDtoImplCopyWith<_$RecipientStateDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
