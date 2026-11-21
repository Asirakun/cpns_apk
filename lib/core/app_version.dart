// Keep aligned with pubspec.yaml. A regression test checks this contract.
const appVersion = '1.2.3';

bool supportsContentMinimum(String? minimum) {
  final value = minimum ?? '1.0.0';
  if (!RegExp(r'^\d+\.\d+\.\d+$').hasMatch(value)) return false;
  final required = value.split('.').map(int.parse).toList();
  final current = appVersion.split('.').map(int.parse).toList();
  for (var i = 0; i < 3; i++) {
    if (current[i] != required[i]) return current[i] > required[i];
  }
  return true;
}
