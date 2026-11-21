# Status

**Atualizado em:** 2026-11-21 · **Estável:** **v0.9.27** (TestFlight, aprovada em 21/11, unida ao `main`; fecha a **etapa 4 da C2**: gate ativo, tela "Escolha seu acesso", chip na Home, avisos na câmera, "Meu plano"). Anteriores: v0.9.26, v0.9.25, v0.9.21, v0.9.19. **Etapa:** pré-lançamento; Apple Negócios (C1) ativo; C2 (compra no app) em andamento: **o gate já bloqueia** a gravação após 10 clipes gratuitos sem acesso pago. **Próximo: v0.9.28** (folha de Ajustes só com o tamanho de 580 pt, sem a opção de tela cheia: o redesenho piscava) e depois **etapa 5a**. **Beta 1 (grupo externo):** 5 testadores na v0.9.13 (build 9); v0.9.14 em diante só no grupo interno.

**Moeda (v0.9.26/27):** `PriceCurrencyGuard` (Core) mostra `displayPrice` só se a moeda do produto for igual à da loja. Em 21/11 o catálogo do TestFlight passou a vir em **BRL** (loja BRA): preços R$ 9,90 / 59,90 / 179,90 aparecem normalmente, validado no aparelho (antes vinha em US$).

**Simulação de teste (v0.9.27):** `AccessSimulation` (Ajustes > Meu plano, grupo de teste; some ao fechar o app) finge "sem acesso pago" com N clipes usados e pode mostrar preços do catálogo. **Remover antes do Beta público** (etapa 7).

**Pendências da C2:** (1) risco de revisão da Apple: preço e período visíveis, regra 3.1.2, links de privacidade e termos (conferir antes da C5; anotar nas notas de revisão); (2) Permanente sem teste (**não comprar com o Apple ID real**); (3) **teste de compra real, sem simulação:** a assinatura de teste renova sozinha (Mensal até 22/11 03:04); ele tenta limpar o Sandbox pelo iPhone ou por IPA; (4) achado para a **5b:** comprar Mensal com o Anual ativo só **agenda** a troca para a renovação (a Apple mostra "Você já é assinante…"); tratar texto e estado; (5) risco da etapa 6: assinante abrindo o app offline sem `LastConfirmed` salvo e com 10 clipes usados pode ver a tela de planos; (6) "Compra em análise" e o preço de lançamento do Permanente (não está no App Store Connect) sem teste; (7) ícone da folha de resgate (ficha do app sem ícone no App Store Connect).

Histórico completo (versão por versão, IPAs antigos do Sideloadly, lições): `docs/arquivo/` (`STATUS_ate_2026-11-19.md`, `STATUS_ate_2026-11-20.md`, `HISTORICO_ate_v0.9.5.md`, `ROADMAP_etapas_6_a_10.md`). Resumo das versões novas: `docs/HISTORICO.md`.

## Próximo passo (retomar aqui)

1. **v0.9.28:** `presentationDetents([.height(580)])` nos Ajustes (sem `.large`); páginas altas rolam dentro da folha. Depois **C2 etapa 5a** (Engine, só leitura: assinatura mesmo com permanente, `willAutoRenew`/`autoRenewPreference`, carência × nova tentativa, Diagnóstico; `AccessGate` não muda) e **5b** (Meu plano, troca agendada, "Cancelada" ≠ "Encerrada", gestos nas telas novas). Cada uma só com o "pode seguir". Detalhes em `docs/PLANO_C2.md`; decisões em `docs/PUBLICACAO.md` (19/11 e 3.13); minuta dos Termos em `docs/TERMOS_MINUTA.md`.
2. **Design aprovado (v0.9.27):** anel/rádio amarelo `#ffd60a` na seleção, ícones de benefícios amarelos, vermelho só para falha de compra, verde só para acesso confirmado; "Acesso permanente" (nunca "vitalício"); texto legal mínimo 12 pt; botão X sobre o canto; gestos por `.edgeGestures`.
3. **Teste de tela bloqueada:** com o app em segundo plano a câmera e a voz fecham, então nenhum gatilho dispara (log de 21/11 confirma).
4. **Decisão pendente dele:** levar uma versão mais nova ao grupo externo `Beta 1` (os testadores ainda estão na v0.9.13). Build nova pode reiniciar a revisão de beta da Apple. Não gravar o link público no repositório.
5. **Condicionais (esperam dados do Beta, sem pressa):** B′ (calor crítico reduz 60→30 fps); limpeza do log de voz (área protegida, versão própria); 4K 60; tutorial de primeira abertura e botão "i"; simulador de calor/espaço no Diagnóstico. Detalhes em `docs/MELHORIAS_FUTURAS.md`.

Antes da publicação: onda própria de reanálise de Termos e Políticas (advogado e contador).

## Fatos úteis (de 19/11)

- Padrão de fábrica 1080p60 Máxima, pré-gravação 30 s (`CaptureConfig.factoryDefault`); `CaptureConfig.standard` (1080p30) é o piso da redução por calor. O 4K fica sempre em 30 fps.
- Estimativa de espaço: (livre − 150 MB) ÷ ((taxa/8 + 24.000 B/s) × 2 cópias); "pouco espaço" em 1080p60 Máxima vale com menos de ~8 GB livres.
- Aviso de calor espera 60 s se o app abre já quente (`ThermalGovernor.quietOpening`); faixa de espaço na tela inicial (v0.9.16, ainda não vista no aparelho). Resumo das versões v0.9.14 a v0.9.17 e testes de calor A/B: `docs/arquivo/STATUS_ate_2026-11-20.md`.

## Versão estável (para voltar se uma nova quebrar)

- **Estável: v0.9.27** (21/11, fecha a C2 etapa 4). Anteriores: **v0.9.26** (moeda), **v0.9.25**, **v0.9.21**, **v0.9.19**. Só pelo TestFlight (o `build.yml` de IPA é manual e vira reserva). Para reenviar uma versão: ramo `vX.Y.Z` no GitHub + `testflight.yml`. O TestFlight guarda cada build por 90 dias.
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
