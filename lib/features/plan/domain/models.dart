import 'package:uuid/uuid.dart';

final _uuid = const Uuid();

class TripPlan {
  TripPlan({
    required this.id,
    required this.vibe,
    required this.summary,
    required this.budgetUsd,
    required this.destinationCity,
    required this.dates,
    required this.flights,
    required this.hotel,
    required this.transit,
    required this.dinners,
  });

  factory TripPlan.create({
    required String vibe,
    required String summary,
    required int budgetUsd,
    required String destinationCity,
    required DateRange dates,
    required List<FlightOption> flights,
    required HotelOption hotel,
    required TransitPlan transit,
    required List<DinnerReservation> dinners,
  }) {
    return TripPlan(
      id: _uuid.v4(),
      vibe: vibe,
      summary: summary,
      budgetUsd: budgetUsd,
      destinationCity: destinationCity,
      dates: dates,
      flights: flights,
      hotel: hotel,
      transit: transit,
      dinners: dinners,
    );
  }

  final String id;
  final String vibe;
  final String summary;
  final int budgetUsd;
  final String destinationCity;
  final DateRange dates;
  final List<FlightOption> flights;
  final HotelOption hotel;
  final TransitPlan transit;
  final List<DinnerReservation> dinners;
}

class DateRange {
  DateRange({required this.start, required this.end});
  final DateTime start;
  final DateTime end;

  int get nights => end.difference(start).inDays;

  String get iso => '${start.toIso8601String().split('T').first} → ${end.toIso8601String().split('T').first}';
}

class MoneyBreakdown {
  MoneyBreakdown({
    required this.flights,
    required this.hotel,
    required this.transit,
    required this.dining,
    required this.buffer,
  });

  final int flights;
  final int hotel;
  final int transit;
  final int dining;
  final int buffer;

  int get total => flights + hotel + transit + dining + buffer;
}

class FlightOption {
  FlightOption({
    required this.airline,
    required this.from,
    required this.to,
    required this.departLocal,
    required this.arriveLocal,
    required this.stops,
    required this.priceUsd,
    required this.carbonKg,
  });

  final String airline;
  final String from;
  final String to;
  final DateTime departLocal;
  final DateTime arriveLocal;
  final int stops;
  final int priceUsd;
  final int carbonKg;

  Duration get duration => arriveLocal.difference(departLocal);
}

class HotelOption {
  HotelOption({
    required this.name,
    required this.area,
    required this.rating,
    required this.pricePerNightUsd,
    required this.perks,
  });

  final String name;
  final String area;
  final double rating;
  final int pricePerNightUsd;
  final List<String> perks;
}

class TransitPlan {
  TransitPlan({
    required this.airportToHotel,
    required this.dayPass,
    required this.totalCostUsd,
    required this.notes,
  });

  final String airportToHotel;
  final String dayPass;
  final int totalCostUsd;
  final List<String> notes;
}

class DinnerReservation {
  DinnerReservation({
    required this.restaurant,
    required this.cuisine,
    required this.neighborhood,
    required this.dayLabel,
    required this.time,
    required this.partySize,
    required this.estimatedCostUsd,
  });

  final String restaurant;
  final String cuisine;
  final String neighborhood;
  final String dayLabel;
  final String time;
  final int partySize;
  final int estimatedCostUsd;
}
