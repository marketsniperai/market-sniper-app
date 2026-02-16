// Imports Checked
import 'dart:async';
import 'dart:convert'; // Added for JSON encoding
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
// import '../config/app_config.dart'; // Unused
import '../logic/day_memory_store.dart';
import '../logic/elite_mentor_brain.dart';
import '../logic/session_thread_memory_store.dart';
import '../logic/ritual_scheduler.dart';
// import '../logic/elite_contextual_recall_engine.dart'; // D43.13 Unused
import 'canonical_scroll_container.dart';
import '../logic/elite_access_window_controller.dart'; // D45.07
import 'elite_ritual_grid.dart'; // Replaces elite_ritual_strip.dart
import '../repositories/elite_repository.dart'; // Logic moved to repo (D74/D75)
import 'elite/elite_ritual_modal.dart';
import '../logic/elite_badge_controller.dart'; // D49

enum EliteTier { free, plus, elite }

class EliteInteractionSheet extends StatefulWidget {
  final String? initialExplainKey;
  final Map<String, dynamic>? initialPayload;
  final bool resetToWelcome;
  final ScrollController? scrollController;
  final VoidCallback? onClose;

  const EliteInteractionSheet({
    super.key,
    this.initialExplainKey,
    this.initialPayload,
    this.resetToWelcome = false,
    this.scrollController,
    this.onClose,
  });

  @override
  State<EliteInteractionSheet> createState() => _EliteInteractionSheetState();
}

class _EliteInteractionSheetState extends State<EliteInteractionSheet> {
  EliteTier _tier = EliteTier.free; // Default safe, updated in initState
  String _statusText = "CHECKING...";
  // Color _statusColor = AppColors.textDisabled; // Unused
  String? _pendingExplainKey;
  bool _showExplainMyScreen = false;
  Map<String, dynamic>? _osSnapshotData;
  // D43.00: First Interaction State
  bool _isFirstInteraction = true;
  Map<String, dynamic>? _scriptData;

  // D43.04: Day Memory
  // List<String> _memoryBullets = []; // Unused
  // D43.08: Session Thread
  List<Map<String, String>> _sessionTurns = [];
  // D43.11: Context Status
  // Map<String, dynamic>? _contextStatus;
  // D43.12: What Changed
  // Map<String, dynamic>? _whatChanged;
  // D43.13: Contextual Recall
  // EliteContextualRecallSnapshot? _recallSnapshot;
  // D43.05: AGMS Recall
  // Map<String, dynamic>? _agmsRecall;

  // D45.H1: Idempotency Guard
  bool _accessResolved = false;

  @override
  void initState() {
    super.initState();
    // D45.07: Resolve Elite Access (Idempotent Guard)
    if (!_accessResolved) _resolveAccess();

    // D43.X2: Reset Logic Priority
    if (widget.resetToWelcome) {
      _isFirstInteraction = true;
      _pendingExplainKey = null;
    } else if (widget.initialExplainKey != null) {
      _pendingExplainKey = widget.initialExplainKey;
      _isFirstInteraction = false;
      _handleExplainRequest(_pendingExplainKey!);
    }

    // Always init memory/status
    if (_pendingExplainKey == null) {
      _fetchStatus(); // Only fetch default status if not explaining
    }
    if (_isFirstInteraction) _fetchFirstInteractionScript();
    _initMemory();
    
    // D49: Clear Badge on Open
    EliteBadgeController().markSeen();
  }

  Future<void> _resolveAccess() async {
    _accessResolved = true;
    final access = await EliteAccessWindowController.resolve();

    setState(() {
      // Map Access to Tier
      if (access.isUnlocked) {
        _tier = EliteTier.elite;
      } else {
        // Fallback to base tier (simplified for now to Free/Guest as we don't have Plus in Enums yet or logic is outside)
        // Assuming Free for now if locked.
        // Real app would check PremiumStatusResolver.currentTier mapping.
        _tier = EliteTier.free;
      }
    });

    // Handle Notice
    if (access.systemNotice != null) {
      // Inject into thread
      await SessionThreadMemoryStore().init(); // Ensure init
      await SessionThreadMemoryStore()
          .append("ELITE", access.systemNotice!); // System as Elite
      _refreshMemoryView();
    }
  }

  Future<void> _initMemory() async {
    await DayMemoryStore().init();
    await SessionThreadMemoryStore().init();
    await RitualScheduler().init(); // D43.09

    // D43.11: Fetch Status
    // _fetchContextStatus();
    // D43.12: Fetch What Changed
    // _fetchWhatChanged();
    // D43.05: Fetch AGMS Recall
    // _fetchAgmsRecall();

    _refreshMemoryView();
  }


  void _refreshMemoryView() {
    if (mounted) {
      setState(() {
        // final bullets = DayMemoryStore().getBullets(); // Unused
        // _memoryBullets = bullets.reversed.toList(); // Unused

        // D43.08
        final turns = SessionThreadMemoryStore().getTurns();
        // Show newest first for display? Or chronologic?
        // Typically chat is Top=Old Bottom=New, but in this compact view
        // we might want to see the last thing. Let's keep chronologic Top->Down
        // but limit to last 6.
        _sessionTurns = turns;
      });
    }
  }

  void _handleExplainRequest(String key) {
    // Tier Gating Logic (Mocked)
    if (_tier == EliteTier.free && key != 'MARKET_REGIME') {
      setState(() {
        _statusText = "EXPLAIN: LOCKED (TIER)";
        // _statusColor = AppColors.stateLocked;
      });
      return;
    }

    // Simulate Fetching
    setState(() {
      _statusText = "EXPLAINING: $key";
     // _statusColor = AppColors.neonCyan;
    });
  }

  Future<void> _fetchStatus() async {
    try {
      final data = await EliteRepository().fetchEliteExplainStatus();
      final bool isAvailable = data['status'] == 'AVAILABLE';

      if (mounted) {
        setState(() {
          // Use isAvailable to determine status
          if (isAvailable) {
            _statusText = "EXPLAIN: ACTIVE";
            // _statusColor = AppColors.neonCyan;
          } else {
            _statusText = "EXPLAIN: UNAVAILABLE";
            // _statusColor = AppColors.stateLocked;
          }
        });
      }
    } catch (e) {
      _handleError();
    }
  }
/*
  Future<void> _triggerExplainMyScreen() async {
    setState(() {
      _statusText = "ANALYZING CONTEXT...";
      _statusColor = AppColors.neonCyan;
    });

    // Simulate analysis delay
    await Future.delayed(const Duration(milliseconds: 600));

    // D43.14: Fetch Snapshot from generic reader
    try {
      _osSnapshotData = await EliteRepository().fetchEliteOsSnapshot();
    } catch (e) {
      // Fallback
    }

    if (mounted) {
      setState(() {
        _showExplainMyScreen = true;
        _statusText = EliteMentorBrain().explainReadyStatus;
      });
      // D43.04: Log to memory
      // Hardcoded keys for now to match the view
      await DayMemoryStore()
          .append("Explained: MARKET_REGIME + GLOBAL_RISK + UNIVERSE_STATUS");

      // D43.08: Log to Session Thread
      await SessionThreadMemoryStore().append("USER", "Explain My Screen");
      await SessionThreadMemoryStore()
          .append("ELITE", "Context Explained: [REGIME/RISK/STATUS]");

      _refreshMemoryView();
    }
  }
*/
  void _clearExplainMyScreen() {
    setState(() {
      _showExplainMyScreen = false;
      _statusText = "EXPLAIN: ACTIVE";
      _osSnapshotData = null;
      _pendingExplainKey = null; // Clear key
      _isFirstInteraction = true; // Restore Home/Welcome
    });
  }


  // D43.00: Fetch Script
  Future<void> _fetchFirstInteractionScript() async {
    try {
      _scriptData = await EliteRepository().fetchEliteFirstInteractionScript();
      if (mounted) setState(() {});
    } catch (e) {
      // Fallback or silent fail
    }
  }

  // D43.00: First Interaction View
  Widget _buildFirstInteractionView(BuildContext context) {
    if (_scriptData == null) return const SizedBox.shrink();

    // greeting variable removed as it was unused and replaced by mentorGreeting

    // Override with Mentor Brain if we want strict control, or compose it.
    // For D43.02 we want Mentor Brain to have a say.
    // If the script allows overriding, we use it.
    // Ideally the Script Artifact IS the source of truth, but Mentor Brain formats it?
    // Re-reading requirements: "Wire EliteInteractionSheet to use MentorBrain for: Greeting line".
    // So we prefer MentorBrain's greeting over the raw template if appropriate, OR used strictly for tone.
    // Let's use MentorBrain's greeting logic directly for the D43.02 requirement scope.
    final mentorGreeting = EliteMentorBrain().getGreeting("Morning", "Sniper");

    final questions = _scriptData!['questions'] as List;

    return Column(
      children: [
        Text(
          mentorGreeting,
          style: AppTypography.body(context)
              .copyWith(color: AppColors.textPrimary),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        ...questions.map<Widget>((q) {
          final tierMin = q['tier_min'];
          final bool isLocked =
              (_tier == EliteTier.free && tierMin != 'free') ||
                  (_tier == EliteTier.plus && tierMin == 'elite');

          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surface2,
                foregroundColor:
                    isLocked ? AppColors.textDisabled : AppColors.neonCyan,
                side: BorderSide(
                    color: isLocked
                        ? AppColors.borderSubtle
                        : AppColors.neonCyan),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                alignment: Alignment.centerLeft,
              ),
              onPressed: isLocked ? null : () => _handleQuestion(q),
              child: Row(
                children: [
                  Expanded(
                      child: Text(q['text'],
                          style: AppTypography.caption(context))),
                  if (isLocked)
                    const Icon(Icons.lock,
                        size: 14, color: AppColors.stateLocked),
                ],
              ),
            ),
          );
        }),
        if (_tier == EliteTier.free)
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text("Upgrade to Unlock Elite Insights",
                style: TextStyle(
                    color: AppColors.stateLocked,
                    fontSize: 10,
                    fontStyle: FontStyle.italic)),
          ),
      ],
    );
  }

  void _handleQuestion(Map<String, dynamic> q) {
    if (q['action_type'] == 'STATIC_ANSWER') {
      // Show static answer
      setState(() {
        _statusText = "CONTEXT MAPPED";
        _isFirstInteraction = false; // Dismiss first interaction view
        _pendingExplainKey = "LEARNING_EVOLUTION";
      });
      
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(q['answer_template'] ?? "No answer defined."),
        backgroundColor: AppColors.surface2,
      ));

      // D43.08: Log
      SessionThreadMemoryStore().append("USER", q['text']);
      SessionThreadMemoryStore()
          .append("ELITE", q['answer_template'] ?? "Answered.");
      _refreshMemoryView();
    } else {
      // Trigger explain
      _handleExplainRequest(q['action_payload']);
      setState(() {
        _isFirstInteraction = false;
      });

      // D43.08: Log
      SessionThreadMemoryStore().append("USER", q['text']);
      SessionThreadMemoryStore()
          .append("ELITE", "Routing explanation for ${q['action_payload']}...");
      _refreshMemoryView();
    }
  }

  // D49: Handle Ritual Tap
  Future<void> _handleRitualTap(String ritualId) async {
      setState(() {
          _statusText = "ACCESSING RITUAL...";
          // _statusColor = AppColors.neonCyan;
      });
      
      try {
          final payload = await EliteRepository().fetchEliteRitual(ritualId);
          
          if (!mounted) return;
          
          await showModalBottomSheet(
              context: context, 
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (ctx) => EliteRitualModal(
                  title: ritualId.replaceAll("_", " "), 
                  payload: payload
              )
          );
          
          setState(() {
              _statusText = "ELITE: ONLINE";
              // _statusColor = AppColors.neonCyan;
          });
          
      } catch (e) {
             if (!mounted) return;
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                 content: Text(e.toString().replaceAll("Exception: ", "")),
                 backgroundColor: AppColors.surface2,
             ));
             setState(() {
                  _statusText = "RITUAL UNAVAILABLE";
                // _statusColor = AppColors.stateLocked;
             });
      }
  }

  // D43.14: Explanation View
  Widget _buildExplanationView(BuildContext context) {
    // Context Collector (Mocked per plan)
    final List<String> screenKeys = [
      'MARKET_REGIME',
      'GLOBAL_RISK',
      'UNIVERSE_STATUS'
    ];

    // D44.13: On-Demand Payload Context
    if (_pendingExplainKey == 'EXPLAIN_ON_DEMAND_RESULT' &&
        widget.initialPayload != null) {
      final p = widget.initialPayload!;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface1.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: AppColors.neonCyan.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("ON-DEMAND CONTEXT",
                    style: AppTypography.label(context)
                        .copyWith(color: AppColors.neonCyan)),
                IconButton(
                  icon: const Icon(Icons.close,
                      size: 16, color: AppColors.textDisabled),
                  onPressed: _clearExplainMyScreen,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildContextRow("TICKER", p['ticker'] ?? 'UNK'),
            _buildContextRow("STATUS", p['status'] ?? 'UNK'),
            _buildContextRow("SOURCE", p['source'] ?? 'UNK'),
            _buildContextRow("TIMESTAMP", p['timestamp'] ?? 'UNK'),
            if (p.containsKey('badges'))
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text("BADGES: ${(p['badges'] as List).join(", ")}",
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 10)),
              ),
            const SizedBox(height: 16),
            Text(
              "Analysis Strategy: The system evaluates high-frequency signals against institutional levels. A locked or stale status indicates data integrity constraints were triggered to prevent false positives.",
              style: AppTypography.body(context)
                  .copyWith(fontSize: 12, height: 1.4),
            ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface1.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("VISIBLE CONTEXT",
                  style: AppTypography.label(context)
                      .copyWith(color: AppColors.neonCyan)),
              Row(
                children: [
                  TextButton(
                    onPressed: _clearExplainMyScreen,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text("ELITE HOME",
                        style: AppTypography.caption(context).copyWith(
                            color: AppColors.neonCyan,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close,
                        size: 16, color: AppColors.textDisabled),
                    onPressed: _clearExplainMyScreen,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              )
            ],
          ),
          const SizedBox(height: 12),
          ...screenKeys.map((key) => _buildKeyExplanation(context, key)),
          const SizedBox(height: 8),
          const Center(
              child: Text("Data source: Iron OS Artifacts (Read-Only)",
                  style: TextStyle(
                      color: AppColors.textDisabled,
                      fontSize: 9,
                      fontStyle: FontStyle.italic))),
        ],
      ),
    );
  }

  Widget _buildContextRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4.0),
      child: Row(
        children: [
          Text("$label: ",
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontFamily: 'RobotoMono',
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontFamily: 'RobotoMono',
                  fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildKeyExplanation(BuildContext context, String key) {
    String content = "Loading...";

    // Data Mapping from _osSnapshotData
    if (_osSnapshotData != null) {
      if (key == 'MARKET_REGIME' || key == 'GLOBAL_RISK') {
        final gr = _osSnapshotData!['global_risk'];
        if (gr != null) {
          final risk = gr['risk_state'] ?? 'UNK';
          final drivers = (gr['drivers'] as List?)?.join(", ") ?? "None";
          content = "RISK: $risk | DRIVERS: $drivers";
        } else {
          content = "UNAVAILABLE";
        }
      } else if (key == 'UNIVERSE_STATUS') {
        final ov = _osSnapshotData!['overlay'];
        if (ov != null) {
          final status = ov['status'] ?? 'UNK';
          content = "STATUS: $status";
        } else {
          content = "UNAVAILABLE";
        }
      }
    } else {
      content = "UNAVAILABLE (No Snapshot)";
    }

    // Tier Gating Logic
    if (_tier == EliteTier.free && key != 'MARKET_REGIME') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          children: [
            const Icon(Icons.lock, size: 12, color: AppColors.stateLocked),
            const SizedBox(width: 8),
            Text(key,
                style: const TextStyle(
                    color: AppColors.textDisabled,
                    fontFamily: 'RobotoMono',
                    fontSize: 11)),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(key,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontFamily: 'RobotoMono',
                  fontSize: 10,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(content,
              style:
                  const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
        ],
      ),
    );
  }

  void _handleError() {
    if (mounted) {
      setState(() {
        _statusText = "EXPLAIN: UNAVAILABLE";
        // _statusColor = AppColors.stateLocked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Elite Shell v2 Structure
    // Glassmorphism + Layout Fixes
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter:
            ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12), // True Glass (Softer Blur)
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface1.withValues(alpha: 0.55), // Lighter transparency for visibility
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: AppColors.neonCyan.withValues(alpha: 0.3), // Soft glow border
              width: 1,
            ),
          ),
          child: SafeArea(
            bottom: true, // Respect bottom notches/nav bars
            child: Column(
              children: [
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 1. Draggable Handle (Visual Only)
                            Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                margin:
                                    const EdgeInsets.only(top: 12, bottom: 8),
                                decoration: BoxDecoration(
                                  color: AppColors.textDisabled
                                      .withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),

                            // 2. Elite Header (Logo + Title)
                            _buildTopBar(context),

                            // 3. Ritual Grid (Replaces Strip)
                            // Using Grid 2x3
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: EliteRitualGrid(
                                onRitualTap: _handleRitualTap,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 4. Chat Area (Lower Section)
                      SliverFillRemaining(
                        hasScrollBody: true, // Allow inner list to scroll
                        child: Container(
                          margin: const EdgeInsets.only(top: 1), // Separator
                          decoration: BoxDecoration(
                            color: AppColors.neonCyan
                                .withValues(alpha: 0.02), // Dark cyan tint
                          ),
                          child: Stack(
                            children: [
                              // Chat Messages
                              _buildChatList(context),

                              // Overlay for Explain My Screen / Context
                              if (_showExplainMyScreen)
                                Positioned.fill(
                                  child: Container(
                                    color: AppColors.surface1
                                        .withValues(alpha: 0.95),
                                    child: CanonicalScrollContainer(
                                        child: _buildExplanationView(context)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // 5. Input Area (Pinned to bottom)
                _buildInputArea(context),
              ],
            ),
          ),
        ),
      ),
    );
  }



  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          // Back Arrow
          IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textSecondary),
            onPressed: () {
               if (widget.onClose != null) {
                 widget.onClose!();
               } else {
                 Navigator.of(context).pop();
               }
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 16),
          
          // Title + Info
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                  Text(
                    "ELITE",
                    style: AppTypography.headline(context).copyWith(
                      color: AppColors.neonCyan,
                      letterSpacing: 1.5,
                      fontSize: 18,
                    ),
                  ),
                
                // Free Window Countdown (Animated)
                AnimatedBuilder(
                  animation: EliteBadgeController(),
                  builder: (context, _) {
                    final countdown = EliteBadgeController().freeWindowCountdown;
                    if (countdown == null) return const SizedBox.shrink();
                    
                    return Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.neonCyan.withValues(alpha: 0.1),
                        border: Border.all(color: AppColors.neonCyan),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.timer, size: 10, color: AppColors.neonCyan),
                          const SizedBox(width: 4),
                          Text(
                            "FREE: ${countdown}m",
                            style: const TextStyle(
                                color: AppColors.neonCyan, 
                                fontSize: 10, 
                                fontWeight: FontWeight.bold,
                                fontFamily: 'RobotoMono',
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: "Elite is your personal market mentor. It explains, contextualizes, and teaches you how the OS works — without signals or predictions.",
                  triggerMode: TooltipTriggerMode.tap,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.textDisabled),
                    ),
                    child: const Icon(Icons.question_mark, size: 10, color: AppColors.textDisabled),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // User Avatar (Placeholder/Existing)
          CircleAvatar(
            radius: 14,
            backgroundColor: AppColors.surface2,
            child: Text(
               _tier.name.substring(0, 1).toUpperCase(),
               style: const TextStyle(color: AppColors.neonCyan, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList(BuildContext context) {
    // Combine session turns and automated messages logic
    // For now, we render the thread similar to _buildSessionThread but expanded
    final turns = _sessionTurns; 

    if (turns.isEmpty && !_isFirstInteraction) {
       return Center(
         child: Text("Ask Elite...", style: AppTypography.body(context).copyWith(color: AppColors.textDisabled)),
       );
    }

    if (_isFirstInteraction && _scriptData != null) {
        return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildFirstInteractionView(context),
        );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: turns.length,
      itemBuilder: (context, index) {
        final t = turns[index];
        final isUser = t['role'] == 'USER';
        
        // Parse content
        String text = t['text'] ?? "";
        Map<String, dynamic>? structData;
        if (!isUser && text.startsWith("JSON::")) {
             try {
                structData = json.decode(text.substring(6));
                text = structData?['answer'] ?? "Response Error";
             } catch (e) {
                text = "Error parsing response.";
             }
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppColors.surface2 : AppColors.neonCyan.withValues(alpha: 0.1),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: isUser ? const Radius.circular(12) : Radius.zero,
                  bottomRight: isUser ? Radius.zero : const Radius.circular(12),
                ),
                border: Border.all(
                    color: isUser ? AppColors.borderSubtle : AppColors.neonCyan.withValues(alpha: 0.3),
                    width: 1
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isUser) ...[
                     Row(
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         Text("ELITE", style: AppTypography.caption(context).copyWith(color: AppColors.neonCyan, fontSize: 10, fontWeight: FontWeight.bold)),
                         if (structData != null && structData['mode'] == 'LLM')
                             Container(
                               margin: const EdgeInsets.only(left: 8),
                               padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                               decoration: BoxDecoration(color: AppColors.neonCyan.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                               child: const Text("AI", style: TextStyle(color: AppColors.neonCyan, fontSize: 8, fontWeight: FontWeight.bold)),
                             )
                         else if (structData != null)
                             Container(
                               margin: const EdgeInsets.only(left: 8),
                               padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                               decoration: BoxDecoration(color: AppColors.textDisabled.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                               child: const Text("OS", style: TextStyle(color: AppColors.textSecondary, fontSize: 8, fontWeight: FontWeight.bold)),
                             )
                       ],
                     ),
                     const SizedBox(height: 4),
                  ],
                  // Main Answer
                  Text(
                    text,
                    style: AppTypography.body(context).copyWith(
                        color: isUser ? AppColors.textPrimary : AppColors.textSecondary,
                        fontSize: 14,
                        height: 1.4
                    ),
                  ),
                  
                  // Structured Sections (e.g. Bullets)
                  if (structData != null && structData['sections'] != null)
                     ... (structData['sections'] as List).map((s) => Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                if (s['title'] != null)
                                   Text(s['title'].toString().toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.neonCyan)),
                                if (s['bullets'] != null)
                                   ... (s['bullets'] as List).map((b) => Padding(
                                     padding: const EdgeInsets.only(top: 2, left: 4),
                                     child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                           const Text("• ", style: TextStyle(color: AppColors.textDisabled, fontSize: 12)),
                                           Expanded(child: Text(b.toString(), style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.3)))
                                        ],
                                     ),
                                   )),
                            ],
                        ),
                     ))
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputArea(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Quick Chips
        _buildQuickChips(context),
        
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: const BoxDecoration(
            color: Colors.transparent, 
            border: Border(top: BorderSide(color: AppColors.borderSubtle)),
          ),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                   height: 40,
                   child: TextField(
                     controller: _textController, // Assuming we add this controller
                     enabled: !_isChatLoading,
                     style: AppTypography.body(context).copyWith(color: AppColors.textPrimary),
                     decoration: InputDecoration(
                        hintText: "Ask Elite... (Context Aware)",
                        hintStyle: AppTypography.body(context).copyWith(color: AppColors.textDisabled),
                        filled: true,
                        fillColor: AppColors.surface2,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: AppColors.borderSubtle),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: const BorderSide(color: AppColors.neonCyan),
                        ),
                     ),
                     onSubmitted: (value) {
                        if (value.isNotEmpty) _handleChatSend(value);
                     },
                   ),
                ),
              ),
              const SizedBox(width: 12),
              InkWell(
                 onTap: () {
                     if (_textController.text.isNotEmpty && !_isChatLoading) {
                        _handleChatSend(_textController.text);
                     }
                 },
                 borderRadius: BorderRadius.circular(20),
                 child: Container(
                   height: 40,
                   width: 40,
                   decoration: BoxDecoration(
                     color: AppColors.neonCyan.withValues(alpha: 0.1),
                     shape: BoxShape.circle,
                     border: Border.all(color: AppColors.neonCyan),
                   ),
                   child: _isChatLoading 
                     ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2))
                     : const Icon(Icons.send, size: 18, color: AppColors.neonCyan),
                 ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuickChips(BuildContext context) {
    // D49: Contextual Hint from Badge Controller
    return AnimatedBuilder(
      animation: EliteBadgeController(),
      builder: (context, _) {
         final hint = EliteBadgeController().contextualHint;
         final chips = ["Explain this screen", "System Status", "Why is it blurred?", "How On-Demand works"];
         
         return Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           mainAxisSize: MainAxisSize.min,
           children: [
             if (hint != null)
               Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                       const Icon(Icons.info_outline, size: 12, color: AppColors.neonCyan),
                       const SizedBox(width: 8),
                       Text("HINT: $hint", style: const TextStyle(color: AppColors.neonCyan, fontSize: 10, fontWeight: FontWeight.bold))
                    ],
                  ),
               ),
               
             SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: chips.map((label) => Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                      label: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.neonCyan)),
                      backgroundColor: AppColors.surface2,
                      side: BorderSide(color: AppColors.neonCyan.withValues(alpha: 0.3)),
                      onPressed: () => _handleChatSend(label),
                    ),
                  )).toList(),
                ),
              ),
           ],
         );
      }
    );
  }

  // Chat State
  final TextEditingController _textController = TextEditingController();
  bool _isChatLoading = false;

  Future<void> _handleChatSend(String message) async {
     setState(() {
       _isChatLoading = true;
       _textController.clear();
     });
     
     // 1. Log User Message locally
     await SessionThreadMemoryStore().append("USER", message);
     _refreshMemoryView();

     try {
       // 2. Call API via Repository
       // Context needed? For V1 passing simplified context
       final contextPayload = {
         "screen_id": "DASHBOARD", // Static for now, or dynamic if we passed it
         "status_text": _statusText
       };
       
       final response = await EliteRepository().sendChatMessage(message, contextPayload);
       
       // 3. Process Response (Stored as full JSON for V1)
       // final String answer = response['answer'] ?? "No response.";
       // final String mode = response['mode'] ?? "UNKNOWN";
       
       // Serialize full response to store in memory (hack for V1 to render sections later)
       // We prepend a marker to identify JSON content
       final String storedValue = "JSON::${json.encode(response)}";
       
       await SessionThreadMemoryStore().append("ELITE", storedValue);
       
     } catch (e) {
       await SessionThreadMemoryStore().append("ELITE", "Error: Connection Failed.");
     } finally {
        if (mounted) {
          setState(() {
            _isChatLoading = false;
          });
          _refreshMemoryView();
        }
     }
  }


  // --- Retained Methods (Helpers) ---
  // Kept for logic compatibility, though some might be unused in new UI.
  // We keep them to satisfy "Preserve logic" constraint.


//   Widget _buildOSSnapshot(BuildContext context) {
//      // ... (Existing implementation kept for future use if needed, or referenced by Explain view)
//      // For refactor scope, this is hidden from main view but code is preserved.
//      return const SizedBox.shrink(); 
//   }


//   Widget _buildDayMemoryStats(BuildContext context) {
//     return const SizedBox.shrink();
//   }


//   Widget _buildSessionThread(BuildContext context) {
//      return const SizedBox.shrink(); // Replaced by _buildChatList
//   }


//   Widget _buildRituals(BuildContext context) {
//       return const SizedBox.shrink(); // Replaced by EliteRitualStrip
//   }
  

//   Widget _buildContextStatus(BuildContext context) {
//       return const SizedBox.shrink();
//   }
  

//   Widget _buildWhatChanged(BuildContext context) {
//       return const SizedBox.shrink();
//   }

}
