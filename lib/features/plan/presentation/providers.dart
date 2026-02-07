import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/agent_service.dart';
import '../data/booking_service.dart';
import '../domain/models.dart';

const kBackendBaseUrl = 'https://vibe-trip-agent-362281276963.us-central1.run.app';

final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 12),
      sendTimeout: const Duration(seconds: 12),
   
      receiveTimeout: null,
      headers: const {'Content-Type': 'application/json'},
    ),
  );
});

final agentServiceProvider = Provider<AgentService>((ref) {
  final dio = ref.read(dioProvider);
  return LiveAgentService(
    baseUrl: kBackendBaseUrl,
    dio: dio,
  );
});

final bookingServiceProvider = Provider<BookingService>((ref) {
  final dio = ref.read(dioProvider);
  return BookingService(
    baseUrl: rememberNoTrailingSlash(kBackendBaseUrl),
    dio: dio,
  );
});

String rememberNoTrailingSlash(String s) => s.endsWith('/') ? s.substring(0, s.length - 1) : s;

final planControllerProvider =
NotifierProvider<PlanController, PlanState>(PlanController.new);

enum PlanStatus { idle, loading, ready, failure }

class PlanState {
  const PlanState._({
    required this.status,
    this.plan,
    this.partialText,
    this.error,
  });

  final PlanStatus status;
  final TripPlan? plan;

  final String? partialText;

  final String? error;

  const PlanState.idle() : this._(status: PlanStatus.idle);

  const PlanState.loading({String partialText = ''})
      : this._(status: PlanStatus.loading, partialText: partialText);

  const PlanState.ready(TripPlan plan)
      : this._(status: PlanStatus.ready, plan: plan);

  const PlanState.failure(String error)
      : this._(status: PlanStatus.failure, error: error);
}

class PlanController extends Notifier<PlanState> {
  Timer? _flushTicker;
  final StringBuffer _buffer = StringBuffer();
  static const Duration _flushEvery = Duration(milliseconds: 100);
  static const int _maxPreviewChars = 4500;
  static const int _maxBufferChars = 12000;

  @override
  PlanState build() {
    ref.onDispose(() {
      _stopTicker();
    });
    return const PlanState.idle();
  }

  void _stopTicker() {
    _flushTicker?.cancel();
    _flushTicker = null;
    _buffer.clear();
  }

  void _startTickerIfNeeded() {
    _flushTicker ??= Timer.periodic(_flushEvery, (_) {
      if (state.status != PlanStatus.loading) return;
      if (_buffer.isEmpty) return;

      final cur = state.partialText ?? '';
      final next = cur + _buffer.toString();
      _buffer.clear();

      final trimmed = next.length > _maxPreviewChars
          ? next.substring(next.length - _maxPreviewChars)
          : next;

      state = PlanState.loading(partialText: trimmed);
    });
  }

  void _enqueueDelta(String d) {
    if (d.isEmpty) return;

    if (_buffer.length > _maxBufferChars) {
      final keep = _buffer.toString();
      _buffer.clear();
      final tail = keep.length > 1500 ? keep.substring(keep.length - 1500) : keep;
      _buffer.write(tail);
    }

    _buffer.write(d);
    _startTickerIfNeeded();
  }

  Future<void> generate({
    required String vibe,
    required int budgetUsd,
    required DateRange dates,
    required String fromAirportCode,
  }) async {
    // Reset
    _stopTicker();
    state = const PlanState.loading(partialText: '');

    try {
      final service = ref.read(agentServiceProvider);

      if (service is LiveAgentService) {
        final plan = await service.buildPlanStreaming(
          vibe: vibe,
          budgetUsd: budgetUsd,
          dates: dates,
          fromAirportCode: fromAirportCode,
          onDelta: (d) => _enqueueDelta(d),
        );

        if (_buffer.isNotEmpty) {
          final cur = state.partialText ?? '';
          final next = cur + _buffer.toString();
          _buffer.clear();

          final trimmed = next.length > _maxPreviewChars
              ? next.substring(next.length - _maxPreviewChars)
              : next;

          state = PlanState.loading(partialText: trimmed);
        }

        _stopTicker();
        state = PlanState.ready(plan);
        return;
      }

      final plan = await service.buildPlan(
        vibe: vibe,
        budgetUsd: budgetUsd,
        dates: dates,
        fromAirportCode: fromAirportCode,
      );

      _stopTicker();
      state = PlanState.ready(plan);
    } catch (e) {
      _stopTicker();
      state = PlanState.failure('Failed to generate plan: $e');
    }
  }

  void reset() {
    _stopTicker();
    state = const PlanState.idle();
  }
}
