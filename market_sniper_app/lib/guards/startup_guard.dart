import 'package:flutter/material.dart';
import '../services/invite_service.dart';
import '../config/app_config.dart';
import '../theme/app_colors.dart';

class StartupGuard extends StatefulWidget {
  final Widget child;
  const StartupGuard({super.key, required this.child});

  @override
  State<StartupGuard> createState() => _StartupGuardState();
}

class _StartupGuardState extends State<StartupGuard> {
  bool _authorized = false;
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    // 1. If Invite Disabled -> Pass
    if (!AppConfig.inviteEnabled) {
      setState(() {
        _authorized = true;
        _checking = false;
      });
      return;
    }

    // 2. Check Service Logic
    // Service must be initialized by main() ideally, but safe to call init() again idempotent
    await InviteService().init();

    final valid = await InviteService().isGateSatisfied();

    if (valid) {
      setState(() {
        _authorized = true;
        _checking = false;
      });
    } else {
      // Bounce
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/welcome');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(backgroundColor: AppColors.bgPrimary); // Invisible Loading
    }
    if (_authorized) {
      return widget.child;
    }
    return const SizedBox.shrink(); // Should have bounced
  }
}
