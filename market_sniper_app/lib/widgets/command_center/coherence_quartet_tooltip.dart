import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';

class CoherenceQuartetTooltip extends StatefulWidget {
  final String symbol;
  final double score;

  // Internal Data (Always present, expanded by default)
  final List<String> whyHighConfidence;
  final List<String> evidenceMemory;
  final List<String> regimeMacroOptions;
  final String? invalidationRisk;

  // External Data (Optional, Stub, collapsed by default)
  final Map<String, dynamic>? capitalActivity;
  final Map<String, dynamic>? humanConsensus;

  const CoherenceQuartetTooltip({
    super.key,
    required this.symbol,
    required this.score,
    required this.whyHighConfidence,
    required this.evidenceMemory,
    required this.regimeMacroOptions,
    this.invalidationRisk,
    this.capitalActivity,
    this.humanConsensus,
  });

  @override
  State<CoherenceQuartetTooltip> createState() =>
      _CoherenceQuartetTooltipState();
}


class _CoherenceQuartetTooltipState extends State<CoherenceQuartetTooltip> {
  // No internal feature flags needed for this display logic

  // The data presence drives the UI, defaulting to N/A if null.

  bool _expandInternal = true;
  bool _expandCapital = false;
  bool _expandHuman = false;

  @override
  void initState() {
    super.initState();
    debugPrint(
        "TOOLTIP_OPEN: symbol=${widget.symbol} internal=${widget.whyHighConfidence.length + widget.evidenceMemory.length}");
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      constraints: const BoxConstraints(maxHeight: 550), // Bumped slightly for 2 sections
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.ccSurface.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.ccAccentDim.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: AppColors.ccShadow.withValues(alpha: 0.5),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header
            _buildHeader(context),
            const SizedBox(height: 12),

            // 2. Risk Strip (Always Visible if present)
            if (widget.invalidationRisk != null) ...[
              _buildRiskStrip(context),
              const SizedBox(height: 12),
            ],

            // 3. Internal Stack (Collapsible Group - Default Open)
            _buildSectionGroup(
              context,
              title: "INTERNAL STACK",
              isExpanded: _expandInternal,
              onToggle: () => setState(() => _expandInternal = !_expandInternal),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSubSection(context, "Why High Confidence?",
                      widget.whyHighConfidence, AppColors.ccAccent),
                  const SizedBox(height: 12),
                  _buildSubSection(context, "Evidence Memory",
                      widget.evidenceMemory, AppColors.textPrimary),
                  const SizedBox(height: 12),
                  _buildSubSection(context, "Regime / Macro / Options",
                      widget.regimeMacroOptions, AppColors.textSecondary),
                ],
              ),
            ),

            // const Divider(color: AppColors.borderSubtle, height: 24), // REMOVED (D61.x.06B)
            const SizedBox(height: 24),

            // 4. Capital Activity (Collapsible - Default Closed)
            _buildSectionGroup(
              context,
              title: "CAPITAL ACTIVITY",
              isExpanded: _expandCapital,
              onToggle: () => setState(() => _expandCapital = !_expandCapital),
              content: _buildCapitalActivity(context),
            ),

            const SizedBox(height: 12),

            // 5. Human Consensus (Collapsible - Default Closed)
            _buildSectionGroup(
              context,
              title: "HUMAN CONSENSUS",
              isExpanded: _expandHuman,
              onToggle: () => setState(() => _expandHuman = !_expandHuman),
              content: _buildHumanConsensus(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final bool isPos = widget.score >= 0;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Symbol + Name
        Expanded(
          child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
                Text(
                  widget.symbol,
                  style: AppTypography.monoHero(context).copyWith(fontSize: 24, height: 1.0),
                ),
             ],
          ),
        ),

        // HF-1 Score Display
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
             Text("Confidence Score",
                style: AppTypography.monoTiny(context).copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5
                )),
             const SizedBox(height: 2),
             Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isPos
                    ? AppColors.ccAccent.withValues(alpha: 0.1)
                    : AppColors.marketBear.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                    color: isPos
                        ? AppColors.ccAccent.withValues(alpha: 0.3)
                        : AppColors.marketBear.withValues(alpha: 0.3)),
              ),
              child: Text(
                "${widget.score.toStringAsFixed(1)} / 10",
                style: AppTypography.monoBody(context).copyWith(
                  fontWeight: FontWeight.bold,
                  color: isPos ? AppColors.ccAccent : AppColors.marketBear,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildRiskStrip(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.marketBear.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
        border:
            Border.all(color: AppColors.marketBear.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              size: 16, color: AppColors.marketBear),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "RISK: ${widget.invalidationRisk}",
              style: AppTypography.monoTiny(context)
                  .copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionGroup(BuildContext context,
      {required String title,
      required bool isExpanded,
      required VoidCallback onToggle,
      required Widget content}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Row
        GestureDetector(
          onTap: onToggle,
          behavior: HitTestBehavior.opaque,
          child: Row(
            children: [
              Text(title,
                  style: AppTypography.monoLabel(context).copyWith(
                      color: AppColors.textDisabled, letterSpacing: 1.0)),
              const Spacer(),
              Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                color: AppColors.textDisabled,
                size: 16,
              ),
            ],
          ),
        ),

        // Animated Body
        AnimatedCrossFade(
          firstChild: Container(height: 0),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: content,
          ),
          crossFadeState: isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }

  Widget _buildSubSection(
      BuildContext context, String title, List<String> items, Color bulletColor) {
    if (items.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: AppTypography.monoTiny(context).copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.bold,
            )),
        const SizedBox(height: 4),
        ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0, right: 8.0),
                    child: Icon(Icons.circle, size: 4, color: bulletColor),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: AppTypography.monoBody(context),
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  Widget _buildCapitalActivity(BuildContext context) {
    // Data Extraction
    final data = widget.capitalActivity;
    
    // Status Logic
    // Default to 'UNPLUGGED' if status is missing or explicitly N/A
    String status = data?['status']?.toString().toUpperCase() ?? 'UNPLUGGED';
    if (status == 'N/A') status = 'UNPLUGGED'; // Normalize legacy
    
    final bool isUnplugged = status == 'UNPLUGGED';
    final bool isMock = status == 'MOCK';
    
    final String summary = data?['summary'] ?? "Scanning market flows...";
    final String bias = data?['bias'] ?? "Neutral"; 

    Color biasColor = AppColors.textDisabled;
    if (bias == "Bullish") biasColor = AppColors.marketBull;
    if (bias == "Bearish") biasColor = AppColors.marketBear;
    if (bias == "Mixed") biasColor = AppColors.stateStale;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         // Status Header / Badge
         if (isUnplugged) ...[
            Row(
              children: [
                const Icon(Icons.power_off, size: 12, color: AppColors.textDisabled),
                const SizedBox(width: 6),
                Text("N/A (External source unplugged)",
                  style: AppTypography.monoTiny(context).copyWith(
                    color: AppColors.textDisabled,
                    fontStyle: FontStyle.italic
                  )
                ),
              ],
            )
         ] else ...[
            // Active/Mock State
            Row(
              children: [
                if (isMock)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.stateStale.withValues(alpha: 0.5)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text("MOCK", style: AppTypography.monoTiny(context).copyWith(fontSize: 8, color: AppColors.stateStale)),
                  ),
                if (isMock) const SizedBox(width: 8),
                Text("FLOW ACTIVITY", style: AppTypography.monoLabel(context).copyWith(color: AppColors.ccAccent)),
              ],
            ),
            const SizedBox(height: 8),
            Text(summary, style: AppTypography.body(context).copyWith(fontSize: 13, height: 1.4)),
            const SizedBox(height: 8),
            Row(
              children: [
                Text("BIAS: ", style: AppTypography.monoTiny(context).copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                Text(bias.toUpperCase(), style: AppTypography.monoTiny(context).copyWith(color: biasColor, fontWeight: FontWeight.bold)),
              ],
            ),
         ],
         
         const SizedBox(height: 8),
         Text("External, delayed market activity",
            style: AppTypography.monoTiny(context).copyWith(
              color: AppColors.textDisabled,
              fontStyle: FontStyle.italic,
              fontSize: 10
            )),
      ],
    );
  }

  Widget _buildHumanConsensus(BuildContext context) {
    final data = widget.humanConsensus;
    
    // Status Logic
    String status = data?['status']?.toString().toUpperCase() ?? 'UNPLUGGED';
    if (status == 'N/A') status = 'UNPLUGGED'; 
    
    final bool isUnplugged = status == 'UNPLUGGED';
    // final bool isMock = status == 'MOCK'; // Not strictly required for Human yet, but good to have

    final String summary = data?['summary'] ?? "No analyst coverage found.";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isUnplugged) ...[
            // Unplugged State
           Row(
              children: [
                const Icon(Icons.power_off, size: 12, color: AppColors.textDisabled),
                const SizedBox(width: 6),
                Text("N/A (External source unplugged)",
                  style: AppTypography.monoTiny(context).copyWith(
                    color: AppColors.textDisabled,
                    fontStyle: FontStyle.italic
                  )
                ),
              ],
            )
        ] else ...[
           // Active State (Summary)
           Text(summary, style: AppTypography.body(context).copyWith(fontSize: 13, height: 1.4)),

           const SizedBox(height: 12),
           Container(
             padding: const EdgeInsets.all(8),
             decoration: BoxDecoration(
               color: AppColors.ccBg,
               borderRadius: BorderRadius.circular(4),
               border: Border.all(color: AppColors.borderSubtle),
             ),
             child: Row(
               children: [
                  const Icon(Icons.school, size: 14, color: AppColors.textDisabled),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text("Human consensus is typically reactive and lagging.",
                       style: AppTypography.monoTiny(context).copyWith(
                         color: AppColors.textSecondary,
                         fontSize: 10,
                         height: 1.3
                       )),
                  ),
               ],
             ),
           ),
        ],
      ],
    );
  }
}
