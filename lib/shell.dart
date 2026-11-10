import 'package:flutter/material.dart';
import 'article.dart';
import 'home.dart';
import 'main.dart';
import 'profile.dart';
import 'summaries.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int selected = 0;
  int previous = 0;

  void select(int value) {
    if (value == selected) return;
    setState(() { previous = selected; selected = value; });
  }

  void openArticle(Map<String, dynamic> article) {
    if (article['id'] != 2) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(context, 'Conteúdo detalhado disponível para Física das Cores.', 'Detailed content is available for Physics of Colors.'))));
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => ArticlePage(article: article)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: IndexedStack(index: selected, children: [
          HomePage(onArticle: openArticle),
          ProfilePage(onBack: () => select(previous)),
          const SummariesPage(),
        ]),
        bottomNavigationBar: NavigationBar(
          selectedIndex: selected,
          onDestinationSelected: select,
          destinations: [
            NavigationDestination(icon: const Icon(Icons.home_outlined), selectedIcon: const Icon(Icons.home), label: tr(context, 'Home', 'Home')),
            NavigationDestination(icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person), label: tr(context, 'Perfil', 'Profile')),
            NavigationDestination(icon: const Icon(Icons.mic_none), selectedIcon: const Icon(Icons.mic), label: tr(context, 'Resumos', 'Summaries')),
          ],
        ),
      );
}
