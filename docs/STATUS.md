# Status

**Atualizado em:** 2026-11-05 · **Versão em teste:** v0.2.0 (sonda de voz) · **Estável:** v0.1.8 · **Etapa:** 2 (voz) iniciada com o OK do Kenidy em 05/11; etapa 1 fechada (todos os critérios aprovados)

## Etapa 2 (voz): onde estamos

- **v0.2.0 = sonda de voz (só medição, não dispara gravação).** Diagnóstico → botão "Sonda de voz (teste)", com a câmera aberta. Escuta o mesmo áudio da captura com `SFSpeechRecognizer` pt-BR e `requiresOnDeviceRecognition = true`, e registra no Diagnóstico (linhas `voz:`): permissão, se pt-BR roda no aparelho, texto parcial/final, vida de cada tarefa, religamentos e resumo a cada 30 s (com temperatura do aparelho).
- Se o aparelho não reconhecer pt-BR sem internet, a sonda PARA e avisa; não usa o servidor da Apple por conta própria (alternativas com custo vão para o Kenidy escolher).
- Próximo (depois do resultado da sonda e do "pode seguir"): portar `src/core/wake-word.ts` do web app para o Core com testes (versão própria), depois ligar a palavra de ativação ao gravar/parar.
- Critérios da etapa 2 (ROADMAP): taxa de acerto em 50 falas (perto, com ruído); falsos disparos em 5 min de conversa; voz + bipe sem chiado.

## Versão estável (para voltar se uma nova quebrar)

- **Última estável testada no aparelho: v0.1.8** (aprovada pelo Kenidy em 05/11; reabertura automática 10 de 10, Teste 20 aberturas com 0 falhas, clipes salvos sem falha desde a v0.1.6). Anterior estável: v0.1.7.
- Se uma versão nova quebrar algo, reinstalar a v0.1.8: https://github.com/Kenidy-WS/Ei-Clip-ios/releases/download/v0.1.8/EiClip.ipa (mesmo Apple ID no Sideloadly).
- Regra: uma versão só vira "estável" depois de testada no aparelho e com o OK do Kenidy; este bloco é atualizado nesse momento.

## Estado atual

- **Etapa 0 validada** (05/11): compilar → Release do GitHub → Sideloadly → confiar no perfil → abrir.
- **v0.1.0 (etapa 1)** compila e os testes da lógica pura passam no CI. Rodou no iPhone do Kenidy em 05/11.
  - Câmera traseira 1080p30 + microfone (uma única `AVCaptureSession`), sessão de áudio configurada à mão.
  - H.264 por hardware (VideoToolbox), keyframe a cada ~1 s, sem quadros B.
  - Anel retroativo de 15 ou 30 s (+3 s): vídeo já codificado; áudio guardado como PCM (cópia própria dos blocos).
  - Gravar/parar: arquivo MP4 único (AVAssetWriter, vídeo passthrough, áudio codificado em AAC pelo arquivo), pré-tempo + ao vivo. Fixo em pé (rotação de 90° gravada no arquivo).
  - Bipe de início/fim (AVAudioPlayer; o microfone é silenciado durante o bipe).
  - Salvar no álbum "Ei Clip" do Rolo (PhotoKit, permissão completa das Fotos).
  - Tela Diagnóstico: botão **Copiar**, **Limpar** e **Teste 20 aberturas** (critério "a"; é automático: tocar e soltar o iPhone).
- Release com o IPA: https://github.com/Kenidy-WS/ei-clip-ios/releases (cada versão tem o seu `vX.Y.Z`).

## Resultado do teste da v0.1.4 (05/11, 01:10 a 01:12): critério (a) PASSOU

- Teste 20 aberturas: **"FIM: 0 microfones mudos e 0 falhas em 20 aberturas"**.
- Pico mínimo 0,0099 (limite 0,0008); abertura em 168 a 338 ms; 0 quadros descartados, 0 erros do codificador, nenhuma interrupção (Kenidy não tocou no iPhone).
- A interrupção "motivo 1" da abertura 6 da v0.1.0 foi provavelmente toque do Kenidy na tela (ele ainda não sabia que o teste é automático). As falhas 7 a 20 daquela rodada eram o defeito de limpeza, corrigido na v0.1.4.
- O "motivo 1" aparece também com o app **inativo** (gesto de deslizar, Central de Controle): a sessão para e volta sozinha em ~0,15 s. A câmera só fecha em segundo plano.
- O app **não reabre** a câmera sozinho ao voltar (só o botão "Abrir câmera"). As vezes em que "abriu direto" foram interrupções por inatividade sem ir ao segundo plano. O Kenidy quer reabrir sozinho ao voltar: versão própria, depois do defeito abaixo.

## Resultado do teste da v0.1.6 (05/11, 02:03): 6 de 6 salvaram, confirmação parcial

- 6 clipes seguidos (3 com bipe no vídeo, 3 sem), buffer 15 s, **sem minimizar o app** (abertura nº 1 o tempo todo), pré-tempo real de 4,7 a 5,8 s. Todos "Rolo: OK", 0 retrocessos, trilhas de vídeo/áudio coerentes.
- A corrida existe: em 4 dos 6 clipes **1 quadro de vídeo ao vivo** chegou antes do pré-tempo (e foi posto na ordem certa).
- **2ª rodada (02:08 a 02:09):** buffer 30 s, minimizar/voltar entre os clipes (aberturas nº 4, 7, 10, 13 e 16): **5 de 5 salvaram**, 0 retrocessos. Chegada cedo em 2 dos 5 (vídeo=1; no último também áudio=1).
- Total na v0.1.6: **11 de 11 salvaram** (a chegada cedo ocorreu em 6). Na v0.1.5 a taxa de falha era ~3 em 7; passar 11 de 11 por sorte teria ~0,2% de chance. **Defeito dado por corrigido.**
- Limite do teste: o pré-tempo ficou em ~5 s (a câmera fecha no segundo plano e o anel recomeça). Pré-tempo longo (≥15 s) será coberto no teste final de (b).

## Defeito corrigido na v0.1.6: o arquivo falhava ~2 ms depois do início

Na v0.1.5, 7 gravações: 3 falharam e 4 salvaram. Falha sempre igual: `-11800` / `-16364`, 60 a 61 quadros e 90 a 121 blocos de áudio gravados, status=3. Não depende do bipe nem de ser o 1º clipe do app. Hipótese: amostras ao vivo entram na fila do arquivo antes do pré-tempo (tempos fora de ordem). A v0.1.6 corrige isso.

## Defeito aberto: gravação depois de várias aberturas (05/11, 00:57 a 01:01, v0.1.4)

Depois de 7 aberturas manuais (minimizar e voltar):
- **Clipe 1** (sem bipe no vídeo): pré 12,7 s + ao vivo 3,3 s (≈16 s esperados). O arquivo saiu com **28,25 s**, só 466 quadros (≈15,5 s) e 675 blocos de áudio: ~12 s sem imagem. O Kenidy viu o clipe travado, com áudio fora de sincronia e parte do áudio ausente. Salvou no Rolo.
- **Clipe 2** (com bipe no vídeo): o arquivo **não fechou**. No pedido de fim só 61 de ~300 quadros e 105 de ~430 blocos de áudio estavam gravados; nenhum "pronto" nem "Rolo". O vigia de 10 s não registrou (o arquivo já estava em `finishWriting`); o de 30 s só disparou quando o Kenidy voltou ao app (o iOS congela o app em segundo plano) e mostrou status=3 (falhou).
- Depois de fechar o app por completo e reabrir, 2 clipes (um com som no vídeo, outro sem) saíram perfeitos (relato do Kenidy; o log dessa rodada se perdeu, o Diagnóstico só existia na memória).
- Causa **desconhecida** (hipótese do Kenidy: o acúmulo de aberturas/minimizações). A v0.1.5 só registra mais para achar a causa; a correção vai numa versão própria.

## Resultado do 1º teste da v0.1.0 (05/11, iPhone 15, iOS 27.0.1)

- (b) pré-tempo: pedido 15 s, real 15,57 / 15,64 / 15,50 / 15,14 s → **passou** (±1 s). Duração do arquivo = pré-tempo + gravação ao vivo (confere).
- (c) 5 min: 300,4 s ao vivo, arquivo de 315,6 s, 476 MB, 9467 quadros (30,0 fps), salvo no Rolo, sem travar → **passou**.
- (d) sincronia: relatada OK pelo Kenidy → **passou**.
- (a) 20 aberturas: reprovado na v0.1.0 (defeito de limpeza meu depois de uma interrupção causada por toque); **passou na v0.1.4** (acima).
- 0 quadros descartados, 0 erros do codificador; ~30 quadros/s; 4 keyframes em 3 s (≈1/s).
- Detalhes do Kenidy: contador do buffer passava de 15/30 s → corrigido na v0.1.2; bipe de início aparecia no vídeo e o de fim não → corrigido na v0.1.1.

## Versões da etapa 2

- **v0.2.0** sonda de voz (`Engine/VoiceProbe.swift`, área protegida) + `Core/RestartGuard.swift` (desiste de religar o reconhecedor se as tarefas morrem quase na hora, 5 vezes seguidas; com testes). Não muda gravação, anel nem bipe; o único ponto novo no motor é entregar o mesmo bloco de áudio à sonda.

## Versões da etapa 1

- **v0.1.0** motor mínimo.
- **v0.1.1** bipe: silêncio no microfone medido pela hora da captura (+ latência do alto-falante); opções "Sons de gravação" (ligado) e "Sons no vídeo" (desligado), como no web app. Com "Sons no vídeo", o bipe é somado ao áudio e o bipe de fim entra no clipe antes de fechar o arquivo.
- **v0.1.2** contador do buffer limitado ao tempo escolhido.
- **v0.1.3** vigia da finalização do arquivo + registro.
- **v0.1.4** abertura que falha limpa a sessão (não contamina as seguintes) + registro do estado do app nas interrupções.
- **v0.1.8** reabertura automática: ao voltar para o app, a câmera reabre sozinha se foi o segundo plano que a fechou (o botão Fechar e o teste de 20 aberturas nunca reabrem sozinhos).
- **v0.1.7** falha do arquivo avisada na hora: o gravador avisa assim que o arquivo falha, o app encerra a gravação, apaga o arquivo parcial e mostra "Não foi possível gravar o clipe. A gravação foi encerrada; tente novamente." (sem esperar o vigia de 30 s). Textos novos para o usuário ficam em `Engine/Textos.swift`, em tom formal.
- **v0.1.6** correção da ordem das amostras no `ClipWriter`: amostras ao vivo que chegam antes do pré-tempo ficam guardadas e entram depois dele; o log mostra quantas chegaram cedo e, se o arquivo falhar, os tempos gravados de vídeo e áudio.
- **v0.1.5** só diagnóstico (nenhuma mudança de comportamento): tempos de vídeo e áudio de cada clipe (primeiro, último, maior salto, retrocessos), estado e erro do arquivo (ao pedir o fim e a cada 3, 6, 10 e 30 s sem fechar), trilhas do arquivo pronto, nº da abertura, estado do app (ativo/inativo/segundo plano) e o Diagnóstico salvo em arquivo, com o botão **Copiar rodada anterior** (sobrevive a fechar o app).

## Etapa 0: lições

- O Sideloadly acrescenta o ID da equipe do Apple ID ao Bundle ID (`br.com.wpstecnologia.eiclip.<equipe>`). Instalar sempre com o **mesmo Apple ID**.
- O app expira em 7 dias: reinstalar pelo Sideloadly (primeira instalação em 05/11 → renovar até 12/11).
- A tabela de artefatos do GitHub não funcionou no navegador do Kenidy: o IPA é publicado numa Release (link direto).

## Critérios da etapa 1

- (a) 20 aberturas seguidas, 0 microfones mudos (pico > 0,0008 após 3 s) e 0 falhas: **passou na v0.1.4**.
- (b) o clipe começa dentro de ±1 s do pré-tempo pedido: passou na v0.1.0; refeito na v0.1.8: passou (relato do Kenidy).
- (c) clipe de 5 min grava e salva no Rolo sem travar: passou na v0.1.0; refeito na v0.1.8: passou (relato do Kenidy).
- (d) áudio e vídeo em sincronia: passou na v0.1.0; refeito na v0.1.8: passou (relato do Kenidy).

## Pendências (retomada em novo chat)

Etapa 1 concluída nos testes (histórico acima). Próximo:

1. **OK explícito do Kenidy** para fechar a etapa 1 e iniciar a etapa 2 (voz). Sem o OK, não começar.
2. **Etapa 2 (voz), área protegida (vai sozinha numa versão, `v0.2.x`):**
   - Verificar `SFSpeechRecognizer` pt-BR em modo no aparelho (`requiresOnDeviceRecognition`) e escuta contínua alimentada pelo áudio da mesma captura (sem segundo microfone). Se não servir, apresentar alternativas com custo e deixar o Kenidy escolher.
   - Ler no web app (somente leitura) `src/core/wake-word.ts` e `tests/wake-word.test.ts`; portar a lógica para o Core com testes.
   - Antes de codar: ler o `CLAUDE.md` e `docs/` do web app (armadilhas do iOS com voz e sessão de áudio).
3. Depois da etapa 2: etapa 3 (interface final, onda de revisão de textos migrando tudo para `Engine/Textos.swift`) conforme `docs/ROADMAP.md`.
4. Opcional: o Kenidy colar o log do teste final (b), (c), (d) para registrar os números.
5. Observação aberta (sem ação): salto de ~0,2 a 0,4 s no início do vídeo quando o pré-tempo começa logo na abertura da câmera (primeiro quadro tardio); observar na sincronia.

## Notas operacionais

- O repositório mudou de endereço no GitHub (`Kenidy-WS/Ei-Clip-ios`); o antigo redireciona e o push funciona. Para a API, `Kenidy-WS/ei-clip-ios` ainda responde.
- Sem toolchain Swift no ambiente: só o CI valida compilação e testes. Commits só de docs levam `[skip ci]`.
- `gh release view` falha (GraphQL 403): usar `gh api repos/Kenidy-WS/ei-clip-ios/releases/tags/vX.Y.Z`.
- Web app de referência (somente leitura): https://github.com/Kenidy-WS/clip (clonar raso para ler `src/core/` e `tests/`).
- O Diagnóstico agora é gravado em `Application Support/Diagnostico/atual.txt` (e a rodada anterior em `anterior.txt`); "Limpar" zera a tela e o arquivo da rodada atual.

## Decisões

- **Textos do usuário:** tom formal e claro; textos novos em `Engine/Textos.swift`. Os demais textos serão migrados para lá e revisados numa onda de revisão de textos na etapa 3 (interface final). O Diagnóstico segue técnico.
- Bundle ID: `br.com.wpstecnologia.eiclip` (definitivo).
- Sem galeria própria: salvar no álbum "Ei Clip" do Rolo.
- Sem toolchain Swift no ambiente de desenvolvimento: lógica pura testada no CI macOS (`swift test` em `Core/`, o IPA só sai se passar).
- **Áudio do anel em PCM, não AAC:** cabe fácil na memória (~6 MB em 30 s) e o próprio arquivo codifica o AAC na gravação (sem trabalho de empacotar AAC à mão). Diverge do texto do plano ("H.264/AAC já codificados"); o vídeo continua codificado.
- 1080p30 fixo na etapa 1 (60 fps só na etapa 4); taxa/resolução vêm de `Core/VideoProfile.swift`.
- Reabrir a câmera sozinha ao voltar ao app é o comportamento desejado (hoje só o botão); entra depois de resolver o defeito de gravação.
