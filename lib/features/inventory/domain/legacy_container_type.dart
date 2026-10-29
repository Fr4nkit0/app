/// Guesses a product's container type code from its name.
///
/// Fallback only, for products the server sent without a container type
/// (until Fr4nkit0/server#1 ships it for every product). This is the one
/// place in the app that may name container codes.
String? legacyContainerCodeFromName(String productName) {
  if (productName.contains('20L')) return 'BIDON_20L';
  if (productName.contains('Sifón')) return 'SIFON_2L';
  return null;
}
