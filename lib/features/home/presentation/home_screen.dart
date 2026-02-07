import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../../app/theme/app_theme.dart';
import 'widgets/vibe_form_card.dart';
import 'widgets/vibe_hero.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _t =
  AnimationController(vsync: this, duration: const Duration(seconds: 9))..repeat();

  Offset _pointer = Offset.zero;

  static bool _disclaimerAcceptedThisSession = false;
  bool _disclaimerDialogShown = false;

  static const String _reportEndpoint = 'https://cyph3r.live/api/report_ai.php';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowDisclaimer();
    });
  }

  @override
  void dispose() {
    _t.dispose();
    super.dispose();
  }

  Future<void> _maybeShowDisclaimer() async {
    if (!mounted) return;
    if (_disclaimerAcceptedThisSession) return;
    if (_disclaimerDialogShown) return;

    _disclaimerDialogShown = true;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final scheme = Theme.of(context).colorScheme;
        final t = Theme.of(context).textTheme;

        return AlertDialog(
          title: Text(
            'Before you continue',
            style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          content: Text(
            'This app uses AI to generate travel suggestions. '
                'Verify prices, availability, and entry requirements before booking.',
            style: t.bodyMedium?.copyWith(color: scheme.onSurface.withOpacity(0.82), height: 1.35),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Cancel',
                style: TextStyle(color: scheme.onSurface.withOpacity(0.75)),
              ),
            ),
            FilledButton(
              onPressed: () {
                _disclaimerAcceptedThisSession = true;
                Navigator.of(context).pop();
              },
              child: const Text('I understand'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openReportDialog() async {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    if (_reportEndpoint.contains('www.cyph3r.live')) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Set your report endpoint URL in home_screen.dart first.'),
          backgroundColor: scheme.error,
        ),
      );
      return;
    }

    final noteController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Report AI content',
            style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Use this to report inappropriate AI-generated output or behavior. '
                    'This sends your note to support for review.',
                style: t.bodyMedium?.copyWith(
                  color: scheme.onSurface.withOpacity(0.82),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'What happened?',
                  hintText: 'Describe the issue (and when it occurred)',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancel',
                style: TextStyle(color: scheme.onSurface.withOpacity(0.75)),
              ),
            ),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(true),
              icon: const Icon(Icons.flag_rounded),
              label: const Text('Send report'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final payload = <String, dynamic>{
        'screen': 'home_screen',
        'note': noteController.text.trim(),
        'content': '', 
        'ts': DateTime.now().toIso8601String(),
        'to': 'cyph3rzw@gmail.com', 
      };

      final res = await http
          .post(
        Uri.parse(_reportEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      )
          .timeout(const Duration(seconds: 8));

      if (!mounted) return;

      if (res.statusCode >= 200 && res.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Report sent. Thank you.'),
            backgroundColor: Color(0xFF2ECC71),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send report (HTTP ${res.statusCode}).'),
            backgroundColor: scheme.error,
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to send report. Check your connection/endpoint.'),
          backgroundColor: scheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: Stack(
        children: [
          const _BackgroundGlow(),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _t,
              builder: (context, _) {
                return _HeroShimmerOverlay(
                  t: _t.value,
                  pointer: _pointer,
                );
              },
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Listener(
                  onPointerHover: (e) => setState(() => _pointer = e.localPosition),
                  onPointerMove: (e) => setState(() => _pointer = e.localPosition),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight - 40),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _BrandMark(color: scheme.primary),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Vibe Trip Agent',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.4,
                                    color: scheme.onSurface.withOpacity(0.92),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),

                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: _StatusPill(
                                  label: 'Live AI',
                                  icon: Icons.circle_rounded,
                                  color: const Color(0xFF2ECC71),
                                )
                                    .animate()
                                    .fadeIn(duration: 350.ms)
                                    .then()
                                    .scale(
                                  begin: const Offset(1, 1),
                                  end: const Offset(1.03, 1.03),
                                  duration: 900.ms,
                                  curve: Curves.easeInOut,
                                )
                                    .then()
                                    .scale(
                                  begin: const Offset(1.03, 1.03),
                                  end: const Offset(1, 1),
                                  duration: 900.ms,
                                  curve: Curves.easeInOut,
                                )
                                    .animate(onPlay: (c) => c.repeat()),
                              ),

                              const SizedBox(width: 6),

                              IconButton(
                                tooltip: 'Report AI content',
                                icon: const Icon(Icons.flag_outlined),
                                onPressed: _openReportDialog,
                              ),
                            ],
                          ).animate().fadeIn(duration: 450.ms).slideY(begin: -0.15, end: 0),

                          const SizedBox(height: 18),

                          const _UpgradedHero()
                              .animate()
                              .fadeIn(duration: 500.ms)
                              .slideY(begin: 0.06, end: 0),

                          const SizedBox(height: 20),

                          Align(
                            alignment: Alignment.topCenter,
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 560),
                              child: VibeFormCard(
                                onSubmit: (params) async {
                                  if (!_disclaimerAcceptedThisSession) {
                                    await _maybeShowDisclaimer();
                                    if (!_disclaimerAcceptedThisSession) return;
                                  }

                                  HapticFeedback.selectionClick();
                                  context.go('/plan', extra: params);
                                },
                              )
                                  .animate()
                                  .fadeIn(duration: 550.ms)
                                  .slideY(begin: 0.08, end: 0),
                            ),
                          ),

                          const SizedBox(height: 18),

                          Text(
                            'Your trip is planned by a private AI agent.',
                            style: textTheme.bodySmall?.copyWith(
                              color: scheme.onSurface.withOpacity(0.70),
                              fontWeight: FontWeight.w600,
                            ),
                          ).animate().fadeIn(delay: 180.ms, duration: 600.ms),

                          const SizedBox(height: 10),

                          Text(
                            'Try: “☀️ Sunny · 🌿 Quiet · 💸 Under \$2k” or “🍷 Foodie weekend · 🚶 Walkable · 🧘 Chill”.',
                            style: textTheme.bodySmall?.copyWith(
                              color: scheme.onSurface.withOpacity(0.68),
                            ),
                          ).animate().fadeIn(delay: 260.ms, duration: 600.ms),

                          const SizedBox(height: 16),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: _openReportDialog,
                              icon: const Icon(Icons.report_gmailerrorred_rounded, size: 18),
                              label: const Text('Report AI-generated content'),
                            ),
                          ),

                          if (kDebugMode) ...[
                            const SizedBox(height: 10),
                            const VibeHero().animate().fadeIn(duration: 500.ms),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _UpgradedHero extends StatelessWidget {
  const _UpgradedHero();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: AppTheme.radiusXL,
        color: Colors.white.withOpacity(0.86),
        border: Border.all(color: scheme.onSurface.withOpacity(0.06)),
        boxShadow: AppTheme.softShadow,
      ),
      child: Row(
        children: [
          _DynamicStateIcon(color: scheme.primary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'One vibe. One tap. Full trip.',
                  style: t.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                    color: scheme.onSurface.withOpacity(0.92),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Flights, transit, hotel, and dinner picks in one go — live.',
                  style: t.bodyMedium?.copyWith(
                    height: 1.35,
                    color: scheme.onSurface.withOpacity(0.72),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DynamicStateIcon extends StatelessWidget {
  const _DynamicStateIcon({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      width: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.62)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.20),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 22)
          .animate(onPlay: (c) => c.repeat())
          .shimmer(duration: 1400.ms),
    );
  }
}

class _HeroShimmerOverlay extends StatelessWidget {
  const _HeroShimmerOverlay({required this.t, required this.pointer});

  final double t;
  final Offset pointer;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;

    final px = (pointer.dx == 0 ? size.width / 2 : pointer.dx) / math.max(1, size.width);
    final py = (pointer.dy == 0 ? size.height / 3 : pointer.dy) / math.max(1, size.height);

    final dx = (px - 0.5) * 14;
    final dy = (py - 0.5) * 10;

    return IgnorePointer(
      ignoring: true,
      child: Transform.translate(
        offset: Offset(dx, dy),
        child: Opacity(
          opacity: 0.18,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scheme.primary.withOpacity(0.35),
                  scheme.secondary.withOpacity(0.25),
                  scheme.tertiary.withOpacity(0.22),
                ],
                stops: [
                  (t - 0.20).clamp(0.0, 1.0),
                  t.clamp(0.0, 1.0),
                  (t + 0.20).clamp(0.0, 1.0),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );
  }
}

class _BackgroundGlow extends StatelessWidget {
  const _BackgroundGlow();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Positioned.fill(
      child: CustomPaint(
        painter: _GlowPainter(
          a: scheme.primary.withOpacity(0.18),
          b: scheme.secondary.withOpacity(0.16),
          c: scheme.tertiary.withOpacity(0.14),
        ),
      ),
    );
  }
}

class _GlowPainter extends CustomPainter {
  _GlowPainter({required this.a, required this.b, required this.c});
  final Color a;
  final Color b;
  final Color c;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 70);
    canvas.drawCircle(Offset(size.width * 0.18, size.height * 0.16), size.width * 0.35, p..color = a);
    canvas.drawCircle(Offset(size.width * 0.88, size.height * 0.22), size.width * 0.30, p..color = b);
    canvas.drawCircle(Offset(size.width * 0.62, size.height * 0.86), size.width * 0.42, p..color = c);
  }

  @override
  bool shouldRepaint(covariant _GlowPainter oldDelegate) => false;
}

class _BrandMark extends StatelessWidget {
  const _BrandMark({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      width: 34,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.65)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: AppTheme.softShadow,
      ),
      child: const Icon(Icons.airplanemode_active_rounded, color: Colors.white, size: 18),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.icon, required this.color});
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withOpacity(0.10),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: t.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}