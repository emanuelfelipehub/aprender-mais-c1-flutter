import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'device.dart';
import 'main.dart';
import 'startup.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key, required this.onBack});
  final VoidCallback onBack;
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String name = 'Estudante';

  Future<void> _avatar(String source) async {
    try {
      final path = await Device.call<String>('chooseAvatar', {'source': source});
      if (mounted && path != null) AppScope.of(context).updateAvatar(path);
    } on PlatformException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message ?? 'Não foi possível selecionar a imagem.')));
    }
  }

  void _chooseAvatar() {
    showModalBottomSheet<void>(context: context, builder: (sheet) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(leading: const Icon(Icons.camera_alt_outlined), title: Text(tr(context, 'Tirar foto', 'Take photo')), onTap: () { Navigator.pop(sheet); _avatar('camera'); }),
      ListTile(leading: const Icon(Icons.photo_library_outlined), title: Text(tr(context, 'Escolher da galeria', 'Choose from gallery')), onTap: () { Navigator.pop(sheet); _avatar('gallery'); }),
    ])));
  }

  Future<void> _edit() async {
    final input = TextEditingController(text: name);
    final result = await showDialog<String>(context: context, builder: (dialog) => AlertDialog(
      title: Text(tr(context, 'Editar Perfil', 'Edit profile')),
      content: TextField(controller: input, decoration: InputDecoration(labelText: tr(context, 'Nome', 'Name'))),
      actions: [TextButton(onPressed: () => Navigator.pop(dialog), child: Text(tr(context, 'Cancelar', 'Cancel'))),
        FilledButton(onPressed: () => Navigator.pop(dialog, input.text.trim()), child: Text(tr(context, 'Salvar', 'Save')))],
    ));
    input.dispose();
    if (mounted && result != null && result.isNotEmpty) setState(() => name = result);
  }

  Future<void> _language() async {
    final app = AppScope.of(context);
    await showModalBottomSheet<void>(context: context, builder: (sheet) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(title: Text(tr(context, 'Automático', 'Automatic')), onTap: () { app.updateLocale(null); Navigator.pop(sheet); }),
      ListTile(title: const Text('Português'), onTap: () { app.updateLocale(const Locale('pt')); Navigator.pop(sheet); }),
      ListTile(title: const Text('English'), onTap: () { app.updateLocale(const Locale('en')); Navigator.pop(sheet); }),
    ])));
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final avatar = app.avatar;
    final hasAvatar = avatar != null && File(avatar).existsSync();
    return SafeArea(child: ListView(children: [
      AppBar(leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack), title: Text(tr(context, 'Perfil', 'Profile'))),
      const SizedBox(height: 20),
      Center(child: Stack(children: [
        CircleAvatar(radius: 55, backgroundImage: hasAvatar ? FileImage(File(avatar)) : null, child: hasAvatar ? null : const Icon(Icons.person, size: 54)),
        Positioned(right: 0, bottom: 0, child: IconButton.filled(onPressed: _chooseAvatar, icon: const Icon(Icons.camera_alt_outlined), tooltip: tr(context, 'Alterar foto', 'Change photo'))),
      ])),
      const SizedBox(height: 8),
      Center(child: Text(name)),
      Center(child: TextButton.icon(onPressed: _edit, icon: const Icon(Icons.edit_outlined), label: Text(tr(context, 'Editar Perfil', 'Edit profile')))),
      Padding(padding: const EdgeInsets.fromLTRB(20, 24, 20, 8), child: Text(tr(context, 'Configurações', 'Settings'), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800))),
      SwitchListTile(secondary: const Icon(Icons.dark_mode_outlined), title: Text(tr(context, 'Tema Escuro', 'Dark theme')), value: app.dark, onChanged: (value) => app.updateBool('dark', value)),
      SwitchListTile(secondary: const Icon(Icons.contrast), title: Text(tr(context, 'Alto Contraste', 'High contrast')), value: app.contrast, onChanged: (value) => app.updateBool('contrast', value)),
      ListTile(leading: const Icon(Icons.language), title: Text(tr(context, 'Idioma: Português (automático)', 'Language: English (automatic)')), trailing: const Icon(Icons.chevron_right), onTap: _language),
      SwitchListTile(secondary: const Icon(Icons.notifications_outlined), title: Text(tr(context, 'Notificações', 'Notifications')), value: app.notifications, onChanged: (value) => app.updateBool('notifications', value)),
      Padding(padding: const EdgeInsets.all(20), child: FilledButton.icon(
        onPressed: () => Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false),
        icon: const Icon(Icons.logout), label: Text(tr(context, 'Sair', 'Sign out')),
      )),
    ]));
  }
}
