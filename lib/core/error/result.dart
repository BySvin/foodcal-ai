import 'failure.dart';

/// Minimal Either-style wrapper for operations that can fail. Kept
/// hand-rolled (no fpdart dependency) since only two variants are needed.
sealed class Result<T> {
  const Result();

  factory Result.success(T value) = Success<T>;
  factory Result.failure(Failure failure) = Failed<T>;

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failed<T>;

  T? get valueOrNull => switch (this) {
        Success<T>(:final value) => value,
        Failed<T>() => null,
      };

  Failure? get failureOrNull => switch (this) {
        Success<T>() => null,
        Failed<T>(:final failure) => failure,
      };

  R fold<R>(R Function(T value) onSuccess, R Function(Failure failure) onFailure) {
    return switch (this) {
      Success<T>(:final value) => onSuccess(value),
      Failed<T>(:final failure) => onFailure(failure),
    };
  }
}

class Success<T> extends Result<T> {
  const Success(this.value);
  final T value;
}

class Failed<T> extends Result<T> {
  const Failed(this.failure);
  final Failure failure;
}
