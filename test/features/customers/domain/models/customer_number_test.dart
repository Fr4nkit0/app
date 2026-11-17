import 'package:flutter_test/flutter_test.dart';

import 'package:app/features/customers/domain/models/customer_number.dart';

void main() {
  test('formats the number as "#128"', () {
    expect(CustomerNumber.format(128), '#128');
  });

  test('a query of digits, with or without "#", asks for that number', () {
    expect(CustomerNumber.parse('128'), 128);
    expect(CustomerNumber.parse(' #128 '), 128);
    expect(CustomerNumber.parse('007'), 7);
  });

  test('any other query asks for no number', () {
    expect(CustomerNumber.parse(''), isNull);
    expect(CustomerNumber.parse('kiosco'), isNull);
    expect(CustomerNumber.parse('12 b'), isNull);
    expect(CustomerNumber.parse('#'), isNull);
  });

  test('only "#" followed by digits asks for the number alone', () {
    expect(CustomerNumber.isExplicit('#128'), isTrue);
    expect(CustomerNumber.isExplicit('128'), isFalse);
    expect(CustomerNumber.isExplicit('#abc'), isFalse);
  });

  test('matches only the exact number; a customer without one never '
      'matches a number', () {
    expect(CustomerNumber.matches('128', 128), isTrue);
    expect(CustomerNumber.matches('12', 128), isFalse);
    expect(CustomerNumber.matches('1280', 128), isFalse);
    expect(CustomerNumber.matches('128', null), isFalse);
    expect(CustomerNumber.matches('kiosco', 128), isFalse);
  });
}
