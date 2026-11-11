# Status

**Atualizado em:** 2026-11-11 15:10 · **Estável:** v0.9.5 (aprovada por ele em 10/11, ~23:03; unida ao `main`) · **Em teste:** v0.9.7 (v0.9.6 + manifesto de privacidade, criptografia e textos de permissão; v0.9.6 é a reserva) · **Etapa:** 10 (Onda 10, atalhos e botões do sistema) FECHADA em 10/11. Etapas 0 a 10 fechadas. Histórico versão por versão em `docs/HISTORICO.md`.

## Próximo passo (retomar aqui)

**Estável: v0.9.5 (aprovada em 10/11, ~23:03, já no `main`).** Reúne tudo da Onda 10 (v0.9.2 a v0.9.5) sobre a v0.9.1, que por sua vez reúne a v0.8.8 e o zoom por pinça. Nada em teste.

**Onda 10 FECHADA (10/11): atalhos e botões do sistema.** Tudo validado no iPhone15,4 (iOS 27.0.1), que não tem Botão de Ação (só 15 Pro/Pro Max e 16 em diante); nele o gatilho físico é o toque nas costas:
1. **v0.9.2/v0.9.3, ação "Abrir câmera" (App Intents, sem extensão):** aparece sozinha no app Atalhos, na lista do Botão de Ação e na Siri; abre o Ei Clip direto na câmera, também com o app fechado. A v0.9.2 falhou (lia `scenePhase` dentro do `onChange`, valor antigo, e o pedido nunca era atendido); a v0.9.3 usa o valor do aviso e `applicationState`. Se a ação "sumir" do Atalhos, conferir se não foi instalado um IPA antigo por engano (versão no topo do Diagnóstico) e reiniciar o iPhone.
2. **v0.9.4:** tela preta no lugar do Início enquanto o atalho abre a câmera (sai ao aparecer a câmera, ao ignorar o pedido ou em 4 s).
3. **v0.9.5:** botões de volume como obturador (soltar + ou − liga e para a gravação; chave em Ajustes > Câmera, ligada por padrão; ignora com tela por cima, reconfiguração, aperto repetido etc.; reserva e log abaixo do iOS 17.2). Aprovada por ele sem colar o Diagnóstico; se aparecer qualquer defeito, procurar as linhas `volume:` e `atalho:`.

**Onda 8 FECHADA (07/11, 14:25), a pedido dele ("tá tudo estável"); estável final: v0.8.8.** Regressão formal dispensada por ele. Ficaram de fora, por decisão dele:
1. Foco ao trocar de lente: adiado ("está bom assim"); ideias em `docs/MELHORIAS_FUTURAS.md`.
2. Miniatura escura no Fotos: adiada (só ao gravar logo depois de abrir a câmera). Se voltar: versão só de Diagnóstico (brilho em 0, 0,5, 1 e 2 s).
3. Erro de áudio do player (OSStatus 561017449, '!pri'): adiado (raro, não repetiu desde a v0.7.3; área protegida, sozinha numa versão).

**Onda 9 FECHADA (07/11, ~14:44): zoom por pinça, estável v0.9.1.** Passou no aparelho (iPhone15,4, iOS 27.0.1): pinça de 0,5× a 6× na traseira (câmera combinada) e de 1× a 6× na frontal, parada e gravando; a lente troca sozinha; pílula de zoom na frontal com o número; botões 0,5/1/2 seguem iguais, também gravando. Log sem `tela: TRAVADA`, `pilha:` nem `SEM QUADROS`; clipe de 17,8 s gravado com pinça e troca de lente, 0 erros do codificador, áudio e vídeo contínuos, salvo no Rolo. Resumo: v0.9.0 (pinça parada; achou a pílula cortada) e v0.9.1 (pinça gravando + pílula corrigida + folga do ponto da lente em 0,05).

**Plano de publicação (07/11, ondas em 11/11):** `docs/PUBLICACAO.md` (fases 0 a 7 e, na seção 2, as **ondas P1 a P5** até o Beta 1; só consulta até ele dar o "pode seguir"). Modelo de cobrança: híbrido anual + acesso permanente, revalidado no jurídico (3.3 e 3.13); a compra fica para depois do Beta 1.

**Próximo passo:** nada marcado; esperar o pedido dele. Caminhos possíveis: (a) a **onda P1** da publicação (conta de desenvolvedor e nomes neutros; ver `docs/PUBLICACAO.md`, seção 2; trabalhar em ondas pequenas, ver `CLAUDE.md`); (b) "Iniciar gravação" pelo atalho (Onda 10, versão própria; ver `docs/MELHORIAS_FUTURAS.md`); (c) os itens adiados por ele: foco na troca de lente, miniatura escura, erro de áudio do player. Se ele colar observações do Codex, tratar como hipótese (ver `CLAUDE.md`).

**Testes que ele ainda pode fazer, sem versão nova:** botões de volume com Ajustes aberto e com o iPhone numa capa molhada (uso real); calor num dia quente com a chave ligada (ver o aviso "Reduzido: …" e, no crítico, se reduzir sozinho continua adequado); clipe longo (5 min ou mais) com partes de 5 s e recuperação se o app fechar gravando; estabilização em movimento; voz por 30 min ou mais em Comando; avisos de pouco espaço e de bateria baixa.

**Decisões dele que valem:** crítico reduz automático por enquanto (rever depois de um teste real); seletor de EV com botão no topo descartado; mostrar a palavra de voz ativa na câmera só se ele pedir; se a falha de minimizar e voltar rápido reaparecer, pedir "Copiar rodada anterior".

## Versão estável (para voltar se uma nova quebrar)

- **Estável: v0.9.5** (aprovada pelo Kenidy em 10/11, ~23:03: botões de volume como obturador; reúne v0.9.2 a v0.9.5): https://github.com/Kenidy-WS/Ei-Clip-ios/releases/download/v0.9.5/EiClip-v0.9.5.ipa
- Estável anterior: **v0.9.4** (aprovada pelo Kenidy em 09/11, ~19:09: tela preta no lugar do Início ao abrir pelo atalho; reúne v0.9.2 a v0.9.4): https://github.com/Kenidy-WS/Ei-Clip-ios/releases/download/v0.9.4/EiClip-v0.9.4.ipa
- Estável anterior: **v0.9.3** (aprovada pelo Kenidy em 07/11, ~19:18: ação "Abrir câmera" pelo toque nas costas/Atalhos, abre direto na câmera, mas passando um instante pelo Início; reúne v0.9.2 e v0.9.3): https://github.com/Kenidy-WS/Ei-Clip-ios/releases/download/v0.9.3/EiClip-v0.9.3.ipa
- Estável anterior: **v0.9.1** (aprovada pelo Kenidy em 07/11, ~14:44: zoom por pinça de 0,5× a 6×, parado e gravando; reúne v0.9.0 e v0.9.1): https://github.com/Kenidy-WS/Ei-Clip-ios/releases/download/v0.9.1/EiClip-v0.9.1.ipa
- Estável anterior: **v0.8.8** (aprovada pelo Kenidy em 07/11, ~13:59: reúne v0.8.4 a v0.8.8: Diagnóstico enxuto, avisos de calor, textos revisados, rolagem automática na Galeria; a chave de calor ainda não foi vista com calor real): https://github.com/Kenidy-WS/Ei-Clip-ios/releases/download/v0.8.8/EiClip-v0.8.8.ipa
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
- Bundle ID: `app.eiclip` (desde a v0.9.6, 11/11; antes `br.com.wpstecnologia.eiclip`). Permanente depois do registro na App Store Connect.
- Salvar sempre no álbum "Ei Clip" do Rolo. A galeria própria deixou de ser "não" e virou a etapa 4 (decisão do Kenidy em 05/11): ela lista só os clipes desse álbum (PhotoKit), sem copiar arquivos.
- Sem toolchain Swift no ambiente de desenvolvimento: lógica pura testada no CI macOS (`swift test` em `Core/`, o IPA só sai se passar).
- **Áudio do anel em PCM, não AAC:** cabe fácil na memória (~6 MB em 30 s) e o próprio arquivo codifica o AAC na gravação (sem trabalho de empacotar AAC à mão). Diverge do texto do plano ("H.264/AAC já codificados"); o vídeo continua codificado.
- 1080p30 fixo na etapa 1 (60 fps só na etapa 4); taxa/resolução vêm de `Core/VideoProfile.swift`.
- Reabrir a câmera sozinha ao voltar ao app é o comportamento desejado (hoje só o botão); entra depois de resolver o defeito de gravação.

## Ramos e tags

O trabalho vive no `main`. Ramos antigos já unidos ainda aparecem no GitHub (`onda7-ev`, `v0.7.18`, `v0.9.0` a `v0.9.5`): o ambiente de desenvolvimento não consegue apagar ramos remotos (o proxy bloqueia); o Kenidy pode apagá-los em github.com/Kenidy-WS/Ei-Clip-ios/branches (nada se perde: o conteúdo está no `main` e nas tags). Cada versão tem uma **tag e uma release** `vX.Y.Z` com o IPA; elas ficam para sempre (são os links de "voltar à estável"). Trabalhar sempre em ramo novo `vX.Y.Z`; como a tag tem o mesmo nome, usar `git push origin HEAD:refs/heads/vX.Y.Z` e, para unir, `git merge --ff-only refs/heads/vX.Y.Z` (nunca só o nome: a tag aponta para o commit da versão, sem os commits de docs feitos depois).

## Onde está o resto

- `docs/ROADMAP.md`: etapas, critérios e a **Onda 8 (Polimento) e o resumo da Onda 7**.
- `docs/HISTORICO.md`: tudo que já foi feito e testado, versão por versão (antigo STATUS).
- `docs/ARCHITECTURE.md`: como o app é feito. `docs/MELHORIAS_FUTURAS.md`: ideias adiadas. `docs/AUDITORIA.md`: auditoria da etapa 4. `docs/RETOMADA.md`: texto para abrir um chat novo.
