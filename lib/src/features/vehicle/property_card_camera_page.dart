import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

/// A local-only capture screen. It returns a temporary file path to the form;
/// persistence and OCR remain the responsibility of the caller.
class PropertyCardCameraPage extends StatefulWidget {
  const PropertyCardCameraPage({super.key});

  @override
  State<PropertyCardCameraPage> createState() => _PropertyCardCameraPageState();
}

class _PropertyCardCameraPageState extends State<PropertyCardCameraPage>
    with WidgetsBindingObserver {
  CameraController? _controller;
  CameraDescription? _description;
  String? _error;
  var _isCapturing = false;
  var _flashEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw CameraException('NoCamera', 'No hay cámara disponible.');
      }
      _description = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        _description!,
        ResolutionPreset.high,
        enableAudio: false,
      );
      _controller = controller;
      await controller.initialize();
      if (!mounted) return;
      setState(() {});
    } on CameraException catch (error) {
      if (!mounted) return;
      setState(() => _error = _messageFor(error));
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'No fue posible preparar la cámara.');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    if (state == AppLifecycleState.inactive) {
      controller.dispose();
      _controller = null;
    } else if (state == AppLifecycleState.resumed && _description != null) {
      _initializeCamera();
    }
  }

  Future<void> _capture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _isCapturing) {
      return;
    }
    setState(() => _isCapturing = true);
    try {
      final file = await controller.takePicture();
      if (mounted) Navigator.of(context).pop(file.path);
    } on CameraException catch (error) {
      if (mounted) setState(() => _error = _messageFor(error));
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _toggleFlash() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;
    final enabled = !_flashEnabled;
    try {
      await controller.setFlashMode(enabled ? FlashMode.torch : FlashMode.off);
      if (mounted) setState(() => _flashEnabled = enabled);
    } on CameraException catch (_) {
      if (mounted) {
        setState(() => _error = 'El flash no está disponible en esta cámara.');
      }
    }
  }

  String _messageFor(CameraException error) {
    if (error.code == 'CameraAccessDenied') {
      return 'Debes permitir el uso de la cámara para tomar la foto.';
    }
    return 'No fue posible usar la cámara. Inténtalo de nuevo o selecciona una imagen.';
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final initialized = controller?.value.isInitialized ?? false;
    return Scaffold(
      backgroundColor: const Color(0xFF101622),
      appBar: AppBar(
        backgroundColor: const Color(0xFF101622),
        foregroundColor: Colors.white,
        title: const Text('Encuadra la tarjeta'),
        actions: [
          IconButton(
            tooltip: _flashEnabled ? 'Apagar flash' : 'Encender flash',
            onPressed: initialized ? _toggleFlash : null,
            icon: Icon(_flashEnabled ? Icons.flash_on : Icons.flash_off),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: initialized
                    ? AspectRatio(
                        aspectRatio: controller!.value.aspectRatio,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CameraPreview(controller),
                            const _PropertyCardGuide(),
                          ],
                        ),
                      )
                    : _CameraLoading(error: _error),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 24, 26),
              child: Column(
                children: [
                  const Text(
                    'Ubica los cuatro bordes dentro del marco. Evita reflejos, sombras y texto cortado.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Color(0xFFD7E1F2), height: 1.35),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFFFFC1BB)),
                    ),
                  ],
                  const SizedBox(height: 18),
                  SizedBox(
                    width: 74,
                    height: 74,
                    child: FilledButton(
                      onPressed: initialized ? _capture : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF075DBA),
                        shape: const CircleBorder(),
                      ),
                      child: _isCapturing
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.camera_alt_rounded, size: 30),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PropertyCardGuide extends StatelessWidget {
  const _PropertyCardGuide();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: .86,
        child: AspectRatio(
          aspectRatio: 1.58,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF67B7FF), width: 3),
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Color(0x55000000), blurRadius: 18),
              ],
            ),
            child: const Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text(
                  'TARJETA COMPLETA Y LEGIBLE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .5,
                    shadows: [Shadow(color: Colors.black, blurRadius: 6)],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CameraLoading extends StatelessWidget {
  const _CameraLoading({this.error});

  final String? error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (error == null) const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            error ?? 'Preparando cámara…',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
