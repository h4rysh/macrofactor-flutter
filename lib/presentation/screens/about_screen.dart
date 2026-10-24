import 'package:flutter/material.dart';
import 'package:sique/presentation/theme/app_theme.dart';

/// Screen displaying app provenance, clean-room methodology, dataset citations, and architecture notes.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('About'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          _buildHeaderCard(),
          const SizedBox(height: 16),
          _buildPillarTile(
            icon: Icons.biotech_rounded,
            color: AppTheme.activeBlue,
            title: 'Clean-Room Architecture',
            description:
                'Engineered from scratch using behavioral black-box reverse engineering of Sique v5.8.9. All math algorithms, StateNotifier graphs, and database schemas were built cleanly without proprietary source code.',
          ),
          const SizedBox(height: 12),
          _buildPillarTile(
            icon: Icons.shield_rounded,
            color: AppTheme.expenditure,
            title: 'Adherence-Neutral Philosophy',
            description:
                'Caloric recommendations adapt dynamically through a Bayesian Kalman filter. The engine does not punish deviations or reward compliance—it neutrally measures thermodynamic reality.',
          ),
          const SizedBox(height: 12),
          _buildPillarTile(
            icon: Icons.restaurant_rounded,
            color: AppTheme.fat,
            title: 'ICMR-NIN IFCT 2017 Database',
            description:
                'Curated with nutritional values from the Indian Council of Medical Research and National Institute of Nutrition (IFCT). Features authentic Indian portions (Katori, Standard Roti, Idli) and cooking oil modifiers.',
          ),
          const SizedBox(height: 12),
          _buildPillarTile(
            icon: Icons.lock_outline_rounded,
            color: AppTheme.trendWeight,
            title: 'Local Data Sovereignty',
            description:
                'All nutrition entries, body weights, and profile settings are stored locally on-device in SQLite. Zero cloud tracking, zero telemetry, and 100% offline functionality.',
          ),
          const SizedBox(height: 24),
          _buildFooterCard(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.activeBlue, AppTheme.calories],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.activeBlue.withAlpha(60),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.bolt_rounded,
              size: 38,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Sique',
            style: TextStyle(
              fontFamily: 'MacroSans',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Indian Edition • Adherence-Neutral',
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.activeBlue,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.cardElevated,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: const Text(
              'v2.0.0 • Build 2026.10',
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 11,
                color: AppTheme.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillarTile({
    required IconData icon,
    required Color color,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withAlpha(30),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'MacroSans',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: const Column(
        children: [
          Text(
            'MIT Open Source License',
            style: TextStyle(
              fontFamily: 'MacroSans',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Crafted with Flutter & Riverpod. Designed for high-performance athletic macro tracking and evidence-based nutrition.',
            style: TextStyle(
              fontFamily: 'DMSans',
              fontSize: 11,
              color: AppTheme.textMuted,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
