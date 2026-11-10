import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import 'device.dart';
import 'main.dart';
import 'pin.dart';
import 'rules.dart';
import 'shell.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});
  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  late final VideoPlayerController video = VideoPlayerController.asset('assets/SplashScreen.mp4');
  Timer? transition;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    bool first = false;
    try {
      first = await Device.call<bool>('firstLaunch') ?? false;
    } on PlatformException catch (_) {
      first = true;
    }
    if (!mounted) return;
    transition = Timer(splashDuration(firstLaunch: first), () {
      if (mounted) Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const LoginPage()));
    });
    try {
      await video.initialize();
      await video.setLooping(false);
      await video.play();
      if (mounted) setState(() {});
    } catch (_) {
      // O gradiente e o logotipo permanecem visíveis se o vídeo não abrir.
    }
  }

  @override
  void dispose() {
    transition?.cancel();
    video.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xff1e0053), Color(0xff5a00fb)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          child: Center(
            child: video.value.isInitialized
                ? AspectRatio(aspectRatio: video.value.aspectRatio, child: VideoPlayer(video))
                : Padding(padding: const EdgeInsets.all(48), child: Image.asset('assets/logo.png')),
          ),
        ),
      );
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final inputs = List.generate(4, (_) => TextEditingController());
  final focus = List.generate(4, (_) => FocusNode());
  final keyboardFocus = List.generate(4, (_) => FocusNode(skipTraversal: true));
  bool invalid = false;
  Timer? reset;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) focus.first.requestFocus();
    });
  }

  Future<void> enter() async {
    final status = checkPin(inputs.map((controller) => controller.text).toList());
    if (status == PinStatus.incomplete) {
      await Device.toast(tr(context, 'Todos os campos são obrigatórios', 'All fields are required'));
      return;
    }
    if (status == PinStatus.incorrect) {
      setState(() => invalid = true);
      for (final controller in inputs) { controller.clear(); }
      await Device.toast(tr(context, 'Pin incorreto', 'Incorrect PIN'));
      reset?.cancel();
      reset = Timer(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() => invalid = false);
        focus.first.requestFocus();
      });
      return;
    }
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const MainShell()));
  }

  @override
  void dispose() {
    reset?.cancel();
    for (final controller in inputs) { controller.dispose(); }
    for (final node in focus) { node.dispose(); }
    for (final node in keyboardFocus) { node.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Image.asset('assets/logo.png', width: 220),
                const SizedBox(height: 36),
                Text(tr(context, 'Digite seu PIN de acesso', 'Enter your access PIN'), style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(4, (i) =>
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: SizedBox(
                      width: 58,
                      child: KeyboardListener(
                        focusNode: keyboardFocus[i],
                        onKeyEvent: (event) {
                          if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.backspace && inputs[i].text.isEmpty && i > 0) {
                            focus[i - 1].requestFocus();
                          }
                        },
                        child: TextField(
                          controller: inputs[i],
                          focusNode: focus[i],
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          maxLength: 1,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: InputDecoration(
                            counterText: '',
                            border: const OutlineInputBorder(),
                            filled: invalid,
                            fillColor: invalid ? Colors.red.shade100 : null,
                          ),
                          onChanged: (value) {
                            if (value.isNotEmpty && i < 3) focus[i + 1].requestFocus();
                            if (value.isEmpty && i > 0) focus[i - 1].requestFocus();
                          },
                        ),
                      ),
                    ),
                  ),
                )),
                const SizedBox(height: 24),
                FilledButton(onPressed: invalid ? null : enter, child: Text(tr(context, 'Entrar', 'Sign in'))),
              ]),
            ),
          ),
        ),
      );
}
