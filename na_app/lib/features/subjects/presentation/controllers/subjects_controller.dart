import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:na_app/features/subjects/data/subjects_repository.dart';
import 'package:na_app/features/subjects/domain/activation_result.dart';
import 'package:na_app/features/subjects/domain/subject_models.dart';

final subjectsListProvider =
    AsyncNotifierProvider<SubjectsListNotifier, List<Subject>>(
  SubjectsListNotifier.new,
);

class SubjectsListNotifier extends AsyncNotifier<List<Subject>> {
  @override
  Future<List<Subject>> build() async {
    final repo = ref.watch(subjectsRepositoryProvider);
    return repo.listSubjects();
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
  }
}

final subjectDetailProvider =
    FutureProvider.family<({Subject subject, List<Lesson> lessons}), String>(
  (ref, id) async {
    final repo = ref.watch(subjectsRepositoryProvider);
    return repo.getSubject(id);
  },
);

final lessonDetailProvider = FutureProvider.family<Lesson, String>(
  (ref, lessonId) async {
    final repo = ref.watch(subjectsRepositoryProvider);
    return repo.getLesson(lessonId);
  },
);

final activateCodeProvider = Provider<Future<ActivationResult> Function(String code)>(
  (ref) {
    return (String code) async {
      final repo = ref.read(subjectsRepositoryProvider);
      final result = await repo.activateCode(code);
      if (result is ActivationSuccess) {
        ref.invalidate(subjectsListProvider);
      }
      return result;
    };
  },
);
