import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

class WarRoomRouteObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _checkRoute(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    if (previousRoute != null) {
      _checkRoute(previousRoute);
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    if (newRoute != null) {
      _checkRoute(newRoute);
    }
  }

  void _checkRoute(Route<dynamic> route) {
    // Check by name or type
    final name = route.settings.name;
    final isActive = (name == '/war_room');
    
    if (AppConfig.isNetAuditEnabled) {
      debugPrint("WAR_ROOM_OBSERVER: Route Push/Pop -> '$name'. WAR_ROOM_ACTIVE will be: $isActive");
    }

    // Toggle Policy
    // D72: Wrap setter to avoid redundant calls or fighting ENV SSOT
    if (AppConfig.isWarRoomActive != isActive) {
      AppConfig.setWarRoomActive(isActive);
    }
    
    if (AppConfig.isNetAuditEnabled) {
      debugPrint("WAR_ROOM_OBSERVER: AppConfig.isWarRoomActive is now: ${AppConfig.isWarRoomActive}");
    }
  }
}
