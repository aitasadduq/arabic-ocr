import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../labels.dart';

/// In-app camera for pages: a page frame to aim with, flash, and several shots
/// in a row. Pops with the captured file paths.
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

enum _CameraIssue { none, permission, unavailable }

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  _CameraIssue _issue = _CameraIssue.none;
  final _shots = <String>[];
  FlashMode _flash = FlashMode.off;
  bool _busy = false;
  bool _flashOverlay = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      if (c != null && c.value.isInitialized) {
        _controller = null;
        c.dispose();
        if (mounted) setState(() {});
      }
    } else if (state == AppLifecycleState.resumed && _controller == null) {
      _init();
    }
  }

  Future<void> _init() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _issue = _CameraIssue.unavailable);
        return;
      }
      final back = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final c = CameraController(
        back,
        ResolutionPreset.max,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await c.initialize();
      await c.setFlashMode(_flash).catchError((_) {});
      if (!mounted) {
        await c.dispose();
        return;
      }
      setState(() {
        _controller = c;
        _issue = _CameraIssue.none;
      });
    } on CameraException catch (e) {
      if (!mounted) return;
      setState(() {
        _issue = e.code.startsWith('CameraAccess')
            ? _CameraIssue.permission
            : _CameraIssue.unavailable;
      });
    }
  }

  Future<void> _shoot() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized || _busy) return;
    setState(() {
      _busy = true;
      _flashOverlay = true;
    });
    unawaited(HapticFeedback.mediumImpact());
    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) setState(() => _flashOverlay = false);
    });
    try {
      final file = await c.takePicture();
      setState(() => _shots.add(file.path));
    } on CameraException {
      // a failed shot is simply not added
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cycleFlash() async {
    final next = switch (_flash) {
      FlashMode.off => FlashMode.auto,
      FlashMode.auto => FlashMode.torch,
      _ => FlashMode.off,
    };
    try {
      await _controller?.setFlashMode(next);
      setState(() => _flash = next);
    } on CameraException {
      // no flash on this camera
    }
  }

  Future<void> _focusAt(TapDownDetails d, BoxConstraints box) async {
    final c = _controller;
    if (c == null) return;
    final p = Offset(
      d.localPosition.dx / box.maxWidth,
      d.localPosition.dy / box.maxHeight,
    );
    try {
      await c.setFocusPoint(p);
      await c.setExposurePoint(p);
    } on CameraException {
      // fixed-focus camera
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final c = _controller;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (c != null && c.value.isInitialized)
              LayoutBuilder(
                builder: (context, box) => GestureDetector(
                  onTapDown: (d) => _focusAt(d, box),
                  child: ClipRect(
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: box.maxWidth,
                        height: box.maxWidth * c.value.aspectRatio,
                        child: CameraPreview(c),
                      ),
                    ),
                  ),
                ),
              )
            else if (_issue != _CameraIssue.none)
              _Issue(issue: _issue)
            else
              const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            if (c != null && c.value.isInitialized)
              IgnorePointer(
                child: CustomPaint(
                  painter: _FramePainter(),
                  child: const SizedBox.expand(),
                ),
              ),
            AnimatedOpacity(
              opacity: _flashOverlay ? 0.7 : 0,
              duration: const Duration(milliseconds: 90),
              child: const IgnorePointer(
                child: ColoredBox(color: Colors.white),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          tooltip: MaterialLocalizations.of(context)
                              .closeButtonTooltip,
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        Expanded(
                          child: Text(
                            l.cameraHint,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: l.cameraFlash,
                          icon: Icon(switch (_flash) {
                            FlashMode.auto => Icons.flash_auto_rounded,
                            FlashMode.torch => Icons.flashlight_on_rounded,
                            _ => Icons.flash_off_rounded,
                          }, color: Colors.white),
                          onPressed: c == null ? null : _cycleFlash,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _ShotStack(paths: _shots),
                        _Shutter(onTap: c == null ? null : _shoot, busy: _busy),
                        SizedBox(
                          width: 88,
                          child: _shots.isEmpty
                              ? null
                              : FilledButton(
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(80, 48),
                                  ),
                                  onPressed: () => Navigator.pop(
                                    context,
                                    List<String>.of(_shots),
                                  ),
                                  child: Text(l.cameraDone),
                                ),
                        ),
                      ],
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

class _Issue extends StatelessWidget {
  const _Issue({required this.issue});
  final _CameraIssue issue;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.no_photography_outlined,
              color: Colors.white70,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              issue == _CameraIssue.permission
                  ? l.cameraPermission
                  : l.cameraUnavailable,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
            if (issue == _CameraIssue.permission && Platform.isIOS) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => launchUrl(Uri.parse('app-settings:')),
                child: Text(l.openSettings),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Shutter extends StatelessWidget {
  const _Shutter({required this.onTap, required this.busy});
  final VoidCallback? onTap;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: context.l10n.cameraTitle,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 78,
          height: 78,
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: busy ? Colors.white54 : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}

class _ShotStack extends StatelessWidget {
  const _ShotStack({required this.paths});
  final List<String> paths;

  @override
  Widget build(BuildContext context) {
    if (paths.isEmpty) return const SizedBox(width: 88);
    return SizedBox(
      width: 88,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: Badge(
          label: Text('${paths.length}'),
          child: Container(
            width: 52,
            height: 68,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Image.file(
              File(paths.last),
              fit: BoxFit.cover,
              cacheWidth: 160,
            ),
          ),
        ),
      ),
    );
  }
}

/// Dims the preview outside a page-shaped frame and marks its corners.
class _FramePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const aspect = 0.72; // close to A4 / letter
    final maxW = size.width * 0.86, maxH = size.height * 0.68;
    var w = maxW, h = w / aspect;
    if (h > maxH) {
      h = maxH;
      w = h * aspect;
    }
    final rect = Rect.fromCenter(
      center: size.center(const Offset(0, -10)),
      width: w,
      height: h,
    );
    final rr = RRect.fromRectAndRadius(rect, const Radius.circular(18));
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(Offset.zero & size),
        Path()..addRRect(rr),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.35),
    );
    final p = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    const k = 28.0;
    for (final (c, dx, dy) in [
      (rect.topLeft, 1.0, 1.0),
      (rect.topRight, -1.0, 1.0),
      (rect.bottomLeft, 1.0, -1.0),
      (rect.bottomRight, -1.0, -1.0),
    ]) {
      canvas.drawPath(
        Path()
          ..moveTo(c.dx, c.dy + dy * k)
          ..lineTo(c.dx, c.dy + dy * 10)
          ..quadraticBezierTo(c.dx, c.dy, c.dx + dx * 10, c.dy)
          ..lineTo(c.dx + dx * k, c.dy),
        p,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
