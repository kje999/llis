import 'package:flutter/material.dart';
import 'package:my_lucky_lotto_pred/core/theme/app_theme.dart';

/// Shows a friendly "About the Developer" dialog with GCash / GCash InstaPay QR code.
class DeveloperInfoDialog extends StatelessWidget {
  const DeveloperInfoDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => const DeveloperInfoDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    // QR image takes up most of the dialog width (min 280, max 380)
    final qrSize = (screenWidth * 0.75).clamp(280.0, 380.0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: AppTheme.pcsoHeroGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.pcsoBlue.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.code_rounded, size: 32, color: Colors.white),
              ),
              const SizedBox(height: 14),
              const Text(
                'About the Developer',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'K.J. Espina',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.pcsoBlue,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Developer & Creator of LLIS\nPhilippine PCSO Lotto Information System',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.blueGrey, height: 1.5),
              ),
              const SizedBox(height: 18),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Buy me a coffee message
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.pcsoGold.withValues(alpha: 0.5)),
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('☕', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'If you enjoy using this app and want to support the work, you can buy me a coffee or send a little something through GCash InstaPay!',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.brown.shade800,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Every bit of support is very much appreciated! 🙏',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: Colors.brown.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // GCash QR Code label
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0E5FCB),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Center(
                      child: Text('G', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'GCash / InstaPay QR Code',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0E5FCB),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // LARGE QR Code image
              Container(
                width: qrSize,
                height: qrSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/gcash_qr.jpg',
                    width: qrSize,
                    height: qrSize,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      width: qrSize,
                      height: qrSize,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: const Center(
                        child: Icon(Icons.qr_code_2_rounded, size: 120, color: Colors.grey),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Scan instruction
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0E5FCB), Color(0xFF1565C0)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Open GCash App → Scan QR → Send via InstaPay',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.pcsoBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    elevation: 0,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Thanks so much! 🎉',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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

/// A compact icon button that opens the developer info dialog.
class DeveloperInfoButton extends StatelessWidget {
  final bool compact;
  const DeveloperInfoButton({super.key, this.compact = false});

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return IconButton(
        tooltip: 'Support the Developer ☕',
        onPressed: () => DeveloperInfoDialog.show(context),
        icon: const Icon(Icons.favorite_rounded, color: Colors.pinkAccent, size: 20),
      );
    }
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: Colors.pinkAccent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      onPressed: () => DeveloperInfoDialog.show(context),
      icon: const Icon(Icons.favorite_rounded, size: 15),
      label: const Text(
        'Support the Dev ☕',
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
