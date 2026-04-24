import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:na_app/core/theme/app_colors.dart';
import 'package:animate_do/animate_do.dart';

class ExamsScreen extends StatelessWidget {
  const ExamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final available = [
      {'title': 'Midterm · Organic Chem', 'subj': 'Organic Chemistry', 'q': 20, 'min': 45, 'hue': 'secondary', 'free': false},
      {'title': 'Weekly quiz · Week 12', 'subj': 'Calculus II', 'q': 10, 'min': 15, 'hue': 'accent', 'free': true},
      {'title': 'Grammar check-in', 'subj': 'Arabic Literature', 'q': 12, 'min': 20, 'hue': 'accent', 'free': true},
    ];

    final done = [
      {'title': 'Chapter 3 quiz', 'subj': 'Calculus II', 'score': 88, 'when': '2 days ago'},
      {'title': 'Mechanics placement', 'subj': 'Physics', 'score': 72, 'when': 'last week'},
    ];

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FadeInDown(
                duration: const Duration(milliseconds: 600),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Exams',
                        style: Theme.of(context).textTheme.displayLarge,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Three available. One due today.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              FadeInUp(
                delay: const Duration(milliseconds: 200),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'Available',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Column(
                children: List.generate(available.length, (index) {
                  final e = available[index];
                  final isSecondary = e['hue'] == 'secondary';
                  final hue = isSecondary ? AppColors.secondary : AppColors.accent;
                  final soft = isSecondary ? AppColors.secondarySoft : AppColors.accentSoft;

                  return FadeInUp(
                    delay: Duration(milliseconds: 300 + (index * 100)),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.bgSurface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.borderSubtle),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                (e['subj'] as String).toUpperCase(),
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: hue),
                              ),
                              if (e['free'] as bool)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: soft,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'Free attempt',
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: hue,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            e['title'] as String,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              const Icon(LucideIcons.clock, size: 13, color: AppColors.textMuted),
                              const SizedBox(width: 5),
                              Text(
                                '${e['min']} min',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(width: 14),
                              const Icon(LucideIcons.clipboardList, size: 13, color: AppColors.textMuted),
                              const SizedBox(width: 5),
                              Text(
                                '${e['q']} questions',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const Spacer(),
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: hue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  minimumSize: Size.zero,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                ),
                                child: const Text('Start'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              FadeInUp(
                delay: const Duration(milliseconds: 600),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'Completed',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FadeInUp(
                delay: const Duration(milliseconds: 700),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: Column(
                    children: List.generate(done.length, (index) {
                      final d = done[index];
                      final score = d['score'] as int;
                      final isSuccess = score >= 80;

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          border: index < done.length - 1
                              ? const Border(bottom: BorderSide(color: AppColors.borderSubtle))
                              : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: const BoxDecoration(
                                color: AppColors.bgSunken,
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '$score',
                                style: TextStyle(
                                  color: isSuccess ? AppColors.success : AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    d['title'] as String,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 15),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${d['subj']} · ${d['when']}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.textMuted),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
