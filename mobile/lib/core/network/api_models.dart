import 'dart:convert';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';

class Attachment extends Equatable {
  const Attachment({required this.bytes, required this.mimeType});

  final Uint8List bytes;
  final String mimeType;

  Map<String, Object?> toJson() => {
    'mimeType': mimeType,
    'dataBase64': base64Encode(bytes),
  };

  @override
  List<Object?> get props => [bytes, mimeType];
}

class GenUiRequest {
  const GenUiRequest({
    required this.sessionId,
    this.text = '',
    this.attachments = const [],
    this.a2uiMessages = const [],
  });

  final String sessionId;
  final String text;
  final List<Attachment> attachments;
  final List<Map<String, Object?>> a2uiMessages;

  Map<String, Object?> toJson() => {
    'sessionId': sessionId,
    'userId': 'mobile-user',
    'text': text,
    'attachments': attachments.map((a) => a.toJson()).toList(),
    if (a2uiMessages.isNotEmpty) 'a2ui': {'messages': a2uiMessages},
  };
}

sealed class BackendEvent {
  const BackendEvent();
}

class StatusEvent extends BackendEvent {
  const StatusEvent(this.label);
  final String label;
}

class TextEvent extends BackendEvent {
  const TextEvent(this.markdown);
  final String markdown;
}

class A2uiEvent extends BackendEvent {
  const A2uiEvent(this.message);
  final Map<String, Object?> message;
}

class ErrorEvent extends BackendEvent {
  const ErrorEvent(this.message);
  final String message;
}

class DoneEvent extends BackendEvent {
  const DoneEvent();
}

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}
