# Retomada em chat novo

Texto para colar no início de um chat novo (Claude Code, com este repositório e o web app `Kenidy-WS/clip` somente leitura). Atualizado em 06/11.

---

Continue o desenvolvimento do **Ei Clip** (iOS nativo, Swift/SwiftUI), repositório `Kenidy-WS/Ei-Clip-ios`. O web app `Kenidy-WS/clip` é **somente leitura** (não alterar, não dar push).

**Primeiro, leia:** `CLAUDE.md`, `docs/STATUS.md` (estado e **próximo passo**), `docs/ROADMAP.md` (a **Onda 7** proposta) e `docs/ARCHITECTURE.md` (seção "Vigia e armadilhas do SwiftUI"). `docs/HISTORICO.md` é só consulta.

**Situação (06/11):**
- Versão estável: **v0.6.26**. Em teste: **v0.6.27** (só reduz o ruído do Diagnóstico: linha `vida:` a cada 30 s).
- O travamento de tela do iOS 27.0.1 está resolvido (aviso `isReconfiguring` publicado na tela durante a troca de lente). **Regra que fica:** não publicar estado novo da tela durante a reconfiguração da câmera.
- Onda 7 (proposta, aguardando o OK do Kenidy depois do teste da v0.6.27): v0.7.0 faixa do topo com qualidade e fluidez; v0.7.1 flash (só traseira, sempre volta apagado); v0.7.2 botão da lua para a faixa; v0.7.3 mostrador da pré-gravação (anel em volta do obturador + texto "PRÉ 12/30 s", sem a pílula); v0.7.4 **EV (compensação de exposição)**, sempre por último e isolado no ramo `onda7-ev`, cancelável. Vibração, cortar clipe e atalhos do sistema ficaram para o futuro.

**Como trabalhar (regras do Kenidy):**
- Uma mudança por versão. Commit em português: `vX.Y.Z: o que mudou`. Subir `MARKETING_VERSION` e `CURRENT_PROJECT_VERSION` em `project.yml`. Push, acompanhar o CI até ficar verde.
- Cada entrega em 4 partes: (a) o que mudou, (b) testes numerados no iPhone, (c) o que copiar do Diagnóstico, (d) próximo passo. Com o link do IPA (`https://github.com/Kenidy-WS/Ei-Clip-ios/releases/download/vX.Y.Z/EiClip.ipa`) e "AÇÃO SUA" em passos numerados.
- **Esperar o "pode seguir" do Kenidy antes de qualquer versão nova.** Só marcar "Versão estável" no STATUS quando ele aprovar uma versão testada.
- Voz e sessão de áudio (área protegida) vão sozinhas numa versão.
- Português simples, listas curtas (ele lê no celular), tratando por "você". Não lembrar que o app expira em 7 dias.
- Commit só de documentos: `[skip ci]` no fim.

**Comece assim:** pergunte se ele testou a v0.6.27. Se colou o Diagnóstico, confira `vida:` a cada 30 s e a ausência de `tela: TRAVADA`, `pilha:`, `SEM QUADROS`; diga "passou" ou "falhou, e por quê". Depois peça o OK final do escopo da Onda 7 e, com o "pode seguir", faça a v0.7.0.
