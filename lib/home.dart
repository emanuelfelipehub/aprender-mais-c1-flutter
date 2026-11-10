import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'main.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.onArticle});
  final ValueChanged<Map<String, dynamic>> onArticle;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final Future<List<Map<String, dynamic>>> articles = _load();
  int current = 0;

  Future<List<Map<String, dynamic>>> _load() async {
    final raw = await rootBundle.loadString('assets/Artigo/artigos.json');
    return (jsonDecode(raw) as List).map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: articles,
          builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Text(tr(context, 'Não foi possível carregar os artigos.', 'Could not load articles.')));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final list = snapshot.data!;
            final featured = list.take(3).toList();
            return ListView(padding: const EdgeInsets.all(20), children: [
              Row(children: [
                Expanded(child: Text(tr(context, 'Olá, Estudante!', 'Hello, Student!'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800))),
                const Icon(Icons.notifications_outlined),
              ]),
              const SizedBox(height: 18),
              SizedBox(
                height: 180,
                child: PageView.builder(
                  itemCount: featured.length,
                  onPageChanged: (value) => setState(() => current = value),
                  itemBuilder: (context, index) {
                    final item = featured[index];
                    return Card.filled(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('${item['titulo']}', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                        FilledButton(onPressed: () => widget.onArticle(item), child: Text(tr(context, 'Começar agora', 'Start now'))),
                      ])),
                    );
                  },
                ),
              ),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(featured.length, (i) => Padding(padding: const EdgeInsets.all(4), child: Icon(i == current ? Icons.circle : Icons.circle_outlined, size: 10)))),
              const SizedBox(height: 12),
              Text(tr(context, 'Artigos', 'Articles'), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              ...list.map((item) => Card(child: ListTile(
                    title: Text('${item['titulo']}'),
                    subtitle: Text('${item['descricao']}\n${item['data']}'),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => widget.onArticle(item),
                  ))),
            ]);
          },
        ),
      );
}
