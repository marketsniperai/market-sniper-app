
import os

file_path = r'c:\MSR\MarketSniperRepo\market_sniper_app\lib\screens\universe\universe_screen.dart'

new_sentinel_code = r'''  Widget _buildSectorSentinelSection(SectorSentinelSnapshot sentinel) {
    final bool isUnavailable = sentinel.state == "UNAVAILABLE";
    Color stateColor;
    if (sentinel.state == "ACTIVE") {
      stateColor = AppColors.stateLive;
    } else if (sentinel.state == "STALE") {
      stateColor = AppColors.stateStale;
    } else if (sentinel.state == "DISABLED") {
      stateColor = AppColors.textDisabled;
    } else {
      stateColor = AppColors.stateLocked;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.shield_outlined, color: AppColors.textSecondary, size: 16),
                const SizedBox(width: 8),
                Text(
                  "SECTOR SENTINEL (RT)",
                  style: AppTypography.label(context).copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
            Row(
              children: [
                if (sentinel.ageSeconds != null)
                   Text("${sentinel.ageSeconds}s ", style: AppTypography.caption(context).copyWith(fontSize: 10, color: AppColors.textDisabled)),
                _buildStatusBadge(sentinel.state),
              ],
            )
          ],
        ),
        const SizedBox(height: 12),
        
        // Content
        if (isUnavailable)
           Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.stateLocked.withValues(alpha: 0.1),
                border: const Border(left: BorderSide(color: AppColors.stateLocked, width: 4)),
              ),
              child: Text("SENTINEL UNAVAILABLE", style: AppTypography.caption(context).copyWith(color: AppColors.stateLocked, fontWeight: FontWeight.bold)),
            )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
               color: AppColors.surface1,
               borderRadius: BorderRadius.circular(8),
               border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Column(
              children: [
                 if (sentinel.lastIngestUtc != null) ...[
                    Align(
                      alignment: Alignment.centerRight,
                      child: Text("INGEST: ${sentinel.lastIngestUtc!.toUtc().toString().split('.').first}Z", style: AppTypography.caption(context).copyWith(fontSize: 9, color: AppColors.textDisabled, fontStyle: FontStyle.italic)),
                    ),
                    const SizedBox(height: 8),
                 ],
                 Wrap(
                   spacing: 6,
                   runSpacing: 6,
                   children: sentinel.sectors.map((s) {
                      Color chipColor = AppColors.textDisabled;
                      if (s.status == "OK" || s.status == "ACTIVE") chipColor = AppColors.stateLive;
                      if (s.status == "STALE" || s.status == "DEGRADED") chipColor = AppColors.stateStale;
                      if (s.status == "UNAVAILABLE") chipColor = AppColors.stateLocked;
                      
                      return Container(
                         padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                         decoration: BoxDecoration(
                            color: chipColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(color: chipColor.withValues(alpha: 0.3)),
                         ),
                         child: Text(s.sector, style: AppTypography.caption(context).copyWith(fontSize: 10, color: chipColor, fontWeight: FontWeight.bold)),
                      );
                   }).toList(),
                 ),
                 const SizedBox(height: 8),
                 Align(
                    alignment: Alignment.centerLeft,
                    child: Text("Real-time sector integrity monitor.", style: AppTypography.caption(context).copyWith(fontSize: 10, color: AppColors.textDisabled)),
                 )
              ],
            ),
          )
      ],
    );
  }'''

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

start_index = -1
end_index = -1

# Find start of sentinel section
for i, line in enumerate(lines):
    if 'Widget _buildSectorSentinelSection(SectorSentinelSnapshot sentinel) {' in line:
        start_index = i
        break

if start_index != -1:
    # Find end (naive brace matching or just known next function)
    # We know _buildSectorSentinelSection ends before _buildSentinelHeatmapSection (which we already replaced? No, failing too)
    # Or before _buildGlobalPulseSynthesisSection?
    # Actually, we can just walk until we find the closing brace at level 0 relative to start?
    
    # Let's verify what follows. It used to be _buildSectorSentinelChip (deleted) or _buildSentinelHeatmapSection.
    # We will search for the start of the NEXT function to define the end, or brace counting.
    
    brace_count = 0
    found_start = False
    for i in range(start_index, len(lines)):
        line = lines[i]
        brace_count += line.count('{')
        brace_count -= line.count('}')
        if brace_count == 0:
            end_index = i
            break

if start_index != -1 and end_index != -1:
    print(f"Replacing lines {start_index} to {end_index}")
    # Replace (inclusive)
    new_lines = lines[:start_index] + [new_sentinel_code + '\n'] + lines[end_index+1:]
    
    with open(file_path, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)
    print("Success")
else:
    print("Could not find start or end")

