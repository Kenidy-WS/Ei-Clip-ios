# Status

**Atualizado em:** 2026-11-05 · **Versão:** v0.1.4 · **Etapa:** 1 (motor mínimo), retestar no iPhone

## Estado atual

- **Etapa 0 validada** (05/11): compilar → Release do GitHub → Sideloadly → confiar no perfil → abrir.
- **v0.1.0 (etapa 1)** compila e os 19 testes da lógica pura passam no CI. Rodou no iPhone do Kenidy em 05/11 (resultado abaixo).
  - Câmera traseira 1080p30 + microfone (uma única `AVCaptureSession`), sessão de áudio configurada à mão.
  - H.264 por hardware (VideoToolbox), keyframe a cada ~1 s, sem quadros B.
  - Anel retroativo de 15 ou 30 s (+3 s): vídeo já codificado; áudio guardado como PCM (cópia própria dos blocos).
  - Gravar/parar: arquivo MP4 único (AVAssetWriter, vídeo passthrough, áudio codificado em AAC pelo arquivo), pré-tempo + ao vivo. Fixo em pé (rotação de 90° gravada no arquivo).
  - Bipe de início/fim (AVAudioPlayer; o microfone é silenciado durante o bipe).
  - Salvar no álbum "Ei Clip" do Rolo (PhotoKit, permissão completa das Fotos).
  - Tela Diagnóstico: botão **Copiar**, **Limpar** e **Teste 20 aberturas** (critério "a").
- Release com o IPA: https://github.com/Kenidy-WS/ei-clip-ios/releases (cada versão tem o seu `vX.Y.Z`).

## Resultado do 1º teste da v0.1.0 (05/11, iPhone 15, iOS 27.0.1)

- (b) pré-tempo: pedido 15 s, real 15,57 / 15,64 / 15,50 / 15,14 s → **passou** (±1 s). Duração do arquivo = pré-tempo + gravação ao vivo (confere).
- (c) 5 min: 300,4 s ao vivo, arquivo de 315,6 s, 476 MB, 9467 quadros (30,0 fps), salvo no Rolo, sem travar → **passou**.
- (d) sincronia: relatada OK pelo Kenidy → **passou**.
- (a) 20 aberturas: **rodado na v0.1.0: NÃO passou** (ver "Teste 20 aberturas" abaixo). Nas 3 aberturas manuais o pico foi 0,0136 / 0,0126 / 0,0142 (ok). A 1ª abertura levou 7 s (pedidos de permissão); as demais ~300 ms.
- 0 quadros descartados, 0 erros do codificador; ~30 quadros/s; 4 keyframes em 3 s (≈1/s).
- Ao ir para o segundo plano a sessão é interrompida (motivo 1) e a câmera fecha limpa, como esperado.
- **Anomalia:** o 2º clipe (início 00:32:35, 18 s ao vivo) não registrou "arquivo: pronto" nem o resultado do Rolo. A v0.1.3 passa a registrar a finalização e fecha o arquivo à força após 10 s.
- Detalhes do Kenidy: contador do buffer passava de 15/30 s (anel guarda +3 s) → corrigido na v0.1.2; bipe de início aparecia no vídeo e o de fim não → corrigido na v0.1.1.

## Teste 20 aberturas na v0.1.0 (05/11): reprovado, mas por outro motivo
- Aberturas 1 a 5: ok, microfone nunca mudo (picos 0,0106 a 0,0172).
- Abertura 6: o sistema interrompeu a sessão (motivo 1, "câmera indisponível em segundo plano") e a sessão não iniciou. Esse motivo apareceu com o app aberto na tela, e a causa de fundo ainda é desconhecida.
- Aberturas 7 a 20 (14 falhas): **defeito meu**. A falha da 6 saiu sem limpar a sessão; ela ficou com a entrada de vídeo antiga e `canAddInput` recusou a nova, registrado como "câmera traseira indisponível".
- v0.1.4 corrige a limpeza (toda falha de abertura limpa a sessão; sobra de abertura anterior é limpa antes de montar) e registra, em cada interrupção, se o app estava ativo.
- 0 microfones mudos em 5 aberturas boas; critério (a) segue **em aberto** até um teste com 0 mudos e 0 falhas.

## Versões da etapa 1

- **v0.1.0** motor mínimo.
- **v0.1.1** bipe: silêncio no microfone medido pela hora da captura (+ latência do alto-falante); opções "Sons de gravação" (ligado) e "Sons no vídeo" (desligado), como no web app. Com "Sons no vídeo", o bipe é somado ao áudio e o bipe de fim entra no clipe antes de fechar o arquivo.
- **v0.1.2** contador do buffer limitado ao tempo escolhido.
- **v0.1.3** vigia da finalização do arquivo + registro.
- **v0.1.4** abertura que falha limpa a sessão (não contamina as seguintes) + registro do estado do app nas interrupções.

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
