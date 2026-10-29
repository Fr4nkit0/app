abstract class NeighborhoodRepository {
  /// The enabled neighborhood names ordered by name, read from the synced
  /// catalog; the bundled Salta list while the catalog was never synced.
  Stream<List<String>> watchNames();
}
