
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../logic/api_client.dart'; // For submission
import 'dart:ui' as ui;

class EliteReflectionModal extends StatefulWidget {
  final VoidCallback onComplete;

  const EliteReflectionModal({super.key, required this.onComplete});

  @override
  State<EliteReflectionModal> createState() => _EliteReflectionModalState();
}


class _EliteReflectionModalState extends State<EliteReflectionModal> {
  final _q1Controller = TextEditingController(); // Focus
  final _q2Controller = TextEditingController(); // Difficulty
  final _q3Controller = TextEditingController(); // Learning
  
  bool _isSubmitting = false;

  @override
  void dispose() {
    _q1Controller.dispose();
    _q2Controller.dispose();
    _q3Controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
     setState(() => _isSubmitting = true);
     
     try {
        final now = DateTime.now().toUtc();
        final dateStr = "${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}";
        
        // D49 Prompt 11: 3 Specific Questions
        final payload = {
           "date": dateStr,
           "session_type": "REGULAR",
           "timestamp_utc": now.toIso8601String(),
           "answers": [
              {"question": "Focus", "answer": _q1Controller.text}, // ¿Qué mirabas hoy?
              {"question": "Difficulty", "answer": _q2Controller.text}, // ¿Qué decisión te costó más?
              {"question": "Learning", "answer": _q3Controller.text}, // ¿Qué aprendiste hoy?
           ],
           "system_context": {
              "regime": "UNKNOWN", // In real version, inject from Status Store
              "volatility": "UNKNOWN",
              "reliability": 1.0
           }
        };

        // Call API
        await ApiClient().post('/elite/reflection', payload);
        
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Reflection Logged.")));
           widget.onComplete(); // callback
           Navigator.pop(context);
        }
     } catch (e) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
        }
     } finally {
        if (mounted) setState(() => _isSubmitting = false);
     }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.90, // Taller for 3 questions
      decoration: BoxDecoration(
         color: AppColors.surface1,
         borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
         border: Border.all(color: AppColors.neonCyan.withValues(alpha: 0.3)),
         boxShadow: [BoxShadow(color: AppColors.bgPrimary.withValues(alpha: 0.5), blurRadius: 20)],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
           filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
           child: Column(
             children: [
               // Header
               Padding(
                 padding: const EdgeInsets.all(24),
                 child: Text("DAILY REFLECTION", style: AppTypography.headline(context).copyWith(color: AppColors.neonCyan)),
               ),
               Divider(color: AppColors.neonCyan.withValues(alpha: 0.2)),
               
               // Form
               Expanded(
                 child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                          _buildField("What were you watching? (Focus)", _q1Controller),
                          const SizedBox(height: 16),
                          _buildField("Hardest decision? (Difficulty)", _q2Controller),
                          const SizedBox(height: 16),
                          _buildField("What did you learn? (Synthesis)", _q3Controller),
                       ],
                    ),
                 ),
               ),
               
               // Actions
               Padding(
                 padding: const EdgeInsets.all(16),
                 child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                       style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.neonCyan.withValues(alpha: 0.2),
                          foregroundColor: AppColors.neonCyan,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: AppColors.neonCyan)
                       ),
                       onPressed: _isSubmitting ? null : _submit,
                       child: _isSubmitting 
                          ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text("COMMIT TO MIRROR", style: AppTypography.label(context)),
                    ),
                 ),
               )
             ],
           ),
        ),
      ),
    );
  }
  
  Widget _buildField(String label, TextEditingController controller) {
      return Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
            Text(label, style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
               controller: controller,
               maxLines: 3, // Reduced to fit 3 Qs
               style: const TextStyle(color: AppColors.textSecondary),
               decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.bgDeepVoid,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  hintText: "Enter your thoughts...",
                  hintStyle: TextStyle(color: AppColors.textDisabled.withValues(alpha: 0.5))
               ),
            )
         ],
      );
  }
}
