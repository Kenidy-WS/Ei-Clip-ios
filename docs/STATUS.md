# Status

**Atualizado em:** 2026-11-20 02:30 · **Estável:** **v0.9.21** (aprovada por ele em 20/11, ~00:30, TestFlight; inclui a v0.9.20; correções na reabertura da câmera ao voltar do segundo plano; contador no Keychain da v0.9.19 segue em modo sombra: 10 de 10 e "além dos 10" registrados sem bloquear) · **Em teste:** **v0.9.22** (build 147, no TestFlight em 20/11 ~02:30; C2 etapa 3: StoreKit 2 em modo sombra + página Acesso nos Ajustes; iOS mínimo 16.3; ele testa em 20/11 com o testador sandbox; ramo `v0.9.22` ainda não unido) · **Beta 1 (grupo externo):** 5 testadores na **v0.9.13 (build 9)**; as versões v0.9.14 a v0.9.17 só foram para o grupo interno · **Etapa:** pré-lançamento; Apple Negócios (C1) ativo; **próximo: C2 (compra no app)**, só com o "pode seguir" dele.

Histórico completo (versão por versão, IPAs antigos do Sideloadly, lições): `docs/arquivo/` (`STATUS_ate_2026-11-19.md`, `HISTORICO_ate_v0.9.5.md`, `ROADMAP_etapas_6_a_10.md`). Resumo das versões novas: `docs/HISTORICO.md`.

## Próximo passo (retomar aqui)

1. **C2 (compra no app): decisões fechadas em 19/11 à noite, SEM código ainda.** Resumo e detalhes em `docs/PUBLICACAO.md`, seção 1, "19/11/2026" (bloco "Decisões de 19/11 à noite"); etapas e testes em `docs/PLANO_C2.md`; minuta dos Termos (base para advogado, não publicar) em `docs/TERMOS_MINUTA.md`. Pontos-chave: 10 clipes no Keychain com UUID, só sem acesso pago, `AccessGate` no Core chamado em `startRecording()`; todos os gatilhos abrem a escolha de acesso; sem clipe pendente; tolerância offline opção B (período pago + 7 dias; prazo só aparece na interface depois de testado); cartões empilhados, botão fixo, nada pré-selecionado, Anual destacado; permanente R$ 179,90 (lançamento R$ 149,90 por 30 dias, mesmo ID, a confirmar no App Store Connect); sem App Attest; avisos laranja, sem vermelho; botão fixo desativado "Escolha um acesso"; ação "Abrir câmera" (Atalhos) mantida, sem destaque e sem entrar nos textos de venda. **Andamento:** plano aprovado em 19/11; **etapa 1 feita e aprovada (v0.9.18)**; **etapa 2 feita e aprovada (v0.9.19)**; **v0.9.20 e v0.9.21 feitas e aprovadas (correções isoladas)**: aviso "não foi possível abrir a câmera" ao voltar de segundo plano durante gravação (v0.9.20: 2ª tentativa após ~300 ms, aviso só se ela também falhar; v0.9.21: voltando rápido, `reopenAfterReturn` esperava `opened` já verdadeiro e gastava o pedido, deixando a tela da câmera congelada; agora espera o fechamento terminar, até 5 s; as duas falhas já vinham da v0.7.24, achadas no teste da etapa 2). **Próximo:** etapa 3 (StoreKit; ele cria produtos e testador sandbox no App Store Connect antes). As versões da C2 seguem a numeração 0.9.x. Os arquivos de docs desta rodada estão **sem commit** até a aprovação dele (regra dele em 19/11). Antes da publicação: onda própria de reanálise de Termos e Políticas.
2. **Decisão pendente dele:** levar a v0.9.17 ao grupo externo `Beta 1` (os testadores ainda estão na v0.9.13, com o padrão antigo). Build nova pode reiniciar a revisão de beta da Apple. Não gravar o link público no repositório.
3. **Condicionais (esperam dados do Beta, sem pressa):** B′ (calor crítico reduz 60→30 fps); limpeza do log de voz (área protegida, versão própria); 4K 60; tutorial de primeira abertura e botão "i"; simulador de calor/espaço no Diagnóstico. Detalhes em `docs/MELHORIAS_FUTURAS.md`.

## O que mudou em 19/11 (v0.9.14 a v0.9.17), resumo

- **Testes de calor A/B (20 min cada, local quente, sem sol, tripé):** A = 1080p60 Máxima; B = 1080p30. Bateria A 40%→33% (aos 10 e 20 min), B 31%→22%. Conclusão: 1080p60 Máxima com 30 s é viável no uso normal; calor ambiente forte e sol direto seguem como risco. Voz: com torneira ligada perto o 1º comando falhou (início e fim); ruído forte mascara a fala. Música baixa não dispara sozinha.
- **v0.9.14:** padrão de fábrica 1080p60 Máxima, pré-gravação 30 s (`CaptureConfig.factoryDefault`, `BufferWindow.defaultSeconds = 30`; vale para quem nunca escolheu nos Ajustes, inclusive quem já tem o app). `CaptureConfig.standard` (1080p30 Padrão) segue como piso da redução por calor e gabarito dos testes. Diagnóstico da instalação limpa: 35 Mbps, 59,4 quadros/s, 0 erros do codificador.
- **v0.9.15:** se o app abre já "quente" (não crítico), o aviso espera 60 s e só vem se ainda estiver quente (`ThermalGovernor.quietOpening`, `openingQuietSec = 60`); crítico avisa na hora; esfriar cancela; redução automática (desligada de fábrica) não muda. Diagnóstico registra `aviso adiado por 60 s`. Não simulado no aparelho (só testes automáticos).
- **v0.9.16:** faixa fixa de espaço na tela inicial (amarela < 15 min, vermelha < 3 min de gravação, só texto, sem botão, **não bloqueia a câmera**); minutos pela qualidade escolhida, atualizados ao aparecer, ao voltar do segundo plano e a cada 10 s (`StorageRules.banner`). O aviso temporário da câmera fica 10 s e o Início esconde a cópia duplicada. Desenho aprovado por protótipo no artefato "Ei Clip: aviso fixo de espaço na tela inicial". **A faixa ainda não foi vista no aparelho** (ele tem muito espaço livre): conferir no Diagnóstico `espaço: POUCO/QUASE ESGOTADO` quando alguém chegar perto do limite.
- **v0.9.17:** Ajustes marcam a pré-gravação que vale (ex.: 30 s em 4K) e guardam a escolha (60 s), que volta ao voltar para 1080p.
- **Fatos úteis:** o 4K fica sempre em 30 fps (`validated()`); a estimativa de espaço é (livre − 150 MB) ÷ ((taxa/8 + 24.000 B/s) × 2 cópias); "pouco espaço" com 1080p60 Máxima vale com menos de ~8 GB livres.

## Versão estável (para voltar se uma nova quebrar)

- **Estável: v0.9.21** (20/11, correções da reabertura da câmera). Anterior: **v0.9.19** (20/11, C2 etapa 2: contador em modo sombra). Só pelo TestFlight (sem IPA do Sideloadly desde a v0.9.9; o `build.yml` é manual). Para reenviar uma versão: ramo `vX.Y.Z` no GitHub + `testflight.yml` (ver "Notas operacionais"). O TestFlight guarda cada build por 90 dias.
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
