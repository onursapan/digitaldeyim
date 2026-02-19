import 'package:equatable/equatable.dart';
import 'sector.dart';

class UserProfile extends Equatable {
  final String id;
  final String email;
  final String businessName;
  final Sector sector;
  final List<String> topProducts;
  final BusinessVibe vibe;
  final TargetAudience audience;
  final String? brandToneAnalysis; // Gemini'nin ses analizinden çıkan metin
  final int credits;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.email,
    required this.businessName,
    required this.sector,
    required this.topProducts,
    required this.vibe,
    required this.audience,
    this.brandToneAnalysis,
    this.credits = 3,
    required this.createdAt,
  });

  UserProfile copyWith({
    String? brandToneAnalysis,
    int? credits,
    List<String>? topProducts,
  }) {
    return UserProfile(
      id: id,
      email: email,
      businessName: businessName,
      sector: sector,
      topProducts: topProducts ?? this.topProducts,
      vibe: vibe,
      audience: audience,
      brandToneAnalysis: brandToneAnalysis ?? this.brandToneAnalysis,
      credits: credits ?? this.credits,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, email, businessName, sector, credits];
}

enum BusinessVibe {
  luxury('Lüks & Sofistike'),
  friendly('Samimi & Sıcak'),
  tech('Teknolojik & Modern'),
  traditional('Geleneksel & Güvenilir');

  final String label;
  const BusinessVibe(this.label);
}

enum TargetAudience {
  youth('Gençler (18-30)'),
  families('Aileler'),
  professionals('Profesyoneller'),
  mixed('Karma');

  final String label;
  const TargetAudience(this.label);
}
