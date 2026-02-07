import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class InlineBarcodeScanner extends StatefulWidget {
  final ValueChanged<String> onBarcodeDetected;
  final VoidCallback onClose;

  const InlineBarcodeScanner({
    super.key,
    required this.onBarcodeDetected,
    required this.onClose,
  });

  @override
  State<InlineBarcodeScanner> createState() => _InlineBarcodeScannerState();
}

class _InlineBarcodeScannerState extends State<InlineBarcodeScanner> {
  late MobileScannerController controller;

  @override
  void initState() {
    super.initState();
    // 1. Configure for linear barcodes only for accuracy
    controller = MobileScannerController(
      formats: const [
        BarcodeFormat.ean13,
        BarcodeFormat.ean8,
        BarcodeFormat.code128,
        BarcodeFormat.code39,
        BarcodeFormat.code93,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
        BarcodeFormat.codabar,
        BarcodeFormat.itf,
      ],
      detectionSpeed: DetectionSpeed.normal, // Balanced speed
      returnImage: false,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 250,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        alignment: Alignment.center,
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  // Stop scanning after detection to prevent duplicates
                  controller.stop();
                  widget.onBarcodeDetected(barcode.rawValue!);
                  break;
                }
              }
            },
          ),

          // Red line indicator
          Container(
            height: 2,
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(1),
              boxShadow: const [
                BoxShadow(color: Colors.redAccent, blurRadius: 4),
              ],
            ),
          ),

          // Close button
          Positioned(
            top: 8,
            right: 8,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              radius: 16,
              child: IconButton(
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.close, size: 18, color: Colors.white),
                onPressed: widget.onClose,
              ),
            ),
          ),

          // Torch toggle
          Positioned(
            bottom: 8,
            right: 8,
            child: ValueListenableBuilder(
              valueListenable: controller,
              builder: (context, state, child) {
                return IconButton(
                  icon: Icon(
                    state.torchState == TorchState.on
                        ? Icons.flash_on
                        : Icons.flash_off,
                    color: Colors.white,
                  ),
                  onPressed: () => controller.toggleTorch(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
