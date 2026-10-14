import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../core/design/design_system.dart';

/// Abre a câmera para ler o código de barras (EAN/UPC) e devolve os dígitos.
/// Também permite digitar o código quando a leitura não funciona.
Future<String?> scanBarcode(BuildContext context) => Navigator.of(context).push<String>(
  MaterialPageRoute(fullscreenDialog: true, builder: (_) => const BarcodeScannerPage()),
);

class BarcodeScannerPage extends StatefulWidget {
  const BarcodeScannerPage({super.key});

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage> {
  final _controller = MobileScannerController(
    formats: const [BarcodeFormat.ean13, BarcodeFormat.ean8, BarcodeFormat.upcA, BarcodeFormat.upcE],
    detectionSpeed: DetectionSpeed.noDuplicates,
  );
  bool _done = false;

  static final _valid = RegExp(r'^\d{8,14}$');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish(String code) {
    if (_done) return;
    _done = true;
    HapticFeedback.selectionClick();
    Navigator.of(context).pop(code);
  }

  void _onDetect(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value != null && _valid.hasMatch(value)) {
        _finish(value);
        return;
      }
    }
  }

  Future<void> _typeCode() async {
    final input = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Digitar código'),
        content: TextField(
          controller: input,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(14)],
          decoration: const InputDecoration(labelText: 'Números abaixo das barras'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.of(context).pop(input.text.trim()), child: const Text('Buscar')),
        ],
      ),
    );
    input.dispose();
    if (code == null || !mounted) return;
    if (_valid.hasMatch(code)) {
      _finish(code);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('O código tem de 8 a 14 números.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    appBar: AppBar(
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      title: const Text('Código de barras'),
      actions: [
        IconButton(
          tooltip: 'Lanterna',
          icon: const Icon(Icons.flashlight_on_outlined),
          onPressed: _controller.toggleTorch,
        ),
      ],
    ),
    body: Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(
          controller: _controller,
          onDetect: _onDetect,
          errorBuilder: (context, error) => Center(
            child: Padding(
              padding: const EdgeInsets.all(Space.xl),
              child: Text(
                'Não foi possível usar a câmera. Verifique a permissão nas configurações ou digite o código.',
                textAlign: TextAlign.center,
                style: context.text.bodyMedium?.copyWith(color: Colors.white),
              ),
            ),
          ),
        ),
        IgnorePointer(
          child: Center(
            child: Container(
              width: 280,
              height: 160,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white, width: 2),
                borderRadius: BorderRadius.circular(Radii.md),
              ),
            ),
          ),
        ),
        Positioned(
          left: Space.page,
          right: Space.page,
          bottom: Space.xxxl,
          child: Column(
            children: [
              Text(
                'Aponte para o código de barras da embalagem.',
                textAlign: TextAlign.center,
                style: context.text.bodyMedium?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: Space.md),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: const BorderSide(color: Colors.white)),
                onPressed: _typeCode,
                icon: const Icon(Icons.keyboard_outlined),
                label: const Text('Digitar código'),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
