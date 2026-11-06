# Retomada em chat novo

Texto para colar no início de um chat novo (Claude Code, com este repositório e o web app `Kenidy-WS/clip` somente leitura). Atualizado em 06/11 (v0.7.3).

---

Continue o desenvolvimento do **Ei Clip** (iOS nativo, Swift/SwiftUI), repositório `Kenidy-WS/Ei-Clip-ios`. O web app `Kenidy-WS/clip` é **somente leitura** (não alterar, não dar push).

**Primeiro, leia:** `CLAUDE.md`, `docs/STATUS.md` (estado e **próximo passo**), `docs/ROADMAP.md` (a **Onda 7** proposta) e `docs/ARCHITECTURE.md` (seção "Vigia e armadilhas do SwiftUI"). `docs/HISTORICO.md` é só consulta.

**Situação (06/11):**
- Versão estável: **v0.7.2** (aprovada em 06/11, 14:43: correção do travamento da v0.7.0, com o topo novo). Em teste: **v0.7.3** (só o botão de lente 1× ↔ 2× com toques rápidos).
- O travamento de tela do iOS 27.0.1 está resolvido (aviso `isReconfiguring` publicado na tela durante a troca de lente). **Regra que fica:** não publicar estado novo da tela durante a reconfiguração da câmera.
- Onda 7 (aprovada em 06/11, cada versão espera o "pode seguir"): v0.7.0 faixa do topo (substituída); v0.7.1 topo redesenhado (substituída); v0.7.2 correção do travamento (estável); **v0.7.3 botão de lente (entregue, em teste)**; pedido do Kenidy ainda sem versão: qualidade junto da pré-gravação na tela escura; v0.7.4 lentes fluidas paradas (câmera combinada, 0,5×/1×/2× como pontos de zoom, com o caminho atual de reserva); v0.7.5 trocar de lente gravando; v0.7.6 flash de verdade (só traseira, sempre volta apagado; o ícone riscado já existe desde a v0.7.1); v0.7.7 valor REAL na pílula (fps aceito, redução por calor); v0.7.8 **EV**, sempre por último e isolado no ramo `onda7-ev`, cancelável. Princípio: decidir pela capacidade do aparelho (não pelo modelo) e sempre deixar o caminho atual como reserva, registrando o motivo no Diagnóstico. Vibração, cortar clipe e atalhos do sistema ficaram para o futuro. Pendência de produto: miniatura escura no Fotos (adiada).

**Como trabalhar (regras do Kenidy):**
- Uma mudança por versão. Commit em português: `vX.Y.Z: o que mudou`. Subir `MARKETING_VERSION` e `CURRENT_PROJECT_VERSION` em `project.yml`. Push, acompanhar o CI até ficar verde.
- Cada entrega em 4 partes: (a) o que mudou, (b) testes numerados no iPhone, (c) o que copiar do Diagnóstico, (d) próximo passo. Com o link do IPA (`https://github.com/Kenidy-WS/Ei-Clip-ios/releases/download/vX.Y.Z/EiClip.ipa`) e "AÇÃO SUA" em passos numerados.
- **Esperar o "pode seguir" do Kenidy antes de qualquer versão nova.** Só marcar "Versão estável" no STATUS quando ele aprovar uma versão testada.
- Voz e sessão de áudio (área protegida) vão sozinhas numa versão.
- Português simples, listas curtas (ele lê no celular), tratando por "você". Não lembrar que o app expira em 7 dias.
- Commit só de documentos: `[skip ci]` no fim.

**Comece assim:** pergunte se o Kenidy testou a v0.7.3; se colar o Diagnóstico, confira `vida:` a cada 30 s e a ausência de `tela: TRAVADA`, `pilha:` e `SEM QUADROS`. Diga em qual versão da Onda 7 estamos e espere o "pode seguir" dele antes da v0.7.4 (lentes fluidas).
