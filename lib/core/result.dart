import 'failure.dart';
sealed class Result<T> {
  const Result();
  bool get isSuccess => this is Success<T>;
  bool get isError => this is Error<T>;
  T? get value => this is Success<T> ? (this as Success<T>).data : null;
  Failure? get failure => this is Error<T> ? (this as Error<T>).error : null;
  R fold<R>(R Function(Failure) onError, R Function(T) onSuccess) =>
      this is Error<T> ? onError((this as Error<T>).error) : onSuccess((this as Success<T>).data);
}
class Success<T> extends Result<T> { final T data; const Success(this.data); }
class Error<T> extends Result<T> { final Failure error; const Error(this.error); }
