import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRService {
  static Widget generateQRCode(String data, {double size = 200}) {
    return QrImageView(
      data: data,
      version: QrVersions.auto,
      size: size,
      gapless: false,
      embeddedImage: const AssetImage('assets/logo.png'),
      embeddedImageStyle: const QrEmbeddedImageStyle(size: Size(40, 40)),
    );
  }

  static Widget buildQRScanner(
      Function(String) onQRScanned,
      BuildContext context,
      ) {
    return Stack(
      children: [
        MobileScanner(
          controller: MobileScannerController(
            facing: CameraFacing.back,
            detectionSpeed: DetectionSpeed.normal,
            detectionTimeoutMs: 1000,
          ),
          onDetect: (barcodeCapture) {
            final barcode = barcodeCapture.barcodes.first;
            if (barcode.rawValue != null) {
              onQRScanned(barcode.rawValue!);
            }
          },
        ),
        Center(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,
            height: MediaQuery.of(context).size.width * 0.8,
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).primaryColor,
                width: 4,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }
}
