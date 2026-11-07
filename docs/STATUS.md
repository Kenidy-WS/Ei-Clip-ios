# Status

**Atualizado em:** 2026-11-07 14:30 · **Estável:** v0.8.8 (aprovada por ele em 07/11, ~13:59; unida ao `main`) · **Em teste:** nada · **Etapa:** 8 (Onda 8, Polimento). Etapas 0 a 7 fechadas. Histórico versão por versão em `docs/HISTORICO.md`.

## Próximo passo (retomar aqui)

**Nada em teste. Estável: v0.8.8** (aprovada pelo Kenidy em 07/11, ~13:59; já no `main`). Ela reúne tudo da Onda 8 até agora: reabertura direto na câmera, Ajustes em 3 tópicos, chave "Reduzir qualidade com calor" (desligada por padrão; no crítico reduz sempre), avisos de calor com o que mudou, parar no 4K em ~0,7 s, Galeria (deslizar para marcar, voltar ao topo ao apagar, rolagem automática nas bordas), Diagnóstico enxuto, textos revisados. Detalhes versão por versão em `docs/HISTORICO.md`.

**Faltam na Onda 8 (esperar o "pode seguir" dele antes de cada uma; ver `docs/ROADMAP.md`):**
1. ~~Foco ao trocar de lente~~ **ADIADO por ele (07/11, 14:15):** "está bom assim, é algo bem específico". Fica em `docs/MELHORIAS_FUTURAS.md` para testar no futuro.
2. ~~Miniatura escura no Fotos~~ **ADIADA por ele (07/11, 14:24):** só acontece ao gravar logo depois de abrir a câmera, e o normal é gravar com a pré-gravação já correndo. Se voltar a incomodar: versão só de Diagnóstico (brilho em 0, 0,5, 1 e 2 s).
3. **Erro de áudio do player** (OSStatus 561017449): **área protegida, sozinha numa versão**, baixa prioridade.
4. Fechamento (Bloco D): regressão (20 trocas de lente, 10 aberturas, minimizar e voltar, gravar e parar) e uma estável final.

**Onda 9 (decisão dele, 07/11, 14:19): zoom por pinça**, só depois de fechar a Onda 8. v0.9.0 com a câmera parada e v0.9.1 gravando. Plano em `docs/ROADMAP.md`.

**Testes que ele ainda pode fazer, sem versão nova:** calor num dia quente com a chave ligada (ver o aviso "Reduzido: …" e, no crítico, se reduzir sozinho continua adequado); clipe longo (5 min ou mais) com partes de 5 s e recuperação se o app fechar gravando; estabilização em movimento; voz por 30 min ou mais em Comando; avisos de pouco espaço e de bateria baixa.

**Decisões dele que valem:** crítico reduz automático por enquanto (rever depois de um teste real); seletor de EV com botão no topo descartado; mostrar a palavra de voz ativa na câmera só se ele pedir; se a falha de minimizar e voltar rápido reaparecer, pedir "Copiar rodada anterior".

## Versão estável (para voltar se uma nova quebrar)

- **Estável: v0.8.8** (aprovada pelo Kenidy em 07/11, ~13:59: reúne v0.8.4 a v0.8.8: Diagnóstico enxuto, avisos de calor, textos revisados, rolagem automática na Galeria; a chave de calor ainda não foi vista com calor real): https://github.com/Kenidy-WS/Ei-Clip-ios/releases/download/v0.8.8/EiClip-v0.8.8.ipa
- Estável anterior: **v0.8.3** (aprovada pelo Kenidy em 07/11, ~13:01: reúne v0.7.27 a v0.8.3: Galeria, chave de calor, Ajustes em 3 tópicos, parar no 4K em ~0,7 s; a chave de calor ainda não foi vista com calor real): https://github.com/Kenidy-WS/Ei-Clip-ios/releases/download/v0.8.3/EiClip-v0.8.3.ipa
- Estável anterior: **v0.7.26** (aprovada pelo Kenidy em 07/11, ~11:54: Galeria volta ao topo quando a lista encolhe): https://github.com/Kenidy-WS/Ei-Clip-ios/releases/download/v0.7.26/EiClip-v0.7.26.ipa
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

## Testes que ele ainda pode fazer (atualizado em 07/11)

1. Calor em dia quente com a chave "Reduzir qualidade com calor" ligada: trazer o Diagnóstico (linhas "Redução por calor").
2. Clipe longo (5 min ou mais): partes de 5 s, arquivo final e recuperação se o app fechar gravando.
3. Avisos de pouco espaço e de bateria baixa.
4. Estabilização em movimento (o enquadramento muda um pouco, esperado).
5. Voz: religamento do reconhecedor após 30 min ou mais em Comando.

## Pendências abertas

- **Foco ao trocar de lente (ADIADO por ele em 07/11):** com mais objetos na cena aparece um repique na volta de 0,5× para 1×; o log mostra o zoom limpo, então o salto parece foco/exposição reajustando no sensor novo. Ideia: fixar foco e exposição no centro durante a troca. Versão própria, com Diagnóstico do estado do foco.
- **Miniatura escura no Fotos (adiada por ele):** clipes gravados logo depois de abrir a câmera têm a miniatura escura no Fotos (a do app está certa). Hipótese não confirmada: exposição ainda ajustando nos primeiros quadros. Começar por uma versão só de Diagnóstico medindo o brilho em 0, 0,5, 1 e 2 s.
- **Erro de áudio do player (OSStatus 561017449, '!pri'):** só quando o player abre no mesmo instante da reabertura automática da câmera ao voltar ao app. Área protegida: versão própria, baixa prioridade.
- **Calor real:** a chave de calor e os avisos novos só serão vistos com o aparelho quente; limites de redução esperam um Diagnóstico de dia quente.
- 4K 60 segue bloqueado (4K 30 já está bom; avaliar depois).
- Pré-gravação 60 s no 4K 30: marcada 60 s, janela real 30 s, com nota nos Ajustes (decisão dele).
- Pequeno: registrar no log os comandos de voz barrados pela regra de 3 s.
- Teste longo da voz (≥ 30 min em Comando): adiado por ele; fazer quando ele pedir.
- Resolvidas e movidas para o `docs/HISTORICO.md`: parar no 4K (v0.8.3), "Abrindo…" sobreposto (v0.7.15), voz logo depois de parar (v0.7.23), defeito do botão de lente (v0.7.3), pílula com o valor real (v0.7.14), revisão de textos (v0.8.6).

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

- `docs/ROADMAP.md`: etapas, critérios e a **Onda 8 (Polimento) e o resumo da Onda 7**.
- `docs/HISTORICO.md`: tudo que já foi feito e testado, versão por versão (antigo STATUS).
- `docs/ARCHITECTURE.md`: como o app é feito. `docs/MELHORIAS_FUTURAS.md`: ideias adiadas. `docs/AUDITORIA.md`: auditoria da etapa 4. `docs/RETOMADA.md`: texto para abrir um chat novo.
