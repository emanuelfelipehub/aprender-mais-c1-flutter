import 'package:aprender_c1/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('a Home carrega os artigos do arquivo e abre o de ID 2', (tester) async {
    Map<String, dynamic>? selected;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: HomePage(onArticle: (article) => selected = article)),
    ));
    await tester.pumpAndSettle();

    final carousel = tester.widget<PageView>(find.byType(PageView));
    expect(carousel.childrenDelegate.estimatedChildCount, 3);
    expect(find.text('Física das Cores'), findsWidgets);

    final article = find.text('Física das Cores').last;
    await tester.ensureVisible(article);
    await tester.tap(article);
    await tester.pump();
    expect(selected?['id'], 2);
  });
}
