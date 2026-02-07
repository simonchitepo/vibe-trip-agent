import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../../../core/network/sse.dart';
import '../domain/models.dart';
import '../domain/plan_parser.dart';
import 'agent_service.dart';

class LiveAgentService implements AgentService {
  LiveAgentService({
    required Dio dio,
    required this.baseUrl,
  })  : _dio = dio,
        _sse = SseClient(dio),
        _parser = PlanParser();

  final Dio _dio;
  final SseClient _sse;
  final PlanParser _parser;

  final String baseUrl;

  Future<String?> getAuthToken() async => null;

  Future<TripPlan> buildPlanStreaming({
    required String vibe,
    required int budgetUsd,
    required DateRange dates,
    required String fromAirportCode,
    required void Function(String deltaText) onDelta,
  }) async {
    final url = '${_trim(baseUrl)}/v1/plan/stream';
    final token = await getAuthToken();

    bool gotAnyDelta = false;
    onDelta('Starting…\n');

    Timer? warmTimer;
    Timer? stillTimer;

    warmTimer = Timer(const Duration(milliseconds: 2200), () {
      if (!gotAnyDelta) onDelta('Warming up the AI…\n');
    });

    stillTimer = Timer(const Duration(seconds: 8), () {
      if (!gotAnyDelta) onDelta('Still working… (this can happen on first request)\n');
    });

    String finalText = '';

    try {
      final stream = _sse.postSse(
        url: url,
        jsonBody: {
          'vibe': vibe,
          'budgetUsd': budgetUsd,
          'fromAirportCode': fromAirportCode,
          'startDate': dates.start.toIso8601String().split('T').first,
          'endDate': dates.end.toIso8601String().split('T').first,
        },
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      await for (final evt in stream) {
        if (evt.event == 'delta') {
          gotAnyDelta = true;
          final obj = json.decode(evt.data) as Map<String, dynamic>;
          final d = (obj['text'] as String?) ?? '';
          if (d.isNotEmpty) {
            onDelta(d);
            finalText += d;
          }
        } else if (evt.event == 'done') {
          final obj = json.decode(evt.data) as Map<String, dynamic>;
          finalText = (obj['finalText'] as String?) ?? finalText;
          break;
        } else if (evt.event == 'error') {
          final obj = json.decode(evt.data) as Map<String, dynamic>;
          throw Exception(obj['message'] ?? 'Unknown server error');
        }
      }
    } finally {
      warmTimer?.cancel();
      stillTimer?.cancel();
    }

    return _parser.parse(vibe: vibe, budgetUsd: budgetUsd, jsonText: finalText);
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

  String _trim(String s) => s.endsWith('/') ? s.substring(0, s.length - 1) : s;
}
