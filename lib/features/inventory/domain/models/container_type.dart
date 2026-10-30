import 'package:flutter/foundation.dart';

/// A kind of returnable container, as the server's catalog defines it.
@immutable
class ContainerType {
  const ContainerType({
    required this.id,
    required this.code,
    required this.label,
  });

  /// The catalog row. The label is the short name of the product that uses
  /// the type ("Bidón 20L") when exactly one product does; otherwise the
  /// catalog description, or the code when the server sent none.
  factory ContainerType.fromCatalog({
    required int id,
    required String code,
    required String? description,
    String? productName,
  }) {
    final name = productName?.trim() ?? '';
    if (name.isNotEmpty) {
      return ContainerType(id: id, code: code, label: name);
    }
    final text = description?.trim() ?? '';
    return ContainerType(id: id, code: code, label: text.isEmpty ? code : text);
  }

  final int id;
  final String code;
  final String label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContainerType &&
          other.id == id &&
          other.code == code &&
          other.label == label;

  @override
  int get hashCode => Object.hash(id, code, label);
}
