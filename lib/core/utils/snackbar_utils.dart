import 'package:flutter/material.dart';

class SnackBarUtils {
  static void showSuccess(BuildContext context, String message) {
    _showSnackBar(
      context,
      message,
      const Color(0xFF66BB6A), // Soft Green (Material Green 400)
      Icons.check_circle_outline,
    );
  }

  static void showError(BuildContext context, String message) {
    _showSnackBar(
      context,
      message,
      const Color(0xFFEF5350), // Soft Red (Material Red 400)
      Icons.error_outline,
    );
  }

  static void showInfo(BuildContext context, String message) {
    _showSnackBar(
      context,
      message,
      const Color(0xFF42A5F5), // Soft Blue (Material Blue 400)
      Icons.info_outline,
    );
  }

  static void _showSnackBar(
    BuildContext context,
    String message,
    Color color,
    IconData icon,
  ) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Segoe UI', // Or default
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: color.withOpacity(0.95),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        elevation: 6,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
