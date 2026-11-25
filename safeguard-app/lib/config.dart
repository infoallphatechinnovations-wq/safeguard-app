class Config {
  // Android emulator reaches your computer at 10.0.2.2. For a real phone or production,
  // build with: flutter run --dart-define=API_BASE=https://api.yourdomain.com/api
  static const apiBase =
      String.fromEnvironment('API_BASE', defaultValue: 'http://10.0.2.2:3000/api');
}
