import 'package:flutter/material.dart';
import 'package:sique/domain/models/macro_program.dart';
import '../cards/card_07_save_strategy.dart';

/// Legacy step 24 compatibility wrapper delegating to [Card07SaveStrategy] (AUD-37, AUD-38).
class Step24ProgramReady extends StatelessWidget {
  const Step24ProgramReady({
    super.key,
    required this.program,
    this.onCompleted,
    this.child,
  });

  final WeeklyMacroProgram program;
  final VoidCallback? onCompleted;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    if (child != null) return child!;
    return Card07SaveStrategy(
      program: program,
      onFinish: onCompleted ?? () {},
    );
  }
}
