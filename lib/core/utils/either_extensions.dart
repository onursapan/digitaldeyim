import 'package:dartz/dartz.dart';
import '../error/failures.dart';

typedef AppResult<T> = Either<Failure, T>;

extension EitherExtension<L, R> on Either<L, R> {
  R? getOrNull() => fold((_) => null, (r) => r);
  bool get isSuccess => isRight();
  bool get isFailure => isLeft();
}
