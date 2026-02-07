import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_theme.dart';

class VibeParams {
  VibeParams({
    required this.vibe,
    required this.budgetUsd,
    required this.fromAirportCode,
    required this.startDate,
    required this.endDate,
  });

  final String vibe;
  final int budgetUsd;
  final String fromAirportCode;
  final DateTime startDate;
  final DateTime endDate;
}

class VibeFormCard extends StatefulWidget {
  const VibeFormCard({super.key, required this.onSubmit});
  final void Function(VibeParams params) onSubmit;

  @override
  State<VibeFormCard> createState() => _VibeFormCardState();
}

class _VibeFormCardState extends State<VibeFormCard> {
  final _formKey = GlobalKey<FormState>();

  final _vibeCtrl = TextEditingController(text: 'sunny, quiet, under 2000');
  final _budgetCtrl = TextEditingController(text: '2000');

  final _airportCtrl = TextEditingController(text: 'Warsaw (WAW) – Chopin Airport');
  String _fromIata = 'WAW';

  DateTime _start = DateTime.now().add(const Duration(days: 21));
  DateTime _end = DateTime.now().add(const Duration(days: 24));

  bool _submitting = false;
  bool _justCompleted = false;

  double _budgetValue = 2000.0;

  int _datePulse = 0;

  static const _minBudget = 300.0;
  static const _maxBudget = 8000.0;

  static const _vibeChips = <String>[
    '☀️ Sunny',
    '🌿 Quiet',
    '💸 Under \$2k',
    '🍷 Foodie',
    '🚶 Walkable',
    '🧘 Chill',
  ];

  static const List<_Airport> _airports = [
    _Airport(city: 'Warsaw', iata: 'WAW', name: 'Chopin Airport'),
    _Airport(city: 'Warsaw', iata: 'WMI', name: 'Modlin Airport'),
    _Airport(city: 'London', iata: 'LHR', name: 'Heathrow'),
    _Airport(city: 'London', iata: 'LGW', name: 'Gatwick'),
    _Airport(city: 'London', iata: 'STN', name: 'Stansted'),
    _Airport(city: 'Paris', iata: 'CDG', name: 'Charles de Gaulle'),
    _Airport(city: 'Paris', iata: 'ORY', name: 'Orly'),
    _Airport(city: 'New York', iata: 'JFK', name: 'John F. Kennedy'),
    _Airport(city: 'New York', iata: 'EWR', name: 'Newark'),
    _Airport(city: 'Dubai', iata: 'DXB', name: 'Dubai International'),
    _Airport(city: 'Lisbon', iata: 'LIS', name: 'Humberto Delgado'),
    _Airport(city: 'Madrid', iata: 'MAD', name: 'Barajas'),
    _Airport(city: 'Rome', iata: 'FCO', name: 'Fiumicino'),
    _Airport(city: 'Berlin', iata: 'BER', name: 'Brandenburg'),
    _Airport(city: 'Amsterdam', iata: 'AMS', name: 'Schiphol'),
  ];

  @override
  void initState() {
    super.initState();
    _budgetValue = (_parseBudget(_budgetCtrl.text)?.toDouble()) ?? 2000.0;
    _budgetCtrl.addListener(_syncBudgetFromText);
  }

  @override
  void dispose() {
    _vibeCtrl.dispose();
    _budgetCtrl.removeListener(_syncBudgetFromText);
    _budgetCtrl.dispose();
    _airportCtrl.dispose();
    super.dispose();
  }

  void _syncBudgetFromText() {
    final n = _parseBudget(_budgetCtrl.text);
    if (n == null) return;

    final clamped = n.clamp(_minBudget.toInt(), _maxBudget.toInt()).toDouble();
    if ((clamped - _budgetValue).abs() >= 1) {
      setState(() => _budgetValue = clamped);
    }
  }

  int? _parseBudget(String s) {
    final cleaned = s.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleaned.isEmpty) return null;
    return int.tryParse(cleaned);
  }

  void _appendVibe(String chip) {
    HapticFeedback.selectionClick();

    final normalized = chip
        .replaceAll('☀️', '')
        .replaceAll('🌿', '')
        .replaceAll('💸', '')
        .replaceAll('🍷', '')
        .replaceAll('🚶', '')
        .replaceAll('🧘', '')
        .trim();

    final current = _vibeCtrl.text.trim();
    final add = normalized.replaceAll('\$2k', '2000');

    if (current.isEmpty) {
      _vibeCtrl.text = add;
    } else {
      final lower = current.toLowerCase();
      if (lower.contains(add.toLowerCase())) return;

      _vibeCtrl.text = '$current, $add';
    }

    _vibeCtrl.selection = TextSelection.fromPosition(TextPosition(offset: _vibeCtrl.text.length));
    setState(() {});
  }

  String _formatAirportDisplay(String iata) {
    final hit = _airports.where((a) => a.iata == iata.toUpperCase()).toList();
    if (hit.isNotEmpty) {
      final a = hit.first;
      return '${a.city} (${a.iata}) – ${a.name}';
    }
    return iata.toUpperCase();
  }

  List<String> _budgetHints(int budgetUsd, int nights) {
    final hints = <String>[];

    final flightLikely = (budgetUsd * 0.25).round();
    if (flightLikely <= 500) {
      hints.add('✓ Flights likely under \$500');
    } else if (flightLikely <= 800) {
      hints.add('✓ Flights likely under \$800');
    } else {
      hints.add('✓ Flights budget: ~\$${flightLikely}');
    }

    final hotelPerNight = (budgetUsd * 0.45 / math.max(1, nights)).round();
    if (hotelPerNight >= 180) {
      hints.add('✓ Boutique hotel possible');
    } else if (hotelPerNight >= 120) {
      hints.add('✓ Solid 3–4★ hotel possible');
    } else {
      hints.add('✓ Budget hotel / apartment likely');
    }

    return hints;
  }

  String _durationLabel() {
    final s = DateTime(_start.year, _start.month, _start.day);
    final e = DateTime(_end.year, _end.month, _end.day);
    var nights = e.difference(s).inDays;
    if (nights < 1) nights = 1;

    final weekendish = nights <= 3 ? 'Long weekend' : nights <= 5 ? 'Short break' : 'Getaway';
    return '$nights night${nights == 1 ? '' : 's'} · $weekendish';
  }

  String _seasonHint(DateTime d) {
    final m = d.month;
    if (m == 12 || m == 1 || m == 2) return 'Winter · Cooler days';
    if (m == 3 || m == 4) return 'Early spring · Mild weather';
    if (m == 5) return 'Late spring · Warmer days';
    if (m == 6 || m == 7 || m == 8) return 'Summer · Peak season';
    if (m == 9) return 'Early autumn · Pleasant temps';
    return 'Autumn · Shoulder season';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    final startDay = DateTime(_start.year, _start.month, _start.day);
    final endDay = DateTime(_end.year, _end.month, _end.day);
    final nights = math.max(1, endDay.difference(startDay).inDays);

    final budgetInt = (_budgetValue.round()).clamp(_minBudget.toInt(), _maxBudget.toInt());

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: AppTheme.radiusXL,
        color: Colors.white,
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: scheme.onSurface.withOpacity(0.06)),
      ),
      child: Form(
        key: _formKey,
        child: LayoutBuilder(
          builder: (context, c) {
            final narrow = c.maxWidth < 420;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.tune_rounded, color: scheme.primary),
                    const SizedBox(width: 10),
                    Text(
                      'Your vibe',
                      style: t.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: scheme.onSurface.withOpacity(0.92),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _vibeCtrl,
                  decoration: InputDecoration(
                    labelText: 'Describe it',
                    hintText: 'sunny, quiet, under 2000',
                    prefixIcon: const Icon(Icons.auto_awesome_rounded),
                    filled: true,
                    fillColor: scheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (v) => (v == null || v.trim().length < 3) ? 'Give at least a few words.' : null,
                  textInputAction: TextInputAction.next,
                ),

                const SizedBox(height: 10),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _vibeChips.map((chip) {
                      return _SuggestionChip(
                        label: chip,
                        onTap: () => _appendVibe(chip),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 16),

                if (narrow)
                  Column(
                    children: [
                      _budgetBlock(scheme, t, budgetInt, nights),
                      const SizedBox(height: 14),
                      _airportBlock(scheme, t),
                    ],
                  )
                else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _budgetBlock(scheme, t, budgetInt, nights)),
                      const SizedBox(width: 12),
                      Expanded(child: _airportBlock(scheme, t)),
                    ],
                  ),

                const SizedBox(height: 14),

                if (narrow)
                  Column(
                    children: [
                      _dateChip(
                        context,
                        label: 'Depart',
                        date: _start,
                        icon: Icons.calendar_month_rounded,
                        pulseKey: _datePulse,
                        onTap: () async {
                          final p = await _pickDate(context, initial: _start);
                          if (p != null) {
                            setState(() {
                              _start = p;
                              if (!_end.isAfter(_start)) _end = _start.add(const Duration(days: 2));
                              _datePulse++;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 12),
                      _dateChip(
                        context,
                        label: 'Return',
                        date: _end,
                        icon: Icons.event_available_rounded,
                        pulseKey: _datePulse,
                        onTap: () async {
                          final p = await _pickDate(context, initial: _end);
                          if (p != null) {
                            setState(() {
                              _end = p.isAfter(_start) ? p : _start.add(const Duration(days: 2));
                              _datePulse++;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 10),
                      _dateMetaRow(scheme, t),
                    ],
                  )
                else
                  Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _dateChip(
                              context,
                              label: 'Depart',
                              date: _start,
                              icon: Icons.calendar_month_rounded,
                              pulseKey: _datePulse,
                              onTap: () async {
                                final p = await _pickDate(context, initial: _start);
                                if (p != null) {
                                  setState(() {
                                    _start = p;
                                    if (!_end.isAfter(_start)) _end = _start.add(const Duration(days: 2));
                                    _datePulse++;
                                  });
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _dateChip(
                              context,
                              label: 'Return',
                              date: _end,
                              icon: Icons.event_available_rounded,
                              pulseKey: _datePulse,
                              onTap: () async {
                                final p = await _pickDate(context, initial: _end);
                                if (p != null) {
                                  setState(() {
                                    _end = p.isAfter(_start) ? p : _start.add(const Duration(days: 2));
                                    _datePulse++;
                                  });
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _dateMetaRow(scheme, t),
                    ],
                  ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: _PressScale(
                    child: FilledButton.icon(
                      icon: AnimatedSwitcher(
                        duration: 180.ms,
                        child: _submitting
                            ? const SizedBox(
                          key: ValueKey('loading'),
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                            : Icon(
                          _justCompleted ? Icons.check_rounded : Icons.auto_awesome_mosaic_rounded,
                          key: ValueKey(_justCompleted ? 'done' : 'idle'),
                        ),
                      ),
                      label: AnimatedSwitcher(
                        duration: 180.ms,
                        child: Text(
                          _submitting
                              ? 'Planning your trip…'
                              : _justCompleted
                              ? 'Trip ready ✨'
                              : 'Generate full trip',
                          key: ValueKey(_submitting ? 'planning' : _justCompleted ? 'ready' : 'generate'),
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      ),
                      onPressed: _submitting
                          ? null
                          : () async {
                        FocusScope.of(context).unfocus();
                        if (!_formKey.currentState!.validate()) return;

                        _budgetCtrl.text = budgetInt.toString();

                        setState(() {
                          _submitting = true;
                          _justCompleted = false;
                        });

                        HapticFeedback.mediumImpact();

                        try {
                          final params = VibeParams(
                            vibe: _vibeCtrl.text.trim(),
                            budgetUsd: budgetInt,
                            fromAirportCode: _fromIata.trim().toUpperCase(),
                            startDate: _start,
                            endDate: _end.isAfter(_start) ? _end : _start.add(const Duration(days: 2)),
                          );

                          widget.onSubmit(params);

                          setState(() {
                            _submitting = false;
                            _justCompleted = true;
                          });

                          Future.delayed(const Duration(milliseconds: 800), () {
                            if (!mounted) return;
                            setState(() => _justCompleted = false);
                          });
                        } catch (_) {
                          if (!mounted) return;
                          setState(() => _submitting = false);
                        }
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Your trip is planned by a private AI agent.',
                  style: t.bodySmall?.copyWith(
                    color: scheme.onSurface.withOpacity(0.72),
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _budgetBlock(ColorScheme scheme, TextTheme t, int budgetInt, int nights) {
    final hints = _budgetHints(budgetInt, nights);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _budgetCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Budget (USD)',
            prefixIcon: const Icon(Icons.payments_rounded),
            filled: true,
            fillColor: scheme.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
          ),
          validator: (v) {
            final n = _parseBudget(v ?? '');
            if (n == null || n < _minBudget.toInt()) return 'Min ${_minBudget.toInt()}';
            return null;
          },
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 10),
        Slider(
          value: _budgetValue.clamp(_minBudget, _maxBudget),
          min: _minBudget,
          max: _maxBudget,
          divisions: ((_maxBudget - _minBudget) / 50).round(),
          label: '\$${budgetInt.toString()}',
          onChanged: (v) {
            setState(() {
              _budgetValue = v;
              _budgetCtrl.text = v.round().toString();
            });
          },
        ),
        const SizedBox(height: 4),
        ...hints.map(
              (h) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              h,
              style: t.bodySmall?.copyWith(
                color: scheme.onSurface.withOpacity(0.70),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _airportBlock(ColorScheme scheme, TextTheme t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Autocomplete<_Airport>(
          initialValue: TextEditingValue(text: _airportCtrl.text),
          displayStringForOption: (a) => '${a.city} (${a.iata}) – ${a.name}',
          optionsBuilder: (text) {
            final q = text.text.trim().toUpperCase();
            if (q.isEmpty) return const Iterable<_Airport>.empty();
            return _airports.where((a) {
              final hay = ('${a.city} ${a.iata} ${a.name}').toUpperCase();
              return hay.contains(q);
            }).take(8);
          },
          fieldViewBuilder: (context, ctrl, focusNode, onFieldSubmitted) {
            _airportCtrl.value = ctrl.value;

            return TextFormField(
              controller: ctrl,
              focusNode: focusNode,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                labelText: 'From (airport)',
                hintText: 'Warsaw (WAW) – Chopin Airport',
                prefixIcon: const Icon(Icons.flight_takeoff_rounded),
                filled: true,
                fillColor: scheme.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
              ),
              validator: (v) {
                final raw = (v ?? '').trim();
                if (raw.length < 3) return 'Type city or IATA (e.g. WAW)';
                final iata = _extractIata(raw);
                if (iata == null || iata.length != 3) return 'Use a valid airport code (e.g. WAW)';
                return null;
              },
              onChanged: (v) {
                final iata = _extractIata(v);
                if (iata != null && iata.length == 3) {
                  _fromIata = iata.toUpperCase();
                } else {
                  final raw = v.trim().toUpperCase();
                  if (raw.length == 3 && RegExp(r'^[A-Z]{3}$').hasMatch(raw)) {
                    _fromIata = raw;
                  }
                }
                setState(() {});
              },
            );
          },
          onSelected: (a) {
            HapticFeedback.selectionClick();
            setState(() {
              _fromIata = a.iata;
              _airportCtrl.text = '${a.city} (${a.iata}) – ${a.name}';
            });
          },
        ),
        const SizedBox(height: 6),
        Text(
          'Selected: ${_formatAirportDisplay(_fromIata)}',
          style: t.bodySmall?.copyWith(
            color: scheme.onSurface.withOpacity(0.68),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  String? _extractIata(String input) {
    final m = RegExp(r'\(([A-Za-z]{3})\)').firstMatch(input);
    if (m != null) return m.group(1)!.toUpperCase();

    final raw = input.trim().toUpperCase();
    if (raw.length == 3 && RegExp(r'^[A-Z]{3}$').hasMatch(raw)) return raw;

    return null;
  }

  Widget _dateMetaRow(ColorScheme scheme, TextTheme t) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _MetaChip(
            icon: Icons.nights_stay_rounded,
            label: _durationLabel(),
          ),
          _MetaChip(
            icon: Icons.thermostat_rounded,
            label: _seasonHint(_start),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 220.ms);
  }

  Widget _dateChip(
      BuildContext context, {
        required String label,
        required DateTime date,
        required IconData icon,
        required VoidCallback onTap,
        required int pulseKey,
      }) {
    final fmt = DateFormat('EEE, MMM d');
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () async {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: scheme.surface,
          border: Border.all(color: scheme.onSurface.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: scheme.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: scheme.onSurface.withOpacity(0.72),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    fmt.format(date),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: scheme.onSurface.withOpacity(0.92),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate(key: ValueKey('$label-$pulseKey-${date.toIso8601String()}'))
        .scale(begin: const Offset(1, 1), end: const Offset(1.01, 1.01), duration: 120.ms)
        .then()
        .scale(begin: const Offset(1.01, 1.01), end: const Offset(1, 1), duration: 140.ms);
  }

  Future<DateTime?> _pickDate(BuildContext context, {required DateTime initial}) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 2),
      initialDate: initial,
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(999),
          color: scheme.primary.withOpacity(0.08),
          border: Border.all(color: scheme.primary.withOpacity(0.18)),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: scheme.onSurface.withOpacity(0.86),
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: scheme.onSurface.withOpacity(0.04),
        border: Border.all(color: scheme.onSurface.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.onSurface.withOpacity(0.86),
            ),
          ),
        ],
      ),
    );
  }
}

class _PressScale extends StatefulWidget {
  const _PressScale({required this.child});
  final Widget child;

  @override
  State<_PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<_PressScale> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      child: AnimatedScale(
        scale: _down ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

class _Airport {
  const _Airport({required this.city, required this.iata, required this.name});
  final String city;
  final String iata;
  final String name;
}
