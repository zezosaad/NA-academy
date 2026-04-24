class Subject {
  final String id;
  final String title;
  final String? description;
  final String? coverImageUrl;
  final int lessonCount;
  final bool isUnlocked;
  final double progressPercent;

  const Subject({
    required this.id,
    required this.title,
    this.description,
    this.coverImageUrl,
    this.lessonCount = 0,
    this.isUnlocked = false,
    this.progressPercent = 0.0,
  });

  factory Subject.fromJson(Map<String, dynamic> json) {
    final id = json['_id'] as String? ?? json['id'] as String?;
    if (id == null || id.isEmpty) {
      throw FormatException('Subject.fromJson: missing "id" in $json');
    }
    return Subject(
      id: id,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      coverImageUrl: json['coverImage'] as String? ?? json['coverImageUrl'] as String?,
      lessonCount: json['lessonCount'] as int? ?? 0,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      progressPercent: (json['progressPercent'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Subject copyWith({
    String? id,
    String? title,
    String? description,
    String? coverImageUrl,
    int? lessonCount,
    bool? isUnlocked,
    double? progressPercent,
  }) {
    return Subject(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      lessonCount: lessonCount ?? this.lessonCount,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      progressPercent: progressPercent ?? this.progressPercent,
    );
  }
}

enum LessonStatus { done, active, locked }

class Lesson {
  final String id;
  final String subjectId;
  final String title;
  final int order;
  final LessonStatus status;
  final String? mediaAssetId;
  final int? estimatedMinutes;

  const Lesson({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.order,
    this.status = LessonStatus.locked,
    this.mediaAssetId,
    this.estimatedMinutes,
  });

  factory Lesson.fromJson(Map<String, dynamic> json, {required String subjectId}) {
    final id = json['_id'] as String? ?? json['id'] as String?;
    if (id == null || id.isEmpty) {
      throw FormatException('Lesson.fromJson: missing "id" in $json');
    }
    return Lesson(
      id: id,
      subjectId: subjectId,
      title: json['title'] as String? ?? '',
      order: json['order'] as int? ?? json['index'] as int? ?? 0,
      status: _parseStatus(json['status'] as String?),
      mediaAssetId: json['mediaAssetId'] as String?,
      estimatedMinutes: json['estimatedMinutes'] as int?,
    );
  }

  static LessonStatus _parseStatus(String? value) {
    switch (value) {
      case 'done':
        return LessonStatus.done;
      case 'active':
        return LessonStatus.active;
      default:
        return LessonStatus.locked;
    }
  }

  Lesson copyWith({
    String? id,
    String? subjectId,
    String? title,
    int? order,
    LessonStatus? status,
    String? mediaAssetId,
    int? estimatedMinutes,
  }) {
    return Lesson(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      order: order ?? this.order,
      status: status ?? this.status,
      mediaAssetId: mediaAssetId ?? this.mediaAssetId,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
    );
  }
}
