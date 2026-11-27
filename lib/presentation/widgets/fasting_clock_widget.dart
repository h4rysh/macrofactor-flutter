import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/algorithms/fasting_service.dart';
import '../../domain/models/lifestyle_models.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';
import 'animated_primitives.dart';
import 'apple_tactile_card.dart';

/// Card for intermittent fasting tracking and biological stage indicators.
class FastingClockCard extends ConsumerStatefulWidget {
  const FastingClockCard({super.key});

  @override
  ConsumerState<FastingClockCard> createState() => _FastingClockCardState();
}

class _FastingClockCardState extends ConsumerState<FastingClockCard> {
  FastingProtocol _selectedProtocol = FastingProtocol.f16_8;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    if (ref.read(fastingSessionProvider) != null) {
      _startTicker();
    }
  }

  void _startTicker() {
    _ticker ??= Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<FastingSession?>(fastingSessionProvider, (prev, next) {
      if (next != null) {
        _startTicker();
      } else {
        _ticker?.cancel();
        _ticker = null;
      }
    });
    final activeFast = ref.watch(fastingSessionProvider);

    return AppleTactileCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 20,
      backgroundColor: AppTheme.cardSurface,
      borderColor: activeFast != null
          ? const Color(0xFFAB47BC).withValues(alpha: 0.5)
          : AppTheme.cardBorder,
      child: activeFast != null
          ? _buildActiveFastView(activeFast)
          : _buildIdleFastView(),
    );
  }

  Widget _buildActiveFastView(FastingSession fast) {
    final now = ref.read(clockProvider)();
    final elapsed = now.difference(fast.startTime);
    final stage = FastingService.getStage(elapsed);
    final targetEnd = fast.targetEndTime;
    final isTargetMet = now.isAfter(targetEnd);

    final hours = elapsed.inHours;
    final mins = elapsed.inMinutes % 60;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFAB47BC).withValues(alpha: 0.16),
                borderRadius: AppRadii.mdBorderRadius,
              ),
              child: const Icon(
                Icons.timer_outlined,
                size: 20,
                color: Color(0xFFAB47BC),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FASTING • ${fast.protocol.displayName.toUpperCase()}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFAB47BC),
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${hours}h ${mins}m elapsed',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimary,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            if (isTargetMet)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF66BB6A).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_rounded,
                        size: 13, color: Color(0xFF66BB6A)),
                    SizedBox(width: 4),
                    Text(
                      'GOAL MET',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF66BB6A),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),

        // Biological Stage Banner
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.cardElevated,
            borderRadius: AppRadii.mdBorderRadius,
            border: Border.all(
              color: const Color(0xFFAB47BC).withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.bolt_rounded,
                    size: 15,
                    color: Color(0xFFAB47BC),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    stage.title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFAB47BC),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                stage.description,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // End Fast Button
        AppleBouncy(
          scaleDown: 0.96,
          onTap: () async {
            AppHaptics.selectionClick();
            final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                backgroundColor: AppTheme.cardSurface,
                title: const Text('End current fast?'),
                content: const Text(
                  'This will log your fasting session and end the active timer.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: const Text('Keep Fasting'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    child: const Text('End Fast'),
                  ),
                ],
              ),
            );
            if (confirmed == true && context.mounted) {
              ref
                  .read(fastingSessionProvider.notifier)
                  .endFast(completed: isTargetMet);
            }
          },
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.cardElevated,
              borderRadius: AppRadii.mdBorderRadius,
              border: Border.all(color: AppTheme.cardBorder, width: 1),
            ),
            alignment: Alignment.center,
            child: const FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'End Fast & Break Window',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIdleFastView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFAB47BC).withValues(alpha: 0.15),
                borderRadius: AppRadii.mdBorderRadius,
              ),
              child: const Icon(
                Icons.timelapse_rounded,
                size: 20,
                color: Color(0xFFAB47BC),
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'INTERMITTENT FASTING',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFAB47BC),
                      letterSpacing: 0.8,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Circadian & Autophagy Clock',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // Protocol Selector Chips
        Row(
          children: [
            _buildProtocolChip(FastingProtocol.f16_8, '16:8'),
            const SizedBox(width: 8),
            _buildProtocolChip(FastingProtocol.f18_6, '18:6'),
            const SizedBox(width: 8),
            _buildProtocolChip(FastingProtocol.f20_4, '20:4'),
          ],
        ),
        const SizedBox(height: 14),

        // Start Fast Action
        AppleBouncy(
          scaleDown: 0.96,
          onTap: () {
            AppHaptics.lightImpact();
            ref
                .read(fastingSessionProvider.notifier)
                .startFast(_selectedProtocol);
          },
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFAB47BC),
              borderRadius: AppRadii.mdBorderRadius,
            ),
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_arrow_rounded,
                      size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    'Start ${_selectedProtocol.displayName}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProtocolChip(FastingProtocol protocol, String label) {
    final isSelected = _selectedProtocol == protocol;
    return Expanded(
      child: AppleBouncy(
        scaleDown: 0.94,
        onTap: () {
          AppHaptics.selectionClick();
          setState(() {
            _selectedProtocol = protocol;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFFAB47BC).withValues(alpha: 0.18)
                : AppTheme.cardElevated,
            borderRadius: AppRadii.mdBorderRadius,
            border: Border.all(
              color: isSelected ? const Color(0xFFAB47BC) : Colors.transparent,
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color:
                  isSelected ? const Color(0xFFAB47BC) : AppTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
