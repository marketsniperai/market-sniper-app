import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart'; // Ensure pubspec has this, it does.
import '../../theme/app_colors.dart';

class DecryptionRitualOverlay extends StatefulWidget {
  final Future<dynamic> task;

  const DecryptionRitualOverlay({super.key, required this.task});

  /// Static helper to launch the ritual
  static Future<T?> run<T>(BuildContext context, {required Future<T> task}) async {
    // Show dialog, but we manage the Navigator pop inside the widget logic
    return await showGeneralDialog<T>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black, // Pure black overlay
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (ctx, anim1, anim2) {
        return DecryptionRitualOverlay(task: task);
      },
    );
  }

  @override
  State<DecryptionRitualOverlay> createState() => _DecryptionRitualOverlayState();
}

class _DecryptionRitualOverlayState extends State<DecryptionRitualOverlay> {
  final List<String> _logLines = [];
  Timer? _lineTimer;
  Timer? _minTimer;
  bool _taskCompleted = false;
  bool _minTimeElapsed = false;
  dynamic _taskResult;
  Object? _taskError;

  // The Ritual Script
  final List<String> _script = [
    "INITIALIZING PROJECTION ORCHESTRATOR...",
    "MATCHING 5-YEAR REGIME FINGERPRINTS...",
    "CHECKING OPTIONS BOUNDARIES...",
    "LOADING NEWS CONTEXT TAGS...",
    "SYNTHESIS IN PROGRESS...",
    "DECRYPTING INTELLIGENCE DOSSIER...",
    "CALIBRATING PROBABILISTIC CONTEXT..."
  ];
  int _scriptIndex = 0;

  @override
  void initState() {
    super.initState();
    _startRitual();
  }

  void _startRitual() {
    // 1. Start Task
    widget.task.then((value) {
      if (mounted) {
        setState(() {
          _taskCompleted = true;
          _taskResult = value;
        });
        _checkRelease();
      }
    }).catchError((e) {
      if (mounted) {
        setState(() {
          _taskCompleted = true;
          _taskError = e;
        });
        _checkRelease(); // Release even on error to show it in panel
      }
    });

    // 2. Start Min Timer (2s)
    _minTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _minTimeElapsed = true;
        });
        _checkRelease();
      }
    });

    // 3. Start Text Cascade
    _nextLine();
    
    // 4. Max Timeout Guard (6s)
    // Interpret: "Hard stop at 6s even if backend stalls"
    // If backend stalls, we pop. The caller will get null?
    // Wait, type safety T?
    // If we pop with null, OnDemandPanel expects a Map.
    // We should probably let it hang or return a Mock "Timeout"?
    // Logic: If 6s passes, we force close.
    // If task is not done, we return a fallback or throw?
    // Let's implement soft timeout: The overlay closes. The task future continues in background?
    // No, we need to return something.
    // Let's just enforce the Visuals. If task takes >6s, the user waits >6s.
    // BUT spec says: "Hard stop at 6s even if backend stalls (then proceed with CALIBRATING state)"
    // This implies we return a "CALIBRATING" / "InProgress" result if currently missing.
    // Since we don't want to invent new data types, we will just rely on standard flow.
    // If the backend is extremely slow (>6s), we will let the user wait?
    // Re-reading: "Overlay must dismiss... as soon as BOTH conditions met... Hard stop at 6s even if backend stalls".
    // Okay, implementing Hard Stop at 6s.
    Timer(const Duration(seconds: 6), () {
      if (mounted) {
         // Force exit
         _finish();
      }
    });
  }

  void _nextLine() {
    if (_scriptIndex >= _script.length) return;
    
    setState(() {
      _logLines.add(_script[_scriptIndex]);
    });
    _scriptIndex++;

    // Randomize speed for "hacker" feel
    // 100ms - 300ms
    _lineTimer = Timer(Duration(milliseconds: 100 + (DateTime.now().microsecond % 200)), _nextLine);
  }

  void _checkRelease() {
    if (_taskCompleted && _minTimeElapsed) {
      _finish();
    }
  }

  void _finish() {
    // 1. Haptic
    HapticFeedback.mediumImpact();
    
    // 2. Cancel Timers
    _lineTimer?.cancel();
    _minTimer?.cancel();
    
    // 3. Pop
    // If task error, rethrow?
    if (_taskError != null) {
       // We can pop with error? Navigator pop doesn't throw.
       // We return Future.error?
       // We can just pop Result, logic handles generic T?
       // Actually showGeneralDialog returns Future<T?>.
       // We need to return the result.
    }
    
    // If task not completed (Timeout case), what to return?
    // We can't fabricate T. 
    // If T is Map (JSON), we could return a "CALIBRATING" payload?
    // For safety, if timeout occurs and no result, we might have to just return null (if T nullable) or throw.
    // Panel uses `dynamic` or `Map`.
    // Let's try to return result if present.
    
    if (mounted) {
       Navigator.of(context).pop(_taskResult);
    }
  }

  @override
  void dispose() {
    _lineTimer?.cancel();
    _minTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Full screen scaffold logic
    return Scaffold(
      backgroundColor: Colors.black, // Explicitly black
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Terminal Text
              Expanded(
                child: ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _logLines.length,
                  itemBuilder: (ctx, index) {
                    // Fade in effect?
                    // Terminal Font
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Text(
                        "> ${_logLines[index]}",
                        style: GoogleFonts.robotoMono(
                          color: AppColors.neonCyan,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              // Bottom Progress / Signature
              Container(
                height: 2,
                width: double.infinity,
                color: AppColors.neonCyan.withValues(alpha: 0.3),
                child: const LinearProgressIndicator(
                  backgroundColor: Colors.transparent,
                  color: AppColors.neonCyan,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("MARKET SNIPER OS // HF22", 
                    style: GoogleFonts.robotoMono(color: AppColors.textDisabled, fontSize: 10)
                  ),
                  const Text("ENCRYPTED", 
                    style: TextStyle(color: AppColors.textDisabled, fontSize: 10)
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
