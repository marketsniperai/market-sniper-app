import 'package:flutter/material.dart';
import '../domain/universe/core20_universe.dart';
import '../screens/universe/universe_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class WatchlistAddModal extends StatefulWidget {
  const WatchlistAddModal({super.key});

  @override
  State<WatchlistAddModal> createState() => _WatchlistAddModalState();
}

class _WatchlistAddModalState extends State<WatchlistAddModal> {
  final TextEditingController _controller = TextEditingController();
  String? _error;
  // bool _isValid = false;

  void _validate() {
    setState(() {
      _error = null;
      // _isValid = false;
    });

    final input = _controller.text.trim();
    if (input.isEmpty) return;

    if (CoreUniverse.isCore20(input)) {
      // setState(() => _isValid = true);
      // In real app, here we would return the symbol or add to repo
      // For D39.01, we just validate UI behavior
      if (mounted) {
         Navigator.of(context).pop(input.toUpperCase());
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Mock: Added ${input.toUpperCase()} to Watchlist (Validation Passed)"))
         );
      }
    } else {
      setState(() {
         // _isValid = false;
         _error = "Institutional Guard: Symbol not in CORE20 universe yet.\nExtended Universe unlocks in D39.02.";
      });
    }
  }

  void _viewCore20() {
    Navigator.of(context).pop(); // Close modal
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const UniverseScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, 
        right: 16, 
        top: 16
      ),
      child: MainAxisSize.min == MainAxisSize.min ? 
       Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("ADD TICKER", style: AppTypography.title(context)),
              IconButton(
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: () => Navigator.of(context).pop(),
              )
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            style: AppTypography.body(context).copyWith(color: AppColors.textPrimary),
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: "Enter Symbol (e.g. SPX)",
              hintStyle: AppTypography.body(context).copyWith(color: AppColors.textDisabled),
              filled: true,
              fillColor: AppColors.surface2,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.accentCyan),
              ),
              errorText: _error,
              errorMaxLines: 3,
            ),
            onSubmitted: (_) => _validate(),
          ),
          if (_error != null)
             Padding(
               padding: const EdgeInsets.only(top: 8.0),
               child: TextButton(
                 onPressed: _viewCore20,
                 child: Text("VIEW CORE20 UNIVERSE >", style: AppTypography.label(context).copyWith(color: AppColors.accentCyan)),
               ),
             ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _validate,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surface2,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text("VALIDATE & ADD", style: AppTypography.label(context)),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ) : const SizedBox.shrink(),
    );
  }
}
