import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:na_app/features/exams/data/exams_repository.dart';
import 'package:na_app/features/exams/domain/exam_models.dart';

final examSessionProvider =
    NotifierProvider<ExamSessionNotifier, AsyncValue<ExamSession?>>(
  ExamSessionNotifier.new,
);

class ExamSessionNotifier extends Notifier<AsyncValue<ExamSession?>> {
  @override
  AsyncValue<ExamSession?> build() => const AsyncData(null);

  Future<void> startSession(String examId, {bool isFree = false}) async {
    state = const AsyncLoading();
    try {
      final repo = ref.read(examsRepositoryProvider);
      final result = await repo.getExamAndStart(examId, isFree: isFree);
      state = AsyncData(result.session);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> saveAnswer(String questionId, String value) async {
    final session = state.value;
    if (session == null) return;
    try {
      final repo = ref.read(examsRepositoryProvider);
      await repo.saveAnswer(session.id, questionId, value);
      final updated = session.copyWith(
        answers: {
          ...session.answers,
          questionId: AnswerValue(selectedOption: value),
        },
      );
      state = AsyncData(updated);
    } catch (_) {}
  }

  Future<ExamScore> submitExam() async {
    final session = state.value!;
    final repo = ref.read(examsRepositoryProvider);
    final answers = session.answers.entries
        .map((e) => {'questionId': e.key, 'selectedOption': e.value.selectedOption})
        .toList();
    final score = await repo.submitSession(session.id, answers);
    state = AsyncData(session.copyWith(status: SessionStatus.submitted));
    return score;
  }

  void markTimedOut() {
    final session = state.value;
    if (session == null) return;
    state = AsyncData(session.copyWith(status: SessionStatus.timedOut));
  }

  void clearSession() {
    state = const AsyncData(null);
  }
}