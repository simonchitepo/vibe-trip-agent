import 'dart:convert';

import 'models.dart';

class PlanParser {
  TripPlan parse({
    required String vibe,
    required int budgetUsd,
    required String jsonText,
  }) {
    final obj = json.decode(_extractJson(jsonText)) as Map<String, dynamic>;

    final datesObj = obj['dates'] as Map<String, dynamic>;
    final start = DateTime.parse(datesObj['start'] as String);
    final end = DateTime.parse(datesObj['end'] as String);

    final flights = (obj['flights'] as List<dynamic>).map((e) {
      final m = e as Map<String, dynamic>;
      return FlightOption(
        airline: m['airline'] as String,
        from: m['from'] as String,
        to: m['to'] as String,
        departLocal: DateTime.parse(m['departLocal'] as String),
        arriveLocal: DateTime.parse(m['arriveLocal'] as String),
        stops: (m['stops'] as num).toInt(),
        priceUsd: (m['priceUsd'] as num).toInt(),
        carbonKg: (m['carbonKg'] as num).toInt(),
      );
    }).toList();

    final hotelObj = obj['hotel'] as Map<String, dynamic>;
    final hotel = HotelOption(
      name: hotelObj['name'] as String,
      area: hotelObj['area'] as String,
      rating: (hotelObj['rating'] as num).toDouble(),
      pricePerNightUsd: (hotelObj['pricePerNightUsd'] as num).toInt(),
      perks: (hotelObj['perks'] as List<dynamic>).cast<String>(),
    );

    final transitObj = obj['transit'] as Map<String, dynamic>;
    final transit = TransitPlan(
      airportToHotel: transitObj['airportToHotel'] as String,
      dayPass: transitObj['dayPass'] as String,
      totalCostUsd: (transitObj['totalCostUsd'] as num).toInt(),
      notes: (transitObj['notes'] as List<dynamic>).cast<String>(),
    );

    final dinners = (obj['dinners'] as List<dynamic>).map((e) {
      final m = e as Map<String, dynamic>;
      return DinnerReservation(
        restaurant: m['restaurant'] as String,
        cuisine: m['cuisine'] as String,
        neighborhood: m['neighborhood'] as String,
        dayLabel: m['dayLabel'] as String,
        time: m['time'] as String,
        partySize: (m['partySize'] as num).toInt(),
        estimatedCostUsd: (m['estimatedCostUsd'] as num).toInt(),
      );
    }).toList();

    return TripPlan.create(
      vibe: vibe,
      summary: (obj['summary'] as String?) ?? '',
      budgetUsd: (obj['budgetUsd'] as num?)?.toInt() ?? budgetUsd,
      destinationCity: obj['destinationCity'] as String,
      dates: DateRange(start: start, end: end),
      flights: flights,
      hotel: hotel,
      transit: transit,
      dinners: dinners,
    );
  }

  String _extractJson(String s) {
    final start = s.indexOf('{');
    final end = s.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) {
      throw FormatException('No JSON object found in model output.');
    }
    return s.substring(start, end + 1);
  }
}
