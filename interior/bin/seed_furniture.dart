// Optional helper: pushes assets/sample_furniture.json into the
// `furniture` node of your Realtime Database, so the Furniture Catalog
// screen (Phase 9) has something to show while developing.
//
// This is a one-off admin/dev tool, not part of the running app, but is
// still plain Dart (per the project's "no other backend language" rule).
//
// The `furniture` node is read-only for normal users (Sec. 26), so a
// regular signed-in user's ID token can't write here. The simplest
// options, in order of preference:
//
//   1. RECOMMENDED — Firebase console → Realtime Database → the
//      `furniture` node → "Import JSON" → select assets/sample_furniture.json.
//      No secrets involved, works in under a minute.
//
//   2. This script, using a legacy RTDB "database secret"
//      (Firebase console → Project settings → Service accounts →
//      Database secrets). Database secrets are deprecated by Google but
//      still function for RTDB and bypass security rules entirely —
//      treat one exactly like a root password: never commit it, never
//      log it, and prefer removing/rotating it once you're done seeding.
//
// Usage (option 2):
//   FIREBASE_DATABASE_URL="https://your-project-default-rtdb.firebaseio.com" \
//   FIREBASE_DATABASE_SECRET="your-secret" \
//   dart run bin/seed_furniture.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

Future<void> main() async {
  final databaseUrl = Platform.environment['FIREBASE_DATABASE_URL'];
  final secret = Platform.environment['FIREBASE_DATABASE_SECRET'];

  if (databaseUrl == null || databaseUrl.isEmpty) {
    stderr.writeln(
        'Missing FIREBASE_DATABASE_URL environment variable. See the '
        'comment at the top of this file for usage.');
    exit(1);
  }
  if (secret == null || secret.isEmpty) {
    stderr.writeln(
        'Missing FIREBASE_DATABASE_SECRET environment variable. Prefer '
        'using the Firebase console\'s "Import JSON" instead if you\'d '
        'rather not use a database secret at all.');
    exit(1);
  }

  final file = File('assets/sample_furniture.json');
  if (!file.existsSync()) {
    stderr.writeln('Could not find assets/sample_furniture.json.');
    exit(1);
  }

  final data = jsonDecode(await file.readAsString());
  final uri = Uri.parse('${databaseUrl.trimRight()}/furniture.json')
      .replace(queryParameters: {'auth': secret});

  stdout.writeln('Seeding ${(data as Map).length} furniture items…');
  final response = await http.put(uri, body: jsonEncode(data));

  if (response.statusCode == 200) {
    stdout.writeln('Done. Furniture catalog seeded successfully.');
  } else {
    stderr.writeln(
        'Failed (${response.statusCode}): ${response.body}');
    exit(1);
  }
}
