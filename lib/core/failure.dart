class Failure {
  final String message;
  final String? code;
  final Object? cause;
  final StackTrace? stackTrace;
  const Failure(this.message, {this.code, this.cause, this.stackTrace});
  @override
  String toString() => 'Failure($code): $message';
}
Failure mapError(Object error, [StackTrace? st]) {
  if (error is Failure) return error;
  return Failure(error.toString(), cause: error, stackTrace: st);
}
