import 'package:aprender_c1/summaries.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('aprender_c1/device');

  testWidgets('inicia, salva, reproduz e exclui somente a gravação escolhida', (tester) async {
    final calls = <String>[];
    final recordings = <Map<String, Object>>[];
    String? playing;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      switch (call.method) {
        case 'recordings':
          return recordings;
        case 'recordStart':
          return null;
        case 'recordStop':
          recordings.insert(0, {'path': '/fake/resumo.m4a', 'date': 1735689600000});
          return '/fake/resumo.m4a';
        case 'recordPlay':
          playing = (call.arguments as Map)['path'] as String;
          return null;
        case 'recordIsPlaying':
          return playing != null;
        case 'recordStopPlayback':
          playing = null;
          return null;
        case 'recordDelete':
          final path = (call.arguments as Map)['path'];
          recordings.removeWhere((item) => item['path'] == path);
          return true;
        default:
          return null;
      }
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));

    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SummariesPage())));
    await tester.pumpAndSettle();
    expect(find.byType(FloatingActionButton), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pump();
    expect(calls, contains('recordStart'));
    expect(find.byTooltip('Stop recording'), findsOneWidget);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    expect(calls, contains('recordStop'));
    expect(find.text('Summary 1'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();
    expect(playing, '/fake/resumo.m4a');
    expect(find.byIcon(Icons.stop), findsOneWidget);
    await tester.tap(find.byIcon(Icons.stop));
    await tester.pump();
    expect(playing, isNull);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(recordings, isEmpty);
  });
}
