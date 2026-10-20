/// Server base URL, injected at build time:
/// `flutter run --dart-define=API_BASE_URL=https://host/api/v1`.
const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');
