# Retomada em chat novo

Texto para colar no início de um chat novo (Claude Code, com este repositório e o web app `Kenidy-WS/clip` somente leitura). Atualizado em 06/11 (v0.7.4 estável; v0.7.5 em teste no iPhone do amigo).

---

Continue o desenvolvimento do **Ei Clip** (iOS nativo, Swift/SwiftUI), repositório `Kenidy-WS/Ei-Clip-ios`. O web app `Kenidy-WS/clip` é **somente leitura** (não alterar, não dar push).

**Primeiro, leia:** `CLAUDE.md`, `docs/STATUS.md` (estado e **próximo passo**), `docs/ROADMAP.md` (a **Onda 7** proposta) e `docs/ARCHITECTURE.md` (seção "Vigia e armadilhas do SwiftUI"). `docs/HISTORICO.md` é só consulta.

**Situação (06/11):**
- Versão estável: **v0.7.4** (aprovada em 06/11). Em teste: **v0.7.5** (só no iPhone do amigo).
- O travamento de tela do iOS 27.0.1 está resolvido (aviso `isReconfiguring` publicado na tela durante a troca de lente). **Regra que fica:** não publicar estado novo da tela durante a reconfiguração da câmera.
- Onda 7 (aprovada em 06/11, cada versão espera o "pode seguir"): v0.7.0 e v0.7.1 topo (substituídas); v0.7.2 travamento; v0.7.3 botão de lente; **v0.7.4 câmera abre sem esperar as Fotos (ESTÁVEL)**; **v0.7.5 permissões com limite de tempo, pedido das Fotos de novo ao gravar e Abrir Ajustes (em teste SÓ no iPhone 16 de um amigo, onde o aviso das Fotos não aparece; não vira estável sem o OK do Kenidy)**; v0.7.6 qualidade junto da pré-gravação na tela escura (só visual); v0.7.7 lentes fluidas paradas (câmera combinada, 0,5×/1×/2× como pontos de zoom, com o caminho atual de reserva); v0.7.8 trocar de lente gravando; v0.7.9 flash de verdade (só traseira, sempre volta apagado); v0.7.10 valor REAL na pílula (fps aceito, redução por calor); v0.7.11 **EV**, sempre por último e isolado no ramo `onda7-ev`, cancelável. Princípio: decidir pela capacidade do aparelho (não pelo modelo) e sempre deixar o caminho atual como reserva, registrando o motivo no Diagnóstico. Pendências de produto: miniatura escura no Fotos (adiada); Início mostra "Nenhum clipe ainda." quando as Fotos não foram liberadas (trocar por um aviso de acesso).

**Como trabalhar (regras do Kenidy):**
- Uma mudança por versão. Commit em português: `vX.Y.Z: o que mudou`. Subir `MARKETING_VERSION` e `CURRENT_PROJECT_VERSION` em `project.yml`. Push, acompanhar o CI até ficar verde.
- Cada entrega em 4 partes: (a) o que mudou, (b) testes numerados no iPhone, (c) o que copiar do Diagnóstico, (d) próximo passo. Com o link do IPA (`https://github.com/Kenidy-WS/Ei-Clip-ios/releases/download/vX.Y.Z/EiClip.ipa`) e "AÇÃO SUA" em passos numerados.
- **Esperar o "pode seguir" do Kenidy antes de qualquer versão nova.** Só marcar "Versão estável" no STATUS quando ele aprovar uma versão testada.
- Voz e sessão de áudio (área protegida) vão sozinhas numa versão.
- Português simples, listas curtas (ele lê no celular), tratando por "você". Não lembrar que o app expira em 7 dias.
- Commit só de documentos: `[skip ci]` no fim.
- **Lições de hoje (06/11):** (1) a versão do app precisa ter no máximo 3 números (0.7.3; "0.7.1.1" não vale no iOS). (2) Se o trabalho `ipa` do CI aparecer como "cancelled" sem nenhum passo, foi fila de máquina macOS, não erro de código: `gh run rerun <id> --failed`. (3) O CI leva 12 a 16 min; use `gh run watch` em blocos de até 9 min. (4) Estado que anda sozinho (tempos) não passa pelo Combine: use `LiveTick`. (5) `setLens` é `@MainActor`; funções `async` do motor rodam fora da principal se não forem marcadas.
- **Pendências de baixa prioridade:** erro de áudio do player (OSStatus 561017449) só quando o player abre no mesmo instante da reabertura automática da câmera (área protegida, versão própria, depois da Onda 7); miniatura escura no Fotos (adiada).

**Comece assim:** diga qual é a estável (v0.7.4) e qual está em teste (v0.7.5); se colar o Diagnóstico, confira `vida:` a cada 30 s e a ausência de `tela: TRAVADA`, `pilha:` e `SEM QUADROS`. Diga em qual versão da Onda 7 estamos e espere o "pode seguir" dele antes de cada versão (as lentes fluidas são a v0.7.5).
