# Status

**Atualizado em:** 2026-11-24 (11:30) · **Estável (no `main`): v0.9.42** · **Em teste no TestFlight, ainda fora do `main`: v0.9.43 e v0.9.44** (ramos empilhados sobre o `main`; o iPhone dele está na v0.9.44, build 67) · **Etapa:** pré-lançamento; Apple Negócios (C1) ativo; C2 (compra no app) com as etapas 1 a 7 no código, falta só a limpeza final (v0.9.47) e as provas de 25/11 · **Beta 1 (grupo externo):** 5 testadores na v0.9.13 (build 9); v0.9.14 em diante só no grupo interno.

Resumo das versões: `docs/HISTORICO.md`. Detalhe antigo deste arquivo (até 24/11): `docs/arquivo/STATUS_ate_2026-11-24.md` e os anteriores em `docs/arquivo/`.

## Próximo passo (retomar aqui)

**Mapa de versões (reorganizado em 24/11; cada uma só com o "pode seguir" dele):**

| Versão | O que é | Estado |
| ------ | ------- | ------ |
| v0.9.43 | Correção: Permanente guardado + sem rede = "não confirmada", liberado **sem prazo** (o Permanente nunca usa os 7 dias) | No TestFlight; só testes automáticos (não dá para provar no aparelho) |
| v0.9.44 | Etapa 7: prazo de 7 dias no Meu plano (data e hora do fim), textos novos, botão "Verificar novamente" | No TestFlight; prova no aparelho em 25/11 |
| v0.9.45 | Reler a assinatura sozinho quando a internet volta (`NetworkPathWatcher`) | A fazer |
| v0.9.46 | Tela de planos sem internet (0 produtos sem erro = falha de rede: "Verifique a conexão" + "Tentar novamente") | A fazer |
| v0.9.47 | Limpeza: tirar a simulação ("Só para teste", `AccessSimulation`), só depois dos testes do limite de 10 clipes e antes do Beta 2 | A fazer |

Depois: **C3** (Beta 2; Permanente por último e com o aval dele; avisar que compras do TestFlight são Sandbox e não valem na loja), **Termos** com advogado e contador (incluir a frase do que cada plano entrega; plano B: lançar só com Permanente se a Apple recusar a assinatura), **C4/C5**. Detalhes: `docs/PLANO_C2.md`, `docs/PUBLICACAO.md` (19/11 e 3.13), `docs/TERMOS_MINUTA.md`.

**Verificações de 25/11 (sem versão nova; lista completa em `docs/TESTE_OFFLINE.md`, "Lista de 25/11"):**
1. Lista vazia com leitura velha: abrir offline cedo, antes das 10:31, sem abrir o app online antes (esperado: `lista VAZIA… NÃO CONFIRMADA`).
2. Teste B (regressão): cancelar com internet, avião antes do fim, abrir offline depois (deve bloquear).
3. Gravar um clipe de verdade em "não confirmada".
4. Fim natural do período (~10:31, offline): Meu plano deve mostrar "Assinatura não confirmada" com a data do fim dos 7 dias.
5. Ele envia o Diagnóstico e um print do Meu plano; eu digo "passou" ou "falhou, e por quê".

**Depois das provas e do OK dele:** unir v0.9.43 e v0.9.44 ao `main` (`git merge --ff-only refs/heads/v0.9.44`), atualizar "Versão estável" e apagar os ramos locais.

**Pendências menores (sem versão):** relógio adiantado/atrasado (por último; avanço de no máximo 5 dias; suja a "maior data vista"); reinstalar offline; restaurar backup; conferir se a contagem de clipes grátis sobrevive à reinstalação (o tutorial diz "10 clipes grátis"); registrar em `docs/PUBLICACAO.md` a data de início da comissão de 15% quando a Apple aprovar o Small Business.

## Estado da C2 (compra no app)

- **No código:** gate de 10 clipes (`AccessGate`), StoreKit 2, tela "Escolha seu acesso", chip e avisos, Meu plano final, leitura da assinatura, resultado da compra, tolerância offline de 7 dias (último acesso confirmado no Keychain + proteção de relógio), tutorial de primeiro acesso (v0.9.35), resumo do Meu plano e Ajuda (v0.9.36), tela "Enviar feedback" (v0.9.40).
- **Regra offline (v0.9.39 a v0.9.44):** sem rede o StoreKit responde pelo cache local e pode dizer "terminou" ou devolver lista vazia mesmo com assinatura paga. Esses casos valem como **não confirmada**: acesso até o fim do último período confirmado + 7 dias. Permanente guardado sem rede fica liberado **sem prazo**. Só resposta válida da Apple com rede bloqueia na hora. `StoreTrustRules` (Core) e `NetworkPathWatcher` (Engine); ver `docs/ARCHITECTURE.md`.
- **Provado no aparelho:** renovando, cancelada, encerrada, teste grátis, aviso de rolagem, resultado da compra (aprovada, nenhuma compra nova, erro sem internet); online + expirada bloqueia na hora (22/11); cancelada + offline passou do fim bloqueia (B, v0.9.38, 23/11); offline passou do fim com renovação ligada libera por tolerância (A, v0.9.42, 24/11); Keychain sobrevive ao fechar o app; "maior data vista" avança.
- **Só em testes automáticos:** lista vazia offline com leitura velha (corrigida na v0.9.42, falta a prova), Permanente (com ou sem assinatura, offline), carência, nova tentativa, revogada, em análise, troca real de loja/conta.
- **Sem cobertura de teste automático:** `StoreManager` e o resto do Engine (só prova no aparelho).
- **Sandbox/TestFlight:** compras são de teste (Diagnóstico mostra `ambiente Sandbox`), não valem na loja; a renovação acontece 1 vez por dia (até ~6). A conta Sandbox existe, mas não dá para entrar nela no iPhone sem Mac. Mesmo assim, **não comprar o Permanente** com o Apple ID dele antes do fim da C3 e sem o aval dele.
- **Moeda:** `PriceCurrencyGuard` (Core) mostra o preço só se a moeda do produto for igual à da loja. O catálogo do TestFlight alterna entre US$ e R$ sem causa conhecida; na loja oficial o catálogo vem da conta (conferir na C5).
- **Simulação de teste (`AccessSimulation`, Ajustes > Meu plano > "Só para teste"):** finge "sem acesso pago" com N clipes usados; some ao fechar o app; a compra funciona com ela ligada (é compra real no Sandbox). **Sai na v0.9.47**, antes do Beta público.

**Pendências da C2:** (1) risco de revisão da Apple: preço e período visíveis, regra 3.1.2, links de privacidade e termos, notas de revisão (conferir antes da C5); (2) Permanente sem teste no aparelho (fazer só no fim da C3, com assinatura renovando, para ver "Acesso permanente liberado" + aviso amarelo e o alerta "Antes de continuar"); (3) itens ainda sem conferência: texto grande, VoiceOver e câmera deitada na tela de planos; gravação em andamento quando o acesso vence (o plano diz que termina e salva); código de oferta resgatado; (4) a tela da Apple (Sandbox) mostrou 21/11 e o app 22/11 03:04 (suspeita de fuso do Sandbox, não confirmada); (5) preço de lançamento do Permanente (Temporary Price Change, agendar só perto do lançamento); (6) ícone da folha de resgate (ficha do app sem ícone no App Store Connect). **Lição (22/11):** conferir o protótipo aprovado contra o que foi codado antes de dar uma etapa de tela por fechada.

## Versão estável (para voltar se uma nova quebrar)

- **Estável: v0.9.42** (24/11, no `main` com o OK dele; contém v0.9.39 a v0.9.41 e a v0.9.38). **Ressalva:** o caminho novo da v0.9.42 (lista de assinaturas vazia sem rede) só tem testes automáticos; a prova no aparelho espera uma leitura guardada velha (25/11 cedo).
- Anteriores: **v0.9.38** (22/11), v0.9.34, v0.9.32, v0.9.29, v0.9.28, v0.9.27, v0.9.26, v0.9.25, v0.9.21, v0.9.16 a v0.9.14 (19/11), v0.9.13 (17/11, Beta 1, build 9). Notas de cada uma: `docs/HISTORICO.md`; IPAs antigos: `docs/arquivo/STATUS_ate_2026-11-19.md`.
- Só pelo TestFlight (o `build.yml` de IPA é manual e vira reserva). Para reenviar uma versão: ramo `vX.Y.Z` no GitHub + `testflight.yml`. O TestFlight guarda cada build por 90 dias.
- Regra: uma versão só vira "estável" depois de testada no aparelho e com o OK dele; este bloco é atualizado nesse momento.

## Regras de tela que ficam (lição do travamento, v0.6.17 a v0.6.26)

- Não publicar (`@Published`) estado novo enquanto a câmera é reconfigurada, nem mudar `.disabled`/`.opacity` de vários botões de uma vez nesse momento (travou a tela no iOS 27.0.1). Estado novo da tela só em resposta a toque, ou lendo o que já existe. Trabalho do motor na fila principal usa `mainAsync`. Detalhes em `docs/ARCHITECTURE.md`.

## Pendências abertas (fora da C2)

- **Programa para Pequenos Negócios da Apple (comissão 15%):** inscrição enviada em **22/11 ~18:35** (Apple: "Thank you for your submission"); a aprovação vem por e-mail. Sem ela a comissão é 30% (assinatura: 15% só a partir do 2º ano de cada assinante). Quando aprovar, registrar a data de início em `docs/PUBLICACAO.md` e conferir o líquido real no primeiro relatório de vendas. Nomes de exibição dos produtos no App Store Connect já são "Acesso permanente" (ele conferiu).
- **Calor real:** os avisos novos (espera de 60 s) e a redução só serão vistos com o aparelho quente; limites de redução esperam um Diagnóstico de dia quente. Preferência dele: redução automática **desligada** de fábrica e "régua" das reduções mais alta.
- **Faixa de espaço (v0.9.16):** falta ver no aparelho ou em testador.
- **Beta 1:** colher relatos (Diagnóstico por Compartilhar ou pela tela "Enviar feedback") e classificar em bug, ajuste ou ideia. **Decisão pendente dele:** levar uma versão mais nova ao grupo externo `Beta 1` (os testadores ainda estão na v0.9.13); build nova pode reiniciar a revisão de beta da Apple. Não gravar o link público no repositório.
- **Voz (área protegida, versão própria):** log só com mudanças do texto filtrado; três horários de falha de 15/11 tratados como indefinidos.
- **Adiadas por ele (ver `docs/MELHORIAS_FUTURAS.md` e `docs/arquivo/`):** foco ao trocar de lente; miniatura escura no Fotos; erro de áudio do player (OSStatus 561017449); teste longo da voz (≥ 30 min); teste de corte do iOS durante a gravação.
- **Condicionais (esperam dados do Beta, sem pressa):** B′ (calor crítico reduz 60→30 fps); limpeza do log de voz; 4K 60; botão "i"; simulador de calor/espaço no Diagnóstico. Detalhes em `docs/MELHORIAS_FUTURAS.md`.
- Antes da publicação: onda própria de reanálise de Termos e Políticas (advogado e contador).

## Notas operacionais

- **Repositório privado** (`Kenidy-WS/Ei-Clip-ios`; o endereço antigo redireciona). Em repositório privado a compilação macOS gasta 10x os minutos do plano (limite grátis 2.000/mês); o saldo só se vê em GitHub > Settings > Billing (não acessível do ambiente). `testflight.yml` roda ~2 a 5 min por execução.
- **Build TestFlight:** `gh api -X POST repos/Kenidy-WS/Ei-Clip-ios/actions/workflows/testflight.yml/dispatches -f ref=vX.Y.Z` (`gh workflow run` falha pelo proxy). O número da build = número da execução. Corrigir algo dentro de uma versão em teste gera só nova **build** (o Diagnóstico mostra "vX.Y.Z (N)"); funcionalidade nova ganha versão nova. **Fila de runner macOS:** o `tests` já foi cancelado depois de ~15 min na fila (23/11, duas vezes; "capacidade dos computadores macOS arm64 do GitHub"); não é erro de código, é só disparar de novo (funcionou na terceira).
- **GitHub pelo ambiente:** `gh` só por REST (`gh api`; GraphQL dá 403, então `gh repo view` e `gh release view` falham). Sem toolchain Swift: só o CI compila e roda `swift test`. Commit só de documentos leva `[skip ci]`.
- **Unir ao `main`:** `git merge --ff-only refs/heads/vX.Y.Z` quando o `main` não andou; se o `main` recebeu documentos em paralelo, usar `git merge --no-ff` (commit de união). Nome puro pega a tag antiga, por isso `refs/heads/`. Depois de unir, apagar o ramo local. Empurrar com `git push origin HEAD:refs/heads/vX.Y.Z`.
- **Ramos remotos:** o proxy não deixa apagar. Restam no GitHub `onda7-ev`, `v0.7.18` e `v0.9.0` a `v0.9.42` (já no `main`), além de `v0.9.43` e `v0.9.44` (ainda não unidos). Ele pode apagar os antigos em github.com/Kenidy-WS/Ei-Clip-ios/branches. Tags/releases `vX.Y.Z` só existem até a v0.9.9 (o `build.yml` as criava; agora é manual).
- **Web app de referência (somente leitura):** https://github.com/Kenidy-WS/clip (clonar raso para ler `src/core/` e `tests/`).
- **Diagnóstico:** `Application Support/Diagnostico/atual.txt` (rodada anterior em `anterior.txt`); Compartilhar gera o .txt; a fala de fundo não é gravada (v0.9.13). Linhas úteis nos testes de compra: `acesso confirmado`, `compras: assinatura`, `acesso:`, `meu plano:`, `rede:`, `assinaturas:`.

## Decisões que valem

- Textos do usuário: tom formal e claro; todo texto novo em `Engine/Textos.swift`. O Diagnóstico segue técnico.
- Bundle ID `app.eiclip` (permanente depois do registro na App Store Connect). Salvar sempre no álbum "Ei Clip" do Rolo (sem galeria própria de arquivos; a Galeria do app lista o álbum por PhotoKit).
- Padrão de fábrica 1080p60 Máxima 30 s; redução automática por calor desligada; crítico só avisa (a escolha dele vale), a reserva por falha da câmera reduz 2 passos.
- Posicionamento: o diferencial é a **gravação retroativa**, não a voz (`docs/PUBLICACAO.md`, seção 1, 15/11).
- Produtos: `app.eiclip.mensal` (R$ 9,90) e `.anual` (R$ 59,90) no grupo 22598306 (Anual nível 1, Mensal nível 2) e `.permanente` (R$ 179,90; lançamento R$ 149,90 por 30 dias); só Brasil; Compartilhamento em Família desligado.
- Contas e dinheiro: conta de desenvolvedor de pessoa física, recebimento em conta pessoal, contador confirmou (não MEI). Dados bancários e fiscais só no site da Apple, nunca no chat.

## Onde está o resto

- `docs/ROADMAP.md`: etapas e a fase atual. `docs/PUBLICACAO.md`: plano de publicação e compra (decisões, ondas P1 a P5 e C0 a C5, jurídico). `docs/PLANO_C2.md`: etapas da compra. `docs/TESTE_OFFLINE.md`: roteiro e lista dos testes offline. `docs/ARCHITECTURE.md`: como o app é feito. `docs/MELHORIAS_FUTURAS.md`: ideias adiadas. `docs/CONVITE_BETA.md`: texto do convite. `docs/AUDITORIA.md`, `docs/RELATORIO_JURIDICO_PACOTE_A.md`, `docs/TERMOS_MINUTA.md`: auditorias e jurídico. `docs/RETOMADA.md`: texto para abrir um chat novo. `docs/arquivo/`: histórico.
