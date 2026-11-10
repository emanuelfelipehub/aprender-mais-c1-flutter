import 'package:flutter_test/flutter_test.dart';
import 'package:aprender_c1/pin.dart';
import 'package:aprender_c1/rules.dart';

void main() {
  test('aceita somente o PIN solicitado no enunciado', () {
    expect(checkPin(['3', '2', '4', '5']), PinStatus.valid);
    expect(checkPin(['3', '2', '4', '6']), PinStatus.incorrect);
  });

  test('campos vazios ou que nao sejam digitos sao incompletos', () {
    expect(checkPin(['3', '2', '', '5']), PinStatus.incomplete);
    expect(checkPin(['3', '2', 'x', '5']), PinStatus.incomplete);
    expect(checkPin(['3', '2', '4']), PinStatus.incomplete);
  });

  test('tempos da splash e da gravacao seguem o enunciado de exemplo', () {
    expect(splashDuration(firstLaunch: true), const Duration(seconds: 10));
    expect(splashDuration(firstLaunch: false), const Duration(seconds: 3));
    expect(maxRecordingDuration, const Duration(minutes: 1));
  });
}
