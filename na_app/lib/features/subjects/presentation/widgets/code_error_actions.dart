import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:na_app/core/widgets/button.dart';

class CodeErrorActions extends StatelessWidget {
  const CodeErrorActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppButton(
          label: 'Try another code',
          onPressed: () => context.go('/subjects/enter-code'),
        ),
        const SizedBox(height: 12),
        AppButton(
          label: 'Message teacher',
          onPressed: () => context.go('/chat'),
          type: AppButtonType.ghost,
        ),
      ],
    );
  }
}
