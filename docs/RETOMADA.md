# Retomada em chat novo

Texto para colar no início de um chat novo (Claude Code, com este repositório e o web app `Kenidy-WS/clip` somente leitura). Atualizado em 10/11, ~23:15 (v0.9.5 estável; Ondas 8, 9 e 10 fechadas; nada em teste).

---

Continue o desenvolvimento do **Ei Clip** (iOS nativo, Swift/SwiftUI), repositório `Kenidy-WS/Ei-Clip-ios`. O web app `Kenidy-WS/clip` é **somente leitura** (não alterar, não dar push).

**Primeiro, leia:** `CLAUDE.md`, `docs/STATUS.md` (estado e **próximo passo**), `docs/ROADMAP.md` (seções **Onda 9** e **Onda 10**), `docs/ARCHITECTURE.md` (seções "Vigia e armadilhas do SwiftUI", "Onda 9", "Onda 10" e "Botões de volume") e `docs/PUBLICACAO.md` (plano de publicação, ainda não iniciado). `docs/HISTORICO.md` é só consulta.

**Situação (10/11):**
- Versão estável: **v0.9.5** (aprovada por ele em 10/11, ~23:03), já no `main`. Nada em teste. Ela reúne: reabertura direto na câmera, Ajustes em 3 tópicos, chave "Reduzir qualidade com calor" (desligada por padrão; no crítico reduz sempre), avisos de calor, parar no 4K em ~0,7 s, Galeria (deslizar para marcar), Diagnóstico enxuto, **zoom por pinça** de 0,5× a 6× (Onda 9), **ação "Abrir câmera"** (App Intents: toque nas costas, Atalhos, Siri; abre direto na câmera, com tela preta no lugar do Início) e **botões de volume como obturador** (Onda 10).
- **Onda 8, 9 e 10 FECHADAS.** Adiados por ele: foco na troca de lente, miniatura escura no Fotos, erro de áudio do player (OSStatus 561017449, área protegida). Testes que ele ainda pode fazer: calor real, clipe longo (5 min ou mais), voz por 30 min, avisos de espaço e bateria, iPhone 16 e 17 de amigos (pedir "Copiar" do Diagnóstico).
- Aparelho dele: iPhone15,4 (iPhone 15 comum), iOS 27.0.1: **não tem Botão de Ação** (só 15 Pro/Pro Max e 16 em diante). O gatilho físico dele é o toque nas costas.
- **Publicação (plano em `docs/PUBLICACAO.md`):** pessoa física primeiro, app grátis com teste por uso (10 a 15 clipes, Keychain) e compra única (StoreKit), códigos de oferta para influenciadores, TestFlight, CI assinado. Nada começa sem o "pode seguir" dele; a Fase 1 (conta, política de privacidade, domínio) não gasta compilação.
- **Visão externa:** o Codex (ChatGPT) avalia o projeto, mas não altera código; a opinião dele pesa menos; tratar como hipótese, conferir no código e no Diagnóstico, decidir com o Kenidy. Ideias em `docs/MELHORIAS_FUTURAS.md`.
- O travamento de tela do iOS 27.0.1 está resolvido. **Regra que fica:** não publicar estado novo (`@Published`) durante a reconfiguração da câmera, nem mudar `.disabled`/`.opacity` de vários botões de uma vez nesse momento. Trabalho do motor na fila principal usa `mainAsync`. **Armadilha nova (v0.9.2):** dentro de `onChange(of: scenePhase)` o valor de `scenePhase` lido pelo `self` ainda é o antigo; usar o valor que o aviso entrega ou `UIApplication.shared.applicationState`.
- O iOS entrega a bateria só de 5 em 5 e a temperatura só em níveis (sem graus). A frontal deitada pede +180° no giro do arquivo.

**Como trabalhar (regras do Kenidy):**
- Uma mudança por versão. Commit em português: `vX.Y.Z: o que mudou`. Subir `MARKETING_VERSION` e `CURRENT_PROJECT_VERSION` em `project.yml` (versão com no máximo 3 números). O trabalho vive no `main` (ramos antigos já unidos podem restar no GitHub; o proxy não deixa apagar ramos remotos, o Kenidy apaga pela página de ramos): criar ramo `vX.Y.Z`, empurrar com `git push origin HEAD:refs/heads/vX.Y.Z` e disparar `gh workflow run build.yml --ref vX.Y.Z -R Kenidy-WS/ei-clip-ios` (o CI só roda sozinho no `main`); acompanhar até ficar verde (12 a 16 min). Para unir: `git merge --ff-only refs/heads/vX.Y.Z` (as tags têm o mesmo nome do ramo; o nome puro pega a tag), e apagar o ramo local depois. Tags e releases ficam para sempre.
- Cada entrega em 4 partes: (a) o que mudou, (b) testes numerados no iPhone, (c) o que copiar do Diagnóstico, (d) próximo passo. Com o link do IPA (`https://github.com/Kenidy-WS/Ei-Clip-ios/releases/download/vX.Y.Z/EiClip-vX.Y.Z.ipa`) e "AÇÃO SUA" em passos numerados. Lembrar de conferir a versão no topo do Diagnóstico (já houve teste com IPA antigo instalado por engano).
- **Esperar o "pode seguir" do Kenidy antes de qualquer versão nova.** Só marcar "Versão estável" no STATUS (e unir ao `main`) quando ele aprovar uma versão testada.
- Voz e sessão de áudio (área protegida) vão sozinhas numa versão.
- Decidir pela capacidade que o aparelho informa, nunca pelo modelo; todo caminho novo mantém o atual como reserva e registra o motivo no Diagnóstico.
- Textos do usuário só em `Engine/Textos.swift`, tom formal e curto (exceção: título e frases da ação do App Intents ficam como literais no arquivo da ação).
- Português simples, listas curtas (ele lê no celular), tratando por "você". Não lembrar que o app expira em 7 dias.
- Commit só de documentos: `[skip ci]` no fim. Se o trabalho `ipa` do CI aparecer "cancelled" sem passos, foi fila de máquina: `gh run rerun <id> --failed`.

**Comece assim:** diga qual é a estável (v0.9.5) e que nada está em teste; pergunte o que ele quer fazer a seguir (próximo passo e itens adiados em `STATUS.md`, `MELHORIAS_FUTURAS.md` e `PUBLICACAO.md`) e espere o "pode seguir" dele. Se ele colar o Diagnóstico, confira `vida:` a cada 30 s e a ausência de `tela: TRAVADA`, `pilha:` e `SEM QUADROS`.
