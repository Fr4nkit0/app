import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/presentation/rejection_message.dart';

void main() {
  const known = {
    "The cancellation was not made on the record's day.":
        'La anulación no se hizo el mismo día del registro.',
    'The cancellation is more than 3 days old.':
        'La anulación tiene más de 3 días.',
    "The edit was not made on the visit's day.":
        'La edición no se hizo el mismo día de la visita.',
    'The edit is more than 3 days old.': 'La edición tiene más de 3 días.',
    'The sale is cancelled.': 'La venta está anulada.',
    'The sale belongs to another customer.':
        'La venta pertenece a otro cliente.',
    "Only today's records can be cancelled.":
        'Solo se pueden anular registros del día.',
    "Only today's visits can be edited.":
        'Solo se pueden editar visitas del día.',
    'The primary address cannot be disabled.':
        'La dirección principal no se puede dar de baja.',
    'A customer needs a primary address.':
        'El cliente necesita una dirección principal.',
    'The time window end must be after its start.':
        'La hora de fin tiene que ser posterior a la de inicio.',
    'The customer already has a preference for that day and time.':
        'El cliente ya tiene una preferencia para ese día y horario.',
    'The sale belongs to another driver.': 'Pertenece a otro repartidor.',
    'The payment belongs to another driver.': 'Pertenece a otro repartidor.',
    'The visit belongs to another driver.': 'Pertenece a otro repartidor.',
    'The sale reference does not match any record.':
        'No se encontró el registro en el servidor.',
    'The payment reference does not match any record.':
        'No se encontró el registro en el servidor.',
    'The server_id does not match any customer preference.':
        'No se encontró el registro en el servidor.',
    'The server_id does not match any customer address.':
        'No se encontró el registro en el servidor.',
    'The record belongs to another customer.':
        'El registro pertenece a otro cliente.',
    'Customer is assigned to another driver.':
        'El cliente está asignado a otro repartidor.',
    'The server_id belongs to another app record.':
        'El registro del servidor pertenece a otro registro de la app.',
    'The visit reference does not match any record.':
        'No se encontró la visita en el servidor.',
  };

  for (final MapEntry(key: reason, value: spanish) in known.entries) {
    test('"$reason" is shown in Spanish', () {
      expect(rejectionMessage(reason), spanish);
    });
  }

  test('an unknown reason is shown as received', () {
    expect(rejectionMessage('Cliente dado de baja'), 'Cliente dado de baja');
  });

  test('a known reason with surrounding whitespace is still mapped', () {
    expect(
      rejectionMessage("  Only today's records can be cancelled.\n"),
      'Solo se pueden anular registros del día.',
    );
  });

  test('an unknown reason is trimmed but otherwise unchanged', () {
    expect(rejectionMessage('  Motivo X  '), 'Motivo X');
  });
}
