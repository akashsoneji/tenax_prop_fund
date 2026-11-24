import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tenax_prop_flutter/app/flavor/config_cipher.dart';
import 'package:tenax_prop_flutter/app/flavor/flavor_config.dart';
import 'package:tenax_prop_flutter/core/network/pinned_http_client.dart';

void main() {
  group('ConfigCipher', () {
    final key = List<int>.generate(32, (i) => (i * 37 + 11) % 256);

    test('round-trips the flavor config', () {
      const plain = '{"API_BASE_URL":"https://example.com/api/v1","APP_NAME":"Ünïcode ✓"}';
      final blob = ConfigCipher.encode(plain, key);
      expect(ConfigCipher.decode(blob, base64.encode(key)), plain);
    });

    test('blob does not reveal the host', () {
      final blob = ConfigCipher.encode('https://example.com', key);
      final raw = utf8.decode(base64.decode(blob), allowMalformed: true);
      expect(blob.contains('example'), isFalse);
      expect(raw.contains('example'), isFalse);
    });

    test('rejects an empty key', () {
      expect(() => ConfigCipher.encode('x', const []), throwsArgumentError);
    });
  });

  group('FlavorConfig.fromValues', () {
    Map<String, String> values() => {
          'API_BASE_URL': 'https://example.com/api/v1',
          'WEB_BASE_URL': 'https://example.com',
          'WS_URL': 'wss://example.com/ws',
          'CHART_BASE_URL': 'https://example.com/chart',
          'PUSHER_HOST': 'example.com',
          'PUSHER_APP_KEY': 'key',
          'APP_NAME': 'Example',
          'PRIMARY_COLOR': '5F259E',
          'SECONDARY_COLOR': 'FDCC29',
          'FEATURE_FLAGS': 'trading, payouts',
          'SIGNING_CERT_HASHES': 'aGFzaDE=, aGFzaDI=',
          'IOS_TEAM_ID': 'TEAM123',
        };

    test('parses a decoded blob', () {
      final config = FlavorConfig.fromValues(
        values(),
        flavorName: 'tenax',
        envName: 'production',
      );
      expect(config.apiBaseUrl, 'https://example.com/api/v1');
      expect(config.featureFlags, {'trading', 'payouts'});
      expect(config.signingCertHashes, ['aGFzaDE=', 'aGFzaDI=']);
      expect(config.iosTeamId, 'TEAM123');
      expect(config.securityWatcherMail, isEmpty);
    });

    test('fails loudly when a required value is missing', () {
      final missing = values()..remove('WS_URL');
      expect(
        () => FlavorConfig.fromValues(
          missing,
          flavorName: 'tenax',
          envName: 'production',
        ),
        throwsStateError,
      );
    });
  });

  group('PinnedHttpClient', () {
    setUpAll(() {
      PinnedHttpClient.initWithPem(
        File(PinnedHttpClient.rootsAsset).readAsBytesSync(),
      );
    });

    Future<int> statusOf(String url) async {
      final client = PinnedHttpClient.create();
      try {
        final request = await client.getUrl(Uri.parse(url));
        final response = await request.close();
        await response.drain<void>();
        return response.statusCode;
      } finally {
        client.close(force: true);
      }
    }

    test('connects to the app server (Let\'s Encrypt chain)', () async {
      expect(await statusOf('https://pipzefunded.com/'), greaterThan(0));
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('rejects a host signed by any other CA', () async {
      expect(
        statusOf('https://www.google.com/'),
        throwsA(isA<HandshakeException>()),
      );
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
