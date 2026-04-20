import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_constant.dart';
import 'glassmorphic_container.dart';

// Simplified Popup for Free Plan Only
class PremiumLimitPopup extends StatelessWidget {
  final Duration waitTime;
  final VoidCallback onSubscribe; // Kept for compatibility but unused in UI for now
  final VoidCallback onWait;

  const PremiumLimitPopup({
    super.key,
    required this.waitTime,
    required this.onSubscribe,
    required this.onWait,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassmorphicContainer(
        blur: 20,
        borderRadius: BorderRadius.circular(24),
        borderWidth: 1.5,
        borderColor: Colors.white.withOpacity(0.2),
        color: const Color(0xFF1E1E1E).withOpacity(0.9),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppConstant.PRIMARY_COLOR.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.hourglass_empty,
                  size: 40,
                  color: AppConstant.PRIMARY_COLOR,
                ),
              ),
              const SizedBox(height: 20),
              
              Text(
                "Limit Reached",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 12),
              
              Text(
                "You've reached the usage limit for now.",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 24),
              
              // Wait Button (Primary Action now)
              ElevatedButton(
                onPressed: onWait,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstant.PRIMARY_COLOR,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  "Wait for ${waitTime.inMinutes}m ${waitTime.inSeconds % 60}s",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
