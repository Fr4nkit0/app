import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/errors/domain_failure.dart';
import 'package:app/core/presentation/failure_message.dart';

void main() {
  const fallback = 'No se pudo guardar. Reintentá.';

  test('a ValidationFailure shows its own message', () {
    expect(
      failureMessage(
        const ValidationFailure('El precio debe ser mayor a 0.'),
        fallback: fallback,
      ),
      'El precio debe ser mayor a 0.',
    );
  });

  test('a NotFoundFailure shows the fallback', () {
    expect(
      failureMessage(const NotFoundFailure('customer'), fallback: fallback),
      fallback,
    );
  });

  test('a StorageFailure shows the fallback', () {
    expect(
      failureMessage(
        StorageFailure(Exception('disk full')),
        fallback: fallback,
      ),
      fallback,
    );
  });

  test('any other error shows the fallback', () {
    expect(failureMessage(Exception('boom'), fallback: fallback), fallback);
    expect(failureMessage(StateError('bug'), fallback: fallback), fallback);
  });
}
