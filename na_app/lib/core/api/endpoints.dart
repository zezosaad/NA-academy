class Endpoints {
  static const auth = _AuthEndpoints();
  static const users = _UserEndpoints();
  static const subjects = _SubjectEndpoints();
  static const lessons = _LessonEndpoints();
  static const activationCodes = _ActivationCodeEndpoints();
  static const exams = _ExamEndpoints();
  static const chat = _ChatEndpoints();
  static const media = _MediaEndpoints();
  static const analytics = _AnalyticsEndpoints();
}

class _AuthEndpoints {
  const _AuthEndpoints();

  static const String _prefix = '/auth';

  String get login => '$_prefix/login';
  String get register => '$_prefix/register';
  String get refresh => '$_prefix/refresh';
  String get logout => '$_prefix/logout';
  String get forgotPassword => '$_prefix/forgot-password';
  String get resetPassword => '$_prefix/reset-password';
}

class _UserEndpoints {
  const _UserEndpoints();

  static const String _prefix = '/users';

  String get me => '$_prefix/me';
  String profile(String id) => '$_prefix/$id';
}

class _SubjectEndpoints {
  const _SubjectEndpoints();

  static const String _prefix = '/subjects';

  String get list => _prefix;
  String byId(String id) => '$_prefix/$id';
  String media(String id) => '$_prefix/$id/media';
  String lessons(String id) => '$_prefix/$id/lessons';
}

class _LessonEndpoints {
  const _LessonEndpoints();

  static const String _prefix = '/lessons';

  String byId(String id) => '$_prefix/$id';
}

class _ActivationCodeEndpoints {
  const _ActivationCodeEndpoints();

  static const String _prefix = '/activation-codes';

  String get activate => '$_prefix/activate';
  String get generateSubjectCodes => '$_prefix/subject/generate';
  String get generateExamCodes => '$_prefix/exam/generate';
  String batch(String batchId) => '$_prefix/batch/$batchId';
}

class _ExamEndpoints {
  const _ExamEndpoints();

  static const String _prefix = '/exams';

  String get list => _prefix;
  String byId(String id) => '$_prefix/$id';
  String start(String id) => '$_prefix/$id/start';
  String get submit => '$_prefix/submit';
  String saveAnswer(String sessionId) => '$_prefix/sessions/$sessionId/answer';
}

class _ChatEndpoints {
  const _ChatEndpoints();

  static const String _prefix = '/chat';

  String get conversations => '$_prefix/conversations';
  String get pending => '$_prefix/pending';
}

class _MediaEndpoints {
  const _MediaEndpoints();

  static const String _prefix = '/media';

  String get chatUpload => '$_prefix/chat/upload';
  String stream(String id) => '$_prefix/$id/stream';
}

class _AnalyticsEndpoints {
  const _AnalyticsEndpoints();

  static const String _prefix = '/analytics';

  String get studentMe => '$_prefix/student/me';
  String get watchTime => '$_prefix/watch-time';
}
