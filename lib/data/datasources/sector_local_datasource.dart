import 'dart:convert';
import 'package:flutter/services.dart';
import '../../domain/entities/sector.dart';

class SectorLocalDatasource {
  static const _configPath = 'assets/sector_configs';

  static const _availableSectors = [
    'gelinlik',
    'market',
  ];

  Future<List<Sector>> loadAllSectors() async {
    final futures = _availableSectors.map(_loadSector);
    final results = await Future.wait(futures);
    return results.whereType<Sector>().toList();
  }

  Future<Sector?> loadSector(String sectorId) => _loadSector(sectorId);

  Future<Sector?> _loadSector(String sectorId) async {
    try {
      final jsonStr = await rootBundle.loadString('$_configPath/$sectorId.json');
      final map = json.decode(jsonStr) as Map<String, dynamic>;
      return _fromJson(map);
    } catch (e) {
      return null;
    }
  }

  Sector _fromJson(Map<String, dynamic> map) {
    final brief = map['directorBrief'] as Map<String, dynamic>;
    final style = map['visualStyle'] as Map<String, dynamic>;
    final checklist = brief['checklist'] as Map<String, dynamic>;

    return Sector(
      id: map['id'] as String,
      name: map['name'] as String,
      emoji: map['emoji'] as String,
      directorBrief: SectorDirectorBrief(
        hook: _stepFromJson(brief['hook'] as Map<String, dynamic>),
        detail: _stepFromJson(brief['detail'] as Map<String, dynamic>),
        exit: _stepFromJson(brief['exit'] as Map<String, dynamic>),
        checklist: CameraChecklist(
          minLux: (checklist['minLux'] as num).toDouble(),
          maxShake: (checklist['maxShake'] as num).toDouble(),
          lightingTip: checklist['lightingTip'] as String,
          backgroundTip: checklist['backgroundTip'] as String,
        ),
      ),
      visualStyle: SectorVisualStyle(
        primaryColorHex: style['primaryColorHex'] as String,
        accentColorHex: style['accentColorHex'] as String,
        fontStyle: style['fontStyle'] as String,
        musicMood: style['musicMood'] as String,
        cutRhythm: (style['cutRhythm'] as num).toDouble(),
        shotstackTemplateIds: List<String>.from(
          style['shotstackTemplateIds'] as List,
        ),
      ),
    );
  }

  ShootStep _stepFromJson(Map<String, dynamic> map) {
    return ShootStep(
      id: map['id'] as String,
      title: map['title'] as String,
      instruction: map['instruction'] as String,
      overlayHint: map['overlayHint'] as String,
      durationSeconds: map['durationSeconds'] as int,
      motion: CameraMotion.values.firstWhere(
        (m) => m.name == map['motion'],
        orElse: () => CameraMotion.still,
      ),
    );
  }
}
