import 'dart:convert';
import 'dart:io';

import 'package:cryptography/cryptography.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:cpns_journey/core/export.dart';
import 'package:cpns_journey/core/app_version.dart';
import 'package:cpns_journey/core/local_store_native.dart';
import 'package:cpns_journey/core/network_policy.dart';
import 'package:cpns_journey/core/state_cipher.dart';
import 'package:cpns_journey/core/services.dart';

import 'support/test_cipher.dart';

void main() {
  test('official links reject spoofed hosts, embedded credentials and nonstandard ports', () {
    expect(isGovernmentUrl('https://www.bkn.go.id/announcement.pdf'), isTrue);
    for (final url in [
      'https://www.bkn.go.id.evil.test',
      'https://user@www.bkn.go.id',
      'https://www.bkn.go.id:8443',
      'http://www.bkn.go.id',
      'https://example.test',
    ]) {
      expect(isGovernmentUrl(url), isFalse);
    }
  });
  test('minimum content version follows the shipped app version', () {
    expect(
      File('pubspec.yaml').readAsStringSync(),
      contains('version: $appVersion+'),
    );
    for (final value in [null, '0.9.9', '1.0.0', '1.0.3', appVersion]) {
      expect(supportsContentMinimum(value), isTrue);
    }
    for (final value in ['', 'invalid', '1.2.4', '1.3.0', '2.0.0', '-1.0.0']) {
      expect(supportsContentMinimum(value), isFalse);
    }
  });
  test('device encryption key persists through secure storage and is never recreated on a missing-key read', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final encrypted = await StateCipher.forDevice().encrypt(
      'guest',
      '{"alias":"Private"}',
    );
    final saved = await const FlutterSecureStorage().read(
      key: 'cpns-state-key-v1',
    );
    expect(base64Decode(saved!).length, 32);
    expect(
      await StateCipher.forDevice().decrypt('guest', encrypted),
      '{"alias":"Private"}',
    );
    FlutterSecureStorage.setMockInitialValues({});
    await expectLater(
      StateCipher.forDevice().decrypt('guest', encrypted),
      throwsStateError,
    );
    expect(
      await const FlutterSecureStorage().read(key: 'cpns-state-key-v1'),
      isNull,
    );
  });

  test('auth sessions and PKCE verifiers remain isolated between Supabase projects', () async {
    FlutterSecureStorage.setMockInitialValues({
      'supabase-session': 'legacy token',
    });
    const a = SecureSessionStorage('https://a.supabase.co');
    const b = SecureSessionStorage('https://b.supabase.co');
    await a.initialize();
    expect(
      await const FlutterSecureStorage().read(key: 'supabase-session'),
      isNull,
    );
    await a.persistSession('project A session');
    expect(await b.hasAccessToken(), isFalse);
    await b.persistSession('project B session');
    await a.removePersistedSession();
    expect(await b.accessToken(), 'project B session');
    const aPkce = SecurePkceStorage('https://a.supabase.co');
    const bPkce = SecurePkceStorage('https://b.supabase.co');
    await aPkce.setItem(key: 'verifier', value: 'private verifier');
    expect(await bPkce.getItem(key: 'verifier'), isNull);
    expect(await aPkce.getItem(key: 'verifier'), 'private verifier');
    await aPkce.removeItem(key: 'verifier');
    expect(await aPkce.getItem(key: 'verifier'), isNull);
  });
  test(
    'encryption uses fresh nonces, rejects tampering and account swapping',
    () async {
      final cipher = testCipher();
      final first = await cipher.encrypt('A', '{"alias":"Private nickname"}');
      final second = await cipher.encrypt('A', '{"alias":"Private nickname"}');
      expect(first, isNot(second));
      expect(first, isNot(contains('Private nickname')));
      expect(await cipher.decrypt('A', first), '{"alias":"Private nickname"}');
      await expectLater(
        cipher.decrypt('B', first),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
      final bytes = base64Decode(first.substring(StateCipher.prefix.length));
      bytes[13] ^= 1;
      await expectLater(
        cipher.decrypt('A', '${StateCipher.prefix}${base64Encode(bytes)}'),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
      final other = StateCipher(
        keyProvider: (_) async => SecretKey(List.filled(32, 99)),
      );
      await expectLater(
        other.decrypt('A', first),
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
    },
  );

  test(
    'missing secure key fails closed and never resets existing progress',
    () async {
      final payload = await testCipher().encrypt('A', '{"alias":"Keep me"}');
      final cipher = StateCipher(
        keyProvider: (create) async {
          expect(create, isFalse);
          throw StateError('key unavailable');
        },
      );
      await expectLater(cipher.decrypt('A', payload), throwsStateError);
      expect(payload, startsWith(StateCipher.prefix));
    },
  );

  test('legacy SQLite progress migrates atomically and survives encrypted cold reopen', () async {
    final directory = await Directory.systemTemp.createTemp('cpns-encryption-');
    final file = File('${directory.path}/state.sqlite');
    var db = JourneyDatabase(NativeDatabase(file));
    await db.customStatement('INSERT INTO local_state VALUES(?,?)', [
      'A',
      '{"alias":"Legacy private value"}',
    ]);
    await db.customStatement('INSERT INTO outbox VALUES(?,?,?)', [
      'old-op',
      'A',
      '2026-11-20',
    ]);
    await db.close();
    db = JourneyDatabase(NativeDatabase(file));
    var store = DriftStore(db, testCipher());
    expect((await store.read('A'))!['alias'], 'Legacy private value');
    final encrypted =
        (await db.customSelect('SELECT payload FROM local_state').getSingle())
            .read<String>('payload');
    expect(encrypted, startsWith(StateCipher.prefix));
    expect(await store.pending('A'), ['old-op']);
    await store.write('B', {'alias': 'Second private value'}, 'new-op');
    await store.close();
    expect(
      latin1.decode(await file.readAsBytes()),
      isNot(contains('Legacy private value')),
    );
    db = JourneyDatabase(NativeDatabase(file));
    store = DriftStore(db, testCipher());
    expect((await store.read('B'))!['alias'], 'Second private value');
    await db.customStatement(
      'UPDATE local_state SET payload=? WHERE namespace=?',
      [encrypted, 'B'],
    );
    await expectLater(
      store.read('B'),
      throwsA(isA<SecretBoxAuthenticationError>()),
    );
    await store.close();
    await directory.delete(recursive: true);
  });

  test(
    'failed encryption migration leaves every legacy row and outbox intact',
    () async {
      final db = JourneyDatabase(NativeDatabase.memory());
      await db.customStatement('INSERT INTO local_state VALUES(?,?)', [
        'A',
        '{"alias":"Retain"}',
      ]);
      await db.customStatement('INSERT INTO local_state VALUES(?,?)', [
        'B',
        'corrupt data',
      ]);
      final store = DriftStore(db, testCipher());
      await expectLater(store.read('A'), throwsFormatException);
      expect(
        (await db
                .customSelect(
                  "SELECT payload FROM local_state WHERE namespace='A'",
                )
                .getSingle())
            .read<String>('payload'),
        '{"alias":"Retain"}',
      );
      await store.close();
    },
  );

  test(
    'Supabase origin rejects credentials, paths, spoofed hosts and ports',
    () {
      expect(
        supabaseOrigin(' https://example.supabase.co/ ').toString(),
        'https://example.supabase.co',
      );
      for (final url in [
        'http://example.supabase.co',
        'https://example.supabase.co.evil.test',
        'https://user:password@example.supabase.co',
        'https://example.supabase.co:8443',
        'https://example.supabase.co/path',
        'https://example.supabase.co?x=1',
        'https://nested.example.supabase.co',
        'https://127.0.0.1',
      ]) {
        expect(() => supabaseOrigin(url), throwsFormatException, reason: url);
      }
    },
  );

  test('public key validator rejects secret/service-role and malformed JWT values', () {
    String jwt(Object payload) =>
        'header.${base64Url.encode(utf8.encode(jsonEncode(payload)))}.signature';
    expect(publicSupabaseKey(jwt({'role': 'anon'})), startsWith('header.'));
    expect(
      publicSupabaseKey(' sb_publishable_publicvalue '),
      'sb_publishable_publicvalue',
    );
    for (final key in [
      'sb_secret_privatevalue',
      jwt({'role': 'service_role'}),
      jwt({'role': 'authenticated'}),
      jwt([]),
      'not-a-key',
      'x' * 5000,
    ]) {
      expect(() => publicSupabaseKey(key), throwsFormatException);
    }
  });

  test('content must use public storage in the connected project', () {
    final project = supabaseOrigin('https://example.supabase.co');
    expect(
      publicContentUri(
        'https://example.supabase.co/storage/v1/object/public/content-packages/v2.json',
        project,
      ).host,
      project.host,
    );
    for (final url in [
      'https://other.supabase.co/storage/v1/object/public/bucket/file',
      'https://example.supabase.co/storage/v1/object/sign/bucket/file',
      'https://example.supabase.co/storage/v1/object/public/bucket/%2e%2e/file',
      'https://user@example.supabase.co/storage/v1/object/public/bucket/file',
      'http://example.supabase.co/storage/v1/object/public/bucket/file',
    ]) {
      expect(() => publicContentUri(url, project), throwsFormatException);
    }
  });

  test(
    'content downloader refuses redirects and sends no authorization token',
    () async {
      final client = MockClient((request) async {
        expect(request.followRedirects, isFalse);
        expect(request.headers.containsKey('authorization'), isFalse);
        return http.Response(
          '',
          302,
          headers: {'location': 'http://127.0.0.1/private'},
        );
      });
      await expectLater(
        downloadPublicContent(
          client,
          Uri.https('example.supabase.co', '/file'),
        ),
        throwsStateError,
      );
    },
  );

  test(
    'content downloader enforces streamed size without trusting content-length',
    () async {
      final client = MockClient.streaming(
        (request, body) async => http.StreamedResponse(
          Stream.fromIterable([
            List<int>.filled(maxContentBytes, 1),
            [2],
          ]),
          200,
        ),
      );
      await expectLater(
        downloadPublicContent(
          client,
          Uri.https('example.supabase.co', '/file'),
        ),
        throwsFormatException,
      );
    },
  );

  test('CSV exports neutralize formula prefixes after whitespace and control characters', () {
    for (final input in [
      '=1+1',
      '+1+1',
      '-1+1',
      '@SUM(A1)',
      '\t=1',
      '\r=1',
      '\n=1',
      '   =HYPERLINK("https://example.test")',
      '＝1+1',
      '＋1',
      '－1',
      '＠SUM(A1)',
    ]) {
      expect(csvCell(input), startsWith('"\''), reason: input);
    }
    expect(csvCell('plain "quote", value'), '"plain ""quote"", value"');
  });
}
