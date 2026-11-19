# Retomada em chat novo

Texto para colar no início de um chat novo (Claude Code, com este repositório e o web app `Kenidy-WS/clip` somente leitura). Atualizado em 19/11/2026, ~18:30 (v0.9.17 estável e unida ao `main`; Apple Negócios ativo; próximo: C2).

---

Continue o desenvolvimento do **Ei Clip** (iOS nativo, Swift/SwiftUI), repositório `Kenidy-WS/Ei-Clip-ios` (privado). O web app `Kenidy-WS/clip` é **somente leitura** (não alterar, não dar push).

**Primeiro, leia:** `CLAUDE.md`, `docs/STATUS.md` (estado, **próximo passo**, notas operacionais), `docs/ROADMAP.md` (fase atual), `docs/PUBLICACAO.md` (seção 1 "18/11/2026" e as tabelas de ondas P1 a P5 e C0 a C5 na seção 2) e `docs/MELHORIAS_FUTURAS.md`. `docs/HISTORICO.md` e `docs/arquivo/` são só consulta.

**Situação (19/11):** v0.9.17 estável (padrão 1080p60 Máxima 30 s; aviso de calor espera 60 s ao abrir quente; faixa fixa de espaço na tela inicial, ainda sem teste real; Ajustes marcam a pré-gravação que vale). Beta 1: 5 testadores na v0.9.13 (build 9); a v0.9.14 a v0.9.17 só foram ao grupo interno. Apple Negócios (contrato de apps pagos, banco, formulários fiscais) está **ativo**; contador confirmou pessoa física (não MEI). **Nada de compra foi implementado.**

**Próximo passo:** onda **C2** (implementação da compra), só com o "pode seguir" dele. Antes de codar: abrir a onda com passos e donos ([ELE]/[EU]/[JUNTOS]) e "pronto quando", conferir se há testador com iOS abaixo de 16.3 (a compra sobe o iOS mínimo) e perguntar se a v0.9.17 vai agora ao `Beta 1`. As ideias condicionais (B′ do calor, limpeza do log de voz, 4K 60, tutorial de primeira abertura, simulador de calor e espaço) esperam dados do Beta.

**Regras que valem (detalhes no `CLAUDE.md`):** uma mudança por versão e nada novo sem o "pode seguir" dele; trabalho em **ondas** (só a onda atual, passos com dono, "pronto quando", progresso "onda N de M"); português simples, listas curtas (ele lê no celular), tratando por "você"; entrega em 4 partes (o que mudou, testes numerados no iPhone via TestFlight, o que copiar do Diagnóstico, próximo passo), com "AÇÃO SUA" quando precisar dele; área protegida (voz e sessão de áudio) vai sozinha numa versão; decidir por capacidade do aparelho, nunca por modelo, com reserva e registro no Diagnóstico; texto de usuário só em `Engine/Textos.swift`, tom formal; nunca segredos no código; dados bancários e fiscais só no site da Apple, nunca no chat; assuntos de imposto, MEI, direito e banco: analisar com mentalidade de contador e advogado, avisando que não sou nenhum dos dois. **Não lembrar** dele da expiração de 7 dias do Sideloadly. Para desenhos de tela, ele gosta de ver um **protótipo no artefato** antes de codar.

**Fluxo de versão:** ramo `vX.Y.Z` a partir do `main`, commit em português "vX.Y.Z: o que mudou", subir `MARKETING_VERSION` e `CURRENT_PROJECT_VERSION` no `project.yml`, empurrar com `git push origin HEAD:refs/heads/vX.Y.Z`, compilar com `gh api -X POST repos/Kenidy-WS/Ei-Clip-ios/actions/workflows/testflight.yml/dispatches -f ref=vX.Y.Z` (disparo manual; se for cancelado por fila do macOS, disparar de novo), esperar CI verde, entregar o roteiro de teste e **só unir ao `main` depois da aprovação dele** (`git merge --ff-only refs/heads/vX.Y.Z`, ou `--no-ff` se o `main` andou). Atualizar `docs/STATUS.md` ao aprovar, com commit só de docs terminando em `[skip ci]`. Atribuição nos commits: linhas `Co-Authored-By` e `Claude-Session` que o ambiente indicar.

**Primeira tarefa:** ler os documentos acima e abrir a onda **C2** com o plano curto, sem mexer no código até ele dizer "pode seguir".
