import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'device.dart';
import 'main.dart';

class ArticlePage extends StatefulWidget {
  const ArticlePage({super.key, required this.article});
  final Map<String, dynamic> article;
  @override
  State<ArticlePage> createState() => _ArticlePageState();
}

class _ArticlePageState extends State<ArticlePage> {
  // Cópia com nome ASCII: alguns empacotadores Android escapam o acento.
  late final VideoPlayerController video = VideoPlayerController.asset('assets/video_fisica.mp4');
  late final Future<Map<String, dynamic>> details = _load();
  bool ready = false;
  bool playing = false;
  double brightness = .7;
  bool brightnessPermissionOffered = false;
  bool brightnessPermissionPending = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    video.addListener(_videoChanged);
    video.initialize().then((_) { if (mounted) setState(() => ready = true); }).catchError((_) {});
    _loadBrightness();
  }

  Future<void> _loadBrightness() async {
    try {
      final value = await Device.call<double>('getBrightness');
      if (mounted && value != null) setState(() => brightness = value.clamp(.01, 1));
    } on PlatformException catch (_) {
      // O valor padrão permanece disponível quando o Android não fornecer o atual.
    }
  }

  Future<void> _applyBrightness(double value) async {
    try {
      await Device.call<bool>('brightness', {'value': value});
    } on PlatformException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message ?? tr(context, 'Não foi possível alterar o brilho.', 'Could not change brightness.'))));
    }
  }

  Future<void> _offerBrightnessPermission({bool force = false}) async {
    if (brightnessPermissionPending || (brightnessPermissionOffered && !force)) return;
    brightnessPermissionPending = true;
    brightnessPermissionOffered = true;
    try {
      final allowed = await Device.call<bool>('canWriteBrightness') ?? false;
      if (!mounted || allowed) return;
      final request = await showDialog<bool>(context: context, builder: (dialog) => AlertDialog(
        title: Text(tr(context, 'Brilho do celular', 'Device brightness')),
        content: Text(tr(context,
          'Para ajustar o brilho do aparelho inteiro, permita que o aplicativo altere as configurações do sistema. Sem essa permissão, o controle ajusta apenas o brilho dentro do aplicativo.',
          'To adjust brightness across the device, allow the app to modify system settings. Without permission, the slider adjusts brightness only inside the app.')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialog, false), child: Text(tr(context, 'Somente no app', 'Only in app'))),
          FilledButton(onPressed: () => Navigator.pop(dialog, true), child: Text(tr(context, 'Abrir configurações', 'Open settings'))),
        ],
      ));
      if (!mounted) return;
      if (request == true) {
        final granted = await Device.call<bool>('requestBrightnessPermission') ?? false;
        if (!mounted) return;
        if (granted) { await _applyBrightness(brightness); return; }
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(context, 'O brilho será ajustado somente dentro do aplicativo.', 'Brightness will be adjusted only inside the app.'))));
    } on PlatformException catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tr(context, 'Não foi possível abrir a permissão; o brilho será ajustado somente no aplicativo.', 'Could not open the permission screen; brightness will be adjusted only in the app.'))));
    } finally {
      brightnessPermissionPending = false;
    }
  }

  Future<Map<String, dynamic>> _load() async =>
      Map<String, dynamic>.from(jsonDecode(await rootBundle.loadString('assets/Artigo/artigo_2_detalhado.json')) as Map);

  void _videoChanged() {
    if (mounted && playing != video.value.isPlaying) setState(() => playing = video.value.isPlaying);
  }

  Future<void> _toggleVideo() async {
    if (!ready) return;
    if (video.value.isPlaying) { await video.pause(); } else { await video.play(); }
  }

  Future<void> _chooseFont() async {
    final app = AppScope.of(context);
    await showDialog<void>(context: context, builder: (dialog) => AlertDialog(
      title: Text(tr(context, 'Tamanho da fonte', 'Font size')),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(title: Text(tr(context, 'Pequeno', 'Small')), onTap: () { app.updateFontScale(.85); Navigator.pop(dialog); }),
        ListTile(title: Text(tr(context, 'Médio', 'Medium')), onTap: () { app.updateFontScale(1); Navigator.pop(dialog); }),
        ListTile(title: Text(tr(context, 'Grande', 'Large')), onTap: () { app.updateFontScale(1.25); Navigator.pop(dialog); }),
      ]),
    ));
  }

  @override
  void dispose() {
    video.removeListener(_videoChanged);
    video.dispose();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('${widget.article['titulo']}'), actions: [
          IconButton(icon: const Icon(Icons.share_outlined), tooltip: tr(context, 'Compartilhar', 'Share'), onPressed: () => Device.call<void>('share', {'text': '${widget.article['titulo']} — ${widget.article['descricao']}'})),
        ]),
        body: FutureBuilder<Map<String, dynamic>>(
          future: details,
          builder: (context, snapshot) {
            if (snapshot.hasError) return Center(child: Text(tr(context, 'Não foi possível carregar o artigo.', 'Could not load article.')));
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
            final item = snapshot.data!;
            return SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${item['titulo']}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text('${item['descricao']}\n${item['data']}'),
              const SizedBox(height: 18),
              if (ready) AspectRatio(aspectRatio: video.value.aspectRatio, child: VideoPlayer(video)) else const AspectRatio(aspectRatio: 16 / 9, child: Center(child: CircularProgressIndicator())),
              const SizedBox(height: 18),
              Text('${item['conteudo']}', style: Theme.of(context).textTheme.bodyLarge),
            ]));
          },
        ),
        bottomNavigationBar: SafeArea(child: Material(
          elevation: 8,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              const SizedBox(width: 12), const Icon(Icons.nightlight_round),
              Expanded(child: Slider(
                value: brightness,
                onChanged: (value) { setState(() => brightness = value); _applyBrightness(value); },
                onChangeEnd: (_) => _offerBrightnessPermission(),
              )),
              const Icon(Icons.wb_sunny_outlined), const SizedBox(width: 12),
            ]),
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              IconButton(onPressed: _chooseFont, icon: const Icon(Icons.format_size), tooltip: tr(context, 'Tamanho da fonte', 'Font size')),
              TextButton.icon(onPressed: ready ? _toggleVideo : null, icon: Icon(playing ? Icons.pause : Icons.play_arrow), label: Text(playing ? tr(context, 'Pausar reprodução', 'Pause playback') : tr(context, 'Ouvir artigo', 'Listen to article'))),
              IconButton(onPressed: () => showModalBottomSheet<void>(context: context, builder: (ctx) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
                ListTile(leading: const Icon(Icons.format_size), title: Text(tr(context, 'Tamanho da fonte', 'Font size')), onTap: () { Navigator.pop(ctx); _chooseFont(); }),
                ListTile(leading: const Icon(Icons.brightness_6_outlined), title: Text(tr(context, 'Permitir brilho do celular', 'Allow device brightness')), onTap: () { Navigator.pop(ctx); _offerBrightnessPermission(force: true); }),
              ]))), icon: const Icon(Icons.settings_outlined), tooltip: tr(context, 'Configurações', 'Settings')),
            ]),
          ]),
        )),
      );
}
