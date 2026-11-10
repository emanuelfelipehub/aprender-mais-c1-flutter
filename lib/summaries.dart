import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'device.dart';
import 'main.dart';
import 'rules.dart';

class SummariesPage extends StatefulWidget {
  const SummariesPage({super.key});
  @override
  State<SummariesPage> createState() => _SummariesPageState();
}

class _SummariesPageState extends State<SummariesPage> {
  List<Map<String, dynamic>> recordings = [];
  bool recording = false;
  bool busy = false;
  int seconds = 0;
  String? playing;
  Timer? recordTimer;
  Timer? playTimer;
  final stopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final values = await Device.call<List<dynamic>>('recordings') ?? [];
      if (mounted) setState(() => recordings = values.map((e) => Map<String, dynamic>.from(e as Map)).toList());
    } on PlatformException catch (error) { _error(error); }
  }

  void _error(PlatformException error) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message ?? tr(context, 'Não foi possível usar este recurso.', 'This feature is unavailable.'))));
  }

  Future<void> _toggleRecord() async {
    if (busy) return;
    setState(() => busy = true);
    try {
      if (recording) {
        await _finishRecord();
      } else {
        await Device.call<void>('recordStart');
        if (!mounted) {
          // A permissão pode ter sido respondida depois que esta tela saiu.
          await Device.call<String>('recordStop');
          return;
        }
        stopwatch.reset(); stopwatch.start();
        setState(() { recording = true; seconds = 0; });
        recordTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
          final next = stopwatch.elapsed.inSeconds;
          if (!mounted) return;
          if (next >= maxRecordingDuration.inSeconds) { _finishRecord(); } else if (next != seconds) { setState(() => seconds = next); }
        });
      }
    } on PlatformException catch (error) { _error(error); }
    finally { if (mounted) setState(() => busy = false); }
  }

  Future<void> _finishRecord() async {
    if (!recording) return;
    recordTimer?.cancel(); stopwatch.stop();
    setState(() { recording = false; seconds = 0; busy = true; });
    try { await Device.call<String>('recordStop'); await _refresh(); }
    on PlatformException catch (error) { _error(error); }
    finally { if (mounted) setState(() => busy = false); }
  }

  Future<void> _togglePlay(String path) async {
    try {
      if (playing == path) {
        await Device.call<void>('recordStopPlayback');
        playTimer?.cancel();
        if (mounted) setState(() => playing = null);
      } else if (playing == null) {
        await Device.call<void>('recordPlay', {'path': path});
        if (!mounted) return;
        setState(() => playing = path);
        playTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
          try {
            final active = await Device.call<bool>('recordIsPlaying') ?? false;
            if (!active && playing == path) { playTimer?.cancel(); if (mounted) setState(() => playing = null); }
          } on PlatformException catch (error) {
            playTimer?.cancel();
            if (mounted && playing == path) setState(() => playing = null);
            _error(error);
          }
        });
      }
    } on PlatformException catch (error) { _error(error); }
  }

  Future<void> _delete(String path) async {
    try {
      await Device.call<bool>('recordDelete', {'path': path});
      if (playing == path) { playTimer?.cancel(); if (mounted) setState(() => playing = null); }
      await _refresh();
    } on PlatformException catch (error) { _error(error); }
  }

  @override
  void dispose() {
    recordTimer?.cancel(); playTimer?.cancel();
    if (recording) unawaited(Device.call<String>('recordStop').catchError((Object _) => null));
    unawaited(Device.call<void>('recordStopPlayback').catchError((Object _) {}));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(child: Column(children: [
        AppBar(title: Text(tr(context, 'Resumos', 'Summaries'))),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20), child: Column(children: [
          LinearProgressIndicator(value: recording ? seconds / maxRecordingDuration.inSeconds : 0),
          const SizedBox(height: 4),
          Text(recording ? '${seconds.toString().padLeft(2, '0')} / 60 s' : tr(context, 'Até 1 minuto por gravação', 'Up to 1 minute per recording')),
        ])),
        Expanded(child: recordings.isEmpty
            ? Center(child: Text(tr(context, 'Grave seus resumos e salve aqui', 'Record your summaries and save them here'), textAlign: TextAlign.center))
            : ListView.builder(
                itemCount: recordings.length,
                itemBuilder: (context, index) {
                  final item = recordings[index];
                  final path = item['path'] as String;
                  final date = DateTime.fromMillisecondsSinceEpoch((item['date'] as num).toInt());
                  final label = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
                  return Card(child: ListTile(
                    leading: IconButton(icon: Icon(playing == path ? Icons.stop : Icons.play_arrow), onPressed: playing == null || playing == path ? () => _togglePlay(path) : null),
                    title: Text('${tr(context, 'Resumo', 'Summary')} ${recordings.length - index}'),
                    subtitle: Text(label),
                    trailing: IconButton(icon: const Icon(Icons.delete_outline), tooltip: tr(context, 'Excluir', 'Delete'), onPressed: () => _delete(path)),
                  ));
                },
              )),
        Padding(padding: const EdgeInsets.all(16), child: FloatingActionButton(
          onPressed: busy ? null : _toggleRecord,
          backgroundColor: Colors.white,
          tooltip: recording ? tr(context, 'Parar gravação', 'Stop recording') : tr(context, 'Gravar resumo', 'Record summary'),
          child: Icon(Icons.mic, color: recording ? Colors.red : Theme.of(context).colorScheme.primary),
        )),
      ]));
}
