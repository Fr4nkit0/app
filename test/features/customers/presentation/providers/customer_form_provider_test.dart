import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/customers/presentation/providers/customer_form_provider.dart';
import 'package:app/features/customers/presentation/providers/customer_form_state.dart';
import 'package:app/features/customers/domain/models/customer.preference.dart';

void main() {
  group('CustomerForm Notifier Tests', () {
    test('initializes with one default preference', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(customerFormProvider);

      expect(state.preferences.length, 1);
      expect(state.preferences.first.dayOfWeek, 1);
      expect(state.preferences.first.timeWindowStart, '08:00');
      expect(state.preferences.first.timeWindowEnd, '12:00');
    });

    test('isPreferenceValid is true when there is at least one preference', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(customerFormProvider);

      expect(state.preferences.isNotEmpty, true);
      expect(state.isPreferenceValid, true);
    });

    test('can add a new preference', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(customerFormProvider.notifier);
      notifier.addPreference();

      final state = container.read(customerFormProvider);
      expect(state.preferences.length, 2);
    });

    test('can remove a preference', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(customerFormProvider.notifier);
      notifier.addPreference(); // Now we have 2
      
      final stateBefore = container.read(customerFormProvider);
      final idToRemove = stateBefore.preferences.last.id;
      
      notifier.removePreference(idToRemove);

      final stateAfter = container.read(customerFormProvider);
      expect(stateAfter.preferences.length, 1);
      expect(stateAfter.preferences.any((p) => p.id == idToRemove), false);
    });

    test('cannot remove the last preference', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(customerFormProvider.notifier);
      final state = container.read(customerFormProvider);
      final id = state.preferences.first.id;

      notifier.removePreference(id);

      final stateAfter = container.read(customerFormProvider);
      expect(stateAfter.preferences.length, 1);
      expect(stateAfter.errorMessage, 'At least one preference is required.');
    });
  });
}
