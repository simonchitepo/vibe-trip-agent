import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../app/theme/app_theme.dart';

class VibeHero extends StatelessWidget {
  const VibeHero({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: AppTheme.radiusXL,
        gradient: LinearGradient(
          colors: [
            scheme.primary.withOpacity(0.12),
            scheme.secondary.withOpacity(0.10),
            scheme.tertiary.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: scheme.onSurface.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'One vibe → full trip',
                  style: t.headlineSmall?.copyWith(fontWeight: FontWeight.w900, letterSpacing: -0.6),
                ),
                const SizedBox(height: 6),
                Text(
                  'Flights, transit, hotel, and dinner reservations in one go.',
                  style: t.bodyMedium?.copyWith(color: scheme.onSurface.withOpacity(0.72), height: 1.3),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: const [
                    _Pill(icon: Icons.flight_takeoff_rounded, label: 'Flights'),
                    _Pill(icon: Icons.train_rounded, label: 'Transit'),
                    _Pill(icon: Icons.hotel_rounded, label: 'Hotel'),
                    _Pill(icon: Icons.restaurant_rounded, label: 'Dinner'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          _Orb(scheme: scheme).animate().scale(duration: 700.ms, curve: Curves.easeOutBack),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: scheme.onSurface.withOpacity(0.05),
        border: Border.all(color: scheme.onSurface.withOpacity(0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: scheme.onSurface.withOpacity(0.72)),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _Orb extends StatelessWidget {
  const _Orb({required this.scheme});
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      width: 92,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: [
            scheme.primary,
            scheme.secondary,
            scheme.tertiary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 40),
    );
  }
}
