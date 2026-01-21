import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../config/app_config.dart';
import '../logic/day_memory_store.dart';
import '../logic/elite_mentor_brain.dart';
import '../logic/session_thread_memory_store.dart';
import '../logic/ritual_scheduler.dart';
import '../logic/elite_contextual_recall_engine.dart'; // D43.13
import 'canonical_scroll_container.dart';

enum EliteTier { free, plus, elite }

class EliteInteractionSheet extends StatefulWidget {
  final String? initialExplainKey;
  final Map<String, dynamic>? initialPayload;
  final bool resetToWelcome;
  final ScrollController? scrollController;

  const EliteInteractionSheet({
    super.key,
    this.initialExplainKey,
    this.initialPayload,
    this.resetToWelcome = false,
    this.scrollController,
  });

  @override
  State<EliteInteractionSheet> createState() => _EliteInteractionSheetState();
}

class _EliteInteractionSheetState extends State<EliteInteractionSheet> {
  final EliteTier _tier = EliteTier.elite; // Fixed: Made final
  String _statusText = "CHECKING...";
  Color _statusColor = AppColors.textDisabled;
  String? _pendingExplainKey;
  bool _showExplainMyScreen = false;
  Map<String, dynamic>? _osSnapshotData;
  // D43.00: First Interaction State
  bool _isFirstInteraction = true; 
  Map<String, dynamic>? _scriptData;
  
  // D43.04: Day Memory
  List<String> _memoryBullets = [];
  // D43.08: Session Thread
  List<Map<String, String>> _sessionTurns = [];
  // D43.11: Context Status
  Map<String, dynamic>? _contextStatus;
  // D43.12: What Changed
  Map<String, dynamic>? _whatChanged;
  // D43.13: Contextual Recall
  EliteContextualRecallSnapshot? _recallSnapshot;
  // D43.05: AGMS Recall
  Map<String, dynamic>? _agmsRecall;

  @override
  void initState() {
    super.initState();
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
    if (_pendingExplainKey == null) _fetchStatus(); // Only fetch default status if not explaining
    if (_isFirstInteraction) _fetchFirstInteractionScript();
    _initMemory();
  }

  Future<void> _initMemory() async {
    await DayMemoryStore().init();
    await SessionThreadMemoryStore().init();
    await RitualScheduler().init(); // D43.09
    
    // D43.11: Fetch Status
    _fetchContextStatus();
    // D43.12: Fetch What Changed
    _fetchWhatChanged();
    // D43.05: Fetch AGMS Recall
    _fetchAgmsRecall();
    
    _refreshMemoryView();
  }
  
  Future<void> _fetchContextStatus() async {
      try {
         // D43.11: Direct API fetch
         final response = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/elite/context/status'));
         if (response.statusCode == 200) {
             if (mounted) {
                 setState(() {
                     _contextStatus = jsonDecode(response.body);
                 });
             }
         }
      } catch (_) {
          // Silent fail on connection error, stays null
      }
  }

  Future<void> _fetchWhatChanged() async {
      try {
         final response = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/elite/what_changed'));
         if (response.statusCode == 200) {
             if (mounted) {
                 setState(() {
                     _whatChanged = jsonDecode(response.body);
                 });
             }
         }
      } catch (_) {
          // Silent fail
      }
  }

  Future<void> _fetchAgmsRecall() async {
      try {
          // Pass arbitrary tier for now, or match _tier variable
          final tierStr = _tier.name; 
          final response = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/elite/agms/recall?tier=$tierStr'));
          if (response.statusCode == 200) {
              if (mounted) {
                  setState(() {
                      _agmsRecall = jsonDecode(response.body);
                  });
              }
          }
      } catch (_) {
          // Silent fail
      }
  }

  void _refreshMemoryView() {
    if (mounted) {
      setState(() {
        final bullets = DayMemoryStore().getBullets();
        _memoryBullets = bullets.reversed.toList();
        
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
         _statusColor = AppColors.stateLocked;
       });
       return;
    }
    
    // Simulate Fetching
    setState(() {
      _statusText = "EXPLAINING: $key";
      _statusColor = AppColors.accentCyan;
    });
  }

  Future<void> _fetchStatus() async {
    try {
      final url = Uri.parse('${AppConfig.apiBaseUrl}/elite/explain/status');
      final response = await http.get(url).timeout(const Duration(seconds: 3));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final bool isAvailable = data['status'] == 'AVAILABLE'; 
        
        if (mounted) {
          setState(() {
            // Use isAvailable to determine status
            if (isAvailable) {
               _statusText = "EXPLAIN: ACTIVE";
               _statusColor = AppColors.accentCyan;
            } else {
               _statusText = "EXPLAIN: UNAVAILABLE";
               _statusColor = AppColors.stateLocked;
            }
          });
        }
      } else {
        _handleError();
      }
    } catch (e) {
      _handleError();
    }
  }

  Future<void> _triggerExplainMyScreen() async {
    setState(() {
       _statusText = "ANALYZING CONTEXT...";
       _statusColor = AppColors.accentCyan;
    });

    // Simulate analysis delay
    await Future.delayed(const Duration(milliseconds: 600));

    // D43.14: Fetch Snapshot from generic reader
    try {
      final response = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/elite/os/snapshot'));
      if (response.statusCode == 200) {
        _osSnapshotData = json.decode(response.body);
      }
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
       await DayMemoryStore().append("Explained: MARKET_REGIME + GLOBAL_RISK + UNIVERSE_STATUS");
       
       // D43.08: Log to Session Thread
       await SessionThreadMemoryStore().append("USER", "Explain My Screen");
       await SessionThreadMemoryStore().append("ELITE", "Context Explained: [REGIME/RISK/STATUS]");
       
       _refreshMemoryView();
    }
  }
  
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
        final response = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/elite/script/first_interaction'));
        if (response.statusCode == 200) {
           setState(() {
              _scriptData = json.decode(response.body);
           });
        }
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
               style: AppTypography.body(context).copyWith(color: AppColors.textPrimary),
               textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ...questions.map<Widget>((q) {
               final tierMin = q['tier_min'];
               final bool isLocked = (_tier == EliteTier.free && tierMin != 'free') || 
                                     (_tier == EliteTier.plus && tierMin == 'elite');
               
               return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: ElevatedButton(
                     style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surface2,
                        foregroundColor: isLocked ? AppColors.textDisabled : AppColors.accentCyan,
                        side: BorderSide(color: isLocked ? AppColors.borderSubtle : AppColors.accentCyan),
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        alignment: Alignment.centerLeft,
                     ),
                     onPressed: isLocked ? null : () => _handleQuestion(q),
                     child: Row(
                        children: [
                           Expanded(child: Text(q['text'], style: AppTypography.caption(context))),
                           if (isLocked) const Icon(Icons.lock, size: 14, color: AppColors.stateLocked),
                        ],
                     ),
                  ),
               );
            }),
            if (_tier == EliteTier.free)
               Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: const Text("Upgrade to Unlock Elite Insights", style: TextStyle(color: AppColors.stateLocked, fontSize: 10, fontStyle: FontStyle.italic)),
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
         // In a real app we'd show the answer text, here we just transition to "Ready" state or similar.
         // Actually, let's just show a snackbar or alert for the answer since we don't have a chat history view yet (D43.08).
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(q['answer_template'] ?? "No answer defined."),
            backgroundColor: AppColors.surface2,
         ));
          
          // D43.08: Log
          SessionThreadMemoryStore().append("USER", q['text']);
          SessionThreadMemoryStore().append("ELITE", q['answer_template'] ?? "Answered.");
          _refreshMemoryView();
          
      } else {
         // Trigger explain
         _handleExplainRequest(q['action_payload']);
         setState(() {
            _isFirstInteraction = false;
         });
          
          // D43.08: Log
          SessionThreadMemoryStore().append("USER", q['text']);
          SessionThreadMemoryStore().append("ELITE", "Routing explanation for ${q['action_payload']}...");
          _refreshMemoryView();
       }
  }

  // D43.14: Explanation View
  Widget _buildExplanationView(BuildContext context) {
      // Context Collector (Mocked per plan)
      final List<String> screenKeys = ['MARKET_REGIME', 'GLOBAL_RISK', 'UNIVERSE_STATUS'];
      
      // D44.13: On-Demand Payload Context
      if (_pendingExplainKey == 'EXPLAIN_ON_DEMAND_RESULT' && widget.initialPayload != null) {
          final p = widget.initialPayload!;
          return Container(
             width: double.infinity,
             padding: const EdgeInsets.all(16),
             decoration: BoxDecoration(
               color: AppColors.surface1.withValues(alpha: 0.5),
               borderRadius: BorderRadius.circular(12),
               border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.3)),
             ),
             child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                        Text("ON-DEMAND CONTEXT", style: AppTypography.label(context).copyWith(color: AppColors.accentCyan)),
                        IconButton(
                           icon: const Icon(Icons.close, size: 16, color: AppColors.textDisabled),
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
                        child: Text("BADGES: ${(p['badges'] as List).join(", ")}", style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                      ),
                   const SizedBox(height: 16),
                   Text(
                     "Analysis Strategy: The system evaluates high-frequency signals against institutional levels. A locked or stale status indicates data integrity constraints were triggered to prevent false positives.",
                     style: AppTypography.body(context).copyWith(fontSize: 12, height: 1.4),
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
           border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.3)),
         ),
         child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Row(
                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
                 children: [
                    Text("VISIBLE CONTEXT", style: AppTypography.label(context).copyWith(color: AppColors.accentCyan)),
                    Row(
                       children: [
                          TextButton(
                             onPressed: _clearExplainMyScreen,
                             style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                             ),
                             child: Text("ELITE HOME", style: AppTypography.caption(context).copyWith(color: AppColors.accentCyan, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                             icon: const Icon(Icons.close, size: 16, color: AppColors.textDisabled),
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
               Center(child: Text("Data source: Iron OS Artifacts (Read-Only)", style: TextStyle(color: AppColors.textDisabled, fontSize: 9, fontStyle: FontStyle.italic))),
            ],
         ),
      );
  }
  
  Widget _buildContextRow(String label, String value) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4.0),
        child: Row(
          children: [
             Text("$label: ", style: TextStyle(color: AppColors.textSecondary, fontFamily: 'RobotoMono', fontSize: 10, fontWeight: FontWeight.bold)),
             Text(value, style: TextStyle(color: AppColors.textPrimary, fontFamily: 'RobotoMono', fontSize: 10)),
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
                 Text(key, style: TextStyle(color: AppColors.textDisabled, fontFamily: 'RobotoMono', fontSize: 11)),
              ],
           ),
        );
     }

     return Padding(
       padding: const EdgeInsets.only(bottom: 12.0),
       child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text(key, style: TextStyle(color: AppColors.textSecondary, fontFamily: 'RobotoMono', fontSize: 10, fontWeight: FontWeight.bold)),
             const SizedBox(height: 2),
             Text(content, style: TextStyle(color: AppColors.textPrimary, fontSize: 12)),
          ],
       ),
     );
  }

  void _handleError() {
    if (mounted) {
      setState(() {
        _statusText = "EXPLAIN: UNAVAILABLE";
        _statusColor = AppColors.stateLocked; // Fixed: Use stateLocked instead of stateError
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.accentCyan, width: 1)),
      ),
      // No padding here, handled by ScrollContainer or internal
      child: CanonicalScrollContainer(
        controller: widget.scrollController,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                color: AppColors.textDisabled,
                margin: const EdgeInsets.only(bottom: 20),
              ),
            ),
            
            // Header
            Text(
              EliteMentorBrain().formatHeader("Elite Context Engine"),
              style: AppTypography.headline(context).copyWith(color: AppColors.accentCyan, letterSpacing: 1.2),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              "Institutional Intelligence Layer",
              style: AppTypography.caption(context).copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            
            // D43.11: Context Status Row
            if (_contextStatus != null) _buildContextStatus(context),
            const SizedBox(height: 8),
  
            // D43.12: What Changed
            _buildWhatChanged(context),
            const SizedBox(height: 16),
            
            // D43.13: Contextual Recall
            _buildContextualRecall(context),
            const SizedBox(height: 16),
  
            // D43.05: AGMS Recall
            _buildAgmsRecall(context),
            const SizedBox(height: 16),
  
            // Status Line
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: _statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _statusText,
                  style: AppTypography.caption(context).copyWith(
                    color: _statusColor, 
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'RobotoMono', 
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            if (!_showExplainMyScreen) 
              Center(
                child: ElevatedButton.icon(
                  onPressed: _triggerExplainMyScreen,
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text("EXPLAIN MY SCREEN"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surface2,
                    foregroundColor: AppColors.accentCyan,
                    textStyle: AppTypography.caption(context).copyWith(fontWeight: FontWeight.bold),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    side: const BorderSide(color: AppColors.accentCyan, width: 1),
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            const SizedBox(height: 32),
  
            // Greeting / Context
            if (_isFirstInteraction && _scriptData != null)
               _buildFirstInteractionView(context)
            else
               Text(
                "Protocol Active. Ready to explain market mechanics.",
                style: AppTypography.body(context).copyWith(color: AppColors.textPrimary),
                textAlign: TextAlign.center,
               ),
            const SizedBox(height: 24),
  
            // Context Content
            if (_showExplainMyScreen)
               // SingleChildScrollView is redundant if wrapped in CanonicalScrollContainer, 
               // BUT CanonicalScrollContainer is the parent now.
               // So we just output the content directly.
               _buildExplanationView(context)
            else
              Container(
                width: double.infinity,
                // height: 120, // Remove fixed height constraint that might conflict?
                // Let it sizing naturally or use constraints if needed.
                constraints: const BoxConstraints(minHeight: 120),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.graphic_eq, color: _statusColor.withValues(alpha: 0.5), size: 48),
                    const SizedBox(height: 16),
                    if (_pendingExplainKey != null) ...[
                      Text(
                        "Analyzing $_pendingExplainKey...",
                         style: AppTypography.label(context).copyWith(color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                       Text(
                        "Drivers • Watch • OS Strategy",
                         style: AppTypography.caption(context).copyWith(color: AppColors.textSecondary),
                      ),
                    ] else 
                    Text(
                      "Awaiting Context...",
                      style: AppTypography.label(context).copyWith(color: AppColors.textDisabled),
                    ),
                  ],
                ),
              ),
            
            const SizedBox(height: 16),
            // D43.03: OS Snapshot Widget
            _buildOSSnapshot(context),
            
            const SizedBox(height: 16),
            // D43.04: Day Memory
            _buildDayMemoryStats(context),
            
            const SizedBox(height: 16),
            // D43.08: Session Thread
            _buildSessionThread(context),
  
            const SizedBox(height: 16),
            // D43.09: Rituals
            _buildRituals(context),
            
            const SizedBox(height: 8),
            Center(
               child: Text(
                  "TONE: ${EliteMentorBrain().toneMode.name.toUpperCase()}",
                  style: AppTypography.caption(context).copyWith(color: AppColors.textDisabled, fontSize: 8),
               ),
            ),
            
            const SizedBox(height: 20),
            
            // Founder Controls (Preserved)
            if (AppConfig.isFounderBuild) ...[
              const Divider(color: AppColors.borderSubtle),
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                     Text("SHELL: 70/30 | TIER: ", style: AppTypography.caption(context)),
                     Text(_tier.name.toUpperCase(), style: AppTypography.caption(context).copyWith(color: AppColors.accentCyan)),
                  ],
                ),
              ),
            ],
            // Extra padding at bottom to ensure scroll clears bottom edges
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildOSSnapshot(BuildContext context) {
      return FutureBuilder(
         future: http.get(Uri.parse('${AppConfig.apiBaseUrl}/elite/os/snapshot')),
         builder: (context, snapshot) {
            String runMode = "--";
            String runId = "--";
            String risk = "--";
            String overlay = "--";
            
            if (snapshot.hasData && snapshot.data!.statusCode == 200) {
               try {
                  final data = json.decode(snapshot.data!.body);
                  final rm = data['run_manifest'];
                  if (rm != null) {
                     runMode = rm['mode'] ?? 'UNK';
                     // runId removed (unused)
                  }
                  
                  final gr = data['global_risk'];
                  if (gr != null) {
                     risk = gr['risk_state'] ?? 'UNK';
                  } else {
                     risk = "UNAVAILABLE";
                  }
                  
                  final ov = data['overlay'];
                  if (ov != null) {
                      overlay = ov['status'] ?? 'UNK';
                  } else {
                      overlay = "UNAVAILABLE";
                  }
               } catch (e) {
                  // error
               }
            } else if (snapshot.hasData && snapshot.data!.statusCode == 404) {
                risk = "UNAVAILABLE";
                overlay = "UNAVAILABLE";
            }
            
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                 crossAxisAlignment: CrossAxisAlignment.start,
                 children: [
                    Text("OS SNAPSHOT", style: AppTypography.caption(context).copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                    const SizedBox(height: 4),
                    Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                          Text("MODE: $runMode", style: TextStyle(color: AppColors.accentCyan, fontSize: 10, fontFamily: 'RobotoMono', package: null)),
                          Text("RISK: $risk", style: TextStyle(color: AppColors.textPrimary, fontSize: 10, fontFamily: 'RobotoMono', package: null)),
                          Text("OVERLAY: $overlay", style: TextStyle(color: AppColors.textPrimary, fontSize: 10, fontFamily: 'RobotoMono', package: null)),
                       ],
                    )
                 ],
              ),
            );
         },
      );
  }

  Widget _buildDayMemoryStats(BuildContext context) {
    // Show only top 3 recent
    final displayBullets = _memoryBullets.take(3).toList();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("DAY MEMORY (LOCAL)", style: AppTypography.caption(context).copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
              InkWell(
                onTap: () async {
                  await DayMemoryStore().clear();
                  _refreshMemoryView();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                  child: Text("CLEAR", style: AppTypography.caption(context).copyWith(color: AppColors.textDisabled, fontSize: 10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (displayBullets.isEmpty)
            Text("No recent interactions.", style: TextStyle(color: AppColors.textDisabled, fontSize: 10, fontStyle: FontStyle.italic))
          else
            ...displayBullets.map((b) => Padding(
              padding: const EdgeInsets.only(bottom: 2.0),
              child: Text("• $b", style: TextStyle(color: AppColors.textSecondary, fontSize: 10, fontFamily: 'RobotoMono')),
            )),
        ],
      ),
    );
  }

  Widget _buildSessionThread(BuildContext context) {
    if (_sessionTurns.isEmpty) return const SizedBox.shrink();

    // Show last 6 turns
    final displayTurns = _sessionTurns.length > 6 
        ? _sessionTurns.sublist(_sessionTurns.length - 6) 
        : _sessionTurns;

    return Container(
       padding: const EdgeInsets.symmetric(horizontal: 24),
       child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                   Text("SESSION THREAD", style: AppTypography.caption(context).copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                   InkWell(
                      onTap: () async {
                         await SessionThreadMemoryStore().clear();
                         _refreshMemoryView();
                      },
                      child: Padding(
                         padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                         child: Text("CLEAR", style: AppTypography.caption(context).copyWith(color: AppColors.textDisabled, fontSize: 10)),
                      ),
                   )
                ],
             ),
             const SizedBox(height: 8),
             ...displayTurns.map((t) {
                final isUser = t['role'] == 'USER';
                return Padding(
                   padding: const EdgeInsets.only(bottom: 4.0),
                   child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                         Text(isUser ? "YOU: " : "ELITE: ", 
                            style: TextStyle(
                               fontFamily: 'RobotoMono', 
                               fontSize: 10, 
                               fontWeight: FontWeight.bold,
                               color: isUser ? AppColors.textDisabled : AppColors.accentCyan
                            )
                         ),
                         Expanded(
                            child: Text(t['text'] ?? "", 
                               style: TextStyle(
                                  fontSize: 10, 
                                  color: AppColors.textSecondary
                               )
                            )
                         )
                      ],
                   ),
                );
             }),
          ],
       ),
    );
  }

  Widget _buildRituals(BuildContext context) {
     return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
              Text("RITUALS (ET)", style: AppTypography.caption(context).copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              ...RitualScheduler.rituals.map((ritual) {
                 final status = RitualScheduler().checkStatus(ritual);
                 
                 Color statusColor = AppColors.textDisabled;
                 String statusText = "";
                 Widget? action;
                 
                 switch (status) {
                    case RitualStatus.ready:
                       statusColor = AppColors.accentCyan;
                       statusText = "READY";
                       action = ElevatedButton(
            onPressed: () async {
               
               // D43.15: Special handling for Morning Briefing
               if (ritual.id == "morning_briefing") {
                  await _handleMorningBriefing(ritual);
               } else {
                   await RitualScheduler().markFired(ritual);
                   // Log to Memory
                   await SessionThreadMemoryStore().append("USER", "Started Ritual: ${ritual.label}");
                   await SessionThreadMemoryStore().append("ELITE", "Ritual Prompt Shown.");
                   await DayMemoryStore().append("Ritual Completed: ${ritual.label}");
               }
               
               _refreshMemoryView();
               setState(() {}); // Force redraw to show Cooldown
            },
            style: ElevatedButton.styleFrom(
               backgroundColor: AppColors.accentCyan.withValues(alpha: 0.1),
               foregroundColor: AppColors.accentCyan,
               minimumSize: const Size(0, 24),
               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
               side: const BorderSide(color: AppColors.accentCyan)
            ),
            child: const Text("START", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
         );
                       break;
                    case RitualStatus.cooldown:
                       statusColor = AppColors.textDisabled;
                       statusText = "DONE TODAY";
                       break;
                    case RitualStatus.notInWindow:
                       statusColor = AppColors.textSecondary;
                       statusText = RitualScheduler().getNextTimeString(ritual);
                       break;
                 }
                 
                 return Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                          Text(ritual.label, style: AppTypography.body(context).copyWith(fontSize: 12)),
                          Row(
                             children: [
                                Text(statusText, style: AppTypography.caption(context).copyWith(color: statusColor, fontSize: 10)),
                                if (action != null) ...[
                                   const SizedBox(width: 8),
                                   action,
                                ]
                             ],
                          )
                       ],
                    ),
                 );
              }),
           ],
        ),
     );
  }
  
  Widget _buildContextStatus(BuildContext context) {
      if (_contextStatus == null) return const SizedBox.shrink();
      
      final status = _contextStatus!['status'] as String? ?? "UNKNOWN";
      final ageSeconds = _contextStatus!['age_seconds'] as int? ?? 0;
      final reason = _contextStatus!['reason_code'] as String? ?? "";
      
      Color statusColor = AppColors.textDisabled;
      switch (status) {
          case "LIVE": statusColor = AppColors.accentCyan; break;
          case "STALE": statusColor = AppColors.textSecondary; break; 
          // AppColors.accentGold exists? If not, use standard yellow/orange. 
          // Let's stick to strict AppColors. If accentGold missing, use accentCyan with opacity or similar.
          // Actually, let's just use textSecondary for stale/locked to be safe if no Warning color.
          // Or use AppColors.accentCyan for LIVE and textDisabled for others.
          // Wait, requirement: "MUST use AppColors/AppTypography only".
      // If Live, use Cyan. Else Grey.
      if (status == "LIVE") statusColor = AppColors.accentCyan;
      
      final ageStr = _formatDuration(Duration(seconds: ageSeconds));
      
      return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                  Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                          borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                          children: [
                              Text("STATUS: $status", style: AppTypography.caption(context).copyWith(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 8),
                              Text("AGE: $ageStr", style: AppTypography.caption(context).copyWith(color: AppColors.textDisabled, fontSize: 10)),
                              if (status != "LIVE") ...[
                                  const SizedBox(width: 8),
                                  Text("($reason)", style: AppTypography.caption(context).copyWith(color: AppColors.textDisabled, fontSize: 10)),
                              ]
                          ],
                      ),
                  )
              ],
          ),
      );
  }
  
  String _formatDuration(Duration d) {
      final hh = d.inHours.toString().padLeft(2, '0');
      final mm = (d.inMinutes % 60).toString().padLeft(2, '0');
      final ss = (d.inSeconds % 60).toString().padLeft(2, '0');
      return "$hh:$mm:$ss";
  }

  Widget _buildWhatChanged(BuildContext context) {
      // ... existing code ...
      return Container(
          // ... existing code ...
          child: Column(
              // ... existing code ...
              children: [
                 // ... existing code ...
              ],
          )
      );
  }

  // D43.15: Handle Morning Briefing logic
  Future<void> _handleMorningBriefing(RitualDefinition ritual) async {
       // 1. Mark Fired
       await RitualScheduler().markFired(ritual);
       
       // 2. Fetch Briefing
       List<String> bullets = [];
       String boundary = "";
       try {
           final response = await http.get(Uri.parse('${AppConfig.apiBaseUrl}/elite/micro_briefing/open'));
           if (response.statusCode == 200) {
               final data = jsonDecode(response.body);
                bullets = List<String>.from(data['bullets'] ?? []);
                boundary = data['boundary'] ?? "";
                
                // D43.16: Safety Filter Check (Briefing)
                bool isSafetyFiltered = data['safety_filtered'] == true;
                if (isSafetyFiltered) {
                    bullets.add("[SAFETY FILTER APPLIED]");
                }
            } else {
               bullets = ["Briefing Unavailable (API Error)"];
           }
       } catch (e) {
           bullets = ["Briefing Unavailable (Connection Error)"];
       }
       
       // 3. Construct Text
       final buffer = StringBuffer();
       buffer.writeln("MICRO-BRIEFING ON OPEN");
       for (final b in bullets) {
           buffer.writeln("• $b");
       }
       if (boundary.isNotEmpty) buffer.writeln(boundary);
       
       final fullText = buffer.toString().trim();
       
       // 4. Log
       await SessionThreadMemoryStore().append("USER", "Started Ritual: ${ritual.label}");
       await SessionThreadMemoryStore().append("ELITE", fullText);
       await DayMemoryStore().append("Ritual Completed: ${ritual.label}");
       await DayMemoryStore().append("MICRO_BRIEFING_OPEN: $fullText");
  }

  Widget _buildContextualRecall(BuildContext context) {
      return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                   if (_whatChanged != null && _whatChanged!['safety_filtered'] == true)
                        Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text("SAFETY FILTER APPLIED", style: AppTypography.caption(context).copyWith(fontSize: 9, color: AppColors.textDisabled, fontWeight: FontWeight.bold)),
                        ),
                   // ... existing children ...
                   Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                           Text("CONTEXTUAL RECALL", style: AppTypography.caption(context).copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                           if (_recallSnapshot == null)
                               InkWell(
                                   onTap: _handleShowRecall,
                                   child: Container(
                                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                       decoration: BoxDecoration(border: Border.all(color: AppColors.accentCyan), borderRadius: BorderRadius.circular(4)),
                                       child: Text("SHOW RECALL", style: AppTypography.caption(context).copyWith(color: AppColors.accentCyan, fontSize: 10, fontWeight: FontWeight.bold)),
                                   ),
                               )
                       ],
                   ),
                   const SizedBox(height: 8),
                   if (_recallSnapshot != null) ...[
                       if (_recallSnapshot!.status == "EMPTY")
                           Text("NO RECENT CONTEXT FOUND", style: AppTypography.caption(context).copyWith(color: AppColors.textDisabled, fontStyle: FontStyle.italic)),
                       
                       if (_recallSnapshot!.status == "SUCCESS")
                           ..._recallSnapshot!.bullets.map((b) => Padding(
                               padding: const EdgeInsets.only(bottom: 4),
                               child: Row(
                                   crossAxisAlignment: CrossAxisAlignment.start,
                                   children: [
                                       Text("• ", style: TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.bold)),
                                       Expanded(child: Text(b, style: AppTypography.label(context).copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.normal))),
                                   ],
                               ),
                           ))
                   ]
              ],
          ),
      );
  }

  Future<void> _handleShowRecall() async {
      try {
          final engine = EliteContextualRecallEngine();
          final snapshot = await engine.build();
          
          if (mounted) {
              setState(() {
                  _recallSnapshot = snapshot;
              });
          }
          
          // Persist to Memory (D43.13 Req)
          // "CONTEXTUAL_RECALL_LAST": <raw json or bullets>
          // Requirement: "Write the rendered recall text back... key CONTEXTUAL_RECALL_LAST"
          // We'll store the bullets as a clean string block to be human readable in the file
          if (snapshot.status == "SUCCESS") {
               final textBlock = snapshot.bullets.join(" | ");
               await DayMemoryStore().append("CONTEXTUAL_RECALL_LAST: $textBlock");
               _refreshMemoryView(); // Update memory viewer immediately
          }
      } catch (e) {
          // Silent fail or UI indication? 
          // Requirement says "degrade safely". Doing nothing is safe.
      }
  }

  Widget _buildAgmsRecall(BuildContext context) {
      final patterns = (_agmsRecall != null && _agmsRecall!['patterns'] is List) 
          ? List<String>.from(_agmsRecall!['patterns']) 
          : <String>[];
          
      final status = _agmsRecall?['status'] ?? "UNAVAILABLE";
      final isSafetyFiltered = _agmsRecall?['safety_filtered'] == true;

      return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                   Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                           Text("AGGREGATE LEARNING (AGMS)", style: AppTypography.caption(context).copyWith(fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                           if (isSafetyFiltered)
                               Text("SAFETY FILTER APPLIED", style: AppTypography.caption(context).copyWith(fontSize: 8, color: AppColors.textDisabled, fontWeight: FontWeight.bold)),
                       ],
                   ),
                   const SizedBox(height: 8),
                   
                   if (status == "UNAVAILABLE" || patterns.isEmpty)
                       Text("No aggregate data yet", style: AppTypography.caption(context).copyWith(color: AppColors.textDisabled, fontStyle: FontStyle.italic)),
                   
                   if (patterns.isNotEmpty)
                       ...patterns.map((p) => Padding(
                           padding: const EdgeInsets.only(bottom: 4),
                           child: Row(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                   Text("• ", style: TextStyle(color: AppColors.accentCyan, fontWeight: FontWeight.bold)), // AGMS uses Cyan for Context alignment
                                   Expanded(child: Text(p, style: AppTypography.label(context).copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.normal))),
                               ],
                           ),
                       ))
              ],
          ),
      );
  }
}
