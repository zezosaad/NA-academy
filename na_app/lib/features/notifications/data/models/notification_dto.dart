import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_dto.freezed.dart';
part 'notification_dto.g.dart';

@freezed
class InboxItemDto with _$InboxItemDto {
  const factory InboxItemDto({
    required String id,
    required String title,
    required String body,
    Map<String, String>? data,
    required String createdAt,
    String? readAt,
    String? senderName,
  }) = _InboxItemDto;

  factory InboxItemDto.fromJson(Map<String, dynamic> json) =>
      _$InboxItemDtoFromJson(json);
}
