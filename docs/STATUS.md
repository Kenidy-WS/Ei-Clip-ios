# Status

**Atualizado em:** 2026-11-07 11:20 · **Estável:** v0.7.26 (aprovada por ele em 07/11, 11:54) · **Em teste:** v0.7.27, v0.7.28, v0.8.0, v0.8.1, v0.8.2 e v0.8.3 · **Etapa:** 7 (Onda 7). Etapas 0 a 6 fechadas. Histórico versão por versão em `docs/HISTORICO.md`.

## Próximo passo (retomar aqui)

**Onda 8 (Polimento) aberta em 07/11, 12:00:** ver `docs/ROADMAP.md`. o plano está organizado em blocos A a D no ROADMAP; falta o OK dele na ordem. Próximo: Ajustes organizado (primeira tela sem rolar) depois do teste do calor.

0. **Em teste: v0.8.3** (07/11, Onda 8, item 3, correção): parar um clipe 4K não espera mais o esvaziamento do codificador (que só volta quando a câmera para: 6189 ms no log da v0.8.2, 8 ms em 1080p60); espera só o quadro do instante do toque (~0,1 s, limite 0,5 s) e, se não chegar, usa o esvaziamento de antes (reserva). Linha nova: `codificador: esvaziar: quadro final entregue em N ms`. Testar: 3 clipes em 4K 30 e 1 em 1080p 60; o clipe deve chegar às Fotos em ~1 s depois de parar; conferir o fim do clipe (sem corte visível) e áudio e vídeo juntos.
0h. **Em teste: v0.8.2** (07/11, Onda 8, item 3, SÓ DIAGNÓSTICO, sem mudar a gravação): mede o esvaziamento do codificador ao parar um clipe 4K. Linhas novas `codificador: esvaziar: …` (pedido, aos 3 s se ainda esperando, e quando o pedido volta de verdade, com enviados/entregues e último quadro). Teste: gravar 4 a 5 clipes em 4K 30 (e 1 em 1080p 60 para comparar), colar o Diagnóstico.
0f. **Em teste: v0.8.1** (só textos, pedido dele em 07/11 12:38): chave de calor "Desligado: só avisa. Ligado: reduz a qualidade automaticamente."; espelhar frontal "Grava a frontal espelhada, como na prévia."
0g. **Em teste: v0.8.0** (07/11, Onda 8, item 2): Ajustes com 3 tópicos na primeira tela, sem rolar: **Voz e sons** (voz, palavra, sons de gravação e no vídeo), **Câmera** (Nível, Estabilização, Espelhar) e **Aparelho** (Reduzir qualidade com calor, Espaço livre, Diagnóstico). Saiu a linha "Gravação longa: sempre ligada" (só informava). A chave de calor ganhou o nome "Reduzir qualidade com calor" e a legenda "Desligado: só avisa. Ligado: reduz sozinho." Folha com 580 pt. Testar: a primeira tela não precisa rolar (também com 4K escolhido); cada tópico abre e volta; o Diagnóstico abre por Aparelho.
0e. **v0.7.28** (07/11): Onda 8 aberta (ver `docs/ROADMAP.md`). Ajustes > Câmera > "Reduzir com calor", desligado por padrão: o "quente" só avisa; ligado, reduz sozinho; no "crítico" reduz sempre. Testar: com o aparelho quente, ver o aviso sem queda de qualidade; ligar a chave e ver a redução.
0d. **Em teste: v0.7.27** (07/11): corrige a contagem de clipes da Galeria, que começava em 0; a 1ª exclusão depois de abrir agora também volta ao topo.
0c. **v0.7.26 aprovada (estável; apagar tudo mostra "Nenhum clipe ainda."):** Galeria volta ao topo sozinha quando a lista encolhe (apagou muitos clipes estando no fim; antes ficava numa área em branco). Testar: encher a Galeria, ir ao fim, selecionar quase tudo e apagar.
0b. **v0.7.25 aprovada (estável):** Galeria, com a seleção ativa, deslizar na horizontal por cima dos clipes marca todos (sem segurar de novo); na vertical continua rolando; segurar e arrastar segue valendo. Funciona também logo depois de tocar em "Selecionar".
0a. **v0.7.24 aprovada (estável):** reabre direto na câmera (250 ms, sem Início; só uma piscada) e Ajustes compacto, aprovados no aparelho. Detalhes: (a) ao voltar do segundo plano o app mantém a tela da câmera (preta por instantes) e reabre por baixo, sem passar pelo Início; se a reabertura falhar, vai ao Início com o aviso; o botão Voltar segue indo ao Início. (b) Ajustes: folha de 560 pt (antes 700; pode ser puxada para cima), mais respiro, textos mais curtos, subtítulos quebram em várias linhas, resumo de Câmera conta Nível, Estabilização e Espelho (antes mostrava "Desligados" com o espelho ligado). Testar: minimizar e voltar várias vezes; abrir cada página dos Ajustes no iPhone15,4.
1. (antes da v0.7.24) A v0.7.23 foi aprovada por ele em 07/11 (11:04) e virou a estável; o `main` agora tem as versões v0.7.16 a v0.7.23. Falta decidir com ele a próxima versão (v0.7.24).
2. **Keyframe (v0.7.23): confirmado no aparelho.** No log de 11:02:52: `pedido aceito; aguardando o primeiro keyframe` e `a gravação começou 212 ms depois do pedido` (pedido logo depois de parar um clipe). Pedido a 0,7 s depois de abrir a câmera já tinha keyframe e começou na hora.
3. **Minimizar e voltar rápido: não reproduzido.** Em 07/11 (11:03) ele fez cerca de 8 ciclos seguidos; todos reabriram a câmera sem erro (200 a 283 ms). Ele diz que às vezes vê o Início por um instante antes da câmera (comportamento normal da reabertura automática). A falha de "Não foi possível abrir a câmera" visto antes não apareceu mais; se voltar, pedir "Copiar rodada anterior". Hipótese guardada: reabrir enquanto o fechamento do segundo plano ainda desmonta a sessão.
4. **Voz:** o gatilho "Câmera, ação" confundiu o teste. Ideia (só se ele pedir): mostrar a palavra ativa na tela da câmera.
5. **Decisões dele:** redução de qualidade por calor **automática**, com aviso claro; seletor de EV com botão no topo **descartado**.

**Resumo do que entrou depois da v0.7.15 (detalhes no `docs/HISTORICO.md`):**
- v0.7.16/17 EV: sol colado ao quadrado de foco novo, faixa ±2, zera ao tocar em outro ponto, ao trocar de lente e ao reabrir (**estável, v0.7.17**).
- v0.7.18 avisos no topo com 3 pesos; Diagnósticos de voz e bateria. v0.7.19 EV com peso (dedo 75 pt por EV, sol 30 pt), aviso de bateria sem número, tempo do aviso pelo texto, arrastar para cima fecha. v0.7.20 avisos curtos e frontal deitada com giro invertido (aprovada). v0.7.21 bateria por degrau e textos de áudio e permissões. v0.7.22 bateria em 20/10/5%, avisos translúcidos, calor sem números, seta nas permissões. v0.7.23 início espera o primeiro keyframe e avisos mais discretos.
- **Medidas confirmadas no aparelho:** o iOS entrega a bateria de 5 em 5; a frontal deitada pede +180° em relação à traseira.

## Versão estável (para voltar se uma nova quebrar)

- **Estável: v0.7.26** (aprovada pelo Kenidy em 07/11, ~11:54: Galeria volta ao topo quando a lista encolhe): https://github.com/Kenidy-WS/Ei-Clip-ios/releases/download/v0.7.26/EiClip-v0.7.26.ipa
- Estável anterior: **v0.7.25** (aprovada pelo Kenidy em 07/11, ~11:46: deslizar na horizontal marca clipes na Galeria): https://github.com/Kenidy-WS/Ei-Clip-ios/releases/download/v0.7.25/EiClip-v0.7.25.ipa
- Estável anterior: **v0.7.24** (aprovada pelo Kenidy em 07/11, ~11:39: reabre direto na câmera e Ajustes compacto): https://github.com/Kenidy-WS/Ei-Clip-ios/releases/download/v0.7.24/EiClip-v0.7.24.ipa
- Estável anterior: **v0.7.23** (aprovada pelo Kenidy em 07/11, ~11:04: tudo das v0.7.18 a v0.7.23; keyframe confirmado no aparelho): https://github.com/Kenidy-WS/Ei-Clip-ios/releases/download/v0.7.23/EiClip-v0.7.23.ipa
- Estável anterior: **v0.7.17** (aprovada pelo Kenidy em 07/11, ~00:43: EV, o sol de compensação de exposição junto do quadrado de foco; já unida ao `main`): https://github.com/Kenidy-WS/Ei-Clip-ios/releases/download/v0.7.17/EiClip-v0.7.17.ipa
- Estável anterior: **v0.7.15** (aprovada pelo Kenidy em 06/11, ~23:04: botão Abrir câmera sem sombra do texto; qualidade real na tela escura, parada e gravando): https://github.com/Kenidy-WS/Ei-Clip-ios/releases/download/v0.7.15/EiClip-v0.7.15.ipa
- Estável anterior: **v0.7.14** (aprovada pelo Kenidy em 06/11, ~22:58: pílula do topo com o valor real; a redução automática por calor não foi testada, depende de um dia quente): https://github.com/Kenidy-WS/Ei-Clip-ios/releases/download/v0.7.14/EiClip-v0.7.14.ipa
- Antes: **v0.7.13** (aprovada pelo Kenidy em 06/11, ~22:48: flash/lanterna da traseira, abre sempre apagada, funciona gravando e em 4K): https://github.com/Kenidy-WS/Ei-Clip-ios/releases/download/v0.7.13/EiClip-v0.7.13.ipa
- Antes: **v0.7.12** (aprovada pelo Kenidy em 06/11, ~22:36: troca de lente durante a gravação, também em 4K, clipe inteiro e contínuo): https://github.com/Kenidy-WS/Ei-Clip-ios/releases/download/v0.7.12/EiClip-v0.7.12.ipa
- Antes ainda: **v0.7.11** (aprovada pelo Kenidy em 06/11, ~22:14: igual à v0.7.9 mais registro da trilha do zoom e da lente ativa; repique 0,5× → 1× não se repetiu): https://github.com/Kenidy-WS/Ei-Clip-ios/releases/download/v0.7.11/EiClip-v0.7.11.ipa
- Antes: **v0.7.9** (aprovada pelo Kenidy em 06/11, ~21:45: câmera combinada, lentes sem reabrir a câmera; ficou só um pequeno repique na volta de 0,5× para 1×, tratado na v0.7.10): https://github.com/Kenidy-WS/Ei-Clip-ios/releases/download/v0.7.9/EiClip-v0.7.9.ipa
- Antes: **v0.7.8** (aprovada pelo Kenidy em 06/11, ~21:35: tela escura com a qualidade junto da pré-gravação; IPA a partir daqui com o nome versionado): https://github.com/Kenidy-WS/Ei-Clip-ios/releases/download/v0.7.8/EiClip-v0.7.8.ipa
- Antes: **v0.7.7** (aprovada pelo Kenidy em 06/11, ~21:20: microfone recusado avisado na mesma abertura, aviso rápido ao gravar sem som, ícone do microfone cortado, ícone de ajustes igual nas duas telas; inclui as permissões sem cronômetro da v0.7.6): https://github.com/Kenidy-WS/Ei-Clip-ios/releases/download/v0.7.7/EiClip.ipa
- Antes: **v0.7.4** (aprovada pelo Kenidy em 06/11, ~17:33: instalação do zero no iPhone dele com câmera, microfone, fala e Fotos pedidos em sequência; câmera abre sem esperar as Fotos): https://github.com/Kenidy-WS/Ei-Clip-ios/releases/download/v0.7.4/EiClip.ipa
- Antes: v0.7.3 (aprovada pelo Kenidy em 06/11, 16:34: toques rápidos 1× ↔ 2× com o destaque acompanhando, também gravando; ~10 trocas de frontal/traseira; log sem TRAVADA, pilha nem SEM QUADROS): https://github.com/Kenidy-WS/Ei-Clip-ios/releases/download/v0.7.3/EiClip.ipa
- Antes: v0.7.2 (aprovada pelo Kenidy em 06/11, 14:43: sem travamento da tela em dezenas de trocas de lente e de câmera; topo novo aprovado; log sem TRAVADA, pilha nem SEM QUADROS): https://github.com/Kenidy-WS/Ei-Clip-ios/releases/download/v0.7.2/EiClip.ipa
- Mais antiga: v0.6.28 (aprovada pelo Kenidy em 06/11, 11:06: frontal em pé e espelhada, chave em Ajustes > Câmera; log sem TRAVADA, SEM QUADROS nem erro do codificador): https://github.com/Kenidy-WS/Ei-Clip-ios/releases/download/v0.6.28/EiClip.ipa
- Antes: v0.6.26 (aprovada em 05/11, 23:57: 34 aberturas da câmera em 4 min; a frontal ainda saía de cabeça para baixo): https://github.com/Kenidy-WS/Ei-Clip-ios/releases/download/v0.6.26/EiClip.ipa
- Mais antigas: v0.6.17 (travava a tela no iOS 27.0.1): https://github.com/Kenidy-WS/Ei-Clip-ios/releases/download/v0.6.17/EiClip.ipa · v0.5.8: https://github.com/Kenidy-WS/Ei-Clip-ios/releases/download/v0.5.8/EiClip.ipa · v0.4.17: https://github.com/Kenidy-WS/Ei-Clip-ios/releases/download/v0.4.17/EiClip.ipa
- **Nome do IPA (a partir da v0.7.8):** `EiClip-vX.Y.Z.ipa`, link `https://github.com/Kenidy-WS/Ei-Clip-ios/releases/download/vX.Y.Z/EiClip-vX.Y.Z.ipa`. As versões anteriores seguem com o nome `EiClip.ipa` (links acima valem).
- Instalar sempre com o **mesmo Apple ID** no Sideloadly.
- Regra: uma versão só vira "estável" depois de testada no aparelho e com o OK do Kenidy; este bloco é atualizado nesse momento.

## Lição do travamento da tela (v0.6.17 a v0.6.26, resolvido)

- **Sintoma:** a tela do app congelava (câmera seguia rodando) e os quadros paravam 5 a 25 s depois; só fechando o app. Acontecia sobretudo logo depois de trocar de lente ou de câmera, em todas as versões a partir da v0.6.17, também depois de reiniciar o iPhone.
- **Causa (iOS 27.0.1, SwiftUI):** a linha principal ficava presa em `ObservableObjectPublisher.send()` publicando `isReconfiguring = true` (a cada troca de lente), enquanto o SwiftUI atualizava a tela numa linha fora da principal e esperava a principal. Impasse dentro do SwiftUI. O fim da v0.6.26 tirou esse aviso da tela e acabou o travamento.
- **Hipóteses descartadas pelo caminho:** nível, frontal, versão do app, iPhone em mau estado, leitura de espaço livre, quantidade de publicações (v0.6.23), tamanho da prévia (v0.6.25).
- **Regra que fica (vale para toda versão nova de tela):** não publicar (`@Published`) estado novo enquanto a câmera é reconfigurada, e não mudar `.disabled`/`.opacity` de vários botões de uma vez nesse momento. Estado novo da tela só em resposta a toque, ou lendo o que já existe (`chosen`, `lens`, `bufferSec`).
- **Ferramentas de diagnóstico que ficam:** vigia da tela (`MainThreadWatch`, linhas `tela:` e `câmera:`), `MainMark`/`mainAsync` (nomeiam a atualização de tela que estava rodando), fotografia das linhas de execução (`ThreadSampler`, linhas `pilha:`, só quando há travamento, no máximo 8 por rodada).

## Testes anotados para o Kenidy fazer quando puder (05/11)

1. Teste A3 da rodada da v0.6.16: falhou, sem detalhe do que era; dizer o que acontece se repetir.
2. Clipe longo (5 min ou mais): partes de 5 s, arquivo final e recuperação se o app fechar gravando.
3. Avisos de pouco espaço e de bateria baixa.
4. Estabilização em movimento (o enquadramento muda um pouco, esperado).
5. Voz: religamento do reconhecedor após 30 min ou mais em Comando.
6. Calor em dia quente (4K Máxima esquenta um pouco): trazer o Diagnóstico com "Redução por calor".

## Pendências abertas

- **Achados do teste da v0.7.14 (06/11):** (1) tela inicial: ao tocar em "Abrir câmera" o texto "Abrindo…" aparece sobreposto ao anterior (transição de texto); (2) tela escura: durante a gravação não mostra a qualidade, e parada ainda usa o valor escolhido (não o real).

- **Parar no 4K demora ~3 s para salvar (v0.7.12/v0.7.13):** a descarga do codificador ao parar atinge o limite de 3 s em todos os clipes 4K30 (`quadros pendentes entregues em 3002 ms (passou de 3 s; seguindo sem esperar)`), mesmo sem quadros pendentes na hora de finalizar; no 1080p60 leva 0–6 ms. Nada se perde (clipes completos), mas o clipe só chega às Fotos ~3 s depois. Investigar numa versão própria se o limite é espera inútil ou o codificador realmente demora (medir quadros pendentes ao longo dos 3 s).
- **Voz logo depois de parar (resolvida na v0.7.23, a confirmar):** o pedido agora espera o primeiro keyframe em vez de ser recusado.

- **Repique da troca de lente e o foco (hipótese do Kenidy, 06/11, 22:16; a confirmar):** com cena simples o repique não aparece (v0.7.11); com mais objetos (notebook perto, armário ao fundo) aparece na subida a partir da 0,5× e some depois de tocar para focar. O log da v0.7.11 mostra o ZOOM limpo em todas as trocas (monotônico, ~0,35 s) e a lente ativa mudando em ~1,45 (subindo) e ~2,00 (descendo), então o salto está na imagem (foco/exposição reajustando no sensor novo), não no zoom. O log atual não registra o estado do foco; só um toque de foco (22:15:11) e a troca seguinte saiu normal. Atualização v0.7.12: a trilha já marca F/E; F apareceu uma vez numa troca 0,5× → 1× (ver item da v0.7.12). Ideia de correção a testar numa versão própria (não feita): ligar o foco automático suave para vídeo (`isSmoothAutoFocusSupported`/`isSmoothAutoFocusEnabled`, com checagem de capacidade, reserva e registro no Diagnóstico), que reduz a caça de foco na gravação; custo: o foco fica um pouco mais lento (avaliar para ação). Outra: fixar o ponto de foco no centro ao trocar de lente, sem sobrescrever um foco tocado. Antes (v0.7.12 já faz): acrescentar à trilha do zoom o estado de foco/exposição (`isAdjustingFocus`/`isAdjustingExposure`, letras F/E) ANTES de mexer em qualquer comportamento; se confirmar, testar fixar o ponto de foco no centro ao trocar de lente (sem sobrescrever um foco tocado pelo usuário).

- **v0.7.2, resultado do teste (06/11, 14:38):** o log passou no critério do travamento (0 `tela: TRAVADA`, 0 `pilha:`, 0 `SEM QUADROS`; `vida:` a cada 30 s; 15 aberturas; ~14 toques 1×↔2× seguidos; 60,2 quadros/s; 0 erros do codificador; clipe de 6,2 s a 35,4 Mbps salvo no Rolo). O Kenidy disse que funcionou; **falta o OK explícito para marcar estável** e o veredito visual do topo.
- **Defeito do botão de lente 1× ↔ 2× (Kenidy, 06/11):** tocando rápido e alternando, o app parece trocar para a outra lente e o destaque da lente atrasa; some depois de uma pausa ou de trocar de lente/câmera de verdade. **Hipótese (pela leitura do código; corrigida na v0.7.3, a confirmar no teste):** `setLens` é `async` e não é `@MainActor`; chamada de `Task { await engine.setLens(item) }`, roda fora da linha principal. Toques rápidos podem rodar em paralelo, com leitura de `old` e gravação de `chosenConfig.lens` separadas por trava, e `lens` (um `@Published`) é atribuído fora da principal. O zoom (`applyZoom` na `sessionQueue`) e o destaque podem terminar fora de ordem. Corrigir: serializar o toque na principal e publicar `lens` só lá. Decidir com o Kenidy se vai numa versão própria antes das lentes fluidas.
- **Erro de áudio ao abrir o player (14:38:04):** `player: áudio: ERRO ao ativar a sessão de reprodução (OSStatus 561017449)`, no mesmo instante da reabertura automática da câmera ao voltar ao app. 561017449 é o código '!pri' (prioridade insuficiente da sessão de áudio). Área protegida: versão própria, baixa prioridade; O Kenidy lembra que o clipe tocou com som (06/11). Na v0.7.3 não repetiu: com a câmera fechada antes do player, a sessão de reprodução ativou sem erro.

- **Miniatura escura no Fotos (adiada pelo Kenidy, 06/11):** clipes gravados logo depois de abrir a câmera têm a miniatura escura no app Fotos (a do app está certa). Hipótese não confirmada: o clipe começa nos primeiros quadros após abrir a câmera, com a exposição ainda ajustando, e o Fotos escolhe a miniatura sozinho (o app não consegue definir o quadro). O web app não tinha o problema (miniatura vinha do último quadro ao vivo, guardada dentro do app). Ideias: (1) versão só de Diagnóstico medindo o brilho em 0, 0,5, 1 e 2 s de cada clipe; (2) descartar os primeiros quadros só quando a pré-gravação for curta (corte em keyframe, ~1 s, sobrando pelo menos 1 s); (3) esperar `isAdjustingExposure`. Perguntas sem resposta: o começo do vídeo também fica escuro ao reproduzir? Sai normal com a câmera aberta há 40 s ou mais?
- **Faixa do topo com o valor REAL (Kenidy, 06/11, importante; agora v0.7.12):** hoje a pílula mostra a escolha; deve mostrar o que o aparelho entrega (fps que o formato aceitou, redução por calor). Fazer depois, quando as lentes/formatos forem refeitos (lentes, agora v0.7.9), sem publicar estado durante a reconfiguração (por exemplo, publicar só depois que a reconfiguração terminar, ou ler em cada render o que já existe).
- Pós-teste da v0.7.1: ver se os ícones sem círculo leem bem sobre cena clara (se não, reforçar a sombra); se a pílula com "12/30 s" informa demais ou de menos.
- Texto da chave "Espelhar a câmera frontal": avisar que a prévia da tela continua espelhada (só o arquivo muda).
- 4K 30 ainda lento nos primeiros usos (medir antes: travamentos da tela no Diagnóstico); 4K 60 bloqueado até isso (fora da Onda 7).
- Limites de redução por calor: esperar Diagnóstico de dia quente (fora da Onda 7).
- Pré-gravação 60 s no 4K 30: marcada 60 s, janela real 30 s, com nota nos Ajustes (decisão do Kenidy).
- Pequeno: registrar no log comandos de voz barrados pela regra de 3 s. (O texto de "Falha na sessão de áudio" já foi para `Textos.swift` na v0.7.21.)
- Teste longo da voz (≥ 30 min em Comando, religar do reconhecedor): o Kenidy adiou; fazer quando ele pedir.

## Notas operacionais

- O repositório mudou de endereço no GitHub (`Kenidy-WS/Ei-Clip-ios`); o antigo redireciona e o push funciona. Para a API, `Kenidy-WS/ei-clip-ios` ainda responde.
- Sem toolchain Swift no ambiente: só o CI valida compilação e testes. Commits só de docs levam `[skip ci]`.
- `gh release view` falha (GraphQL 403): usar `gh api repos/Kenidy-WS/ei-clip-ios/releases/tags/vX.Y.Z`.
- Web app de referência (somente leitura): https://github.com/Kenidy-WS/clip (clonar raso para ler `src/core/` e `tests/`).
- O Diagnóstico agora é gravado em `Application Support/Diagnostico/atual.txt` (e a rodada anterior em `anterior.txt`); "Limpar" zera a tela e o arquivo da rodada atual.

## Decisões

- **Textos do usuário:** tom formal e claro; TODO texto novo entra em `Engine/Textos.swift` (revisão geral feita na v0.3.12). O Diagnóstico segue técnico.
- Bundle ID: `br.com.wpstecnologia.eiclip` (definitivo).
- Salvar sempre no álbum "Ei Clip" do Rolo. A galeria própria deixou de ser "não" e virou a etapa 4 (decisão do Kenidy em 05/11): ela lista só os clipes desse álbum (PhotoKit), sem copiar arquivos.
- Sem toolchain Swift no ambiente de desenvolvimento: lógica pura testada no CI macOS (`swift test` em `Core/`, o IPA só sai se passar).
- **Áudio do anel em PCM, não AAC:** cabe fácil na memória (~6 MB em 30 s) e o próprio arquivo codifica o AAC na gravação (sem trabalho de empacotar AAC à mão). Diverge do texto do plano ("H.264/AAC já codificados"); o vídeo continua codificado.
- 1080p30 fixo na etapa 1 (60 fps só na etapa 4); taxa/resolução vêm de `Core/VideoProfile.swift`.
- Reabrir a câmera sozinha ao voltar ao app é o comportamento desejado (hoje só o botão); entra depois de resolver o defeito de gravação.

## Onde está o resto

- `docs/ROADMAP.md`: etapas, critérios e a **proposta da Onda 7**.
- `docs/HISTORICO.md`: tudo que já foi feito e testado, versão por versão (antigo STATUS).
- `docs/ARCHITECTURE.md`: como o app é feito. `docs/MELHORIAS_FUTURAS.md`: ideias adiadas. `docs/AUDITORIA.md`: auditoria da etapa 4. `docs/RETOMADA.md`: texto para abrir um chat novo.
