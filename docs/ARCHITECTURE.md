# Arquitetura

```
câmera + mic (AVCaptureSession única; sessão de áudio configurada à mão)
  ├─ vídeo (420v 1080p30) ─► VideoEncoder (VideoToolbox H.264, keyframe ~1 s) ─┐
  └─ áudio (PCM) ─► cópia própria do bloco ────────────────────────────────────┴─► ReplayBuffer (últimos N s + 3 s)
                                                                                      │ gravar: corta no keyframe,
                                                                                      ▼ ClipWriter escreve o anel e segue ao vivo
                                                              MP4 único (AVAssetWriter: vídeo passthrough, áudio PCM → AAC)
                                                                                      ▼
                                                              PhotoKit: álbum "Ei Clip" do Rolo
voz (etapa 2): SFSpeechRecognizer pt-BR alimentado pelo áudio da mesma captura (sem segundo microfone)
```

## Pastas

- `Core/` — pacote Swift com a lógica pura e testes (`swift test` no CI). O app compila `Core/Sources/EiClipCore` direto (sem módulo separado). Etapa 4: `ScreenFlow` (telas e tipo de transição), `DayLabel` (Hoje/Ontem), `PlaybackRate` (velocidades), `ClipInfoFormat` (detalhes) `SwipeRules` (limiares dos gestos) e `ClipSelection` (seleção e seleção por arrasto), todos com testes. Etapa 5: `BufferWindow` (15/30 s válidos), `RouteRules` (rota da Galeria/player e ações dos gestos de borda), `EdgeSwipe` (limiar do gesto de borda), `Preferences` (chaves, padrões e validação; guardam em um `KeyValueStore`, que no app é o `UserDefaults`) e `CaptureConfig` (qualidade, fps, imagem e câmera; validado).
  - `ReplayBuffer` (porta de `replay-buffer.ts`), `VideoProfile` (tabela de taxa), `ClipName` (nome e m:ss), `MicLevel` (pico e microfone mudo), `BeepWave` (bipe e WAV), `TimelineStats` (primeiro/último tempo, maior salto e retrocessos de uma sequência de tempos; diagnóstico do clipe), `RestartGuard` (v0.2.0: quando desistir de religar o reconhecedor de voz), `WakeWords`/`WakeWord`/`WakeGate` (v0.2.1: porta de `wake-word.ts`), `WakeTracker`/`WakeState` (v0.2.1/0.2.2/0.2.4: acertos únicos a partir do texto cumulativo do iOS, contando ocorrências da frase e sabendo se está gravando), `DeviceHold`/`OrientationTracker` (v0.3.8: como o iPhone está segurado a partir da gravidade, com histerese, confirmação e "na mesa mantém"; e a matriz de giro do arquivo para cada posição). `DiagPanel`/`DiagSnapshot`/`DiagSection` (v0.3.10: seções do Diagnóstico a partir de valores simples; o motor preenche, a tela só desenha).
  - Etapa 6 (v0.6.x): `StorageRules` (espaço livre e quando avisar/encerrar), `BatteryRules`, `ThermalPolicy` (`ThermalGovernor`: reduz um passo por vez, nunca gravando), `DayGrouping` (Galeria por dia), `BufferWindow` (15/30/60 s e orçamento de memória do anel), `FocusRules`/`FocusMark`, `LevelRules` (inclinação a partir da gravidade), `Lens`/`LensRules`, `FormatPicker` (escolhe o formato da câmera para resolução e fps), `RecordingFiles` (pasta de gravações, partes de 5 s, regra de recuperação). `CaptureConfig` ganhou `stabilize` e `lens`; `Preferences` guarda estabilização, nível e a escolha de captura crua (o `validated()` corrige na hora de usar).
- `Engine/` — câmera, codificação, gravação, Rolo. **Área protegida (mudar sozinha numa versão):** `AudioSessionConfig.swift` (sessão de áudio) e, na etapa 2, a voz.
  - `OrientationSensor` (v0.3.8: acelerômetro que diz como o aparelho está segurado; não é área protegida), `DiagnosticsInfo` (v0.3.10: permissões, temperatura e inícios do app, só leitura), `CaptureEngine` (orquestra), `CaptureEngine+Diagnostics` (v0.5.6: o que o painel do Diagnóstico mostra), `VideoEncoder`, `ClipWriter`, `PhotoSaver`, `BeepPlayer`, `SampleBufferUtils`, `Diagnostics`, `AudioSessionConfig`, `VoiceProbe` (v0.2.0, área protegida: escuta o mesmo bloco de áudio da captura com `SFSpeechRecognizer` pt-BR no aparelho e só registra no Diagnóstico; desde a v0.2.1 também aplica o `WakeTracker` e registra `GATILHO`; desde a v0.2.2, no modo Comando, o acerto de "Ei Clip" chama `CaptureEngine.voiceWake`, que liga ou para a gravação; desde a v0.2.5 age só a palavra escolhida em `CaptureEngine.voiceWord`).
- `App/` — SwiftUI: `RootView` (câmera fechada: `HomeView`; aberta: `CameraScreen`), `HomeView` e `BrandMark` (v0.3.0), `RecentClips` e `ClipPlayerView` (v0.3.1), `CameraScreen` e `Glass` (v0.3.4), `EdgeGesture` (v0.5.2: gesto de borda NATIVO, `UIScreenEdgePanGestureRecognizer`, com um registro central; só a tela de cima recebe), `SettingsSheet` (v0.3.6: folha de Ajustes; Diagnóstico fica dentro), `DiagnosticsView` (v0.3.10: painel de seções + registro), `GalleryView` (v0.4.0: grade da Galeria), `ScreenTransitions` (v0.4.2), `PlayerModel` e `ClipInfo` (v0.4.3/0.4.4: player e detalhes), `ClipShare` (v0.4.10: arquivo temporário e folha de compartilhar), `PhotoDeleter` (v0.4.11), `PlayerInfoCard`, `PlayerControlsBar` e `NoticeToast` (v0.5.3: partes do player e aviso compartilhado com a Galeria), `Thumbnails` (v0.5.4: cache em memória e pedido cancelável), `CameraPreview`, `EiClipApp`, `Assets.xcassets` (marca e logo).
- `project.yml` — XcodeGen (o `.xcodeproj` não é versionado). `.github/workflows/build.yml` — testes → IPA não assinado → Release.

## Detalhes que importam

- **Filas:** `sessionQueue` (abrir/fechar), `videoQueue`/`audioQueue` (entrega de amostras), `controlQueue` (iniciar gravação), fila própria do `ClipWriter`. O estado compartilhado do motor fica sob um único `NSLock`.
- **Áudio no anel:** cada bloco da captura é COPIADO (`deepCopyAudio`). Guardar os buffers originais por 30 s esgotaria o pool de memória da captura.
- **Gravação:** durante o clipe o anel é esvaziado e as amostras vão direto ao `ClipWriter`. Ao parar, o anel é descartado até o último quadro (o fim do clipe não reaparece no começo do próximo).
- **ClipWriter:** entradas em modo não-tempo-real, fila de pendentes e `requestMediaDataWhenReady`. Cada entrada é encerrada quando a sua fila acaba (senão uma esperaria a outra e o arquivo nunca fecharia).
- **Bipe:** o microfone é trocado por silêncio durante o bipe (não grava o alto-falante); o relógio do áudio segue contínuo.
- **Orientação (v0.3.8):** a tela é sempre em pé. `OrientationSensor` (acelerômetro, 10 leituras por segundo, só com a câmera aberta) alimenta o `OrientationTracker` (Core); o motor lê a posição UMA vez no começo do clipe e grava o giro na matriz do arquivo (em pé 90°, topo à esquerda 0°, topo à direita 180°, de cabeça para baixo 270°), sem recodificar. Aparelho quase deitado na mesa mantém a última posição.

- **Configuração (v0.6):** `chosenConfig` (o que o usuário escolheu) e `config` (o que vale: escolhido, reduzido pelo calor, corrigido pelo formato real da câmera). Trocar câmera, lente (ultra-angular), resolução ou fps reabre a câmera (`reconfigure`, sem piscar o Início); nunca gravando. 1× ↔ 2× só muda o zoom e vale até gravando.
- **Gravação em partes (v0.6.12):** o `ClipWriter` usa `movieFragmentInterval` de 5 s e o arquivo fica em `Application Support/Gravando`. Se o app fechar, o que foi gravado até a última parte abre; `CaptureEngine.recoverLeftovers` (v0.6.13) salva o que sobrou no álbum Ei Clip e apaga o arquivo.
- **Anel de memória (v0.6.5):** `BufferWindow.effective` limita a janela pedida ao que cabe em 350 MB (v0.6.15) (vídeo codificado + PCM do áudio); o Diagnóstico mostra a memória real do app (`phys_footprint`).
- **Tela escura (v0.6.3):** preto por cima da câmera (não muda o brilho do sistema); a câmera, a gravação e a voz seguem.
- **Avisos (v0.7.18 a v0.7.23):** `flash(_:level:)` mostra o aviso no topo, sob a pílula. Pesos `NoticeLevel` (informação, atenção, crítico) em `NoticeRules` (Core); aviso mais leve não apaga o mais pesado; o tempo na tela é o maior entre o mínimo do peso e o tempo de leitura do texto (teto 12 s); tocar ou arrastar para cima fecha. O peso e o texto são variáveis comuns lidas por `LiveTick` (nada novo `@Published` durante a reconfiguração); `clearNotice` adia 0,5 s se a câmera está sendo reconfigurada.
- **Bateria (v0.7.21/22):** o iOS só entrega a bateria de 5 em 5. `BatteryStepTracker` (Core) avisa uma vez por degrau (20, 10, 5%) e guarda o menor degrau já avisado em `UserDefaults` (`bateria.menorDegrauAvisado`); carregar ou passar de 25% zera.
- **EV (v0.7.16 a v0.7.19):** `ExposureRules` (Core) com faixa ±2 e dois pesos (`fingerPointsPerEV` 75, `sunPointsPerEV` 30). `setExposureTargetBias` na `sessionQueue`; zera ao tocar em outro ponto, trocar de lente, abrir e fechar. O sol (`ExposureSun`) fica ao lado do quadrado de foco (`FocusSquare`).
- **Início da gravação (v0.7.23):** sem keyframe no anel, `doStartRecording` não recusa: reagenda a si mesmo a cada 0,1 s por até 2,5 s (`StartWaitRules`). `startPending` (variável comum sob a trava) evita pedidos duplicados; parar antes do início cancela o pedido.
- **Frontal deitada (v0.7.20):** `DeviceHold.fileMatrix(front:mirrored:)` soma 180° ao giro quando a frontal está deitada (`frontLandscapeInverted`); o espelho vem depois do giro.

## Riscos abertos

- Microfone mudo pode ocorrer também no nativo: a etapa 1 mede (Diagnóstico + "Teste 20 aberturas").
- Voz pt-BR: confirmar reconhecimento no aparelho e escuta contínua antes da etapa 2.
- Achar o álbum "Ei Clip" exige permissão completa das Fotos.
- Etapa 6 sem medida em aparelho: memória e temperatura do anel de 60 s; giro do arquivo da frontal; sinal do nível; MP4 em partes aceito pelas Fotos e pelo player (testar clipe longo); recuperação após fechar o app à força.
- Sincronia áudio/vídeo: o AAC do arquivo tem um pequeno atraso de "priming" (dezenas de ms); medir no teste (d).

- **Parada da gravação (v0.6.17):** `VideoEncoder.complete()` espera só até o último quadro enviado (`lastSubmittedPts`), não até esvaziar (com `.invalid` travava em 4K). `stopRecording()` roda o `complete()` fora da fila do Swift com limite de 3 s e segue mesmo se estourar.
- **Miniatura (v0.6.17):** `ThumbnailRules` (Core) escolhe instantes candidatos e rejeita quadro escuro (brilho médio < 0,08); `ThumbnailStore.makeImage` tenta os instantes em ordem e guarda o primeiro claro (ou o mais claro).

## Vigia e armadilhas do SwiftUI (v0.6.18 a v0.6.27)

- **Impasse do SwiftUI no iOS 27.0.1 (v0.6.26):** publicar um `@Published` do motor na linha principal enquanto o SwiftUI atualiza o layout em outra linha podia travar a tela (a principal em `ObservableObjectPublisher.send`, o SwiftUI esperando a principal). `isReconfiguring` deixou de ser `@Published`; quem bloqueia toques é o `ReconfigureGate` (Core). **Regra:** estado novo da tela só em resposta a toque ou lendo o que já existe; nada novo publicado durante a reconfiguração da câmera.
- **`ReconfigureGate`:** um só dono por vez para trocar câmera/lente/formato; toque durante a troca é ignorado e registrado ("ignorado: a câmera já está sendo reconfigurada"). `opened` (sob a trava do motor) é o estado real; `isOpen` publicado atrasa de propósito (`DispatchQueue.main.async`) e não serve para decidir.
- **Tempos sem `@Published` (v0.7.2):** `bufferSec` e `recordSec` não são mais publicados (a v0.7.0 travou 28 s no `tick` publicando `bufferSec`, igual ao impasse da v0.6.26). O `tick` só guarda (quantizado por `PublishRules`); a tela lê com `LiveTick` (`TimelineView` a 0,25 s). Regra: tempo que anda sozinho nunca passa pelo Combine.
- **Vigia (`MainThreadWatch`, v0.6.21+):** a cada 0,5 s pede um sinal de vida à tela principal; sem resposta em 1 s registra `tela: TRAVADA`; sem quadros da câmera em 2 s registra `câmera: SEM QUADROS`; linha `vida:` a cada 30 s com a câmera aberta. Só vigia com o app ativo. `StallDetector` (Core) decide.
- **`MainMark` e `mainAsync`/`mainAsyncAfter`:** todo trabalho do motor que roda na fila principal se anuncia com "função:linha"; o `TRAVADA` diz em qual estava ("dentro de ...").
- **`ThreadSampler` + `StackText`:** quando a tela trava, fotografa a pilha de cada linha de execução (Mach: suspende, lê pc/lr/fp, libera, sem alocar com a linha suspensa) e escreve linhas `pilha:` no Diagnóstico (máx. 8 por rodada). Nomes do sistema escondidos pelo iOS aparecem como biblioteca+posição.
- **Nível (v0.6.19):** sensor a 30 leituras/s (`LevelRules.sampleRate`), publica só com mudança maior que 0,2°; `Decimator` mantém o `OrientationTracker` em ~10 Hz.

## Onda 8: o que entrou (v0.7.24 a v0.8.8)

- **Reabertura ao voltar (v0.7.24):** `closeCamera(reason:reopenOnReturn:true)` no `.background` mantém a tela da câmera (`isOpen` não é publicado como falso); `.active` chama `reopenAfterReturn()` (~250 ms). Se falhar, `isOpen = false` e o app volta ao Início, registrando "reabertura ao voltar falhou".
- **Calor (v0.7.28 a v0.8.6):** o iOS só informa `thermalState` (nominal, fair, serious, critical), sem graus. `ThermalGovernor.react(level:chosen:recording:autoReduce:)` em `Core/ThermalPolicy.swift`: com a chave `heatAutoReduce` desligada (padrão) o "quente" só avisa (`hotAdvice`); ligada, reduz; o `critical` reduz sempre. `reductionDescription(from:to:)` gera o texto "Reduzido: 60 → 30 fps" dos avisos.
- **Ajustes (v0.8.0):** `SettingsSheet` com `Page` (`main`, `voice`, `camera`, `device`): primeira tela com os 4 itens de vídeo e 3 tópicos (Voz e sons, Câmera, Aparelho), altura 580 pt e `.large`.
- **Parar no 4K (v0.8.3):** `VTCompressionSessionCompleteFrames` não volta enquanto a câmera continua enviando quadros. `VideoEncoder.waitDelivered(timeout:)` espera só o último PTS enviado ser entregue (contadores em `stats()`); o esvaziamento (`complete()`, limite de 3 s) fica de reserva e é registrado. Resultado: ~0,7 s do toque até o Fotos.
- **Galeria (v0.7.25 a v0.8.8):** seleção por varredura horizontal (`sweepGesture`); volta ao topo quando a lista encolhe (`ScrollViewReader` com "topo" e `lastCount`); `App/GalleryAutoScroll.swift`: `GalleryAutoScroller` (Timer de 1/60 s no runloop `.common` que move o `contentOffset` do `UIScrollView` perto das bordas; zona 70 pt, até 16 pt por quadro) e `ScrollViewFinder` (acha o `UIScrollView` pela hierarquia). Se não achar a lista, registra "rolagem automática indisponível" e a seleção segue sem rolar sozinha.

