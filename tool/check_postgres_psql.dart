import 'dart:io';

Map<String, String> loadDotEnvFile(String path) {
  final file = File(path);
  if (!file.existsSync()) return {};
  final lines = file.readAsLinesSync();
  final map = <String, String>{};
  for (var line in lines) {
    line = line.trim();
    if (line.isEmpty) continue;
    if (line.startsWith('#')) continue;
    final idx = line.indexOf('=');
    if (idx <= 0) continue;
    final key = line.substring(0, idx).trim();
    var value = line.substring(idx + 1).trim();
    if (value.startsWith('"') && value.endsWith('"')) {
      value = value.substring(1, value.length - 1);
    }
    map[key] = value;
  }
  return map;
}

Future<int> runPsqlTest(String host, String port, String db, String user, String password) async {
  final args = ['-h', host, '-p', port, '-U', user, '-d', db, '-c', "SELECT 'ok' as result;" ];
  final env = Map<String, String>.from(Platform.environment);
  env['PGPASSWORD'] = password;
  print('Running: psql ${args.join(' ')}');
  final proc = await Process.start('psql', args, environment: env, runInShell: true);
  await stdout.addStream(proc.stdout);
  await stderr.addStream(proc.stderr);
  final code = await proc.exitCode;
  return code;
}

Future<void> main(List<String> args) async {
  final envPath = '.env';
  print('Loading $envPath');
  final env = loadDotEnvFile(envPath);
  final host = env['DB_HOST'] ?? 'localhost';
  final port = env['DB_PORT'] ?? '5432';
  final db = env['DB_NAME'] ?? 'postgres';
  final user = env['DB_USER'] ?? 'postgres';
  final password = env['DB_PASSWORD'] ?? '';

  try {
    final code = await runPsqlTest(host, port, db, user, password);
    print('psql exit code: $code');
    if (code == 0) {
      print('✅ Postgres reachable and accepted query via psql');
    } else {
      print('❌ psql returned non-zero exit code');
    }
  } catch (e) {
    print('Error running psql: $e');
  }
}
