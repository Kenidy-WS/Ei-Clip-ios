# Status

**Atualizado em:** 2026-11-26 (20:30) · **Estável (no `main`): v0.9.49** (build 73; contém v0.9.43 a v0.9.49) · **Etapa:** pré-lançamento; Apple Negócios (C1) ativo; C2 (compra no app) **concluída no código e provada no aparelho**; **C3 em andamento: Beta 2** · **Beta 2:** a build **0.9.49 (73)** foi adicionada em 26/11, ~20:20, ao grupo externo `Beta 1` (mesmos 5 testadores, que estavam na v0.9.13) e está **em revisão da Apple**.

Resumo das versões: `docs/HISTORICO.md`. Detalhe antigo deste arquivo (até 26/11): `docs/arquivo/STATUS_ate_2026-11-26.md` e os anteriores em `docs/arquivo/`.

## Próximo passo (retomar aqui)

1. **Beta 2 (C3):** esperar a revisão da Apple. Quando liberar, os testadores recebem a 0.9.49 (aviso curto em "O que testar", texto em `docs/CONVITE_BETA.md`). Colher Diagnósticos e feedbacks (o feedback já leva a rodada anterior do log); ler, dizer "passou" ou "falhou, e por quê" e classificar em bug, ajuste ou ideia.
2. **Permanente: teste ADIADO (27/11, decisão dele).** Ele **não** compra o Permanente de teste no aparelho dele, para poder simular assinaturas depois (com o Permanente ativo, o bloqueio por "assinatura terminou" ficaria mascarado). Fica para um testador do Beta 2 com Apple ID próprio ou para a primeira build de produção (C5). Reembolso/revogação: só testes automáticos (leitura do código em 26/11: Permanente revogado vira "Acesso reembolsado ou revogado", sem tolerância). Próxima onda sugerida: texto grande, deitado e VoiceOver nas telas de planos e Meu plano (ainda não feita).
3. **Termos** com advogado e contador (incluir a frase do que cada plano entrega; plano B: lançar só com Permanente se a Apple recusar a assinatura), depois **C4** (campanhas) e **C5** (envio e revisão da Apple). Detalhes: `docs/PLANO_C2.md`, `docs/PUBLICACAO.md` (seções 1 e 2), `docs/TERMOS_MINUTA.md`.
4. **4K 60 fps (decidido 27/11):** ele quer **antes do lançamento**, como versão própria **depois do Beta 2** e com dados de calor (`docs/MELHORIAS_FUTURAS.md`). Hoje o 4K é fixo em 30 fps.
5. Nada de versão nova sem o "pode seguir" dele. Correções que o Beta 2 pedir viram versões próprias.

**Mapa das versões recentes (todas no `main`, provadas no aparelho, salvo onde dito):**

| Versão | O que é |
| ------ | ------- |
| v0.9.43 | Permanente guardado sem rede fica liberado **sem prazo**. Só testes automáticos (não dá para provar sem Permanente) |
| v0.9.44 | Etapa 7: prazo de 7 dias no Meu plano ("Assinatura não confirmada" com data e hora), botão "Verificar novamente" (25/11) |
| v0.9.45 | Relê a assinatura sozinho quando a internet volta com o app aberto (`NetworkReturnRules`) (26/11) |
| v0.9.46 | Tela de planos sem internet: "Verifique a conexão" + "Tentar novamente" (`ProductsLoadRules`); texto visto na tela em 26/11 18:46 |
| v0.9.47 | Remove a simulação "Só para teste" (`AccessSimulation`); sem mudança de regra |
| v0.9.48 | Marca TestFlight x loja nos registros do Keychain (`EnvironmentRules`, `AppEnvironment`); na loja descarta o que veio do TestFlight (contador volta a 0, "permanente" de teste some). O descarte só aparece na versão da loja: no TestFlight prova-se que nada é perdido; conferir na primeira build de produção (C5) a linha "registro gravado no TestFlight descartado" |
| v0.9.49 | "Enviar feedback" leva também o fim da rodada anterior do log (até 300 KB, linhas inteiras, aviso de corte). O app guarda só 1 rodada anterior |

**Pendências menores (sem versão):** relógio adiantado/atrasado (por último; avanço de no máximo 5 dias; suja a "maior data vista"); reinstalar offline; restaurar backup; registrar em `docs/PUBLICACAO.md` a data de início da comissão de 15% quando a Apple aprovar o Small Business.

## Estado da C2 (compra no app)

- **No código:** gate de 10 clipes (`AccessGate`), StoreKit 2, tela "Escolha seu acesso", chip e avisos, Meu plano, resultado da compra, tolerância offline de 7 dias (último acesso confirmado no Keychain + proteção de relógio), tutorial (v0.9.35), resumo do Meu plano e Ajuda (v0.9.36), "Enviar feedback" (v0.9.40), ambiente do Keychain (v0.9.48).
- **Regra offline (v0.9.39 a v0.9.46):** sem rede o StoreKit responde pelo cache e pode dizer "terminou" ou devolver lista vazia mesmo com assinatura paga. Esses casos valem como **não confirmada**: acesso até o fim do último período confirmado + 7 dias. Permanente guardado sem rede fica liberado **sem prazo**. Só resposta válida da Apple com rede bloqueia na hora. `StoreTrustRules` (Core), `NetworkPathWatcher` (Engine); ver `docs/ARCHITECTURE.md`.
- **Provado no aparelho:** renovando, cancelada, encerrada, teste grátis, resultado da compra (aprovada, nenhuma compra nova, erro sem internet), online + expirada bloqueia, cancelada + offline depois do fim bloqueia (B), offline com renovação ligada libera por tolerância (A), lista vazia offline com leitura velha, fim natural offline com gravação e texto do Meu plano, releitura ao voltar a internet, tela de planos sem internet, Keychain sobrevive ao fechar o app, ambiente "TESTE" marcado. Lista e resultados: `docs/TESTE_OFFLINE.md`.
- **Só em testes automáticos:** Permanente (com ou sem assinatura, offline), carência, nova tentativa, revogada, em análise, troca real de loja/conta, descarte de registro de teste na loja. `StoreManager` e o resto do Engine não têm teste automático (só prova no aparelho).
- **Sandbox/TestFlight:** compras são de teste (Diagnóstico mostra `ambiente Sandbox`), não cobram e não valem na loja; a renovação acontece 1 vez por dia (até ~6), perto das 10:31. A conta Sandbox não entra no iPhone sem Mac. Avisar isso aos testadores.
- **Contador de clipes grátis:** fica no Keychain e sobrevive à reinstalação; **na versão da loja zera** (decisão dele, 26/11; feito na v0.9.48). Para testar o limite de 10 agora só gastando os 10 grátis.
- **Moeda:** `PriceCurrencyGuard` (Core) mostra o preço só se a moeda do produto for igual à da loja. O catálogo do TestFlight alterna entre US$ e R$ sem causa conhecida; conferir na loja oficial (C5).

**Pendências da C2:** (1) risco de revisão da Apple: preço e período visíveis, regra 3.1.2, links de privacidade e termos, notas de revisão (conferir antes da C5); (2) itens sem conferência: texto grande, VoiceOver e câmera deitada na tela de planos; gravação em andamento quando o acesso vence; código de oferta resgatado; (3) a tela da Apple (Sandbox) mostrou 21/11 e o app 22/11 03:04 (suspeita de fuso do Sandbox); (4) preço de lançamento do Permanente (Temporary Price Change, agendar só perto do lançamento); (5) ícone da folha de resgate (ficha do app sem ícone no App Store Connect). **Lição (22/11):** conferir o protótipo aprovado contra o que foi codado antes de dar uma etapa de tela por fechada.

## Versão estável (para voltar se uma nova quebrar)

- **Estável: v0.9.49** (26/11, no `main` com o OK dele; build 73).
- Anteriores: v0.9.48, v0.9.47, v0.9.46, v0.9.42 (24/11), v0.9.38 (22/11), v0.9.34, v0.9.32, v0.9.29, v0.9.28, v0.9.27, v0.9.26, v0.9.25, v0.9.21, v0.9.16 a v0.9.14 (19/11), v0.9.13 (17/11, Beta 1, build 9). Notas de cada uma: `docs/HISTORICO.md`; IPAs antigos: `docs/arquivo/STATUS_ate_2026-11-19.md`.
- Só pelo TestFlight (o `build.yml` de IPA é manual e vira reserva). Para reenviar uma versão: ramo `vX.Y.Z` no GitHub + `testflight.yml`. O TestFlight guarda cada build por 90 dias.
- Regra: uma versão só vira "estável" depois de testada no aparelho e com o OK dele; este bloco é atualizado nesse momento.

## Regras de tela que ficam (lição do travamento, v0.6.17 a v0.6.26)

- Não publicar (`@Published`) estado novo enquanto a câmera é reconfigurada, nem mudar `.disabled`/`.opacity` de vários botões de uma vez nesse momento (travou a tela no iOS 27.0.1). Estado novo da tela só em resposta a toque, ou lendo o que já existe. Trabalho do motor na fila principal usa `mainAsync`. Detalhes em `docs/ARCHITECTURE.md`.

## Pendências abertas (fora da C2)

- **Small Business Program (comissão 15%):** inscrição enviada em **22/11 ~18:35**; a aprovação vem por e-mail. Sem ela a comissão é 30% (assinatura: 15% só a partir do 2º ano de cada assinante). Ao aprovar, registrar a data em `docs/PUBLICACAO.md` e conferir o líquido no primeiro relatório de vendas.
- **Calor real:** os avisos novos (espera de 60 s) e a redução só serão vistos com o aparelho quente; limites esperam um Diagnóstico de dia quente. Preferência dele: redução automática **desligada** de fábrica e "régua" mais alta.
- **Faixa de espaço (v0.9.16):** falta ver no aparelho ou em testador.
- **Voz (área protegida, versão própria):** log só com mudanças do texto filtrado; no Diagnóstico de 26/11 a voz ficou 12 e 40 s sem texto com som no microfone e voltou sozinha (comportamento do iOS, já registrado no log).
- **Adiadas por ele (ver `docs/MELHORIAS_FUTURAS.md`):** foco ao trocar de lente; miniatura escura no Fotos; erro de áudio do player (OSStatus 561017449); teste longo da voz (≥ 30 min); teste de corte do iOS durante a gravação.
- **Condicionais (esperam dados do Beta):** B′ (calor crítico reduz 60→30 fps); limpeza do log de voz; 4K 60 (**vai antes do lançamento**, 27/11); botão "i"; simulador de calor/espaço.
- Antes da publicação: onda própria de reanálise de Termos e Políticas (advogado e contador). Não gravar o link público do TestFlight no repositório.

## Notas operacionais

- **Repositório privado** (`Kenidy-WS/Ei-Clip-ios`; o endereço antigo redireciona). A compilação macOS gasta 10x os minutos do plano (limite grátis 2.000/mês); o saldo só se vê em GitHub > Settings > Billing. `testflight.yml` roda ~2 a 5 min.
- **Build TestFlight:** `gh api -X POST repos/Kenidy-WS/Ei-Clip-ios/actions/workflows/testflight.yml/dispatches -f ref=vX.Y.Z` (`gh workflow run` falha pelo proxy). Número da build = número da execução (v0.9.49 = 73). A Apple leva ~5 a 30 min para processar depois do envio. Corrigir algo dentro de uma versão em teste gera só nova **build**; funcionalidade nova ganha versão nova. **Fila macOS:** o `tests` às vezes é cancelado depois de ~15 min (falta de computador); não é erro de código, disparar de novo.
- **GitHub pelo ambiente:** `gh` só por REST (GraphQL dá 403). Sem toolchain Swift: só o CI compila e roda `swift test`. Commit só de documentos leva `[skip ci]`.
- **Unir ao `main`:** `git merge --ff-only refs/heads/vX.Y.Z` quando o `main` não andou; se o `main` recebeu documentos em paralelo, `git merge --no-ff refs/remotes/origin/vX.Y.Z` (commit de união, como na v0.9.47 a v0.9.49). Nome puro pega a tag antiga, por isso `refs/`. **Antes de editar documentos, confirmar com `git branch --show-current` que está no `main`** (em 26/11 um `checkout` falhou em silêncio por haver mudança local). Depois de unir, apagar o ramo local.
- **Ramos remotos:** o proxy não deixa apagar. Restam no GitHub `onda7-ev`, `v0.7.18` e `v0.9.0` a `v0.9.49` (todos já no `main`); ele pode apagar os antigos em github.com/Kenidy-WS/Ei-Clip-ios/branches. Tags/releases só existem até a v0.9.9.
- **Web app de referência (somente leitura):** https://github.com/Kenidy-WS/clip.
- **Diagnóstico:** `Application Support/Diagnostico/atual.txt` (rodada anterior em `anterior.txt`); Compartilhar gera o .txt; a fala de fundo não é gravada. Linhas úteis: `ambiente`, `contador`, `acesso confirmado`, `compras: assinatura`, `acesso:`, `meu plano:`, `rede:`, `assinaturas:`.

## Decisões que valem

- Textos do usuário: tom formal e claro; todo texto novo em `Engine/Textos.swift`. O Diagnóstico segue técnico.
- Bundle ID `app.eiclip` (permanente depois do registro na App Store Connect). Salvar sempre no álbum "Ei Clip" do Rolo (sem galeria própria de arquivos).
- Padrão de fábrica 1080p60 Máxima 30 s; redução automática por calor desligada; crítico só avisa, a reserva por falha da câmera reduz 2 passos.
- Posicionamento: o diferencial é a **gravação retroativa**, não a voz (`docs/PUBLICACAO.md`, seção 1, 15/11).
- Produtos: `app.eiclip.mensal` (R$ 9,90) e `.anual` (R$ 59,90) no grupo 22598306 (Anual nível 1, Mensal nível 2) e `.permanente` (R$ 179,90; lançamento R$ 149,90 por 30 dias); só Brasil; Compartilhamento em Família desligado.
- Contas e dinheiro: conta de desenvolvedor de pessoa física, recebimento em conta pessoal, contador confirmou (não MEI). Dados bancários e fiscais só no site da Apple, nunca no chat.
- Beta 2 (26/11): mesmo grupo externo do Beta 1, app completo (inclui Permanente); compras de teste, avisadas aos testadores. Versões de teste podem ir aos testadores porque tudo é revalidado na versão oficial.

## Onde está o resto

- `docs/ROADMAP.md`: etapas e fase atual. `docs/PUBLICACAO.md`: plano de publicação e compra (decisões, ondas P1 a P5 e C0 a C5, jurídico). `docs/PLANO_C2.md`: etapas da compra. `docs/TESTE_OFFLINE.md`: roteiro e resultados dos testes offline. `docs/ARCHITECTURE.md`: como o app é feito. `docs/MELHORIAS_FUTURAS.md`: ideias adiadas. `docs/CONVITE_BETA.md`: textos do convite e do Beta 2. `docs/AUDITORIA.md`, `docs/RELATORIO_JURIDICO_PACOTE_A.md`, `docs/TERMOS_MINUTA.md`: auditorias e jurídico. `docs/RETOMADA.md`: texto para abrir um chat novo. `docs/arquivo/`: histórico.
