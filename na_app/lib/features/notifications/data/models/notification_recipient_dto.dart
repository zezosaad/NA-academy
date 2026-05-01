import 'package:freezed_annotation/freezed_annotation.dart';

part 'notification_recipient_dto.freezed.dart';
part 'notification_recipient_dto.g.dart';

@freezed
class RecipientStateDto with _$RecipientStateDto {
  const factory RecipientStateDto({
    required String userId,
    required String userName,
    required String state,
    String? failureReason,
    String? deliveredAt,
    String? readAt,
  }) = _RecipientStateDto;

  factory RecipientStateDto.fromJson(Map<String, dynamic> json) =>
      _$RecipientStateDtoFromJson(json);
}
