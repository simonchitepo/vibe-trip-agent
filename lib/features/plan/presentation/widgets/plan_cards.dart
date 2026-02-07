import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/launch_url.dart';
import '../../domain/models.dart';
import '../providers.dart';

class PlanView extends ConsumerWidget {
  const PlanView({super.key, required this.plan});
  final TripPlan plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nights = plan.dates.nights;
    final flightCost = plan.flights.first.priceUsd;
    final hotelCost = plan.hotel.pricePerNightUsd * nights;
    final diningCost = plan.dinners.fold<int>(0, (s, d) => s + d.estimatedCostUsd);
    final transitCost = plan.transit.totalCostUsd;
    final buffer = (plan.budgetUsd * 0.08).round();

    final breakdown = MoneyBreakdown(
      flights: flightCost,
      hotel: hotelCost,
      transit: transitCost,
      dining: diningCost,
      buffer: buffer,
    );

    return Column(
      children: [
        _HeroSummary(plan: plan, breakdown: breakdown)
            .animate()
            .fadeIn(duration: 450.ms)
            .slideY(begin: 0.06, end: 0),
        const SizedBox(height: 14),

        const _SectionTitle(icon: Icons.flight_takeoff_rounded, title: 'Flights'),
        const SizedBox(height: 10),
        _FlightsCard(plan: plan)
            .animate()
            .fadeIn(duration: 500.ms)
            .slideY(begin: 0.04, end: 0),

        const SizedBox(height: 14),
        const _SectionTitle(icon: Icons.hotel_rounded, title: 'Hotel'),
        const SizedBox(height: 10),
        _HotelCard(plan: plan)
            .animate()
            .fadeIn(duration: 520.ms)
            .slideY(begin: 0.04, end: 0),

        const SizedBox(height: 14),
        const _SectionTitle(icon: Icons.train_rounded, title: 'Transit'),
        const SizedBox(height: 10),
        _TransitCard(plan: plan)
            .animate()
            .fadeIn(duration: 540.ms)
            .slideY(begin: 0.04, end: 0),

        const SizedBox(height: 14),
        const _SectionTitle(icon: Icons.restaurant_rounded, title: 'Dinner'),
        const SizedBox(height: 10),
        _DinnerCard(plan: plan)
            .animate()
            .fadeIn(duration: 560.ms)
            .slideY(begin: 0.04, end: 0),

        const SizedBox(height: 22),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          height: 34,
          width: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: scheme.onSurface.withOpacity(0.05),
            border: Border.all(color: scheme.onSurface.withOpacity(0.06)),
          ),
          child: Icon(icon, color: scheme.onSurface.withOpacity(0.75), size: 18),
        ),
        const SizedBox(width: 10),
        Text(title, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _HeroSummary extends StatelessWidget {
  const _HeroSummary({required this.plan, required this.breakdown});
  final TripPlan plan;
  final MoneyBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final fmt = DateFormat('MMM d');

    final total = breakdown.total;
    final over = total > plan.budgetUsd;

    return Container(
      padding: const EdgeInsets.all(18),
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
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(colors: [scheme.primary, scheme.secondary]),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${plan.destinationCity} • ${plan.dates.nights} nights',
                      style: t.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    Text(
                      '${fmt.format(plan.dates.start)} → ${fmt.format(plan.dates.end)}   •   from ${plan.flights.first.from}',
                      style: t.bodySmall?.copyWith(color: scheme.onSurface.withOpacity(0.65)),
                    ),
                  ],
                ),
              ),
              _BudgetPill(
                label: '\$$total',
                hint: over ? 'Over budget' : 'Within budget',
                color: over ? scheme.error : scheme.primary,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            plan.summary,
            style: t.bodyMedium?.copyWith(height: 1.35, color: scheme.onSurface.withOpacity(0.82)),
          ),
          const SizedBox(height: 14),
          _BreakdownRow(breakdown: breakdown, budget: plan.budgetUsd),
        ],
      ),
    );
  }
}

class _BudgetPill extends StatelessWidget {
  const _BudgetPill({required this.label, required this.hint, required this.color});
  final String label;
  final String hint;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: color.withOpacity(0.10),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            hint,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: color.withOpacity(0.9)),
          ),
        ],
      ),
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({required this.breakdown, required this.budget});
  final MoneyBreakdown breakdown;
  final int budget;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final pct = (breakdown.total / budget).clamp(0.0, 1.3);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Budget breakdown', style: t.labelLarge?.copyWith(fontWeight: FontWeight.w900))),
            Text(
              '\$${breakdown.total} / \$$budget',
              style: t.labelLarge?.copyWith(color: scheme.onSurface.withOpacity(0.75)),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 10,
            value: pct > 1 ? 1 : pct,
            backgroundColor: scheme.onSurface.withOpacity(0.06),
            valueColor: AlwaysStoppedAnimation<Color>(pct > 1 ? scheme.error : scheme.primary),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _MiniChip(label: 'Flights', value: '\$${breakdown.flights}', icon: Icons.flight_rounded),
            _MiniChip(label: 'Hotel', value: '\$${breakdown.hotel}', icon: Icons.hotel_rounded),
            _MiniChip(label: 'Transit', value: '\$${breakdown.transit}', icon: Icons.train_rounded),
            _MiniChip(label: 'Dining', value: '\$${breakdown.dining}', icon: Icons.restaurant_rounded),
            _MiniChip(label: 'Buffer', value: '\$${breakdown.buffer}', icon: Icons.savings_rounded),
          ],
        ),
      ],
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: scheme.onSurface.withOpacity(0.04),
        border: Border.all(color: scheme.onSurface.withOpacity(0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: scheme.onSurface.withOpacity(0.72)),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(color: scheme.onSurface.withOpacity(0.65)),
              ),
              Text(
                value,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FlightsCard extends ConsumerStatefulWidget {
  const _FlightsCard({required this.plan});
  final TripPlan plan;

  @override
  ConsumerState<_FlightsCard> createState() => _FlightsCardState();
}

class _FlightsCardState extends ConsumerState<_FlightsCard> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final fmt = DateFormat('EEE, MMM d • HH:mm');

    final out = plan.flights.first;
    final back = plan.flights.last;

    Widget leg(String title, FlightOption f, {bool showPrice = false}) {
      final dur = f.duration;
      final h = dur.inHours;
      final m = dur.inMinutes.remainder(60);

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: scheme.surface,
          border: Border.all(color: scheme.onSurface.withOpacity(0.06)),
        ),
        child: Row(
          children: [
            Icon(Icons.flight_rounded, color: scheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: t.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(
                    '${f.from} → ${f.to} • ${fmt.format(f.departLocal)}',
                    style: t.bodySmall?.copyWith(color: scheme.onSurface.withOpacity(0.75)),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Duration ${h}h ${m}m • ${f.stops} stop(s) • ~${f.carbonKg} kg CO₂',
                    style: t.bodySmall?.copyWith(color: scheme.onSurface.withOpacity(0.65)),
                  ),
                ],
              ),
            ),
            if (showPrice) Text('\$${f.priceUsd}', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
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
              Expanded(
                child: Text(
                  '${out.airline} • round trip',
                  style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900),
                ),
              ),
              _PrimaryActionButton(
                label: _busy ? 'Opening…' : 'Book flights',
                icon: Icons.open_in_new_rounded,
                busy: _busy,
                onPressed: _busy
                    ? null
                    : () async {
                  setState(() => _busy = true);
                  try {
                    final booking = ref.read(bookingServiceProvider);
                    final url = await booking.getBookingUrl(
                      type: 'flight',
                      payload: {
                        'from': out.from,
                        'to': out.to,
                        'departDate': plan.dates.start.toIso8601String().substring(0, 10),
                        'returnDate': plan.dates.end.toIso8601String().substring(0, 10),
                      },
                    );
                    await launchExternalUrl(url);
                  } finally {
                    if (mounted) setState(() => _busy = false);
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          leg('Outbound', out, showPrice: true),
          const SizedBox(height: 10),
          leg('Return', back),
        ],
      ),
    );
  }
}

class _HotelCard extends ConsumerStatefulWidget {
  const _HotelCard({required this.plan});
  final TripPlan plan;

  @override
  ConsumerState<_HotelCard> createState() => _HotelCardState();
}

class _HotelCardState extends ConsumerState<_HotelCard> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    final nights = plan.dates.nights;

    return Container(
      padding: const EdgeInsets.all(18),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(plan.hotel.name, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 2),
                    Text(
                      '${plan.hotel.area} • ★ ${plan.hotel.rating}',
                      style: t.bodySmall?.copyWith(color: scheme.onSurface.withOpacity(0.7)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: scheme.primary.withOpacity(0.10),
                  border: Border.all(color: scheme.primary.withOpacity(0.20)),
                ),
                child: Text(
                  '\$${plan.hotel.pricePerNightUsd}/night',
                  style: t.labelLarge?.copyWith(fontWeight: FontWeight.w900, color: scheme.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: plan.hotel.perks.map((p) => _Tag(text: p)).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Estimate: $nights nights × \$${plan.hotel.pricePerNightUsd} = \$${plan.hotel.pricePerNightUsd * nights}',
                  style: t.bodySmall?.copyWith(color: scheme.onSurface.withOpacity(0.65)),
                ),
              ),
              _PrimaryActionButton(
                label: _busy ? 'Opening…' : 'Book hotel',
                icon: Icons.open_in_new_rounded,
                busy: _busy,
                onPressed: _busy
                    ? null
                    : () async {
                  setState(() => _busy = true);
                  try {
                    final booking = ref.read(bookingServiceProvider);
                    final url = await booking.getBookingUrl(
                      type: 'hotel',
                      payload: {
                        'city': plan.destinationCity,
                        'checkIn': plan.dates.start.toIso8601String().substring(0, 10),
                        'checkOut': plan.dates.end.toIso8601String().substring(0, 10),
                        'adults': 2,
                        'rooms': 1,
                      },
                    );
                    await launchExternalUrl(url);
                  } finally {
                    if (mounted) setState(() => _busy = false);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TransitCard extends StatelessWidget {
  const _TransitCard({required this.plan});
  final TripPlan plan;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(18),
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
              Expanded(child: Text('Transit plan', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900))),
              Text('\$${plan.transit.totalCostUsd}', style: t.titleSmall?.copyWith(fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 10),
          _InfoRow(icon: Icons.luggage_rounded, title: 'Arrival', value: plan.transit.airportToHotel),
          const SizedBox(height: 8),
          _InfoRow(icon: Icons.confirmation_num_rounded, title: 'Pass', value: plan.transit.dayPass),
          const SizedBox(height: 12),
          ...plan.transit.notes.map(
                (n) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_rounded, size: 18, color: scheme.secondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      n,
                      style: t.bodySmall?.copyWith(color: scheme.onSurface.withOpacity(0.72), height: 1.3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DinnerCard extends ConsumerStatefulWidget {
  const _DinnerCard({required this.plan});
  final TripPlan plan;

  @override
  ConsumerState<_DinnerCard> createState() => _DinnerCardState();
}

class _DinnerCardState extends ConsumerState<_DinnerCard> {
  String? _busyRestaurant;

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: AppTheme.radiusXL,
        color: Colors.white,
        boxShadow: AppTheme.softShadow,
        border: Border.all(color: scheme.onSurface.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dinner picks', style: t.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
          const SizedBox(height: 12),
          ...plan.dinners.map((d) {
            final busy = _busyRestaurant == d.restaurant;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: scheme.surface,
                border: Border.all(color: scheme.onSurface.withOpacity(0.06)),
              ),
              child: Row(
                children: [
                  Container(
                    height: 38,
                    width: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: scheme.tertiary.withOpacity(0.16),
                    ),
                    child: Icon(Icons.restaurant_rounded, color: scheme.tertiary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.restaurant, style: t.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
                        const SizedBox(height: 2),
                        Text(
                          '${d.dayLabel} • ${d.time} • party of ${d.partySize}',
                          style: t.bodySmall?.copyWith(color: scheme.onSurface.withOpacity(0.7)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${d.cuisine} • ${d.neighborhood}',
                          style: t.bodySmall?.copyWith(color: scheme.onSurface.withOpacity(0.65)),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('\$${d.estimatedCostUsd}', style: t.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 8),
                      _SmallActionButton(
                        label: busy ? 'Opening…' : 'Reserve',
                        icon: Icons.open_in_new_rounded,
                        busy: busy,
                        onPressed: busy
                            ? null
                            : () async {
                          setState(() => _busyRestaurant = d.restaurant);
                          try {
                            final booking = ref.read(bookingServiceProvider);
                            final url = await booking.getBookingUrl(
                              type: 'restaurant',
                              payload: {
                                'city': plan.destinationCity,
                                'restaurant': d.restaurant,
                                'date': plan.dates.start.toIso8601String().substring(0, 10),
                                'time': d.time,
                                'partySize': d.partySize,
                              },
                            );
                            await launchExternalUrl(url);
                          } finally {
                            if (mounted) setState(() => _busyRestaurant = null);
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({
    required this.label,
    required this.icon,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FilledButton.icon(
      onPressed: onPressed,
      icon: busy
          ? SizedBox(
        height: 16,
        width: 16,
        child: CircularProgressIndicator(strokeWidth: 2, color: scheme.onPrimary),
      )
          : Icon(icon, size: 18),
      label: Text(label),
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _SmallActionButton extends StatelessWidget {
  const _SmallActionButton({
    required this.label,
    required this.icon,
    required this.busy,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: scheme.primary.withOpacity(0.08),
          border: Border.all(color: scheme.primary.withOpacity(0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (busy)
              SizedBox(
                height: 14,
                width: 14,
                child: CircularProgressIndicator(strokeWidth: 2, color: scheme.primary),
              )
            else
              Icon(icon, size: 16, color: scheme.primary),
            const SizedBox(width: 8),
            Text(
              label,
              style: t.labelMedium?.copyWith(fontWeight: FontWeight.w900, color: scheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: scheme.secondary.withOpacity(0.10),
        border: Border.all(color: scheme.secondary.withOpacity(0.18)),
      ),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: scheme.secondary,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.title, required this.value});
  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: scheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: t.labelLarge?.copyWith(fontWeight: FontWeight.w900)),
              const SizedBox(height: 2),
              Text(
                value,
                style: t.bodySmall?.copyWith(color: scheme.onSurface.withOpacity(0.72), height: 1.25),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
