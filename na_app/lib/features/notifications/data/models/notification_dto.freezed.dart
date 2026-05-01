// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notification_dto.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

InboxItemDto _$InboxItemDtoFromJson(Map<String, dynamic> json) {
  return _InboxItemDto.fromJson(json);
}

/// @nodoc
mixin _$InboxItemDto {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String get body => throw _privateConstructorUsedError;
  String? get data => throw _privateConstructorUsedError;
  String get createdAt => throw _privateConstructorUsedError;
  String? get readAt => throw _privateConstructorUsedError;
  String? get senderName => throw _privateConstructorUsedError;

  /// Serializes this InboxItemDto to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of InboxItemDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $InboxItemDtoCopyWith<InboxItemDto> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InboxItemDtoCopyWith<$Res> {
  factory $InboxItemDtoCopyWith(
    InboxItemDto value,
    $Res Function(InboxItemDto) then,
  ) = _$InboxItemDtoCopyWithImpl<$Res, InboxItemDto>;
  @useResult
  $Res call({
    String id,
    String title,
    String body,
    String? data,
    String createdAt,
    String? readAt,
    String? senderName,
  });
}

/// @nodoc
class _$InboxItemDtoCopyWithImpl<$Res, $Val extends InboxItemDto>
    implements $InboxItemDtoCopyWith<$Res> {
  _$InboxItemDtoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of InboxItemDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? body = null,
    Object? data = freezed,
    Object? createdAt = null,
    Object? readAt = freezed,
    Object? senderName = freezed,
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
            body: null == body
                ? _value.body
                : body // ignore: cast_nullable_to_non_nullable
                      as String,
            data: freezed == data
                ? _value.data
                : data // ignore: cast_nullable_to_non_nullable
                      as String?,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as String,
            readAt: freezed == readAt
                ? _value.readAt
                : readAt // ignore: cast_nullable_to_non_nullable
                      as String?,
            senderName: freezed == senderName
                ? _value.senderName
                : senderName // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$InboxItemDtoImplCopyWith<$Res>
    implements $InboxItemDtoCopyWith<$Res> {
  factory _$$InboxItemDtoImplCopyWith(
    _$InboxItemDtoImpl value,
    $Res Function(_$InboxItemDtoImpl) then,
  ) = __$$InboxItemDtoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String title,
    String body,
    String? data,
    String createdAt,
    String? readAt,
    String? senderName,
  });
}

/// @nodoc
class __$$InboxItemDtoImplCopyWithImpl<$Res>
    extends _$InboxItemDtoCopyWithImpl<$Res, _$InboxItemDtoImpl>
    implements _$$InboxItemDtoImplCopyWith<$Res> {
  __$$InboxItemDtoImplCopyWithImpl(
    _$InboxItemDtoImpl _value,
    $Res Function(_$InboxItemDtoImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of InboxItemDto
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? body = null,
    Object? data = freezed,
    Object? createdAt = null,
    Object? readAt = freezed,
    Object? senderName = freezed,
  }) {
    return _then(
      _$InboxItemDtoImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        body: null == body
            ? _value.body
            : body // ignore: cast_nullable_to_non_nullable
                  as String,
        data: freezed == data
            ? _value.data
            : data // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as String,
        readAt: freezed == readAt
            ? _value.readAt
            : readAt // ignore: cast_nullable_to_non_nullable
                  as String?,
        senderName: freezed == senderName
            ? _value.senderName
            : senderName // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$InboxItemDtoImpl implements _InboxItemDto {
  const _$InboxItemDtoImpl({
    required this.id,
    required this.title,
    required this.body,
    this.data,
    required this.createdAt,
    this.readAt,
    this.senderName,
  });

  factory _$InboxItemDtoImpl.fromJson(Map<String, dynamic> json) =>
      _$$InboxItemDtoImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  final String body;
  @override
  final String? data;
  @override
  final String createdAt;
  @override
  final String? readAt;
  @override
  final String? senderName;

  @override
  String toString() {
    return 'InboxItemDto(id: $id, title: $title, body: $body, data: $data, createdAt: $createdAt, readAt: $readAt, senderName: $senderName)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InboxItemDtoImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.body, body) || other.body == body) &&
            (identical(other.data, data) || other.data == data) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.readAt, readAt) || other.readAt == readAt) &&
            (identical(other.senderName, senderName) ||
                other.senderName == senderName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    title,
    body,
    data,
    createdAt,
    readAt,
    senderName,
  );

  /// Create a copy of InboxItemDto
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InboxItemDtoImplCopyWith<_$InboxItemDtoImpl> get copyWith =>
      __$$InboxItemDtoImplCopyWithImpl<_$InboxItemDtoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$InboxItemDtoImplToJson(this);
  }
}

abstract class _InboxItemDto implements InboxItemDto {
  const factory _InboxItemDto({
    required final String id,
    required final String title,
    required final String body,
    final String? data,
    required final String createdAt,
    final String? readAt,
    final String? senderName,
  }) = _$InboxItemDtoImpl;

  factory _InboxItemDto.fromJson(Map<String, dynamic> json) =
      _$InboxItemDtoImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  String get body;
  @override
  String? get data;
  @override
  String get createdAt;
  @override
  String? get readAt;
  @override
  String? get senderName;

  /// Create a copy of InboxItemDto
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InboxItemDtoImplCopyWith<_$InboxItemDtoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
