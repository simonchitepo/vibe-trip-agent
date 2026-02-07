import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

class SseEvent {
  SseEvent({required this.event, required this.data});
  final String event;
  final String data;
}

typedef SseOnEvent = void Function(SseEvent event);

class SseClient {
  SseClient(this._dio);

  final Dio _dio;

  Stream<SseEvent> postSse({
    required String url,
    required Map<String, dynamic> jsonBody,
    Map<String, String> headers = const {},
  }) async* {
    final res = await _dio.post<ResponseBody>(
      url,
      data: jsonBody,
      options: Options(
        responseType: ResponseType.stream,
        headers: <String, dynamic>{
          'Accept': 'text/event-stream',
          'Cache-Control': 'no-cache',
          'Content-Type': 'application/json',
          ...headers,
        },
      ),
    );

    final body = res.data;
    if (body == null) {
      throw StateError('Empty SSE response body');
    }

    final Stream<String> stream = utf8.decoder.bind(body.stream.cast<List<int>>());

    final buffer = StringBuffer();

    await for (final chunk in stream) {
      buffer.write(chunk);
      var text = buffer.toString();

      while (true) {
        final idx = text.indexOf('\n\n');
        if (idx == -1) break;

        final frame = text.substring(0, idx);
        text = text.substring(idx + 2);

        if (frame.trim().isEmpty) continue;

        String eventName = 'message';
        final dataLines = <String>[];

        for (final rawLine in frame.split('\n')) {
          final line = rawLine.trimRight();
          if (line.startsWith('event:')) {
            eventName = line.substring('event:'.length).trim();
          } else if (line.startsWith('data:')) {
            dataLines.add(line.substring('data:'.length).trimLeft());
          }
        }

        if (dataLines.isNotEmpty) {
          yield SseEvent(event: eventName, data: dataLines.join('\n'));
        }
      }

      buffer
        ..clear()
        ..write(text);
    }
  }
}
