import 'package:flutter/material.dart';
import 'package:sique/domain/models/macro_program.dart';
import 'package:sique/presentation/screens/onboarding/steps/step_24_program_ready.dart';

/// Card 7: 'Save Your Strategy' (Optional Google/Email Auth + Health Connect sync moved here from start).
class Card07SaveStrategy extends StatelessWidget {
  const Card07SaveStrategy({
    super.key,
    required this.program,
    required this.onFinish,
  });

  final WeeklyMacroProgram program;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    return Step24ProgramReady(
      program: program,
      onCompleted: onFinish,
    );
  }
}
