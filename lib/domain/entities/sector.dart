import 'package:equatable/equatable.dart';

/// Sektörel Zeka Katmanı — Her meslek kendi "Yönetmenlik Anayasası"nı taşır.
class Sector extends Equatable {
  final String id;
  final String name;
  final String emoji;
  final SectorDirectorBrief directorBrief;
  final SectorVisualStyle visualStyle;

  const Sector({
    required this.id,
    required this.name,
    required this.emoji,
    required this.directorBrief,
    required this.visualStyle,
  });

  @override
  List<Object> get props => [id];
}

/// 3 aşamalı çekim paketi — her sektöre özel
class SectorDirectorBrief extends Equatable {
  final ShootStep hook;
  final ShootStep detail;
  final ShootStep exit;
  final CameraChecklist checklist;

  const SectorDirectorBrief({
    required this.hook,
    required this.detail,
    required this.exit,
    required this.checklist,
  });

  List<ShootStep> get steps => [hook, detail, exit];

  @override
  List<Object> get props => [hook, detail, exit];
}

class ShootStep extends Equatable {
  final String id;
  final String title;
  final String instruction;
  final String overlayHint; // Ghost overlay için kısa ipucu
  final int durationSeconds;
  final CameraMotion motion;

  const ShootStep({
    required this.id,
    required this.title,
    required this.instruction,
    required this.overlayHint,
    required this.durationSeconds,
    required this.motion,
  });

  @override
  List<Object> get props => [id];
}

enum CameraMotion {
  still,       // Sabit
  slowUp,      // Yavaş yukarı
  zoomIn,      // Yakınlaş
  zoomPunch,   // Hızlı yakınlaş
  halfCircle,  // Yarım daire
  slideRight,  // Sağa kay
}

class CameraChecklist extends Equatable {
  final double minLux;
  final double maxShake;
  final String lightingTip;
  final String backgroundTip;

  const CameraChecklist({
    required this.minLux,
    required this.maxShake,
    required this.lightingTip,
    required this.backgroundTip,
  });

  @override
  List<Object> get props => [minLux, maxShake];
}

/// Kurgu ve grafik dili
class SectorVisualStyle extends Equatable {
  final String primaryColorHex;
  final String accentColorHex;
  final String fontStyle; // 'elegant', 'bold', 'modern', 'warm'
  final String musicMood; // 'cinematic', 'upbeat', 'calm', 'energetic'
  final double cutRhythm; // saniye bazında kesim ritmi
  final List<String> shotstackTemplateIds;

  const SectorVisualStyle({
    required this.primaryColorHex,
    required this.accentColorHex,
    required this.fontStyle,
    required this.musicMood,
    required this.cutRhythm,
    required this.shotstackTemplateIds,
  });

  @override
  List<Object> get props => [primaryColorHex, fontStyle];
}
