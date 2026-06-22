import 'package:flutter/material.dart';
import '../data/constants.dart';

class WebLoginHero extends StatelessWidget {
  const WebLoginHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            KConstants.primaryColor,
            KConstants.secondaryColor,
            KConstants.primaryColor.withValues(alpha: 0.9),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80,
            right: -80,
            child: _circle(240, 0.15),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: _circle(200, 0.12),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(48),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.sports_soccer,
                      size: 72,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'PASSA A BOLA',
                      style: KTextStyle.extraLargeTitleText.copyWith(
                        color: Colors.white,
                        fontSize: 40,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'A plataforma do futebol feminino. '
                      'Campeonatos, times, notícias e muito mais.',
                      style: KTextStyle.descriptionText.copyWith(
                        color: Colors.white.withValues(alpha: 0.92),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: const [
                        _FeatureChip(
                          icon: Icons.emoji_events_outlined,
                          label: 'Campeonatos',
                        ),
                        _FeatureChip(
                          icon: Icons.groups_outlined,
                          label: 'Times',
                        ),
                        _FeatureChip(
                          icon: Icons.article_outlined,
                          label: 'Notícias',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: opacity),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: KTextStyle.bodyText.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
