import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:applicationweb/services/postgres_service.dart';

Future<void> main() async {
  print('Loading .env...');
  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    print('Warning: could not load .env: $e');
  }

  print('Attempting Postgres initialization (may be disabled)...');
  try {
    await postgresService.initialize();
    print('Postgres initialized: ${postgresService.isConnected}');
    // PostgresService may be disabled in this build; do not access internal connection.
    await postgresService.close();
    print('Postgres initialize/close completed.');
  } catch (e, st) {
    print('Postgres initialization failed: $e');
    print(st);
  }
}
