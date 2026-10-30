import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The wall clock; tests override it so time-dependent rules are
/// deterministic.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
