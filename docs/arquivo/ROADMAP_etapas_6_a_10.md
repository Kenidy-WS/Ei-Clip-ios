# Roadmap: etapas 6 a 10 (arquivo, fechadas até 10/11/2026)

Movido do `docs/ROADMAP.md` em 19/11/2026. Só consulta.

## Etapa 6: escopo aprovado pelo Kenidy (05/11)

Fazer como na etapa 5: versões `v0.6.x`, uma mudança por versão, agrupadas; o Kenidy valida só a última e, se falhar, voltamos versão por versão. Área protegida (voz e sessão de áudio) fica fora, ou vai sozinha numa versão.

**Câmera (já previsto):** troca de lentes (ultra-angular), câmera frontal, estabilização, foco por toque, 4K30/1080p60, nível, gravação longa direta e recuperação se o app fechar gravando. A base é `CaptureConfig` (v0.5.7).

**Incluídos além do web app:**
1. **Pré-gravação de 60 s** (opções 15, 30 e 60). Atenção: mexe no anel de memória (`ReplayBuffer`, `BufferWindow`); medir memória e temperatura antes de aprovar.
2. **Galeria agrupada por dia** (Hoje, Ontem, datas), como no app Fotos.
3. **Aviso de pouco espaço:** antes de abrir a câmera e um alerta durante a gravação (a gravação pode falhar no meio de um peixe). Não existe no código hoje.
4. **Escurecer a tela mantendo a câmera ativa:** a tela fica ligada por horas (bateria e calor); modo que escurece e volta com um toque. O web não faz isso.
5. **Reação à temperatura:** avisar e, se preciso, reduzir a qualidade sozinho (4K, 60 fps, sol) antes de o iOS derrubar a câmera. A leitura da temperatura já existe no Diagnóstico.
6. **Aviso de bateria baixa** antes de a câmera acabar no meio da pescaria.

Ordem sugerida: grupo A (proteção em campo: espaço, bateria, temperatura, tela escura) → grupo B (Galeria por dia, pré-gravação de 60 s) → grupo C (lentes, frontal, 4K/60, estabilização, foco, nível) → grupo D (gravação longa e recuperação).

## Onda 7: escopo aprovado (06/11) e andamento até 07/11

Acabamento da tela da câmera, no estilo discreto da câmera nativa do iPhone (faixa no topo com flash e "4K 60"), mais três extras. Fazer como nas etapas 5 e 6: versões `v0.7.x`, **uma mudança por versão**, o Kenidy valida cada uma pelo Diagnóstico e, se falhar, voltamos versão por versão. O item "nível mais ágil" já foi feito (v0.6.18 e v0.6.19). Área protegida (voz e sessão de áudio) vai sozinha numa versão.

**Regra nova (aprendida no travamento da v0.6.17 a v0.6.25):** nenhuma informação nova da tela pode ser publicada (`@Published`) enquanto a câmera está sendo reconfigurada, e nada pode mudar `.disabled`/`.opacity` de vários botões de uma vez nesse momento. A faixa do topo, o flash e o anel usam o que já existe (`chosen`, `lens`, `bufferSec`) e só publicam em resposta a toque do usuário. Foi o que travou a tela no iOS 27.0.1.

**Incluídos (pedidos do Kenidy):**
1. **Faixa do topo (qualidade e fluidez):** texto discreto, como na câmera nativa, ex. "4K 30" ou "1080 60". Só leitura, vem de `chosen` e `lens`. É a base dos itens 2, 3 e 4.
2. **Flash (lanterna) ligar/desligar:** ícone na faixa do topo; só na traseira (`torchMode`; na frontal o ícone não aparece). Cuidados: apagar ao trocar para a frontal e voltar sozinho ou não ao reabrir (decidir abaixo); a lanterna esquenta e gasta bateria, então apaga também com bateria baixa ou calor alto (já existem as leituras).
3. **Reposicionar o botão da lua (tela escura):** sai do lugar atual e passa para o canto da faixa do topo. O comportamento da tela escura não muda.
4. **Mostrador da pré-gravação novo:** ficou resolvido na v0.7.1 pela própria pílula do topo ("12/30 s", sem anel em volta do obturador: o Kenidy preferiu só a pílula, mais limpa e precisa). No 4K 30 a janela real é 30 s (decisão já tomada): o texto mostra o real e os Ajustes continuam com a nota.

**Incluído em 06/11, 11:16 (pedido do Kenidy, aprovado o plano):**
9. **Lentes fluidas (como o app Câmera do iPhone):** hoje a 0,5× ↔ 1× fecha e reabre a câmera (dois aparelhos físicos; ~200 ms de corte, zera a pré-gravação, reinicia a voz e é bloqueada gravando). Só a 1× ↔ 2× é lisa (zoom). A ideia é usar a **câmera combinada do iPhone** (`builtInDualWideCamera`, ou a tripla nos Pro): 0,5×, 1× e 2× passam a ser **pontos de zoom** da mesma câmera (os fatores vêm do aparelho: `virtualDeviceSwitchOverVideoZoomFactors`, não ficam fixos no código). Efeitos esperados: sem corte, a pré-gravação não zera, a voz não reinicia, dá para trocar gravando e some um caminho que reabria a câmera (o que travou a tela). Em duas versões: v0.7.1 parada, v0.7.2 gravando (uma mudança por versão). Entra ANTES do flash e do EV porque muda o aparelho de câmera de que eles dependem.
   - **Riscos (só o aparelho confirma):** a lista de formatos da câmera combinada (1080p60, 4K30) pode diferir; tranco curto de foco/exposição no ponto de troca; estabilização e macro automático podem se comportar diferente (travar a troca automática de lente); calor e bateria.
   - **Passou quando:** o Diagnóstico bate com o da v0.6.28 (resolução entregue igual, ~59,9 quadros/s, ~35 Mbps, 0 descartados, 0 erros do codificador), 20 trocas seguidas sem travar a tela e sem corte visível; na v0.7.2, um clipe gravado trocando de lente sem salto de imagem nem de som e com o áudio em sincronia.

**Princípio de reserva e de vários aparelhos (Kenidy, 06/11):** o app vai rodar em iPhones diferentes e não dá para testar em todos. Regras: (1) decidir pela **capacidade** que o aparelho informa (formatos, fatores de zoom, tipos de câmera disponíveis), **nunca pelo nome do modelo**; (2) todo caminho novo deixa o **caminho atual como reserva**, usado se o aparelho não oferecer o que o novo precisa ou se a abertura falhar; (3) a reserva entra em ação sozinha e **registra no Diagnóstico** por quê (para eu ver em qual aparelho aconteceu); (4) cada versão nova só vira estável com o OK do Kenidy, e a estável anterior fica como volta.

**Isolado, sempre por último (decisão do Kenidy, 06/11):**
8. **EV (compensação de exposição):** controle de brilho (−2 a +2) em toque e arraste, como o ícone de sol da câmera nativa; ajuda com reflexo do sol na água e com contraluz. Entra **só depois de todo o resto da onda**, na versão **v0.7.16**, desenvolvido no **ramo `onda7-ev`** (fora do `main`). Se der problema, o ramo é descartado e o `main` fica intacto. Só entra no `main` com o OK do Kenidy depois de testado.

**Candidatas (adiadas, ver decisões abaixo):**
5. **Vibração ao começar e ao parar a gravação.** Atenção: com o microfone ativo o iOS corta a vibração, a menos que a sessão de áudio permita; isso mexe na sessão de áudio, então é **área protegida e vai sozinha numa versão**.
6. **Cortar o clipe (início e fim) no player,** salvando um clipe novo no álbum Ei Clip. Sem regravar o vídeo (corte direto), então é rápido.
7. **Atalhos do sistema** (botão de Ação, Siri, Atalhos) para abrir a câmera ou iniciar a gravação. **A verificar:** se a conta Apple gratuita permite; o botão de Ação exige iOS 17 ou mais novo (o app hoje aceita iOS 16). Testar antes de prometer.

**Fora desta onda (decisão do Kenidy):** 4K 60, 4K 30 mais fluido e limites de redução por calor.

**Ordem sugerida (cada linha é uma versão):**
- v0.7.0: faixa do topo só com qualidade e fluidez (item 1). Funcionou, mas deixou o topo poluído; foi substituída pela v0.7.1.
- v0.7.1: **topo redesenhado (só visual)**: pílula discreta "1080 60 | 12/30 s" (gravando: "● 0:07 | 1080 60"), microfone, flash (ícone riscado, sem função) e ajustes sem círculo, lua entre o obturador e o virar câmera. Desenho aprovado pelo Kenidy em 06/11 (itens 1, 3 e parte do 4: a pílula fica e o anel em volta do obturador foi **descartado**).
- v0.7.2: **correção do travamento da tela** (06/11; `bufferSec`/`recordSec` sem `@Published`, `LiveTick`). Inserida porque a v0.7.0 travou; as seguintes andaram uma casa.
- v0.7.3: **correção do botão de lente 1× ↔ 2×** (toques rápidos; `setLens` na principal).
- v0.7.4: **correção: a câmera não espera mais o pedido das Fotos** (06/11; num iPhone novo o pedido ficava sem resposta e a câmera nunca abria). Inserida; as seguintes andaram uma casa.
- v0.7.5: DESCARTADA (limite de 10 s nos pedidos de permissão: tratava pessoa lenta como "o iPhone não mostrou o aviso" e abria a câmera sem microfone).
- v0.7.6: **avisos de permissão sem cronômetro** para as 4 permissões: pedido sem prazo, aviso único com Abrir Ajustes antes de abrir a câmera, Fotos pedidas ao abrir e ao gravar, Início explica a falta de acesso (06/11; teste no iPhone do Kenidy e no do amigo, onde o iOS não mostrava o aviso das Fotos).
- v0.7.7: **avisos de microfone e de permissões na mesma abertura** (06/11, pedido do Kenidy): aviso único com Abrir Ajustes logo depois dos avisos do iOS quando algo foi negado ou ficou sem resposta NESTA abertura (fora da gravação); aviso rápido "Microfone desligado: este clipe ficará sem som." ao tocar em gravar; ícone do microfone cortado e apagado sem a permissão; ícone de ajustes do Início igual ao da câmera. Não toca em `VoiceProbe`.
- v0.7.8: **tela escura com a qualidade junto da pré-gravação** (pedido do Kenidy, 06/11; só visual, bem apagado).
- v0.7.9: **lentes fluidas, paradas** (item 9): 0,5×/1×/2× viram pontos de zoom da câmera combinada, sem reabrir a câmera (em teste, 06/11).
- v0.7.10: descartada (passar do ponto de troca piorou o repique).
- v0.7.11: **só Diagnóstico** da subida a partir da 0,5× (repique achado no teste da v0.7.9); o repique não se repetiu (aprovada, 06/11); a trilha fica no código para o caso de voltar.
- v0.7.12: **trocar de lente durante a gravação** (item 9, parte 2; aprovada, 06/11; a trilha do zoom ganha F/E do foco).
- v0.7.13: flash de verdade (item 2): lanterna, só traseira, sempre volta apagado; o ícone já está na tela desde a v0.7.1 (aprovada, 06/11).
- v0.7.15 (estável): botão Abrir câmera sem sombra do texto e qualidade real na tela escura.
- v0.7.14 (estável): faixa do topo com o valor REAL entregue (fps aceito pelo formato, redução por calor), junto de qualquer ajuste do mostrador.
- v0.7.16 e v0.7.17: EV (item 8), no ramo `onda7-ev`; a v0.7.17 virou a estável e foi unida ao `main` em 07/11.
- v0.7.18: avisos no topo com 3 pesos (informação, atenção, crítico) e Diagnósticos de voz e de bateria. v0.7.19: EV com peso e barra curta, bateria sem número, tempo do aviso pelo texto, arrastar para fechar. v0.7.20: avisos curtos e frontal deitada com +180°. v0.7.21: bateria por degrau e textos de áudio e permissões. v0.7.22: degraus 20/10/5%, avisos translúcidos, calor sem números. v0.7.23: início de gravação espera o primeiro keyframe (até 2,5 s). A v0.7.23 foi aprovada por ele em 07/11 (11:04) e é a estável; tudo já está no `main`.
- Descartado por ele (07/11): seletor de EV com botão no topo (o sol basta).
- Adiadas para o futuro (sem versão marcada): cortar clipe (6), vibração (5, área protegida) e atalhos do sistema (7).

**Passou quando (cada versão):** nenhuma linha `tela: TRAVADA` nem `SEM QUADROS` no Diagnóstico; 20 trocas de lente seguidas sem travar; o item novo funciona no aparelho (faixa legível ao sol, flash acende e apaga, lua alcançável com o polegar, anel enche e zera ao gravar).

**Decisões do Kenidy (06/11, 00:21):**
1. Itens 5 (vibração) e 6 (cortar clipe): **ficam para o futuro**, fora desta onda. O item 7 (atalhos do sistema) interessa, mas **também fica para depois**; não implementar agora.
2. Flash: **sempre volta apagado** ao reabrir a câmera.
3. Subir o iOS mínimo para 17: depende do item 7, que foi adiado; sem decisão por enquanto (o iPhone do Kenidy tem iOS 27, então não o afeta).
4. EV (compensação de brilho): **entra**, por último e isolado (v0.7.16 no ramo `onda7-ev`), cancelável se der problema.

**Escopo da Onda 7 agora:** topo novo (v0.7.1), lentes fluidas, flash e valor real (v0.7.2 a v0.7.11, com as correções das permissões inseridas como v0.7.4 e v0.7.6) no `main`, mais o EV (v0.7.16) isolado no ramo `onda7-ev`. **Aprovado pelo Kenidy em 06/11, 11:16** ("pode começar"); cada versão ainda espera o "pode seguir" dele.

**Como funciona o ramo `onda7-ev`:** criado a partir do `main` (06/11). O CI compila o `main` a cada push; para compilar o ramo, rodar o workflow "Compilar IPA" nele (`gh workflow run build.yml --ref onda7-ev`). Isso publica uma Release `v0.7.16` com o IPA. Se o EV for cancelado: apagar o ramo e a Release/tag `v0.7.16`. Se for aprovado: unir ao `main` (merge) e só então a versão conta como estável. Antes de começar o EV, atualizar o ramo com o `main`.

## Pendências abertas (06/11)

- 4K 30 ainda lento nos primeiros usos (medir antes: travamentos da tela no Diagnóstico); 4K 60 bloqueado até isso.
- Limites de redução por calor: esperar Diagnóstico de dia quente.
- Decisão do Kenidy: com 4K 30 a pré-gravação de 60 s fica marcada e a janela real é 30 s (nota nos Ajustes); mantido.
- Testes anotados para o Kenidy: ver `docs/STATUS.md`.

## Onda 8: Polimento (aberta em 07/11, 12:00; plano organizado em 12:30)

Decisão do Kenidy: não há mais funções essenciais; agora é polir o que existe. **Regras da onda:** sem função nova; uma mudança por versão; cada versão testada no aparelho e com o "pode seguir" dele; área protegida (áudio e voz) sempre sozinha; sem regressão (nenhum `tela: TRAVADA`, `pilha:` ou `SEM QUADROS` no Diagnóstico). Numeração: a v0.7.28 (calor) fecha a Onda 7; os próximos passos seguem como **v0.8.x** (etapa 8), a confirmar com ele.

**Bloco A — uso real (primeiro)**
1. **Calor menos sensível** (v0.7.28 e v0.8.5/v0.8.6: avisos que dizem o que mudou; FEITO e aprovado; falta ver com calor real): chave "Reduzir com calor", desligada por padrão; crítico reduz sempre.
2. **Ajustes organizado (v0.8.0, FEITO e aprovado; a chave de calor foi renomeada e a linha Gravação longa saiu):** primeira tela sem rolar (Resolução, Fluidez, Qualidade, Pré-gravação + 3 tópicos: Voz e sons, Câmera, Aparelho; Calor, Armazenamento e Diagnóstico ficam em Aparelho). Critério: nenhuma página principal precisa rolar no iPhone15,4.
3. **Parar no 4K demora ~3 s (v0.8.2 mediu, v0.8.3 corrigiu: ~0,7 s; FEITO e aprovado em 07/11):** primeiro medir (quadros pendentes ao longo dos 3 s); depois reduzir se for espera inútil. Critério: clipe 4K chega às Fotos em menos de 1 s depois do fim, sem perder quadro.
4. **Textos (v0.8.1, v0.8.5, v0.8.6, v0.8.7: FEITO e aprovado):** revisão geral e migração dos que faltam para `Engine/Textos.swift`; tom formal e curto. Critério: nenhum texto do usuário fora de `Textos.swift`.

**Bloco B — achados pequenos (itens 5 e 6 feitos; 7 a 9 abertos)**
5. Tela inicial: "Abrindo…" sobreposto ao texto anterior: **resolvido desde a v0.7.15**.
6. Galeria: rolagem automática ao selecionar arrastando perto da borda da grade: **FEITO na v0.8.8 e aprovado**.
7. Miniatura escura no Fotos: **ADIADA por ele em 07/11** (só ao gravar logo depois de abrir a câmera; o normal é ter a pré-gravação correndo). Se voltar: versão só de Diagnóstico.
8. Foco ao trocar de lente: **ADIADO por ele em 07/11** (fica em `docs/MELHORIAS_FUTURAS.md`, para testar no futuro).
9. Erro de áudio do player (OSStatus 561017449) ao abrir o player junto da reabertura da câmera: **área protegida, sozinha**, baixa prioridade.

**Bloco C — testes que ele ainda pode fazer (sem versão nova; nenhum feito ainda):** clipe longo (5 min ou mais) com partes de 5 s e recuperação; estabilização em movimento; voz por 30 min ou mais em Comando; avisos de pouco espaço; calor num dia quente com a chave ligada.

**Bloco D — fechamento:** rodada de regressão (20 trocas de lente, 10 aberturas, minimizar e voltar, gravar e parar), uma estável aprovada por ele e unida ao `main`.

**Fora da onda (futuro, sem versão):** cortar clipe, vibração (área protegida), atalhos do sistema (feitos na Onda 10), palavra de ativação própria, esconder o Diagnóstico no app definitivo. Detalhes em `docs/MELHORIAS_FUTURAS.md`.

## Onda 9: zoom por pinça (decisão do Kenidy, 07/11; começa só depois de fechar a Onda 8)

Hoje o app só tem 3 pontos fixos (0,5×, 1×, 2×), pelos botões, com teto em 2×. A ideia é o zoom contínuo do app Câmera do iPhone: pinçar a tela avança ou volta o zoom de 0,5× a 6×, e a lente em uso muda sozinha pelo caminho.

1. **v0.9.0, câmera parada:** pinça contínua; na câmera combinada, a troca de lente é automática e sem reabrir a câmera; o botão da lente em uso mostra o valor real (ex.: "1,4×") e o destaque acompanha o dedo; botões 0,5 / 1 / 2 seguem funcionando. Teto: 6× ou o que o formato escolhido informar (4K pode ser menos; registrar no Diagnóstico). Fator da tela = fator do aparelho ÷ `combinedMain`.
2. **v0.9.1, gravando (FEITA e aprovada; junto da correção da pílula da frontal, a pedido dele):** a mesma pinça durante a gravação, sem corte nem perda de áudio (a v0.7.12 já troca de lente gravando).

Cuidados: a pinça não reabre a câmera; o valor do zoom na tela é lido sem `@Published` (`LiveTick`); sem câmera combinada, a pinça vai de 1× a 6× e o 0,5× fica só no botão (reserva, com o motivo no Diagnóstico); acima de 2× o zoom é digital. O brilho (EV) não zera ao pinçar, só ao trocar pelos botões, como hoje.

## Onda 10: atalhos e botões do sistema (decisão do Kenidy, 07/11; FECHADA em 10/11, estável v0.9.5)

Abrir o app direto na câmera pelo Botão de Ação (iPhone 15), toque nas costas (via Atalhos) e Siri.

1. **v0.9.2 "Abrir câmera" (FALHOU: o pedido nunca era atendido) e v0.9.3 (correção, APROVADA e estável):** ação do App Intents dentro do próprio app (sem extensão, para caber na conta grátis). A ação só deixa um recado; a `RootView` abre a câmera quando o app está ativo, pelos caminhos de sempre. Regra pura em `Core/LaunchRules.swift` (com testes). Reserva: o atalho "Abrir App" do Atalhos continua valendo.
2. **v0.9.4 (APROVADA e estável, 09/11):** tela preta no lugar do Início enquanto o atalho abre a câmera (o Início piscava por ~0,4 s).
3. **v0.9.5 (APROVADA e estável, 10/11): botões de volume como obturador** (AVCaptureEventInteraction, iOS 17.2+; liga e para a gravação; chave em Ajustes; reserva e log para iOS anterior). Ideia dele: backup do comando de voz e mais prático com a mão molhada.
4. **Depois (só se ele pedir): "Iniciar gravação".** Abre a câmera e já grava. Aviso: com o app fechado o buffer retroativo recomeça do zero (não há pré-clipe). Fica em versão própria.
5. Fora (conta grátis): botão no Centro de Controle/tela bloqueada (exige extensão) e abrir pela tela bloqueada como a câmera nativa (exige permissão especial da Apple). Ver `docs/PUBLICACAO.md` (depois da conta paga).
