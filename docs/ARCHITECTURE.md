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

- `Core/` — pacote Swift com a lógica pura e testes (`swift test` no CI). O app compila `Core/Sources/EiClipCore` direto (sem módulo separado).
  - `ReplayBuffer` (porta de `replay-buffer.ts`), `VideoProfile` (tabela de taxa), `ClipName` (nome e m:ss), `MicLevel` (pico e microfone mudo), `BeepWave` (bipe e WAV), `TimelineStats` (primeiro/último tempo, maior salto e retrocessos de uma sequência de tempos; diagnóstico do clipe).
- `Engine/` — câmera, codificação, gravação, Rolo. **Área protegida (mudar sozinha numa versão):** `AudioSessionConfig.swift` (sessão de áudio) e, na etapa 2, a voz.
  - `CaptureEngine` (orquestra), `VideoEncoder`, `ClipWriter`, `PhotoSaver`, `BeepPlayer`, `SampleBufferUtils`, `Diagnostics`, `AudioSessionConfig`.
- `App/` — SwiftUI: `RootView` (provisória; a interface final é a etapa 3), `DiagnosticsView`, `CameraPreview`, `EiClipApp`.
- `project.yml` — XcodeGen (o `.xcodeproj` não é versionado). `.github/workflows/build.yml` — testes → IPA não assinado → Release.

## Detalhes que importam

- **Filas:** `sessionQueue` (abrir/fechar), `videoQueue`/`audioQueue` (entrega de amostras), `controlQueue` (iniciar gravação), fila própria do `ClipWriter`. O estado compartilhado do motor fica sob um único `NSLock`.
- **Áudio no anel:** cada bloco da captura é COPIADO (`deepCopyAudio`). Guardar os buffers originais por 30 s esgotaria o pool de memória da captura.
- **Gravação:** durante o clipe o anel é esvaziado e as amostras vão direto ao `ClipWriter`. Ao parar, o anel é descartado até o último quadro (o fim do clipe não reaparece no começo do próximo).
- **ClipWriter:** entradas em modo não-tempo-real, fila de pendentes e `requestMediaDataWhenReady`. Cada entrada é encerrada quando a sua fila acaba (senão uma esperaria a outra e o arquivo nunca fecharia).
- **Bipe:** o microfone é trocado por silêncio durante o bipe (não grava o alto-falante); o relógio do áudio segue contínuo.
- **Orientação:** etapa 1 só em pé; o vídeo é gravado sem recodificar com rotação de 90° no arquivo. Em pé e deitado é a etapa 3.

## Riscos abertos

- Microfone mudo pode ocorrer também no nativo: a etapa 1 mede (Diagnóstico + "Teste 20 aberturas").
- Voz pt-BR: confirmar reconhecimento no aparelho e escuta contínua antes da etapa 2.
- Achar o álbum "Ei Clip" exige permissão completa das Fotos.
- Sincronia áudio/vídeo: o AAC do arquivo tem um pequeno atraso de "priming" (dezenas de ms); medir no teste (d).
