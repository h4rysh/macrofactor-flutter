import 'package:flutter/material.dart';
import 'package:sique/presentation/screens/onboarding/widgets/onboarding_step_scaffold.dart';
import 'package:sique/presentation/theme/app_theme.dart';

/// Step 2: Athlete Name
class Step02Name extends StatefulWidget {
  const Step02Name({
    super.key,
    required this.initialName,
    required this.onNext,
  });

  final String initialName;
  final ValueChanged<String> onNext;

  @override
  State<Step02Name> createState() => _Step02NameState();
}

class _Step02NameState extends State<Step02Name> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OnboardingStepScaffold(
      title: 'What should we call you?',
      subtitle: 'Your name personalizes your metabolic coaching dashboard.',
      icon: Icons.person_outline_rounded,
      continueKey: const Key('step_02_continue_btn'),
      isContinueEnabled: _controller.text.trim().isNotEmpty,
      onContinue: () => widget.onNext(_controller.text.trim()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          TextFormField(
            key: const Key('step_02_name_input'),
            controller: _controller,
            autofocus: true,
            style: const TextStyle(
              fontFamily: 'MacroSans',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Enter your name',
              hintStyle: TextStyle(
                color: AppTheme.textSecondary.withValues(alpha: 0.5),
              ),
              filled: true,
              fillColor: AppTheme.cardSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTheme.cardBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTheme.cardBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide:
                    const BorderSide(color: AppTheme.activeBlue, width: 2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
