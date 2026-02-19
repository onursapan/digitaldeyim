import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;
  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Bağlantı hatası. Lütfen internet bağlantınızı kontrol edin.']);
}

class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Sunucu hatası. Lütfen tekrar deneyin.']);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Giriş yapılamadı.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class CameraFailure extends Failure {
  const CameraFailure(super.message);
}

class RenderFailure extends Failure {
  const RenderFailure(super.message);
}

class InsufficientCreditsFailure extends Failure {
  const InsufficientCreditsFailure()
      : super('Yetersiz kredi. Lütfen kredi satın alın.');
}
