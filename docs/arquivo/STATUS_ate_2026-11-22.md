# Status

**Atualizado em:** 2026-11-22 · **Estável:** **v0.9.32** (TestFlight, aprovada em 22/11; v0.9.30, v0.9.31 e v0.9.32 unidas ao `main`). Ela fecha a **etapa 5b da C2**: tela "Meu plano" final (`PlanScreenRules`, Core, com testes: teste grátis, renovando, troca agendada, renovação não confirmada, cancelada, carência, pausado, permanente com ou sem assinatura, não confirmada, encerrada, revogada, em análise), aviso e alerta "Antes de continuar" ao comprar o permanente **só** quando a assinatura ainda pode cobrar, "Gerenciar assinatura" / "Resolver pagamento na Apple" (`AppStore.showManageSubscriptions`; no TestFlight a tela da Apple deixa cancelar), aviso "Role para ver mais" e folha de 640 pt. Junto vieram as correções da v0.9.30 (aviso de espaço acompanha a qualidade; sem "loja mudou" falso). Anteriores: v0.9.29, v0.9.28, v0.9.27, v0.9.26, v0.9.25, v0.9.21. **Etapa:** pré-lançamento; Apple Negócios (C1) ativo; C2 em andamento (gate ativo). **Próximo:** v0.9.33 (texto "gravação retroativa de até 60 segundos, conforme a qualidade" no lugar de 30; ramo pronto, sem build) e **C2 etapa 6** (tolerância offline de 7 dias), cada uma só com o "pode seguir". **Beta 1 (grupo externo):** 5 testadores na v0.9.13 (build 9); v0.9.14 em diante só no grupo interno.

**Moeda:** `PriceCurrencyGuard` (Core) mostra o preço só se a moeda do produto for igual à da loja. O catálogo do TestFlight alterna entre **US$** (1,99 / 9,99 / 29,99) e **R$** (9,90 / 59,90 / 179,90) sem causa conhecida (21/11: US$ de manhã e sem conta logada; R$ às 11:18 e às 12:04). A proteção funcionou nos dois casos. Desde a v0.9.29 produtos e preços são relidos, em silêncio, quando a loja muda (`Storefront.updates`) e ao voltar ao app com a loja diferente (no aparelho só se viu a abertura; troca real de loja não dá para provocar no Sandbox). Na loja oficial o catálogo vem da conta; conferir na C5.

**Simulação de teste (v0.9.27):** `AccessSimulation` (Ajustes > Meu plano, grupo de teste; some ao fechar o app) finge "sem acesso pago" com N clipes usados e pode mostrar preços do catálogo. Com a simulação ligada, o painel "Acesso liberado" nunca aparece (a simulação esconde o acesso real). **Remover antes do Beta público** (etapa 7).

**Pendências da C2:** (1) risco de revisão da Apple: preço e período visíveis, regra 3.1.2, links de privacidade e termos (conferir antes da C5; notas de revisão); (2) Permanente sem teste (**não comprar com o Apple ID real**); (3) **compra nova do zero e os painéis "Acesso liberado" / "Compra em análise" nunca foram vistos no aparelho.** Plano de teste (ele, 22/11): a assinatura Mensal foi **cancelada** pela tela da Apple (Meu plano > Gerenciar assinatura) e acaba em 22/11 às 03:04; depois ele confere o estado "Encerrada", assina de novo, testa a troca de plano pela tela da Apple ("Ver todos os planos") e, **por último**, compra o permanente com a assinatura renovando (alerta "Antes de continuar" e estado "Acesso permanente + renovação ativa"); (4) **5b feita (v0.9.31/32).** Com assinatura ativa só se oferece o permanente; Mensal/Anual só aparecem sem acesso pago, então a troca agendada vem da tela da Apple; (5) **já vistos no aparelho:** renovando, cancelada (22/11, com `meu plano: canceled` no Diagnóstico), teste grátis (simulação) e o aviso de rolagem. **Só em testes automáticos:** troca agendada, carência, nova tentativa (pausado), encerrada, revogada, em análise, permanente com assinatura, troca real de loja/conta. Divergência a vigiar: a tela da Apple (Sandbox) mostrou 21/11 e o app 22/11 03:04 (suspeita de fuso do Sandbox; conferir quando o acesso acabar). O valor da renovação na tela é o **preço de tabela** do produto (não `renewalInfo.renewalPrice`) e some se a moeda da loja não for confiável; (6) risco da etapa 6: assinante offline sem `LastConfirmed` salvo e com 10 usados pode ver a tela de planos; (7) preço de lançamento do Permanente fora do App Store Connect; (8) ícone da folha de resgate (ficha do app sem ícone no App Store Connect).

Histórico completo (versão por versão, IPAs antigos do Sideloadly, lições): `docs/arquivo/` (`STATUS_ate_2026-11-19.md`, `STATUS_ate_2026-11-20.md`, `STATUS_ate_2026-11-21.md`, `HISTORICO_ate_v0.9.5.md`, `ROADMAP_etapas_6_a_10.md`). Resumo das versões novas: `docs/HISTORICO.md`.

## Próximo passo (retomar aqui)

1. **v0.9.33** (texto): `Textos.beneficioRetroativa` diz 30 s, mas a janela vai a 60 s (`BufferWindow.options` 15/30/60; só 4K Máxima fica em 30 s pela memória). Novo texto: "Gravação retroativa de até 60 segundos, conforme a qualidade". Depois **C2 etapa 6** (tolerância offline de 7 dias), **7** (prazo na tela; remover a simulação), **C3** (teste geral), Termos com advogado e contador, **C4/C5**. Cada uma só com o "pode seguir". Detalhes em `docs/PLANO_C2.md`; decisões em `docs/PUBLICACAO.md` (19/11 e 3.13); `docs/TERMOS_MINUTA.md`.
2. **Design e testes da etapa 4:** resumo em `docs/ARCHITECTURE.md` (seção "C2 etapa 4") e `docs/arquivo/STATUS_ate_2026-11-21.md`.
3. **Decisão pendente dele:** levar uma versão mais nova ao grupo externo `Beta 1` (os testadores ainda estão na v0.9.13). Build nova pode reiniciar a revisão de beta da Apple. Não gravar o link público no repositório.
4. **Condicionais (esperam dados do Beta, sem pressa):** B′ (calor crítico reduz 60→30 fps); limpeza do log de voz (área protegida, versão própria); 4K 60; tutorial de primeira abertura e botão "i"; simulador de calor/espaço no Diagnóstico. Detalhes em `docs/MELHORIAS_FUTURAS.md`.

Antes da publicação: onda própria de reanálise de Termos e Políticas (advogado e contador).

## Versão estável (para voltar se uma nova quebrar)

- **Estável: v0.9.32** (22/11, C2 etapa 5b + correções da v0.9.30). Anteriores: **v0.9.29** (5a), **v0.9.28** (folha de Ajustes), **v0.9.27** (C2 etapa 4), **v0.9.26** (moeda), **v0.9.25**, **v0.9.21**. Só pelo TestFlight (o `build.yml` de IPA é manual e vira reserva). Para reenviar uma versão: ramo `vX.Y.Z` no GitHub + `testflight.yml`. O TestFlight guarda cada build por 90 dias.
- Estáveis anteriores, nesta ordem: v0.9.16, v0.9.15, v0.9.14 (todas de 19/11), v0.9.13 (17/11, Beta 1, build 9), v0.9.10, v0.9.9. IPAs antigos e notas de cada uma: `docs/arquivo/STATUS_ate_2026-11-19.md`, seção "Versão estável".
- Regra: uma versão só vira "estável" depois de testada no aparelho e com o OK dele; este bloco é atualizado nesse momento.

## Regras de tela que ficam (lição do travamento, v0.6.17 a v0.6.26)

- Não publicar (`@Published`) estado novo enquanto a câmera é reconfigurada, nem mudar `.disabled`/`.opacity` de vários botões de uma vez nesse momento (travou a tela no iOS 27.0.1). Estado novo da tela só em resposta a toque, ou lendo o que já existe. Trabalho do motor na fila principal usa `mainAsync`. Detalhes em `docs/ARCHITECTURE.md`.

## Pendências abertas

- **Programa para Pequenos Negócios da Apple (comissão 15%) — NÃO ESQUECER antes de abrir as vendas (C5):** a inscrição é manual, pelo titular da conta (pessoa física), em `developer.apple.com/app-store/small-business-program/enroll/`; sem ela a comissão é 30% (assinatura: 15% só a partir do 2º ano de cada assinante). Pedido dele em 20/11: **confirmar se já está inscrito** (e-mail de confirmação da Apple ou página de inscrição) e, se não, inscrever; o repositório não registra que foi feito. Conferir também o líquido real no primeiro relatório de vendas.
- **Calor real:** os avisos novos (espera de 60 s) e a redução só serão vistos com o aparelho quente; limites de redução esperam um Diagnóstico de dia quente. Preferência dele: redução automática **desligada** de fábrica e "régua" das reduções mais alta.
- **Faixa de espaço (v0.9.16):** falta ver no aparelho ou em testador.
- **Beta 1:** colher relatos (Diagnóstico por Compartilhar) e classificar em bug, ajuste ou ideia; decidir quando subir a v0.9.17 ao grupo externo.
- **Voz (área protegida, versão própria):** log só com mudanças do texto filtrado; três horários de falha de 15/11 tratados como indefinidos.
- **Adiadas por ele (ver `docs/MELHORIAS_FUTURAS.md` e `docs/arquivo/`):** foco ao trocar de lente; miniatura escura no Fotos; erro de áudio do player (OSStatus 561017449); teste longo da voz (≥ 30 min); teste de corte do iOS durante a gravação.

## Notas operacionais

- **Repositório privado** (`Kenidy-WS/Ei-Clip-ios`; o endereço antigo redireciona). Em repositório privado a compilação macOS gasta 10x os minutos do plano (limite grátis 2.000/mês); o saldo só se vê em GitHub > Settings > Billing (não acessível do ambiente). `testflight.yml` roda ~2 a 5 min por execução.
- **Build TestFlight:** `gh api -X POST repos/Kenidy-WS/Ei-Clip-ios/actions/workflows/testflight.yml/dispatches -f ref=vX.Y.Z` (`gh workflow run` falha pelo proxy). O número da build = número da execução. Corrigir algo dentro de uma versão em teste gera só nova **build** (o Diagnóstico mostra "vX.Y.Z (N)"); funcionalidade nova ganha versão nova. Se a execução for **cancelada por fila de runner macOS** (≈15 min), é só disparar de novo.
- **GitHub pelo ambiente:** `gh` só por REST (`gh api`; GraphQL dá 403, então `gh repo view` e `gh release view` falham). Sem toolchain Swift: só o CI compila e roda `swift test`. Commit só de documentos leva `[skip ci]`.
- **Unir ao `main`:** `git merge --ff-only refs/heads/vX.Y.Z` quando o `main` não andou; se o `main` recebeu documentos em paralelo, usar `git merge --no-ff` (commit de união). Nome puro pega a tag antiga, por isso `refs/heads/`. Depois de unir, apagar o ramo local.
- **Ramos remotos:** o proxy não deixa apagar. Restam no GitHub `onda7-ev`, `v0.7.18`, `v0.9.0` a `v0.9.17` (todos já no `main`); ele pode apagar em github.com/Kenidy-WS/Ei-Clip-ios/branches se quiser. Tags/releases `vX.Y.Z` só existem até a v0.9.9 (o `build.yml` as criava; agora é manual).
- **Web app de referência (somente leitura):** https://github.com/Kenidy-WS/clip (clonar raso para ler `src/core/` e `tests/`).
- **Diagnóstico:** `Application Support/Diagnostico/atual.txt` (rodada anterior em `anterior.txt`); Compartilhar gera o .txt; a fala de fundo não é gravada (v0.9.13).

## Decisões que valem

- Textos do usuário: tom formal e claro; todo texto novo em `Engine/Textos.swift`. O Diagnóstico segue técnico.
- Bundle ID `app.eiclip` (permanente depois do registro na App Store Connect). Salvar sempre no álbum "Ei Clip" do Rolo (sem galeria própria de arquivos; a Galeria do app lista o álbum por PhotoKit).
- Padrão de fábrica 1080p60 Máxima 30 s; redução automática por calor desligada; crítico só avisa (a escolha dele vale), a reserva por falha da câmera reduz 2 passos.
- Posicionamento: o diferencial é a **gravação retroativa**, não a voz (`docs/PUBLICACAO.md`, seção 1, 15/11).
- Contas e dinheiro: conta de desenvolvedor de pessoa física, recebimento em conta pessoal, contador confirmou (não MEI). Dados bancários e fiscais só no site da Apple, nunca no chat.

## Onde está o resto

- `docs/ROADMAP.md`: etapas e a fase atual. `docs/PUBLICACAO.md`: plano de publicação e compra (decisões, ondas P1 a P5 e C0 a C5, jurídico). `docs/ARCHITECTURE.md`: como o app é feito. `docs/MELHORIAS_FUTURAS.md`: ideias adiadas. `docs/CONVITE_BETA.md`: texto do convite. `docs/AUDITORIA.md`, `docs/RELATORIO_JURIDICO_PACOTE_A.md`: auditorias. `docs/RETOMADA.md`: texto para abrir um chat novo. `docs/arquivo/`: histórico.
