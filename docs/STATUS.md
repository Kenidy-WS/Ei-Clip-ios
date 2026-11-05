# Status

**Atualizado em:** 2026-11-05 · **Versão:** v0.1.0 · **Etapa:** 1 (motor mínimo), aguardando testes no iPhone

## Estado atual

- **Etapa 0 validada** (05/11): compilar → Release do GitHub → Sideloadly → confiar no perfil → abrir.
- **v0.1.0 (etapa 1)** compila e os 19 testes da lógica pura passam no CI. **Nunca rodou no aparelho:** tudo abaixo ainda é hipótese até o Kenidy testar.
  - Câmera traseira 1080p30 + microfone (uma única `AVCaptureSession`), sessão de áudio configurada à mão.
  - H.264 por hardware (VideoToolbox), keyframe a cada ~1 s, sem quadros B.
  - Anel retroativo de 15 ou 30 s (+3 s): vídeo já codificado; áudio guardado como PCM (cópia própria dos blocos).
  - Gravar/parar: arquivo MP4 único (AVAssetWriter, vídeo passthrough, áudio codificado em AAC pelo arquivo), pré-tempo + ao vivo. Fixo em pé (rotação de 90° gravada no arquivo).
  - Bipe de início/fim (AVAudioPlayer; o microfone é silenciado durante o bipe).
  - Salvar no álbum "Ei Clip" do Rolo (PhotoKit, permissão completa das Fotos).
  - Tela Diagnóstico: botão **Copiar**, **Limpar** e **Teste 20 aberturas** (critério "a").
- Release com o IPA: https://github.com/Kenidy-WS/ei-clip-ios/releases (cada versão tem o seu `vX.Y.Z`).

## Etapa 0: lições

- O Sideloadly acrescenta o ID da equipe do Apple ID ao Bundle ID (`br.com.wpstecnologia.eiclip.<equipe>`). Instalar sempre com o **mesmo Apple ID**.
- O app expira em 7 dias: reinstalar pelo Sideloadly (primeira instalação em 05/11 → renovar até 12/11).
- A tabela de artefatos do GitHub não funcionou no navegador do Kenidy: o IPA é publicado numa Release (link direto).

## Critérios da etapa 1 (a medir no iPhone)

- (a) 20 aberturas seguidas, 0 microfones mudos (pico > 0,0008 após 3 s).
- (b) o clipe começa dentro de ±1 s do pré-tempo pedido.
- (c) clipe de 5 min grava e salva no Rolo sem travar.
- (d) áudio e vídeo em sincronia.

## Pendências

1. Kenidy testar a v0.1.0 (lista numerada enviada no chat) e colar o Diagnóstico.
2. Confirmar se o álbum "Ei Clip" é criado/reaproveitado com a permissão completa das Fotos.
3. Etapa 2 (voz) só depois de a etapa 1 bater os critérios.

## Decisões

- Bundle ID: `br.com.wpstecnologia.eiclip` (definitivo).
- Sem galeria própria: salvar no álbum "Ei Clip" do Rolo.
- Sem toolchain Swift no ambiente de desenvolvimento: lógica pura testada no CI macOS (`swift test` em `Core/`, o IPA só sai se passar).
- **Áudio do anel em PCM, não AAC:** cabe fácil na memória (~6 MB em 30 s) e o próprio arquivo codifica o AAC na gravação (sem trabalho de empacotar AAC à mão). Diverge do texto do plano ("H.264/AAC já codificados"); o vídeo continua codificado.
- 1080p30 fixo na etapa 1 (60 fps só na etapa 4); taxa/resolução vêm de `Core/VideoProfile.swift`.
