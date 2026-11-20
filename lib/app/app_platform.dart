import 'package:flutter/services.dart';

/// Where Send feedback goes (owner's decision, plan 0009 decision 9). Kept
/// here only, in one place.
const feedbackAddress = 'faheemsameer10@gmail.com';

/// The few things Sahai asks Android for directly: its version, and an
/// email draft for Send feedback (M7 frames 15 and 17). Tests use a fake.
abstract interface class AppPlatform {
  /// The installed version, such as "0.7.0", or null if Android can't say.
  Future<String?> version();

  /// Opens the email app with [address] and [subject] filled in and the
  /// body empty. False when the phone has no email app.
  Future<bool> sendFeedback({required String address, required String subject});
}

/// Talks to `MainActivity.kt` over the "sahai/app" channel.
class ChannelAppPlatform implements AppPlatform {
  const ChannelAppPlatform();

  static const _channel = MethodChannel('sahai/app');

  @override
  Future<String?> version() => _channel.invokeMethod<String>('version');

  @override
  Future<bool> sendFeedback({
    required String address,
    required String subject,
  }) async =>
      await _channel.invokeMethod<bool>('sendFeedback', {
        'address': address,
        'subject': subject,
      }) ??
      false;
}
