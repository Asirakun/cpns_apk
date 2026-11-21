import 'package:cryptography/cryptography.dart';
import 'package:cpns_journey/core/state_cipher.dart';

// Fixture only: production keys are generated randomly and held in secure storage.
StateCipher testCipher() => StateCipher(
  keyProvider: (_) async => SecretKey(List<int>.generate(32, (i) => i)),
);
