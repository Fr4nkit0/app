/// Server rejection reasons the driver sees in Spanish, keyed by the exact
/// English text the server sends. Add new reasons here as the server adds them.
const _spanishRejections = {
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
};

/// The driver-facing text for a stored server rejection [reason]: the Spanish
/// copy of a known reason, otherwise the reason as received (trimmed).
///
/// Presentation only; the stored reason is never rewritten.
String rejectionMessage(String reason) {
  final key = reason.trim();
  return _spanishRejections[key] ?? key;
}
