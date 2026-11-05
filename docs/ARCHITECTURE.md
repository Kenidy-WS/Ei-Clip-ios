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

- `Core/` — pacote Swift com a lógica pura e testes (`swift test` no CI). O app compila `Core/Sources/EiClipCore` direto (sem módulo separado). Etapa 4: `ScreenFlow` (telas e tipo de transição), `DayLabel` (Hoje/Ontem), `PlaybackRate` (velocidades), `ClipInfoFormat` (detalhes) `SwipeRules` (limiares dos gestos) e `ClipSelection` (seleção e seleção por arrasto), todos com testes.
  - `ReplayBuffer` (porta de `replay-buffer.ts`), `VideoProfile` (tabela de taxa), `ClipName` (nome e m:ss), `MicLevel` (pico e microfone mudo), `BeepWave` (bipe e WAV), `TimelineStats` (primeiro/último tempo, maior salto e retrocessos de uma sequência de tempos; diagnóstico do clipe), `RestartGuard` (v0.2.0: quando desistir de religar o reconhecedor de voz), `WakeWords`/`WakeWord`/`WakeGate` (v0.2.1: porta de `wake-word.ts`), `WakeTracker`/`WakeState` (v0.2.1/0.2.2/0.2.4: acertos únicos a partir do texto cumulativo do iOS, contando ocorrências da frase e sabendo se está gravando), `DeviceHold`/`OrientationTracker` (v0.3.8: como o iPhone está segurado a partir da gravidade, com histerese, confirmação e "na mesa mantém"; e a matriz de giro do arquivo para cada posição). `DiagPanel`/`DiagSnapshot`/`DiagSection` (v0.3.10: seções do Diagnóstico a partir de valores simples; o motor preenche, a tela só desenha).
- `Engine/` — câmera, codificação, gravação, Rolo. **Área protegida (mudar sozinha numa versão):** `AudioSessionConfig.swift` (sessão de áudio) e, na etapa 2, a voz.
  - `OrientationSensor` (v0.3.8: acelerômetro que diz como o aparelho está segurado; não é área protegida), `DiagnosticsInfo` (v0.3.10: permissões, temperatura e inícios do app, só leitura), `CaptureEngine` (orquestra), `VideoEncoder`, `ClipWriter`, `PhotoSaver`, `BeepPlayer`, `SampleBufferUtils`, `Diagnostics`, `AudioSessionConfig`, `VoiceProbe` (v0.2.0, área protegida: escuta o mesmo bloco de áudio da captura com `SFSpeechRecognizer` pt-BR no aparelho e só registra no Diagnóstico; desde a v0.2.1 também aplica o `WakeTracker` e registra `GATILHO`; desde a v0.2.2, no modo Comando, o acerto de "Ei Clip" chama `CaptureEngine.voiceWake`, que liga ou para a gravação; desde a v0.2.5 age só a palavra escolhida em `CaptureEngine.voiceWord`).
- `App/` — SwiftUI: `RootView` (câmera fechada: `HomeView`; aberta: `CameraScreen`), `HomeView` e `BrandMark` (v0.3.0), `RecentClips` e `ClipPlayerView` (v0.3.1), `CameraScreen` e `Glass` (v0.3.4), `EdgeGesture` (v0.3.5), `SettingsSheet` (v0.3.6: folha de Ajustes; Diagnóstico fica dentro), `DiagnosticsView` (v0.3.10: painel de seções + registro), `GalleryView` (v0.4.0: grade da Galeria), `ScreenTransitions` (v0.4.2), `PlayerModel` e `ClipInfo` (v0.4.3/0.4.4: player e detalhes), `ClipShare` (v0.4.10: arquivo temporário e folha de compartilhar), `PhotoDeleter` (v0.4.11), `CameraPreview`, `EiClipApp`, `Assets.xcassets` (marca e logo).
- `project.yml` — XcodeGen (o `.xcodeproj` não é versionado). `.github/workflows/build.yml` — testes → IPA não assinado → Release.

## Detalhes que importam

- **Filas:** `sessionQueue` (abrir/fechar), `videoQueue`/`audioQueue` (entrega de amostras), `controlQueue` (iniciar gravação), fila própria do `ClipWriter`. O estado compartilhado do motor fica sob um único `NSLock`.
- **Áudio no anel:** cada bloco da captura é COPIADO (`deepCopyAudio`). Guardar os buffers originais por 30 s esgotaria o pool de memória da captura.
- **Gravação:** durante o clipe o anel é esvaziado e as amostras vão direto ao `ClipWriter`. Ao parar, o anel é descartado até o último quadro (o fim do clipe não reaparece no começo do próximo).
- **ClipWriter:** entradas em modo não-tempo-real, fila de pendentes e `requestMediaDataWhenReady`. Cada entrada é encerrada quando a sua fila acaba (senão uma esperaria a outra e o arquivo nunca fecharia).
- **Bipe:** o microfone é trocado por silêncio durante o bipe (não grava o alto-falante); o relógio do áudio segue contínuo.
- **Orientação (v0.3.8):** a tela é sempre em pé. `OrientationSensor` (acelerômetro, 10 leituras por segundo, só com a câmera aberta) alimenta o `OrientationTracker` (Core); o motor lê a posição UMA vez no começo do clipe e grava o giro na matriz do arquivo (em pé 90°, topo à esquerda 0°, topo à direita 180°, de cabeça para baixo 270°), sem recodificar. Aparelho quase deitado na mesa mantém a última posição.

## Riscos abertos

- Microfone mudo pode ocorrer também no nativo: a etapa 1 mede (Diagnóstico + "Teste 20 aberturas").
- Voz pt-BR: confirmar reconhecimento no aparelho e escuta contínua antes da etapa 2.
- Achar o álbum "Ei Clip" exige permissão completa das Fotos.
- Sincronia áudio/vídeo: o AAC do arquivo tem um pequeno atraso de "priming" (dezenas de ms); medir no teste (d).
