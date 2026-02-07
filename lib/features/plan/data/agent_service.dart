import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../domain/models.dart';

abstract class AgentService {
  Future<TripPlan> buildPlan({
    required String vibe,
    required int budgetUsd,
    required DateRange dates,
    required String fromAirportCode,
  });
}

class LiveAgentService implements AgentService {
  LiveAgentService({
    required String baseUrl,
    Dio? dio,
    Duration connectTimeout = const Duration(seconds: 12),
    Duration sendTimeout = const Duration(seconds: 12),
  })  : _baseUrl = baseUrl.endsWith('/')
      ? baseUrl.substring(0, baseUrl.length - 1)
      : baseUrl,
        _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: connectTimeout,
                sendTimeout: sendTimeout,
                receiveTimeout: null, // streaming: no receive timeout
                headers: const {'Content-Type': 'application/json'},
              ),
            );

  final String _baseUrl;
  final Dio _dio;

  Future<TripPlan> buildPlanStreaming({
    required String vibe,
    required int budgetUsd,
    required DateRange dates,
    required String fromAirportCode,
    required void Function(String deltaText) onDelta,
  }) async {
    final url = '$_baseUrl/v1/plan/stream';

    final resp = await _dio.post<ResponseBody>(
      url,
      data: <String, dynamic>{
        'vibe': vibe,
        'budgetUsd': budgetUsd,
        'fromAirportCode': fromAirportCode,
        'startDate': _yyyyMmDd(dates.start),
        'endDate': _yyyyMmDd(dates.end),
      },
      options: Options(
        responseType: ResponseType.stream,
        headers: const {
          'Accept': 'text/event-stream',
          'Cache-Control': 'no-cache',
        },
      ),
    );

    final body = resp.data;
    if (body == null) {
      throw StateError('Empty SSE response body');
    }

    String finalText = '';

    final stream = utf8.decoder.bind(body.stream.cast<List<int>>());

    final buffer = StringBuffer();

    Future<void> handleFrame(String frame) async {
      String eventName = 'message';
      final dataLines = <String>[];

      for (final raw in frame.split('\n')) {
        final line = raw.trimRight();
        if (line.startsWith('event:')) {
          eventName = line.substring('event:'.length).trim();
        } else if (line.startsWith('data:')) {
          dataLines.add(line.substring('data:'.length).trimLeft());
        }
      }

      if (dataLines.isEmpty) return;
      final dataRaw = dataLines.join('\n');

      if (eventName == 'delta') {
        final obj = _safeJson(dataRaw);
        final d = (obj?['text'] as String?) ?? '';
        if (d.isNotEmpty) {
          onDelta(d);
          finalText += d;
        }
        return;
      }

      if (eventName == 'done') {
        final obj = _safeJson(dataRaw);
        final ft = (obj?['finalText'] as String?) ?? finalText;
        finalText = ft;
        return;
      }

      if (eventName == 'error') {
        final obj = _safeJson(dataRaw);
        final msg = (obj?['message'] as String?) ?? 'Unknown server error';
        throw Exception(msg);
      }

      final obj = _safeJson(dataRaw);
      final maybeText = (obj?['text'] as String?) ?? '';
      if (maybeText.isNotEmpty) {
        onDelta(maybeText);
        finalText += maybeText;
      }
    }

    await for (final chunk in stream) {
      buffer.write(chunk);
      var text = buffer.toString();

      while (true) {
        final idx = text.indexOf('\n\n');
        if (idx == -1) break;

        final frame = text.substring(0, idx);
        text = text.substring(idx + 2);

        if (frame.trim().isEmpty) continue;
        await handleFrame(frame);
      }

      buffer
        ..clear()
        ..write(text);
    }

    return _planFromModelOutput(
      vibe: vibe,
      fallbackBudget: budgetUsd,
      jsonText: finalText,
    );
  }

  @override
  Future<TripPlan> buildPlan({
    required String vibe,
    required int budgetUsd,
    required DateRange dates,
    required String fromAirportCode,
  }) async {
    return buildPlanStreaming(
      vibe: vibe,
      budgetUsd: budgetUsd,
      dates: dates,
      fromAirportCode: fromAirportCode,
      onDelta: (_) {},
    );
  }

  String _yyyyMmDd(DateTime d) {
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  Map<String, dynamic>? _safeJson(String s) {
    try {
      final v = jsonDecode(s);
      if (v is Map<String, dynamic>) return v;
      return null;
    } catch (_) {
      return null;
    }
  }

  TripPlan _planFromModelOutput({
    required String vibe,
    required int fallbackBudget,
    required String jsonText,
  }) {
    final extracted = _extractJsonObject(jsonText);
    final obj = jsonDecode(extracted) as Map<String, dynamic>;

    final datesObj = obj['dates'] as Map<String, dynamic>;
    final dates = DateRange(
      start: DateTime.parse(datesObj['start'] as String),
      end: DateTime.parse(datesObj['end'] as String),
    );

    final flights = (obj['flights'] as List<dynamic>).map((f) {
      final m = f as Map<String, dynamic>;
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

    final hotelJ = obj['hotel'] as Map<String, dynamic>;
    final hotel = HotelOption(
      name: hotelJ['name'] as String,
      area: hotelJ['area'] as String,
      rating: (hotelJ['rating'] as num).toDouble(),
      pricePerNightUsd: (hotelJ['pricePerNightUsd'] as num).toInt(),
      perks: (hotelJ['perks'] as List<dynamic>).map((x) => x.toString()).toList(),
    );

    final transitJ = obj['transit'] as Map<String, dynamic>;
    final transit = TransitPlan(
      airportToHotel: transitJ['airportToHotel'] as String,
      dayPass: transitJ['dayPass'] as String,
      totalCostUsd: (transitJ['totalCostUsd'] as num).toInt(),
      notes: (transitJ['notes'] as List<dynamic>).map((x) => x.toString()).toList(),
    );

    final dinners = (obj['dinners'] as List<dynamic>).map((d) {
      final m = d as Map<String, dynamic>;
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
      budgetUsd: (obj['budgetUsd'] as num?)?.toInt() ?? fallbackBudget,
      destinationCity: obj['destinationCity'] as String,
      dates: dates,
      flights: flights,
      hotel: hotel,
      transit: transit,
      dinners: dinners,
    );
  }

  String _extractJsonObject(String s) {
    final start = s.indexOf('{');
    final end = s.lastIndexOf('}');
    if (start == -1 || end == -1 || end <= start) {
      throw FormatException('No JSON object found in streamed model output.');
    }
    return s.substring(start, end + 1);
  }
}
