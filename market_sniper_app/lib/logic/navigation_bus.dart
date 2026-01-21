import 'dart:async';

/// Simple event bus for navigating between decoupled screens/tabs.
/// Used to switch tabs in MainLayout from deep child widgets.
class NavigationBus {
  static final NavigationBus _instance = NavigationBus._internal();
  factory NavigationBus() => _instance;
  NavigationBus._internal();

  final _controller = StreamController<NavigationEvent>.broadcast();
  Stream<NavigationEvent> get events => _controller.stream;

  void navigate(int tabIndex, {Object? arguments}) {
    _controller.add(NavigationEvent(tabIndex, arguments: arguments));
  }

  void dispose() {
    _controller.close();
  }
}

class NavigationEvent {
  final int tabIndex;
  final Object? arguments;

  NavigationEvent(this.tabIndex, {this.arguments});
}
