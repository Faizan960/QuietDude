import 'package:flutter/services.dart';

class PlatformChannelException implements Exception {
  const PlatformChannelException(this.operation, this.cause);

  final String operation;
  final Object cause;

  @override
  String toString() => 'PlatformChannelException($operation): $cause';
}

class PlatformChannel {
  PlatformChannel({
    MethodChannel? methodChannel,
    EventChannel? eventChannel,
    EventChannel? listenerStatusEventChannel,
  }) : _methodChannel = methodChannel ?? const MethodChannel(methodChannelName),
       _eventChannel = eventChannel ?? const EventChannel(eventChannelName),
       _listenerStatusEventChannel =
           listenerStatusEventChannel ??
           const EventChannel(listenerStatusEventChannelName);

  static const methodChannelName = 'com.example.notification_privacy/platform';
  static const eventChannelName =
      'com.example.notification_privacy/platform_events';
  static const listenerStatusEventChannelName =
      'com.example.notification_privacy/listener_status_events';

  final MethodChannel _methodChannel;
  final EventChannel _eventChannel;
  final EventChannel _listenerStatusEventChannel;

  Future<Object?> invokeMethod(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    try {
      return await _methodChannel.invokeMethod<Object?>(method, arguments);
    } on PlatformException catch (error) {
      throw PlatformChannelException(method, error);
    } on MissingPluginException catch (error) {
      throw PlatformChannelException(method, error);
    }
  }

  Future<List<Object?>?> invokeListMethod(
    String method, [
    Map<String, Object?>? arguments,
  ]) async {
    try {
      return await _methodChannel.invokeListMethod<Object?>(method, arguments);
    } on PlatformException catch (error) {
      throw PlatformChannelException(method, error);
    } on MissingPluginException catch (error) {
      throw PlatformChannelException(method, error);
    }
  }

  Stream<Object?> get events => _eventChannel.receiveBroadcastStream();

  Stream<Object?> get listenerStatusEvents =>
      _listenerStatusEventChannel.receiveBroadcastStream();
}
