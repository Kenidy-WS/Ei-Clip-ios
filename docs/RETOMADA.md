# Retomada em chat novo

Texto para colar no início de um chat novo (Claude Code, com este repositório e o web app `Kenidy-WS/clip` somente leitura). Atualizado em 07/11, 11:30 (v0.7.17 estável no `main`; v0.7.18 a v0.7.23 testadas, aguardando o OK).

---

Continue o desenvolvimento do **Ei Clip** (iOS nativo, Swift/SwiftUI), repositório `Kenidy-WS/Ei-Clip-ios`. O web app `Kenidy-WS/clip` é **somente leitura** (não alterar, não dar push).

**Primeiro, leia:** `CLAUDE.md`, `docs/STATUS.md` (estado e **próximo passo**), `docs/ROADMAP.md` (a **Onda 7** proposta) e `docs/ARCHITECTURE.md` (seção "Vigia e armadilhas do SwiftUI"). `docs/HISTORICO.md` é só consulta.

**Situação (07/11):**
- Versão estável: **v0.7.17** (EV, no `main`). As versões **v0.7.18 a v0.7.23** estão só no ramo `v0.7.18` (que inclui o EV): avisos no topo com pesos, bateria por degrau (20/10/5%), frontal deitada corrigida, início de gravação que espera o primeiro keyframe, textos revisados. O Kenidy testou a v0.7.23 e disse que está tudo certo; falta ele dizer "estável" para unir o ramo ao `main`.
- **Pendente agora:** (1) pedir esse OK; (2) falha ao minimizar e voltar muito rápido: o app foi para o Início com "Não foi possível abrir a câmera" (hipótese: reabrir enquanto o fechamento ainda desmonta a sessão; falta log); (3) o caminho novo do keyframe ainda não foi exercitado (tocar em gravar em menos de 1 s depois de abrir ou de parar).
- Decisões dele: redução de qualidade por calor **automática** com aviso claro; seletor de EV com botão no topo **descartado**; "Falha na sessão de áudio" e textos de permissões já revisados.
- O travamento de tela do iOS 27.0.1 está resolvido. **Regra que fica:** não publicar estado novo da tela durante a reconfiguração da câmera (o EV, a lanterna, o nível do aviso e a bateria são variáveis comuns lidas por `LiveTick`).
- O iOS entrega a bateria só de 5 em 5; o aviso não mostra número. A frontal deitada pede +180° no giro do arquivo (`DeviceHold.frontLandscapeInverted`).
- Outras pendências: salvar clipe em 4K leva ~3 s ao parar (flush do codificador, sem perda); redução automática por calor só foi vista uma vez (1080p60 → 30); ideias de foco em `docs/MELHORIAS_FUTURAS.md`; miniatura escura no Fotos (adiada); queda ao trocar para a frontal no iPhone 16 de um amigo, sem registro (ideia: guardar o registro da sessão anterior).

**Como trabalhar (regras do Kenidy):**
- Uma mudança por versão. Commit em português: `vX.Y.Z: o que mudou`. Subir `MARKETING_VERSION` e `CURRENT_PROJECT_VERSION` em `project.yml`. Push, acompanhar o CI até ficar verde.
- Cada entrega em 4 partes: (a) o que mudou, (b) testes numerados no iPhone, (c) o que copiar do Diagnóstico, (d) próximo passo. Com o link do IPA (a partir da v0.7.8: `https://github.com/Kenidy-WS/Ei-Clip-ios/releases/download/vX.Y.Z/EiClip-vX.Y.Z.ipa`; as anteriores usam `EiClip.ipa`) e "AÇÃO SUA" em passos numerados.
- **Esperar o "pode seguir" do Kenidy antes de qualquer versão nova.** Só marcar "Versão estável" no STATUS quando ele aprovar uma versão testada.
- Voz e sessão de áudio (área protegida) vão sozinhas numa versão.
- Português simples, listas curtas (ele lê no celular), tratando por "você". Não lembrar que o app expira em 7 dias.
- Commit só de documentos: `[skip ci]` no fim.
- **Lições de hoje (06/11):** (1) a versão do app precisa ter no máximo 3 números (0.7.3; "0.7.1.1" não vale no iOS). (2) Se o trabalho `ipa` do CI aparecer como "cancelled" sem nenhum passo, foi fila de máquina macOS, não erro de código: `gh run rerun <id> --failed`. (3) O CI leva 12 a 16 min; use `gh run watch` em blocos de até 9 min. (4) Estado que anda sozinho (tempos) não passa pelo Combine: use `LiveTick`. (5) `setLens` é `@MainActor`; funções `async` do motor rodam fora da principal se não forem marcadas.
- **Pendências de baixa prioridade:** erro de áudio do player (OSStatus 561017449) só quando o player abre no mesmo instante da reabertura automática da câmera (área protegida, versão própria, depois da Onda 7); miniatura escura no Fotos (adiada).

**Comece assim:** diga qual é a estável (v0.7.17) e que as v0.7.18 a v0.7.23 aguardam o OK; se colar o Diagnóstico, confira `vida:` a cada 30 s e a ausência de `tela: TRAVADA`, `pilha:` e `SEM QUADROS`. Diga em qual versão da Onda 7 estamos e espere o "pode seguir" dele antes de cada versão (a próxima é a v0.7.24, a definir com ele).
