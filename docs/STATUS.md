# Status

**Atualizado em:** 2026-11-20 · **Estável:** **v0.9.26** (TestFlight, aprovada em 20/11, unida ao `main`; fecha a **etapa 3 da C2**). Anteriores: v0.9.25, v0.9.21, v0.9.19. **Etapa:** pré-lançamento; Apple Negócios (C1) ativo; C2 (compra no app) em andamento, **nada bloqueado ainda** (modo sombra). **Próximo: C2 etapa 4** (gate ativo + tela "Escolha seu acesso"), só com o "pode seguir" dele. **Beta 1 (grupo externo):** 5 testadores na v0.9.13 (build 9); v0.9.14 em diante só no grupo interno.

**Proteção de moeda (v0.9.26):** `PriceCurrencyGuard` (Core) mostra `displayPrice` só se a moeda do produto for igual à da loja (`Storefront.currency`) ou se a da loja for desconhecida; se forem diferentes, botão "Ver preço" + linha "O valor é exibido pela App Store ao confirmar a compra." (a compra não muda). No TestFlight o catálogo vem em US$ com loja BRA/BRL e a transação sai em R$ (Sandbox); não se sabe se acontece na loja oficial.

**Pendências da C2:** (1) risco de revisão da Apple: preço e período visíveis no app, regra 3.1.2, links de privacidade e termos (conferir antes da C5; anotar nas notas de revisão); (2) Permanente sem teste (**não comprar com o Apple ID real**; usar outro Apple ID ou o fim da C3); (3) mover "Acesso" para cima de "Aparelho" nos Ajustes (etapa 5); (4) ícone da folha de resgate (ficha do app sem ícone no App Store Connect); (5) renovação do Anual no TestFlight terminava em 21/11 03:04: abrir o app depois e mandar o Diagnóstico.

Histórico completo (versão por versão, IPAs antigos do Sideloadly, lições): `docs/arquivo/` (`STATUS_ate_2026-11-19.md`, `STATUS_ate_2026-11-20.md`, `HISTORICO_ate_v0.9.5.md`, `ROADMAP_etapas_6_a_10.md`). Resumo das versões novas: `docs/HISTORICO.md`.

## Próximo passo (retomar aqui)

1. **C2 etapa 4**, só com o "pode seguir" dele. Etapas 4 a 7 e testes em `docs/PLANO_C2.md`; decisões em `docs/PUBLICACAO.md`, seção 1, "19/11/2026" (bloco "Decisões de 19/11 à noite") e 3.13; minuta dos Termos (base para advogado, não publicar) em `docs/TERMOS_MINUTA.md`. Regras resumidas: 10 clipes gratuitos no Keychain (UUID), só sem acesso pago; `AccessGate` (Core) chamado no início de `startRecording()`; todos os gatilhos (botão, voz, volume) abrem a escolha de acesso, sem clipe pendente; tela com cartões empilhados, botão fixo, nada pré-selecionado, Anual destacado; avisos laranja (sem vermelho) a partir do 7º clipe; permanente R$ 179,90 (lançamento R$ 149,90 por 30 dias, a confirmar no App Store Connect); tolerância offline de 7 dias na etapa 6 (prazo só aparece na interface na etapa 7); sem App Attest; "Abrir câmera" (Atalhos) mantida, fora dos textos de venda. Versões da C2 seguem 0.9.x (feitas: v0.9.18, v0.9.19, v0.9.22 a v0.9.26, mais v0.9.20/21 de reabertura da câmera).
2. **Antes de codar a etapa 4:** abrir a onda com passos e donos e mostrar o protótipo no artefato "Ei Clip: protótipo da etapa 4 (Escolha seu acesso)"; a tela reaproveita `PriceCurrencyGuard`; se o comando de voz precisar mudar, vira versão própria (área protegida).
3. **Decisão pendente dele:** levar uma versão mais nova ao grupo externo `Beta 1` (os testadores ainda estão na v0.9.13). Build nova pode reiniciar a revisão de beta da Apple. Não gravar o link público no repositório.
4. **Condicionais (esperam dados do Beta, sem pressa):** B′ (calor crítico reduz 60→30 fps); limpeza do log de voz (área protegida, versão própria); 4K 60; tutorial de primeira abertura e botão "i"; simulador de calor/espaço no Diagnóstico. Detalhes em `docs/MELHORIAS_FUTURAS.md`.

Antes da publicação: onda própria de reanálise de Termos e Políticas (advogado e contador).

## Fatos úteis (de 19/11)

- Padrão de fábrica 1080p60 Máxima, pré-gravação 30 s (`CaptureConfig.factoryDefault`); `CaptureConfig.standard` (1080p30) é o piso da redução por calor. O 4K fica sempre em 30 fps.
- Estimativa de espaço: (livre − 150 MB) ÷ ((taxa/8 + 24.000 B/s) × 2 cópias); "pouco espaço" em 1080p60 Máxima vale com menos de ~8 GB livres.
- Aviso de calor espera 60 s se o app abre já quente (`ThermalGovernor.quietOpening`); faixa de espaço na tela inicial (v0.9.16, ainda não vista no aparelho). Resumo das versões v0.9.14 a v0.9.17 e testes de calor A/B: `docs/arquivo/STATUS_ate_2026-11-20.md`.

## Versão estável (para voltar se uma nova quebrar)

- **Estável: v0.9.26** (20/11, fecha a C2 etapa 3). Anteriores: **v0.9.25** (diagnóstico de preços), **v0.9.21** (20/11, reabertura da câmera), depois **v0.9.19** (20/11, C2 etapa 2: contador em modo sombra). Só pelo TestFlight (sem IPA do Sideloadly desde a v0.9.9; o `build.yml` é manual). Para reenviar uma versão: ramo `vX.Y.Z` no GitHub + `testflight.yml` (ver "Notas operacionais"). O TestFlight guarda cada build por 90 dias.
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
