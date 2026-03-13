import 'package:flutter_dotenv/flutter_dotenv.dart';

class MapboxConfig {
  // Replace this with your actual public Mapbox Access Token
  static String get publicToken => dotenv.env['MAPBOX_PUBLIC_TOKEN'] ?? '';
}
