# Arquitetura (plano; implementada por etapas)

```
câmera + mic (AVCaptureSession única)
  ├─ vídeo ─► VideoToolbox H.264 (keyframe ~1 s) ─┐
  └─ áudio ─► AAC ────────────────────────────────┴─► Anel (últimos 15/30 s + 3 s, já codificado)
                                                        │ ao gravar: corta no keyframe,
                                                        ▼ escreve o anel e segue ao vivo no MESMO arquivo (AVAssetWriter, passthrough)
                                                     Salvar no álbum "Ei Clip" (PhotoKit)
voz (etapa 2): SFSpeechRecognizer pt-BR alimentado pelo áudio da mesma captura (sem segundo microfone)
```

## Pastas (previstas)

- `App/` — telas SwiftUI e Diagnóstico.
- `Core/` — lógica pura com testes (palavras de ativação, tabelas de qualidade, nome do clipe, nível, anel).
- `Engine/` — captura, codificação, gravação, voz. **Área protegida:** voz e sessão de áudio.
- `project.yml` — projeto XcodeGen (o `.xcodeproj` não é versionado).
- `.github/workflows/build.yml` — compila e gera o IPA não assinado.

## Riscos

- Microfone mudo pode ocorrer também no nativo: a etapa 1 mede.
- Voz pt-BR: confirmar reconhecimento no aparelho e escuta contínua antes da etapa 2.
- Sideloadly/AltStore podem alterar o Bundle ID ao assinar.
- Achar o álbum "Ei Clip" pode exigir permissão completa das Fotos.
