// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_recipient_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RecipientStateDtoImpl _$$RecipientStateDtoImplFromJson(
  Map<String, dynamic> json,
) => _$RecipientStateDtoImpl(
  userId: json['userId'] as String,
  userName: json['userName'] as String,
  state: json['state'] as String,
  failureReason: json['failureReason'] as String?,
  deliveredAt: json['deliveredAt'] as String?,
  readAt: json['readAt'] as String?,
);

Map<String, dynamic> _$$RecipientStateDtoImplToJson(
  _$RecipientStateDtoImpl instance,
) => <String, dynamic>{
  'userId': instance.userId,
  'userName': instance.userName,
  'state': instance.state,
  'failureReason': instance.failureReason,
  'deliveredAt': instance.deliveredAt,
  'readAt': instance.readAt,
};
