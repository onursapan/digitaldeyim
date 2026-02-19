import 'package:flutter/material.dart';
import '../../../domain/entities/sector.dart';

/// Ghost Overlay — kamera ekranı üzerinde yarı şeffaf yönlendirme katmanı.
/// Statik animasyonlu oklar + yazı gösterir. ML Kit entegrasyonu Phase 2.
class GhostOverlay extends StatefulWidget {
  final ShootStep step;
  final bool isRecording;

  const GhostOverlay({
    super.key,
    required this.step,
    required this.isRecording,
  });

  @override
  State<GhostOverlay> createState() => _GhostOverlayState();
}

class _GhostOverlayState extends State<GhostOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );

    _slideAnimation = _buildSlideAnimation(widget.step.motion);
  }

  @override
  void didUpdateWidget(GhostOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step.id != widget.step.id) {
      _slideAnimation = _buildSlideAnimation(widget.step.motion);
    }
  }

  Animation<Offset> _buildSlideAnimation(CameraMotion motion) {
    final Offset begin;
    final Offset end;

    switch (motion) {
      case CameraMotion.slowUp:
        begin = const Offset(0, 0.05);
        end = const Offset(0, -0.05);
      case CameraMotion.zoomIn:
      case CameraMotion.zoomPunch:
        begin = const Offset(0, 0);
        end = const Offset(0, 0);
      case CameraMotion.halfCircle:
        begin = const Offset(-0.05, 0);
        end = const Offset(0.05, 0);
      case CameraMotion.slideRight:
        begin = const Offset(-0.05, 0);
        end = const Offset(0.05, 0);
      case CameraMotion.still:
        begin = const Offset(0, 0);
        end = const Offset(0, 0);
    }

    return Tween<Offset>(begin: begin, end: end).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Çerçeve kuralları — altın oran kılavuz çizgileri
        _buildGridLines(),

        // Hareket yönü oku
        Center(
          child: SlideTransition(
            position: _slideAnimation,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildMotionIndicator(widget.step.motion),
            ),
          ),
        ),

        // Kayıt sırasında kırmızı köşe indikatörleri
        if (widget.isRecording) _buildRecordingIndicators(),

        // Alt overlay — talimat metni
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: _buildInstructionBar(),
        ),
      ],
    );
  }

  Widget _buildGridLines() {
    return CustomPaint(
      painter: _GridLinePainter(),
      child: const SizedBox.expand(),
    );
  }

  Widget _buildMotionIndicator(CameraMotion motion) {
    switch (motion) {
      case CameraMotion.slowUp:
        return _arrowIcon(Icons.keyboard_arrow_up, size: 64);
      case CameraMotion.zoomIn:
      case CameraMotion.zoomPunch:
        return _zoomIndicator();
      case CameraMotion.halfCircle:
        return _arrowIcon(Icons.rotate_right, size: 64);
      case CameraMotion.slideRight:
        return _arrowIcon(Icons.keyboard_arrow_right, size: 64);
      case CameraMotion.still:
        return _stillIndicator();
    }
  }

  Widget _arrowIcon(IconData icon, {double size = 48}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFC9A96E).withValues(alpha: 0.8),
          width: 2,
        ),
      ),
      child: Icon(icon, color: const Color(0xFFC9A96E), size: size),
    );
  }

  Widget _zoomIndicator() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFC9A96E).withValues(alpha: 0.7),
          width: 2,
        ),
      ),
      child: Center(
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFC9A96E).withValues(alpha: 0.9),
              width: 2,
            ),
          ),
          child: const Icon(
            Icons.add,
            color: Color(0xFFC9A96E),
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _stillIndicator() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Icon(
        Icons.crop_free,
        color: Colors.white.withValues(alpha: 0.8),
        size: 40,
      ),
    );
  }

  Widget _buildRecordingIndicators() {
    return Stack(
      children: [
        // Sol üst
        Positioned(
          top: 12,
          left: 12,
          child: _cornerIndicator(topLeft: true),
        ),
        // Sağ üst
        Positioned(
          top: 12,
          right: 12,
          child: _cornerIndicator(topLeft: false),
        ),
        // Kayıt göstergesi
        Positioned(
          top: 20,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE53E3E).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.circle, color: Colors.white, size: 8),
                  SizedBox(width: 6),
                  Text(
                    'REC',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _cornerIndicator({required bool topLeft}) {
    return SizedBox(
      width: 24,
      height: 24,
      child: CustomPaint(
        painter: _CornerPainter(topLeft: topLeft),
      ),
    );
  }

  Widget _buildInstructionBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.black.withValues(alpha: 0.85),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.step.title,
            style: const TextStyle(
              color: Color(0xFFC9A96E),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.step.instruction,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          if (widget.step.overlayHint.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              widget.step.overlayHint,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Painters ─────────────────────────────────────────────────────────────────

class _GridLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 0.8;

    // Üçte bir kılavuz çizgileri (kural-üçler)
    canvas.drawLine(
      Offset(size.width / 3, 0),
      Offset(size.width / 3, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(size.width * 2 / 3, 0),
      Offset(size.width * 2 / 3, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height / 3),
      Offset(size.width, size.height / 3),
      paint,
    );
    canvas.drawLine(
      Offset(0, size.height * 2 / 3),
      Offset(size.width, size.height * 2 / 3),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CornerPainter extends CustomPainter {
  final bool topLeft;
  const _CornerPainter({required this.topLeft});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE53E3E)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    if (topLeft) {
      canvas.drawLine(Offset.zero, Offset(size.width, 0), paint);
      canvas.drawLine(Offset.zero, Offset(0, size.height), paint);
    } else {
      canvas.drawLine(Offset(size.width, 0), Offset(0, 0), paint);
      canvas.drawLine(Offset(size.width, 0), Offset(size.width, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
