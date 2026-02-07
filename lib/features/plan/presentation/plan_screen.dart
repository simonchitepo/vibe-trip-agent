import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:http/http.dart' as http;

import '../../../app/theme/app_theme.dart';
import '../../home/presentation/widgets/vibe_form_card.dart';
import '../domain/models.dart';
import 'providers.dart';
import 'widgets/plan_cards.dart';

class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  bool _requested = false;
  final ScrollController _scrollController = ScrollController();

  Timer? _autoScrollTimer;

  static const String _reportEndpoint = 'https://cyph3r.live/api/report_ai.php';

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requested) return;

    final extra = GoRouterState.of(context).extra;
    if (extra is VibeParams) {
      _requested = true;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(planControllerProvider.notifier).generate(
          vibe: extra.vibe,
          budgetUsd: extra.budgetUsd,
          dates: DateRange(start: extra.startDate, end: extra.endDate),
          fromAirportCode: extra.fromAirportCode,
        );
      });
    }
  }

  void _scheduleAutoScroll() {
    if (!_scrollController.hasClients) return;

    _autoScrollTimer ??= Timer(const Duration(milliseconds: 260), () {
      _autoScrollTimer = null;
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _openReportDialog({
    required PlanStatus status,
    required String visibleText,
  }) async {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    if (_reportEndpoint.contains('YOUR_DOMAIN.com')) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Set your report endpoint URL in plan_screen.dart first.'),
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
                'This will send the currently visible AI output (and your note) to support for review.',
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
                  labelText: 'Optional note',
                  hintText: 'What’s inappropriate or wrong?',
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
        'screen': 'plan_screen',
        'status': status.name,
        'note': noteController.text.trim(),
        'content': visibleText,
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
          SnackBar(
            content: const Text('Report sent. Thank you.'),
            backgroundColor: const Color(0xFF2ECC71),
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
    final state = ref.watch(planControllerProvider);
    final scheme = Theme.of(context).colorScheme;

    if (state.status == PlanStatus.loading && (state.partialText ?? '').isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scheduleAutoScroll());
    }

    final reportText = (state.status == PlanStatus.ready && state.plan != null)
        ? state.plan.toString()
        : (state.partialText ?? '');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your trip'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            ref.read(planControllerProvider.notifier).reset();
            context.pop();
          },
        ),
        actions: [
  
          IconButton(
            tooltip: 'Report AI content',
            icon: const Icon(Icons.flag_outlined),
            onPressed: () => _openReportDialog(
              status: state.status,
              visibleText: reportText,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _AiStatusPill(status: state.status),
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _SoftGridPainter(color: scheme.onSurface.withOpacity(0.05)),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: switch (state.status) {
                        PlanStatus.loading => _LoadingWithLiveOutput(
                          partialText: state.partialText ?? '',
                        ).animate().fadeIn(duration: 220.ms),
                        PlanStatus.failure => _ErrorState(message: state.error ?? 'Unknown error'),
                        PlanStatus.ready => PlanView(plan: state.plan!),
                        PlanStatus.idle => const _IdleState(),
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiStatusPill extends StatelessWidget {
  const _AiStatusPill({required this.status});
  final PlanStatus status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final (label, color, icon) = switch (status) {
      PlanStatus.idle => ('Live AI', const Color(0xFF2ECC71), Icons.auto_awesome_rounded),
      PlanStatus.loading => ('Planning', scheme.secondary, Icons.hourglass_top_rounded),
      PlanStatus.ready => ('Ready', const Color(0xFF2ECC71), Icons.check_circle_rounded),
      PlanStatus.failure => ('Error', scheme.error, Icons.error_outline_rounded),
    };

    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withOpacity(0.10),
        border: Border.all(color: color.withOpacity(0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == PlanStatus.loading)
            SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          else
            Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );

    if (status == PlanStatus.loading) {
      return pill
          .animate(onPlay: (c) => c.repeat())
          .fadeIn(duration: 250.ms)
          .then()
          .scale(begin: const Offset(1, 1), end: const Offset(1.03, 1.03), duration: 650.ms)
          .then()
          .scale(begin: const Offset(1.03, 1.03), end: const Offset(1, 1), duration: 650.ms);
    }

    return pill;
  }
}

class _LoadingWithLiveOutput extends StatelessWidget {
  const _LoadingWithLiveOutput({required this.partialText});
  final String partialText;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _LoadingSkeleton(),
        const SizedBox(height: 12),

        _LiveOutputCard(text: partialText),
      ],
    );
  }
}

class _LiveOutputCard extends StatelessWidget {
  const _LiveOutputCard({required this.text});
  final String text;

  static const _maxChars = 5500; 
  static const _maxLines = 18;

  String _preview(String s) {
    final trimmed = s.trimRight();
    if (trimmed.isEmpty) return '';

    var out = trimmed;
    if (out.length > _maxChars) {
      out = out.substring(out.length - _maxChars);
    }

    final lines = out.split('\n');
    if (lines.length > _maxLines) {
      out = lines.sublist(lines.length - _maxLines).join('\n');
    }

    return out;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    final preview = _preview(text);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: AppTheme.radiusXL,
        color: Colors.white,
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: scheme.onSurface.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 34,
                width: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: scheme.primary.withOpacity(0.10),
                  border: Border.all(color: scheme.primary.withOpacity(0.20)),
                ),
                child: Icon(Icons.stream_rounded, color: scheme.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Live output',
                style: t.titleSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: scheme.onSurface.withOpacity(0.92),
                ),
              ),
              const Spacer(),
              _StreamingDot(color: scheme.secondary),
              const SizedBox(width: 8),
              Text(
                'streaming',
                style: t.labelMedium?.copyWith(
                  color: scheme.onSurface.withOpacity(0.70),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (preview.isEmpty)
            Text(
              'Thinking…',
              style: t.bodyMedium?.copyWith(color: scheme.onSurface.withOpacity(0.68)),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: scheme.surface,
                border: Border.all(color: scheme.onSurface.withOpacity(0.06)),
              ),
              child: SelectableText(
                preview,
                style: t.bodySmall?.copyWith(
                  height: 1.35,
                  fontFamily: 'monospace',
                  color: scheme.onSurface.withOpacity(0.86),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StreamingDot extends StatelessWidget {
  const _StreamingDot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color.withOpacity(0.25), blurRadius: 10, spreadRadius: 2)],
      ),
    ).animate(onPlay: (c) => c.repeat()).fadeIn(duration: 450.ms).then().fadeOut(duration: 450.ms);
  }
}

class _IdleState extends StatelessWidget {
  const _IdleState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: AppTheme.radiusXL,
          color: Colors.white,
          boxShadow: AppTheme.softShadow,
        ),
        child: Text(
          'No plan yet.',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: scheme.onSurface.withOpacity(0.7),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: AppTheme.radiusXL,
          color: Colors.white,
          boxShadow: AppTheme.softShadow,
          border: Border.all(color: scheme.error.withOpacity(0.2)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, color: scheme.error, size: 34),
            const SizedBox(height: 10),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Shimmer.fromColors(
      baseColor: scheme.onSurface.withOpacity(0.06),
      highlightColor: scheme.onSurface.withOpacity(0.02),
      child: Column(
        children: [
          _skel(height: 120),
          const SizedBox(height: 14),
          _skel(height: 92),
          const SizedBox(height: 14),
          _skel(height: 140),
          const SizedBox(height: 14),
          _skel(height: 160),
        ],
      ),
    );
  }

  Widget _skel({required double height}) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: AppTheme.radiusXL,
        color: Colors.white,
      ),
    );
  }
}

class _SoftGridPainter extends CustomPainter {
  _SoftGridPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 26.0;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += gap) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gap) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SoftGridPainter oldDelegate) => false;
}