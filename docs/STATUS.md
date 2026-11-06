# Status

**Atualizado em:** 2026-11-06 · **Estável:** v0.7.2 · **Em teste:** v0.7.3 (botão de lente 1× ↔ 2×, só correção) · **Etapa:** 7 (Onda 7 aprovada; v0.7.3 entregue). Etapas 0 a 6 fechadas. Histórico completo em `docs/HISTORICO.md`.

## Próximo passo (retomar aqui)

00. **v0.7.2 aprovada pelo Kenidy em 06/11, 14:43 (vira a estável).** **v0.7.3 entregue (só correção do botão de lente):** `setLens` passou a `@MainActor` (um toque por vez, na principal) e registra `lente: toque X → Y` (ou `ignorado`) no Diagnóstico. Testar: alternar 1× ↔ 2× bem rápido por uns 20 s; o destaque deve acompanhar o último toque e o zoom deve bater; sem `tela: TRAVADA`. Se ainda errar, o log novo mostra a ordem dos toques. **Pedido do Kenidy (14:43), ainda sem versão:** na tela escura mostrar a qualidade junto da pré-gravação (versão própria, só visual, baixa luminosidade); aguardando o OK dele sobre quando entra. Depois: lentes fluidas (v0.7.4).

0. **v0.7.2 (06/11, entregue; só correção):** o Diagnóstico da v0.7.0 (14:03) mostrou `tela: TRAVADA` por 28 s e `SEM QUADROS`, sem troca de lente: a linha principal presa no `tick` publicando `bufferSec` (`ObservableObjectPublisher.send`), com o SwiftUI calculando layout (`_SafeAreaRegionsIgnoringLayout.sizeThatFits`) em outra linha. Mesmo impasse da v0.6.17–v0.6.25, outro aviso. A v0.7.1 (não testada) tinha o mesmo risco. **Correção:** `bufferSec` e `recordSec` deixam de ser `@Published`; a pílula e a tela escura leem com `LiveTick` (`TimelineView` a 4 por segundo). Visual e câmera iguais à v0.7.1. **Numeração:** o 4º número (0.7.1.1) não vale no iOS, então a correção ficou v0.7.2 e **as demais versões da Onda 7 andaram uma casa** (lentes fluidas v0.7.3, trocar de lente gravando v0.7.4, flash v0.7.5, valor real v0.7.6, EV v0.7.7 no ramo `onda7-ev`). Passou quando: sem `tela: TRAVADA`/`pilha:`/`SEM QUADROS`, `vida:` a cada 30 s, pílula e contador do gravar andando; teste: abrir a câmera e tocar no 2× logo depois de abrir, várias vezes (o app não tem gesto de pinch; o `lente: aproximação` do log vem do botão). Só depois do "passou" e do "pode seguir" vem a v0.7.3.

1. **v0.6.28 aprovada pelo Kenidy em 06/11, 11:06 (vira a estável; inclui a v0.6.27, que passou no log).** Fica sem confirmação o clipe da frontal com a chave "Espelhar a câmera frontal" DESLIGADA (no log da v0.6.28 nenhum clipe da frontal foi gravado com ela desligada; a prévia da tela é sempre espelhada pelo iOS). Se o Kenidy notar que a chave não muda o arquivo, tratar como defeito.
2. **Onda 7 aprovada pelo Kenidy (06/11, 11:16)** (`docs/ROADMAP.md`). A v0.7.0 (faixa do topo) funcionou mas poluiu a tela; o Kenidy pediu redesenho. **Desenho aprovado em 06/11 (12:21)** e implementado na **v0.7.1 (em teste)**: pílula discreta de largura fixa ("1080 60 | 12/30 s"; gravando, vermelha: "● 0:07 | 1080 60"), microfone entre o voltar e a pílula, flash entre a pílula e os ajustes, ajustes com o ícone do web app (duas barras com pontos), todos sem círculo; embaixo, miniatura, obturador (centro exato) e, à direita, a lua entre o obturador e o virar câmera (estes dois mantêm o círculo). Sem anel em volta do obturador. O flash é só desenho (bolt riscado, sem função; some na frontal). **Nenhuma mudança de câmera, voz ou áudio.** Quando o Kenidy testar: conferir o Diagnóstico (sem `tela: TRAVADA`/`SEM QUADROS`) e dar o "passou" ou o ajuste fino (tamanho, sombra, posição). Só depois do "pode seguir" começa a v0.7.2 (lentes fluidas paradas).
3. Miniatura escura no Fotos: **adiada pelo Kenidy (06/11)**; ver "Pendências abertas".
4. Antes de cada versão nova: esperar o "pode seguir" dele.

## Versão estável (para voltar se uma nova quebrar)

- **Estável: v0.7.2** (aprovada pelo Kenidy em 06/11, 14:43: sem travamento da tela em dezenas de trocas de lente e de câmera; topo novo aprovado; log sem TRAVADA, pilha nem SEM QUADROS): https://github.com/Kenidy-WS/Ei-Clip-ios/releases/download/v0.7.2/EiClip.ipa
- Estável anterior: v0.6.28 (aprovada pelo Kenidy em 06/11, 11:06: frontal em pé e espelhada, chave em Ajustes > Câmera; log sem TRAVADA, SEM QUADROS nem erro do codificador): https://github.com/Kenidy-WS/Ei-Clip-ios/releases/download/v0.6.28/EiClip.ipa
- Mais antiga estável: v0.6.26 (aprovada em 05/11, 23:57: 34 aberturas da câmera em 4 min; a frontal ainda saía de cabeça para baixo): https://github.com/Kenidy-WS/Ei-Clip-ios/releases/download/v0.6.26/EiClip.ipa
- Mais antigas: v0.6.17 (travava a tela no iOS 27.0.1): https://github.com/Kenidy-WS/Ei-Clip-ios/releases/download/v0.6.17/EiClip.ipa · v0.5.8: https://github.com/Kenidy-WS/Ei-Clip-ios/releases/download/v0.5.8/EiClip.ipa · v0.4.17: https://github.com/Kenidy-WS/Ei-Clip-ios/releases/download/v0.4.17/EiClip.ipa
- Instalar sempre com o **mesmo Apple ID** no Sideloadly.
- Regra: uma versão só vira "estável" depois de testada no aparelho e com o OK do Kenidy; este bloco é atualizado nesse momento.

## Em teste

- **v0.6.26 aprovada pelo Kenidy e marcada como estável** (ver "Versão estável"). Causa do travamento: o aviso `isReconfiguring` publicado para a tela a cada troca de lente, em impasse com a atualização de layout do SwiftUI no iOS 27.0.1.
- **v0.6.27 (só Diagnóstico, nada muda no app):** a linha `vida:` do vigia sai a cada 30 s em vez de 10 s (o Registro enche menos). As fotografias de pilha já só saem quando a tela trava ou os quadros param (no máximo 8 por rodada); o vigia continua ligado igual.
- **v0.7.3 (06/11):** correção do botão de lente (ver "Próximo passo" item 00).
- **v0.7.2 (06/11, agora estável):** correção do travamento (ver "Próximo passo" item 0).
- **v0.7.1 (06/11):** topo novo (só visual), ver "Próximo passo" item 2. A v0.7.0 não foi marcada estável (foi substituída).
- **v0.6.28 (06/11):** a frontal salvava de cabeça para baixo (regra "+180°" da v0.6.9 era hipótese errada). Agora a frontal usa o giro da traseira e sai espelhada (padrão), com a chave "Espelhar a câmera frontal" em Ajustes > Câmera. Detalhes em `docs/HISTORICO.md`. Frontal deitada ainda não medida.

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

- **v0.7.2, resultado do teste (06/11, 14:38):** o log passou no critério do travamento (0 `tela: TRAVADA`, 0 `pilha:`, 0 `SEM QUADROS`; `vida:` a cada 30 s; 15 aberturas; ~14 toques 1×↔2× seguidos; 60,2 quadros/s; 0 erros do codificador; clipe de 6,2 s a 35,4 Mbps salvo no Rolo). O Kenidy disse que funcionou; **falta o OK explícito para marcar estável** e o veredito visual do topo.
- **Defeito do botão de lente 1× ↔ 2× (Kenidy, 06/11):** tocando rápido e alternando, o app parece trocar para a outra lente e o destaque da lente atrasa; some depois de uma pausa ou de trocar de lente/câmera de verdade. **Hipótese (pela leitura do código; corrigida na v0.7.3, a confirmar no teste):** `setLens` é `async` e não é `@MainActor`; chamada de `Task { await engine.setLens(item) }`, roda fora da linha principal. Toques rápidos podem rodar em paralelo, com leitura de `old` e gravação de `chosenConfig.lens` separadas por trava, e `lens` (um `@Published`) é atribuído fora da principal. O zoom (`applyZoom` na `sessionQueue`) e o destaque podem terminar fora de ordem. Corrigir: serializar o toque na principal e publicar `lens` só lá. Decidir com o Kenidy se vai numa versão própria antes das lentes fluidas.
- **Erro de áudio ao abrir o player (14:38:04):** `player: áudio: ERRO ao ativar a sessão de reprodução (OSStatus 561017449)`, no mesmo instante da reabertura automática da câmera ao voltar ao app. 561017449 é o código '!pri' (prioridade insuficiente da sessão de áudio). Área protegida: versão própria, baixa prioridade; perguntar ao Kenidy se o clipe tocou com som.

- **Miniatura escura no Fotos (adiada pelo Kenidy, 06/11):** clipes gravados logo depois de abrir a câmera têm a miniatura escura no app Fotos (a do app está certa). Hipótese não confirmada: o clipe começa nos primeiros quadros após abrir a câmera, com a exposição ainda ajustando, e o Fotos escolhe a miniatura sozinho (o app não consegue definir o quadro). O web app não tinha o problema (miniatura vinha do último quadro ao vivo, guardada dentro do app). Ideias: (1) versão só de Diagnóstico medindo o brilho em 0, 0,5, 1 e 2 s de cada clipe; (2) descartar os primeiros quadros só quando a pré-gravação for curta (corte em keyframe, ~1 s, sobrando pelo menos 1 s); (3) esperar `isAdjustingExposure`. Perguntas sem resposta: o começo do vídeo também fica escuro ao reproduzir? Sai normal com a câmera aberta há 40 s ou mais?
- **Faixa do topo com o valor REAL (Kenidy, 06/11, importante; v0.7.5):** hoje a pílula mostra a escolha; deve mostrar o que o aparelho entrega (fps que o formato aceitou, redução por calor). Fazer depois, quando as lentes/formatos forem refeitos (v0.7.5), sem publicar estado durante a reconfiguração (por exemplo, publicar só depois que a reconfiguração terminar, ou ler em cada render o que já existe).
- Pós-teste da v0.7.1: ver se os ícones sem círculo leem bem sobre cena clara (se não, reforçar a sombra); se a pílula com "12/30 s" informa demais ou de menos.
- Texto da chave "Espelhar a câmera frontal": avisar que a prévia da tela continua espelhada (só o arquivo muda).
- 4K 30 ainda lento nos primeiros usos (medir antes: travamentos da tela no Diagnóstico); 4K 60 bloqueado até isso (fora da Onda 7).
- Limites de redução por calor: esperar Diagnóstico de dia quente (fora da Onda 7).
- Pré-gravação 60 s no 4K 30: marcada 60 s, janela real 30 s, com nota nos Ajustes (decisão do Kenidy).
- Pequenos: migrar "Falha na sessão de áudio." para `Textos.swift` (área protegida, versão própria); registrar no log comandos de voz barrados pela regra de 3 s.
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
