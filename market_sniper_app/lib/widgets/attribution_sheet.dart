import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../adapters/on_demand/models.dart';
import '../logic/on_demand_tier_resolver.dart';

class AttributionSheet extends StatelessWidget {
  final AttributionModel attribution;
  final OnDemandTier userTier;

  const AttributionSheet({
    super.key,
    required this.attribution,
    required this.userTier,
  });

  @override
  Widget build(BuildContext context) {
    // Filter Active Blurs based on Tier
    final activeBlurs = attribution.blurPolicies.where((policy) {
      if (policy.reason == "TierGate") {
        return userTier != OnDemandTier.elite; 
      }
      if (policy.reason == "TimeGate") {
         return true; // Active
      }
      return false;
    }).toList();

    return Container(
      color: AppColors.surface1,
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context),
          const SizedBox(height: 24),
          _buildSectionTitle(context, "INPUTS CONSULTED"),
          const SizedBox(height: 8),
          ...attribution.inputs.map((e) => _buildInputRow(context, e)),
          
          const SizedBox(height: 16),
          _buildSectionTitle(context, "DERIVATION RULES"),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: attribution.rules.map((e) => _buildChip(context, e)).toList(),
          ),

          if (activeBlurs.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildSectionTitle(context, "ACTIVE RESTRICTIONS"),
            const SizedBox(height: 8),
            ...activeBlurs.map((e) => _buildBlurRow(context, e)),
          ] else if (userTier == OnDemandTier.elite) ...[
             const SizedBox(height: 24),
             _buildSectionTitle(context, "RESTRICTIONS"),
             const SizedBox(height: 8),
             Text(
               "No active tier restrictions. (Elite Unlocked)",
               style: AppTypography.caption(context).copyWith(
                 color: AppColors.marketBull, 
               ),
             ),
          ],
          
          const SizedBox(height: 24),
          _buildMetaRow(context, "Generated", attribution.generatedAtUtc),
          if (attribution.sourceLadderUsed != "UNKNOWN")
             _buildMetaRow(context, "Source", attribution.sourceLadderUsed),
             
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.account_tree_outlined, color: AppColors.neonCyan, size: 20),
        const SizedBox(width: 8),
        Text(
          "SOURCE ATTRIBUTION",
          style: AppTypography.title(context).copyWith(color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: AppTypography.label(context).copyWith(color: AppColors.textSecondary),
    );
  }

  Widget _buildInputRow(BuildContext context, InputConsulted input) {
    Color statusColor = AppColors.textSecondary;
    if (input.status == "LIVE" || input.status == "AVAILABLE" || input.status == "NOMINAL") {
      statusColor = AppColors.marketBull;
    } else if (input.status == "OFFLINE" || input.status == "ERROR") {
      statusColor = AppColors.marketBear;
    } else if (input.status.contains("STUB") || input.status == "DEMO") {
      statusColor = AppColors.stateStale; // Amber
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            input.engine,
            style: AppTypography.body(context).copyWith(color: AppColors.textPrimary),
          ),
          Text(
            input.status,
            style: AppTypography.caption(context).copyWith(color: statusColor),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBlurRow(BuildContext context, BlurPolicy policy) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderSubtle),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Row(
               children: [
                 Icon(Icons.lock_outline, size: 14, color: AppColors.stateLocked),
                 const SizedBox(width: 6),
                 Text(policy.surface, style: AppTypography.label(context).copyWith(color: AppColors.textPrimary)),
               ],
             ),
             const SizedBox(height: 4),
             Text(
               policy.explanation,
               style: AppTypography.body(context).copyWith(color: AppColors.textSecondary, fontSize: 13),
             ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label, 
        style: AppTypography.caption(context).copyWith(color: AppColors.neonCyan)
      ),
    );
  }
  
  Widget _buildMetaRow(BuildContext context, String label, String value) {
     return Padding(
       padding: const EdgeInsets.symmetric(vertical: 2),
       child: Row(
         children: [
           Text("$label: ", style: AppTypography.caption(context).copyWith(color: AppColors.textSecondary)),
           Expanded(
             child: Text(value, style: AppTypography.caption(context).copyWith(color: AppColors.textPrimary), overflow: TextOverflow.ellipsis),
           ),
         ],
       ),
     );
  }
}
