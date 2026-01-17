import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/watchlist_add_modal.dart';

class WatchlistScreen extends StatelessWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Handled by MainLayout
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.list_alt, size: 48, color: AppColors.textDisabled),
            const SizedBox(height: 16),
            Text(
              "Watchlist Coming Soon (D44)", 
              style: AppTypography.headline(context)
            ),
            const SizedBox(height: 8),
            Text(
              "Use the button below to test D39.01 Validation",
              style: AppTypography.body(context).copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
           showModalBottomSheet(
             context: context,
             isScrollControlled: true,
             backgroundColor: AppColors.surface1,
             shape: const RoundedRectangleBorder(
               borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
             ),
             builder: (_) => const WatchlistAddModal(),
           );
        },
        backgroundColor: AppColors.accentCyan,
        icon: const Icon(Icons.add, color: AppColors.bgPrimary),
        label: Text("ADD TICKER", style: AppTypography.label(context).copyWith(color: AppColors.bgPrimary, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
