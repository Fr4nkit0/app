sealed class Resource<T> {
  const Resource();

  const factory Resource.success(T value) = Success._;

  const factory Resource.error(Exception error) = Error._;
}

final class Success<T> extends Resource<T> {
  const Success._(this.value);

  final T value;

  @override
  String toString() => 'Resource<$T>.success($value)';
}

final class Error<T> extends Resource<T> {
  const Error._(this.error);

  final Exception error;

  @override
  String toString() => 'Resource<$T>.error($error)';
}
