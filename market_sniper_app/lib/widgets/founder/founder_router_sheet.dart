import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../logic/founder/founder_router_store.dart';
import '../../screens/command_center_screen.dart';
import '../../screens/war_room_screen.dart';

class FounderRouterSheet extends StatefulWidget {
  const FounderRouterSheet({super.key});

  @override
  State<FounderRouterSheet> createState() => _FounderRouterSheetState();
}

class _FounderRouterSheetState extends State<FounderRouterSheet> {
  String _selectedDestination = FounderRouterStore.warRoom;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final last = await FounderRouterStore.getLastDestination();
    if (mounted) {
      setState(() {
        _selectedDestination = last;
        _isLoading = false;
      });
    }
  }

  void _handleOpen() {
    // 1. Save
    FounderRouterStore.saveDestination(_selectedDestination);
    
    // 2. Navigate
    Navigator.pop(context); // Close sheet
    
    if (_selectedDestination == FounderRouterStore.warRoom) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const WarRoomScreen()));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const CommandCenterScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(top: BorderSide(color: AppColors.stateLive, width: 2)), // Founder Green
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
             children: [
                const Icon(Icons.security, color: AppColors.stateLive, size: 20),
                const SizedBox(width: 8),
                Text("FOUNDER ROUTER", style: AppTypography.label(context).copyWith(color: AppColors.stateLive)),
             ],
          ),
          const SizedBox(height: 24),
          
          // Selector
          Container(
             height: 48,
             decoration: BoxDecoration(
               color: AppColors.bgPrimary,
               borderRadius: BorderRadius.circular(8),
               border: Border.all(color: AppColors.borderSubtle),
             ),
             child: Row(
               children: [
                 _buildOption(FounderRouterStore.warRoom, "WAR ROOM"),
                 _buildOption(FounderRouterStore.commandCenter, "COMMAND CENTER"),
               ],
             ),
          ),
          
          const SizedBox(height: 12),
          Center(
            child: Text(
              "Founder router — choose destination",
              style: GoogleFonts.robotoMono(color: AppColors.textDisabled, fontSize: 10),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Action Buttons
          Row(
            children: [
               Expanded(
                 child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.borderSubtle),
                    ),
                    child: Text("CANCEL", style: AppTypography.label(context)),
                 ),
               ),
               const SizedBox(width: 16),
               Expanded(
                 child: ElevatedButton(
                    onPressed: _handleOpen,
                    style: ElevatedButton.styleFrom(
                       backgroundColor: AppColors.stateLive,
                       foregroundColor: AppColors.bgPrimary,
                    ),
                    child: Text("OPEN", style: AppTypography.label(context).copyWith(color: AppColors.bgPrimary)),
                 ),
               ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOption(String value, String label) {
    final isSelected = _selectedDestination == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedDestination = value),
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? AppColors.surface1 : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
          ),
          margin: const EdgeInsets.all(2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               if (isSelected) ...[
                  Container(
                    width: 6, height: 6,
                    decoration: const BoxDecoration(color: AppColors.accentCyan, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
               ],
               Text(
                 label, 
                 style: AppTypography.label(context).copyWith(
                   color: isSelected ? AppColors.textPrimary : AppColors.textDisabled,
                   fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                 )
               ),
            ],
          ),
        ),
      ),
    );
  }
}
