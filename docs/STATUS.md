# Status

**Atualizado em:** 2026-11-05 · **Versão em teste:** v0.3.3 (etapa 3: botão do Início) · **Estável:** v0.1.8 · **Etapa:** 3 (interface) iniciada em 05/11; etapas 1 e 2 fechadas (a 2 com ressalva: falta exercitar o religar do reconhecedor)

## Etapa 2 (voz): onde estamos

- **v0.2.0 = sonda de voz (só medição, não dispara gravação).** Diagnóstico → botão "Sonda de voz (teste)", com a câmera aberta. Escuta o mesmo áudio da captura com `SFSpeechRecognizer` pt-BR e `requiresOnDeviceRecognition = true`, e registra no Diagnóstico (linhas `voz:`): permissão, se pt-BR roda no aparelho, texto parcial/final, vida de cada tarefa, religamentos e resumo a cada 30 s (com temperatura do aparelho).
- Se o aparelho não reconhecer pt-BR sem internet, a sonda PARA e avisa; não usa o servidor da Apple por conta própria (alternativas com custo vão para o Kenidy escolher).
- **Resultado da sonda (05/11, iPhone 15, iOS 27.0.1): PASSOU nas perguntas centrais.**
  - pt-BR roda no aparelho (`no aparelho=SIM`); o Kenidy relatou que reconheceu em modo avião e com música alta.
  - Mesmo áudio da captura: 2728 blocos entregues em 63 s (~43/s, igual ao ritmo da captura), 0 falhas.
  - O iOS escreve "clipe" (não "clip"): parciais "Ei" → "Ei cli" → "Ei clipe", cerca de 0,7 s da primeira parcial até "clipe".
  - O texto às vezes zera depois de uma pausa (volta a "Ei") e às vezes acumula ("Ei clipe ei clipe"): a lógica da palavra de ativação não pode depender do texto inteiro.
  - Confiança vem 0.00 nos parciais: não usar como critério.
  - Uma tarefa viveu 63 s sem religar, atravessou ~27 s de silêncio e a temperatura ficou normal.
  - **Não coberto pelo log recebido (termina em 63 s):** religamento da tarefa (limite de vida), 3 min parado, música e as 50 falas. Ficam para a verificação com o gatilho real.
- **Resultado da v0.2.1 (05/11, teste de ~5,7 min): detector PASSOU nas falas; falsos disparos NÃO medidos.**
  - 1 `GATILHO` por fala nas três palavras, sem duplicar: 14 de "Ei Clip", 2 de "Ei Câmera" e 8 de "Câmera, ação" (24 no total pelo log). Em 10 falas seguidas, a cerca de 1,8 s uma da outra, com o texto acumulando ("Em clipe ei clipe ei clipe…"), cada fala deu exatamente um gatilho.
  - Revisão do iOS tratada: "Câmeras ação" → "Câmera ação" deu um gatilho só. "Câmera" solta não dispara.
  - A mesma tarefa de escuta viveu 343 s (5,7 min) sem religar; temperatura normal; ~43 blocos/s entregues. O caminho de religamento ainda não foi exercitado.
  - O iOS escreveu "Em"/"Ec" no lugar de "Ei" ("Em clipe"). "Em" não está na lista de saudações: só "clip solto" (que liga; gravando, só para depois de 3,5 s, como no web app) pegaria. Candidato: incluir "em" (avaliar o risco com teste antes).
  - **Lacuna:** de 64 s a 203 s o log não tem NENHUM texto (resultados=41 parado). Não houve conversa nem música com letra reconhecida nesse trecho, então os falsos disparos continuam sem medida.
- **Decisão do Kenidy (05/11, 09:08): avançar.** Aceitou a rodada solta no lugar das 50 falas contadas ("foi bastante", repetir cansa) e confirmou que o bipe no vídeo não estourou. Registrado no ROADMAP como aprovação com ressalvas. Ressalvas abertas da etapa 2: (1) escolher entre as 3 palavras (só "Ei Clip" age); "Câmera, ação" e "Ei Câmera" só foram vistas em log, sem teste de comando; (2) o religar do reconhecedor nunca foi exercitado (a tarefa mais longa viveu 6 min sem cair); em pesca, com horas de câmera aberta, vale uma espera longa (30 min ou mais) em Comando antes de confiar.
- **Teste de acertos (rodada solta, "Só medir", 05/11): NÃO conta como as 50 falas, porque o Kenidy não contou as falas ditas.** O log tem ~2 min e 18 gatilhos (4 frase completa, 11 começo parcial, 3 "clip solto"), espaçados no mínimo 3,1 s (a trava de 3 s funciona). Em rajadas de ~1,2 s entre falas, o texto do iOS mostrou todas as falas ("Ei clipe ei clipe ..." acumulado) e a trava deixou passar uma a cada ~3 s, como projetado. As falas a menos de 3 s do gatilho anterior foram barradas (esperado). Com vídeo tocando perto o iOS transcreveu o vídeo ("Daniel quatro reinos na Babilônia...") sem nenhum gatilho. Falas mais distantes: o iOS às vezes perdeu o "Ei" e ficou "Clipe" solto, que ainda liga (por isso o "clip solto" existe). Falta repetir com contagem: 25 de perto + 25 com ruído, 4 s entre falas, Kenidy informa quantas disse.
- **Teste de falsos disparos da v0.2.4 (05/11): PASSOU. 0 gatilhos em 6 min (349 s de sonda ligada, 422 resultados, ~434 textos), fala contínua em português; reconhecedor numa só tarefa, 0 religadas, temperatura normal.** O texto cresceu até frases longas (acumulado de minutos) sem problema. Única palavra parecida no texto: "aceitação" (contém "ação" só como pedaço de palavra; não casa). Falta: 50 falas (acertos), ouvido do chiado do bipe, caminho de religar o reconhecedor.
- **Resultado da v0.2.4 (05/11): PASSOU. 7 clipes por voz em 2 rodadas, 14 de 14 comandos, nenhum começou ou parou sozinho, todos salvos.** Comando de parar antes de 3 s do início é ignorado e não fica guardado (confirmado 3 vezes: "Ei clipe ei clipe" 1,1 a 1,9 s depois de ligar não parou; a fala seguinte, depois de 3 s, parou na hora). Falas durante o encerramento são descartadas (não religam). Texto acumulado ("Ei clipe ei clipe ei clipe ei clipe"), "Ei Felipe" e "Eclipse Lipp" não atrapalharam. A contagem dos 3 s é de relógio desde o comando que ligou (não usa pré-tempo nem tamanho do vídeo). A impressão de "parar cedo demais" era a percepção do tempo: as falas já estavam além de 3 s. Pendente (opcional): registrar no Diagnóstico o comando barrado pela trava (hoje é silencioso).
- **Resultado da v0.2.3 (05/11): 4 clipes por voz, 8 de 8 comandos, arquivos e Rolo sem falha; achou 1 defeito novo (meu, da v0.2.3).** No clip 2, "Ei clipe" dito 3,3 s depois de ligar não parou; parou 2 s depois, quando o iOS repetiu o mesmo texto. Causa: o tempo entre textos era medido também nos resultados repetidos (31 resultados contra 25 linhas no log), então o "Ei" novo foi lido como revisão e a 1ª palavra ficou "gasta"; "Ei clipe" virou "clip solto", que só vale depois de 3,5 s. Decisão do Kenidy: "Eclipse" continua valendo como acionador (paridade com o web; 5 dos 8 comandos chegaram assim); falsos disparos serão medidos no teste de 5 min em "Só medir".
- **Resultado da v0.2.2 (05/11): PASSOU. 3 clipes por voz, 6 de 6 comandos (3 ligar, 3 parar), clipes salvos no Rolo.**
  - Pré-tempo: 15,03 s e 15,87 s nos clipes 1 e 3 (pedido 15 s; o 2º teve 9,83 s porque o anel só guarda o que veio depois do fim do clipe anterior, por desenho). Vídeo e áudio em sincronia (trilhas com 0,04 s de diferença), 0 saltos > 0,25 s, 0 retrocessos, 0 erros de arquivo.
  - Parar: da fala até o bipe de fim, 16 ms; fim do arquivo em ~0,4 s.
  - **Defeito 1 (achado no log, linha da frase repetida):** depois de ligar por "ei cli", o iOS revisou o texto de 5 para 3 palavras ("Chuca ei clipe") 2,1 s depois; o `WakeTracker` tratou como fala nova e pediu PARAR. Só a trava de 3 s do motor impediu. Se a revisão viesse depois de 3 s, a gravação pararia logo depois de começar.
  - **Defeito 2:** "Ec clipe" saiu como "clip solto" e não "frase completa": depois de "Eclipse" (1 palavra) o rastreador ficou com `consumed = 1` e pulou a 1ª palavra da fala seguinte (a detecção de fala nova só olha se o texto encolheu). Ligar funcionou (clip solto liga); parar nos primeiros 3,5 s de gravação ficaria sem efeito.
  - Ainda abertos: 50 falas (perto e com ruído), falsos disparos em 5 min de conversa real (em "Só medir"), chiado do bipe (só o ouvido diz; o Kenidy relatou que funcionaram bem).
- Próximo (depois do "pode seguir"): portar `src/core/wake-word.ts` do web app para o Core com testes (versão própria), depois ligar a palavra de ativação ao gravar/parar.
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

- **Resultado da v0.2.5 (05/11): PASSOU. 6 clipes (3 com "Câmera, ação", 3 com "Ei Câmera"), 12 de 12 comandos, todos salvos.** Com uma palavra escolhida, as outras só entram no log: "Eclipse" e "Ei câmera" (com "Câmera, ação" escolhida) e "Ec clipe" (com "Ei Câmera" escolhida) deram `GATILHO` sem `COMANDO`. Troca de palavra valeu na hora. "Ei ei ei câmera" foi aceito como "Ei Câmera". Fala a 2,6 s do comando anterior foi barrada (trava de 3 s). Temperatura do aparelho passou a "morno" (antes "normal") com câmera e voz ligadas por ~2 min: acompanhar em sessões longas (aviso se virar "quente").
- **Etapa 3, plano (decidido com o Kenidy em 05/11):** v0.3.0 Início (marca animada, texto, "Abrir câmera", versão) · v0.3.1 Recentes (clipes do álbum "Ei Clip" no Início; tocar abre no app Fotos) · v0.3.2 tela da Câmera (pílula do buffer, botão de voz, obturador, miniatura, ajustes) · v0.3.3 folha de Ajustes (buffer, sons, comando de voz e palavra, câmera, armazenamento, Diagnóstico) · v0.3.4 em pé e deitado: tela fixa em pé; o sensor do aparelho só decide a rotação do ARQUIVO no começo do clipe (iPhone deitado na mesa mantém a última orientação). Galeria e player próprios NÃO entram: usa o app Fotos.
- **Plano mudou (Kenidy, 05/11, depois de validar a v0.3.1):** entra uma **etapa 4 — Galeria e gestos**, idêntica ao web app (galeria só com os clipes do álbum "Ei Clip", player, seleção em lote, transições, gestos de arrastar), e a antiga Paridade vira **etapa 5** (versões v0.5.x). Fica assim: etapa 3: v0.3.2 espaçamento do Início · v0.3.3 botão do Início · v0.3.4 tela da Câmera · v0.3.5 Ajustes · v0.3.6 voz liga junto com a câmera (preferência; área protegida, sozinha) · v0.3.7 em pé e deitado (sensor). Etapa 4 (v0.4.x, ordem a confirmar): Galeria (grade, rolagem, transições de tela e "Ver todos") · Player (barras de vidro, play/pause, posição, velocidade, som, detalhes, tocar esconde barras, arrastar para baixo fecha) · trocar de clipe arrastando para os lados · seleção em lote (toque longo, arrastar para selecionar, selecionar todos, compartilhar, excluir) · gestos de borda (voltar pela borda esquerda, avançar para a Galeria pela direita) e arrastar para baixo fecha os Ajustes. Fonte da verdade: `src/ui/clips-view.ts`, `gestures.ts`, `transitions.ts`, `sheet-swipe.ts` e `docs/HISTORICO.md` do web app. Limites do iOS a combinar: excluir sempre mostra a confirmação do sistema; "Salvar" vira a folha de compartilhar do iOS.
- **v0.3.3** (só interface) botão "Abrir câmera" igual ao do web app: branco, 52 pt de altura, até 320 pt de largura, cantos de 14 pt, texto 17 semibold, ícone de câmera de contorno, 85% ao tocar. Avaliação feita a pedido do Kenidy: o botão amarelo em cápsula das v0.3.0 a 0.3.2 era invenção minha, não do web app. O branco é melhor aqui: a marca é o único amarelo da tela (no web app o amarelo só marca o que está ativo), o contraste sobre preto é o máximo (sol), e 52 x 320 pt é um alvo maior para o polegar (mão molhada, luva).
- **v0.3.2** (só interface) espaçamento do Início igual ao do web app: marca e logo a 10; blocos a 8; texto com 20 a mais embaixo (o botão fica 6 pt mais afastado do que na v0.3.1). Pedido do Kenidy: o botão parecia colado na marca.
- **v0.3.1** (só interface) "Recentes" no Início, como no web app: título "Recentes", os 4 clipes mais novos do álbum "Ei Clip" em miniaturas 3:4 com a duração no canto, "Ver todos" e, sem clipes, "Nenhum clipe ainda.". Tocar numa miniatura reproduz o clipe dentro do app (tela cheia, botão voltar); "Ver todos" abre o app Fotos (o iOS não permite abrir um clipe ou álbum específico no Fotos; abre onde o Fotos estava). Compartilhar e excluir ficam no Fotos. A lista só lê as Fotos se já houver permissão (não provoca o pedido no Início) e se atualiza sozinha quando um clipe novo é salvo. Novos: `App/RecentClips.swift` (lista e miniatura), `App/ClipPlayerView.swift`; textos novos em `Engine/Textos.swift`. Mudança em relação ao combinado: tocar reproduz no app em vez de abrir no Fotos (o Fotos não aceita abrir um clipe específico).
- **v0.3.0** (só interface) tela de Início igual à do web app: marca animada (anel desenhado em 1 s, triângulo aos 0,6 s, ponto aos 0,95 s), logo, "Câmera de ação com comando de voz.", botão "Abrir câmera", versão no rodapé. Câmera fechada mostra o Início; aberta, a tela provisória da etapa 1 (com "Fechar" volta ao Início). A engrenagem abre o Diagnóstico até a v0.3.3. Imagens da marca e o ícone do app (1024, do `icon.svg` do web app) renderizados dos SVG do web app (somente leitura) para `App/Assets.xcassets` (o catálogo exige o conjunto "AppIcon" para compilar). Novos: `App/HomeView.swift`, `App/BrandMark.swift`. O log da sonda de voz ainda diz "v0.2.5" na linha "sonda ligada" (texto fixo; corrigir numa versão da voz).
- **v0.2.5** (área protegida da voz, sozinha) escolha da palavra de ativação: no Diagnóstico, abaixo de "Voz (teste)", seletor "Palavra de ativação" com Ei Clip / Câmera, ação / Ei Câmera (guardado no aparelho; a tela final de Ajustes é a etapa 3). No modo Comando só a palavra escolhida liga e para; as outras continuam só no log. Troca valendo na hora, sem religar a voz. O detector (Core) não mudou. Teste: 3 clipes com cada palavra.
- **v0.2.4** (só o detector; sem câmera nem áudio) `WakeTracker` passa a contar OCORRÊNCIAS da frase no texto (completa, começo parcial ou "clip" solto) e só dispara para ocorrência nova; `fired` encolhe com o texto. Sai a lógica de palavras gastas e de tempo entre textos da v0.2.3. Texto repetido, revisão e texto que zera não dependem de relógio; "ei cli" gravando não é gasto e vira "ei clipe" (mesma ocorrência). Comando antes dos 3 s é ignorado de vez (não fica guardado). Testes novos com a sequência do clip 2.
- **v0.2.3** (só o detector, Core + versão; sem mudar câmera nem áudio) corrige os dois defeitos achados no log da v0.2.2. `WakeTracker` agora guarda o texto anterior e a hora dele: texto que continua o anterior segue; texto que mudou depois de 1 s ou mais é fala nova (zera o gasto); mudou em menos de 1 s é revisão (o gasto só encolhe junto). Trava de intervalo do rastreador de 1,5 s para 3 s (igual ao `voice.ts`), que barra a revisão tardia (1 a 3 s). Testes novos com as sequências reais do log ("Chuca ei Chuca ei cli" → "Chuca ei clipe"; "Eclipse" e depois "Ei"/"Ec"/"Ec clipe").
- **v0.2.2** (área protegida, sozinha) comando de voz: no Diagnóstico, "Voz (teste)" tem Desligada / Só medir / Comando. Em "Comando", "Ei Clip" liga a gravação (frase completa, começo parcial "ei cli" ou "clip" solto) e para (frase completa; "clip" solto só depois de 3,5 s gravando; durante o encerramento nada vale), com 3 s entre comandos, como no `voice.ts` do web app. Core: `WakeState` e `WakeTracker.feed(..., state:)` (gravando, o "ei cli" parcial não é gasto, senão o "ei clipe" completo nunca pararia). Só "Ei Clip" age; "Câmera, ação" e "Ei Câmera" continuam só no log (seletor de palavra fica para depois). O bipe segue sem pausar o reconhecedor: o microfone já é silenciado durante o bipe e a captura é a mesma.
- **v0.2.1** porta de `src/core/wake-word.ts` para o Core (`WakeWords`, `WakeWord`, `WakeGate`, com os testes do web app) + `WakeTracker` (novo: transforma o texto cumulativo do iOS em acertos únicos; trata "clipe", o texto que zera e o que acumula). A sonda aplica o detector nas três palavras (Ei Clip, Câmera ação, Ei Câmera) e registra `GATILHO` no Diagnóstico. Continua sem gravar nem parar nada. Próxima: v0.2.2 liga o gatilho a gravar/parar (área protegida, sozinha), depois de validar acertos e falsos disparos na prática.
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
