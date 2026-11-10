# C1 — estudo passo a passo

Este é um **projeto de treino** para o exemplo do módulo C1. A referência para as regras é o PDF original. O guia explica o caminho pelo código; ao estudar, mantenha o PDF aberto para conferir cada requisito.

## 1. O que o aplicativo faz

O aplicativo começa com uma tela Splash, passa para uma tela de PIN e depois mostra uma navegação com Home, Perfil e Resumos. A Home lê uma lista de artigos de um arquivo JSON. O artigo de ID 2 abre uma página com texto e vídeo. O usuário pode gravar resumos, reproduzir gravações, alterar o tema e selecionar uma foto para o perfil.

As partes que usam microfone, câmera, galeria e brilho dependem do Android e das permissões concedidas no aparelho. Compilar o projeto não comprova por si só que todos esses recursos funcionam no equipamento da prova.

## 2. Como abrir e executar

1. No Android Studio, escolha **Open** e selecione a pasta `08_Modulo_C1_XX`, a que contém `pubspec.yaml`.
2. Confirme que o caminho do SDK Flutter está configurado no Android Studio.
3. Selecione um emulador Android ou um celular Android conectado. Aguarde o dispositivo iniciar.
4. Abra `lib/main.dart` e execute o aplicativo pelo botão **Run**.
5. Aguarde a Splash. A tela de PIN do material aceita **3245**. Se aparecer um pedido de microfone ou de configurações do sistema durante um teste, leia a explicação antes de decidir.

O projeto depende do pacote `video_player` e dos componentes Android de compilação. Para criar o APK sem internet, as versões exigidas precisam estar previamente disponíveis no computador. A versão Flutter e o emulador usados neste desenvolvimento não são os mesmos indicados no PDF; a compatibilidade com o ambiente exato da prova precisa ser testada.

Para conferir em um terminal aberto na pasta do projeto:

```text
flutter pub get --offline
flutter analyze
flutter test
flutter build apk --debug
```

O comando de compilação gera um APK de depuração para treino. A entrega oficial pode exigir nome, assinatura e localização específicos; confira o PDF e as instruções atuais. Não há envio automático ao repositório da prova.

## 3. Por onde começar a ler o código

| Arquivo | O que você encontra nele |
| --- | --- |
| `pubspec.yaml` | Nome do projeto, pacotes, imagens, JSON, vídeos e fontes que o Flutter pode usar. |
| `lib/main.dart` | Início do app, tema, idioma e informações compartilhadas entre telas. |
| `lib/startup.dart` | Splash, quatro campos do PIN e navegação após o login. |
| `lib/pin.dart` | Regra que distingue PIN incompleto, incorreto ou válido. |
| `lib/rules.dart` | Tempos da Splash e duração máxima da gravação. |
| `lib/shell.dart` | Barra inferior e navegação entre Home, Perfil e Resumos. |
| `lib/home.dart` | Leitura do JSON de artigos, carrossel, indicador e lista. |
| `lib/article.dart` | Artigo detalhado, vídeo, tamanho da fonte, compartilhamento e controle de brilho. |
| `lib/summaries.dart` | Estado da gravação, temporizador, lista, reprodução e exclusão dos áudios. |
| `lib/profile.dart` | Foto, tema escuro, alto contraste, idioma e saída. |
| `lib/device.dart` | Comunicação entre o Dart e recursos específicos do Android. |
| `android/app/src/main/kotlin/.../MainActivity.kt` | Lado Android dessa comunicação: permissões, gravação, reprodução, fotos, brilho e preferências. |
| `test/` | Testes de regras e de telas; algumas chamadas ao Android são simuladas. |

## 4. Como o Flutter começa

No `main.dart`, a função `main` é o ponto inicial. `WidgetsFlutterBinding.ensureInitialized()` prepara a ligação com o Flutter antes de chamarmos recursos assíncronos. `SystemChrome.setPreferredOrientations(...)` pede a orientação da tela. `runApp(const C1App())` inicia a interface.

O `MaterialApp` concentra configurações como tema e idioma. O `home` aponta para `SplashPage`, a primeira tela. A classe `C1AppState` guarda, por exemplo, se o tema escuro está ligado e qual foto foi escolhida. O `AppScope` permite às outras telas acessar essas informações.

Um **widget** é uma peça da interface. Um `Text` mostra texto; um `Column` organiza peças de cima para baixo; um `Scaffold` oferece estrutura para uma tela. Um `StatefulWidget` é usado quando algo mostrado pode mudar.

## 5. Splash e PIN

Em `startup.dart`, a Splash chama `firstLaunch` pela ponte Android. Esse método guarda se o aplicativo já foi aberto. `splashDuration(firstLaunch: first)` retorna dez segundos para a primeira abertura e três para as seguintes. Um `Timer` espera esse tempo e navega para o login. A animação usa o vídeo entregue com o exemplo.

Os quatro `TextField` aceitam apenas dígitos. Cada `TextEditingController` guarda o conteúdo de um campo; cada `FocusNode` ajuda a mover o cursor entre eles. O método `checkPin`, em `pin.dart`, verifica se todos os campos têm um dígito e compara o conjunto com `3245`.

Ao tocar em **Entrar**, um PIN incompleto mostra o aviso pedido. Um PIN incorreto deixa os campos vermelhos por dois segundos, mostra o aviso e limpa os valores. Um PIN correto abre a navegação principal.

## 6. Home, artigos e navegação

Em `home.dart`, `rootBundle.loadString(...)` lê `artigos.json`, um arquivo de texto com dados. `jsonDecode` transforma o texto em valores que o Dart consegue percorrer. O `FutureBuilder` mostra um indicador enquanto a leitura ocorre e depois constrói a tela.

O `PageView` monta o carrossel com três itens. O `onPageChanged` guarda qual item está visível e atualiza os pontos indicadores. A lista mostra o título, a descrição e a data. O artigo de ID 2 abre `ArticlePage`; o conteúdo detalhado vem de `artigo_2_detalhado.json`.

Em `shell.dart`, `NavigationBar` é a barra inferior. A variável `selected` guarda o item escolhido. `IndexedStack` preserva as telas ao trocar entre elas, em vez de recriá-las a cada toque.

## 7. Vídeo, fonte e brilho

Na página do artigo, `VideoPlayerController.asset(...)` aponta para o vídeo local. O botão chama `play()` ou `pause()` conforme o estado. O texto do botão acompanha esse estado. A área do artigo pode rolar; os controles ficam na parte inferior.

O botão de fonte abre um diálogo com Pequeno, Médio e Grande. `fontScale` é aplicado pelo `MediaQuery` para ajustar o texto do aplicativo.

O controle de brilho tenta alterar o brilho do aparelho quando o Android permite que o app modifique configurações do sistema. Caso essa permissão não seja concedida, ajusta somente a janela do aplicativo e informa essa diferença. O fluxo de permissão e o efeito real em cada aparelho devem ser verificados no dispositivo da prova.

## 8. Gravar e ouvir resumos

Em `summaries.dart`, a variável `recording` indica se uma gravação está ativa. O botão chama `recordStart` ou `recordStop` no Android. Um `Stopwatch` acompanha o tempo e o `Timer` atualiza a tela; após um minuto, o app solicita a parada.

As gravações são guardadas em arquivos privados do aplicativo e aparecem na lista. Os botões chamam métodos Android para reproduzir, parar ou excluir o arquivo selecionado. O aplicativo só habilita a reprodução de outra gravação depois de parar ou terminar a atual.

O teste de widget simula as respostas do Android para verificar o fluxo da interface. Ele não prova que o microfone real gravou som nem que o alto-falante reproduziu áudio. Esses pontos precisam ser testados em um dispositivo ou emulador que ofereça os recursos e permissões.

## 9. Fotos e recursos do Android

`Device` usa um `MethodChannel`, uma ponte que leva uma mensagem do Dart para o Android. Em `MainActivity.kt`, o Android recebe o nome da mensagem e chama uma função correspondente. A seleção de foto abre a câmera ou a galeria do aparelho. Quando uma imagem é escolhida, o app salva uma cópia privada e atualiza o avatar.

`Future` representa uma operação que termina depois. `await` aguarda o resultado sem bloquear a interface. `try` e `catch` permitem tratar situações como permissão negada ou falha de recurso. `mounted` indica se uma tela ainda existe antes de atualizá-la depois de uma espera.

## 10. O que os testes existentes comprovam

- O teste de PIN confere a combinação válida, a incorreta e campos incompletos.
- O teste de regras confere os tempos de dez e três segundos e o limite de um minuto.
- O teste da Home lê os dados de artigos, confere três posições no carrossel e verifica o toque no artigo de ID 2.
- O teste de resumos simula a ponte Android e verifica iniciar, salvar, reproduzir, parar e excluir uma gravação.

Esses testes não cobrem integralmente todos os requisitos. Ainda é necessário verificar no ambiente de destino: o vídeo e a aparência da Splash, o microfone e a reprodução reais, a câmera e a galeria, a orientação nas telas, o brilho global e seu fluxo de permissão, o idioma do sistema e os detalhes de acessibilidade. Consulte também o PDF e o esquema de avaliação.
