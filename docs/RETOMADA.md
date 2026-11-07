# Retomada em chat novo

Texto para colar no início de um chat novo (Claude Code, com este repositório e o web app `Kenidy-WS/clip` somente leitura). Atualizado em 07/11, 14:40 (v0.8.8 estável; Onda 8 fechada; Onda 9, zoom por pinça, aberta).

---

Continue o desenvolvimento do **Ei Clip** (iOS nativo, Swift/SwiftUI), repositório `Kenidy-WS/Ei-Clip-ios`. O web app `Kenidy-WS/clip` é **somente leitura** (não alterar, não dar push).

**Primeiro, leia:** `CLAUDE.md`, `docs/STATUS.md` (estado e **próximo passo**), `docs/ROADMAP.md` (seções **Onda 8** e **Onda 9**) e `docs/ARCHITECTURE.md` (seções "Vigia e armadilhas do SwiftUI" e "Onda 8"). `docs/HISTORICO.md` é só consulta.

**Situação (07/11):**
- Versão estável: **v0.8.8** (aprovada por ele em 07/11, ~13:59), já no `main`. Nada em teste. Reúne: reabertura direto na câmera, Ajustes em 3 tópicos, chave "Reduzir qualidade com calor" (desligada por padrão; no crítico reduz sempre), avisos de calor que dizem o que mudou, parar no 4K em ~0,7 s, Galeria (deslizar para marcar, voltar ao topo ao apagar, rolagem automática), Diagnóstico enxuto e textos revisados.
- **Onda 8 FECHADA em 07/11 (14:25)** com a v0.8.8 como estável final. Adiados por ele: foco na troca de lente, miniatura escura no Fotos e erro de áudio do player (OSStatus 561017449). Testes que ele ainda pode fazer: calor real com a chave ligada, clipe longo, estabilização em movimento, voz por 30 min, avisos de espaço e bateria.
- **Onda 9 (aberta): zoom por pinça** (v0.9.0 parado, v0.9.1 gravando); plano no `ROADMAP.md`.
- Decisões dele: no calor crítico a redução segue automática até um teste real; seletor de EV no topo descartado; mostrar a palavra de voz ativa na câmera só se ele pedir.
- O travamento de tela do iOS 27.0.1 está resolvido. **Regra que fica:** não publicar estado novo (`@Published`) durante a reconfiguração da câmera, nem mudar `.disabled`/`.opacity` de vários botões de uma vez nesse momento. Trabalho do motor na fila principal usa `mainAsync`.
- O iOS entrega a bateria só de 5 em 5 e a temperatura só em níveis (sem graus). A frontal deitada pede +180° no giro do arquivo.

**Como trabalhar (regras do Kenidy):**
- Uma mudança por versão. Commit em português: `vX.Y.Z: o que mudou`. Subir `MARKETING_VERSION` e `CURRENT_PROJECT_VERSION` em `project.yml` (versão com no máximo 3 números). Push com `git push origin HEAD:refs/heads/<ramo>` (existem tags com nomes iguais aos ramos), acompanhar o CI até ficar verde (12 a 16 min).
- Cada entrega em 4 partes: (a) o que mudou, (b) testes numerados no iPhone, (c) o que copiar do Diagnóstico, (d) próximo passo. Com o link do IPA (`https://github.com/Kenidy-WS/Ei-Clip-ios/releases/download/vX.Y.Z/EiClip-vX.Y.Z.ipa`) e "AÇÃO SUA" em passos numerados.
- **Esperar o "pode seguir" do Kenidy antes de qualquer versão nova.** Só marcar "Versão estável" no STATUS (e unir ao `main`) quando ele aprovar uma versão testada.
- Voz e sessão de áudio (área protegida) vão sozinhas numa versão.
- Decidir pela capacidade que o aparelho informa, nunca pelo modelo; todo caminho novo mantém o atual como reserva e registra o motivo no Diagnóstico.
- Textos do usuário só em `Engine/Textos.swift`, tom formal e curto.
- Português simples, listas curtas (ele lê no celular), tratando por "você". Não lembrar que o app expira em 7 dias.
- Commit só de documentos: `[skip ci]` no fim. Se o trabalho `ipa` do CI aparecer "cancelled" sem passos, foi fila de máquina: `gh run rerun <id> --failed`.

**Comece assim:** diga qual é a estável e o que está em teste (veja o `STATUS.md`), proponha o próximo passo da Onda 9 e espere o "pode seguir" dele. Se ele colar o Diagnóstico, confira `vida:` a cada 30 s e a ausência de `tela: TRAVADA`, `pilha:` e `SEM QUADROS`.
