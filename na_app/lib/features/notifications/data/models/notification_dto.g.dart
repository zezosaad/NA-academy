// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$InboxItemDtoImpl _$$InboxItemDtoImplFromJson(Map<String, dynamic> json) =>
    _$InboxItemDtoImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      data: (json['data'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ),
      createdAt: json['createdAt'] as String,
      readAt: json['readAt'] as String?,
      senderName: json['senderName'] as String?,
    );

Map<String, dynamic> _$$InboxItemDtoImplToJson(_$InboxItemDtoImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'body': instance.body,
      'data': instance.data,
      'createdAt': instance.createdAt,
      'readAt': instance.readAt,
      'senderName': instance.senderName,
    };
