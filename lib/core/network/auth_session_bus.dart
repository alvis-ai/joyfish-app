import 'dart:async';

enum AuthSessionEvent { expired }

class AuthSessionBus {
  static final StreamController<AuthSessionEvent> _controller =
      StreamController<AuthSessionEvent>.broadcast();

  static Stream<AuthSessionEvent> get stream => _controller.stream;

  static void emitExpired() {
    if (!_controller.isClosed) {
      _controller.add(AuthSessionEvent.expired);
    }
  }
}
