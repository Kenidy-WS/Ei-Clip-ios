# Roadmap por etapas

Uma etapa por vez. Cada etapa tem **critérios medidos**; só avança se todos baterem. Se algum falhar, paramos e escolhemos o caminho juntos (sem contornar).

## Regras (para o Kenidy acompanhar)

1. **Número da versão mostra a etapa:** etapa N = `v0.N.x`. Etapa 1 = `v0.1.0`, `v0.1.1`…; etapa 2 = `v0.2.0`…
2. **Uma mudança por versão**, com commit "vX.Y.Z: o que mudou". A versão aparece no app (Diagnóstico).
3. **Toda entrega termina igual:** (a) o que mudou, (b) o que testar no iPhone (lista numerada curta), (c) o que copiar do Diagnóstico, (d) o próximo passo.
4. **Estado sempre em `docs/STATUS.md`** (versão, etapa, próximo passo, o que falta testar); o que já foi feito fica em `docs/HISTORICO.md` (resumo) e em `docs/arquivo/`. Este arquivo só muda quando o plano muda.

## Etapas

| Etapa | O que entrega | Critério de aprovação | Estado |
| ----- | ------------- | --------------------- | ------ |
| 0 — Preparação | Repositório, CI, instalação no iPhone | App "olá" compilado, instalado e aberto | **Concluída** (05/11) |
| 1 — Motor mínimo | Câmera 1080p30 + mic, buffer retroativo, gravar/parar, bipe, Rolo, Diagnóstico | (a) 20 aberturas, 0 microfones mudos · (b) clipe começa ±1 s do pré-tempo · (c) 5 min gravam e salvam sem travar · (d) áudio e vídeo em sincronia | **Em teste** (`v0.1.8`; a passou na v0.1.4; b, c, d passaram na v0.1.0, a refazer na versão final; defeito do arquivo que falhava ao começar corrigido na v0.1.6, 11 de 11 clipes salvaram) |
| 2 — Voz | Palavra de ativação (SFSpeechRecognizer pt-BR), 3 palavras | Taxa de acerto em 50 falas (perto, com ruído) · falsos disparos em 5 min de conversa · voz + bipe sem chiado | **Aprovada pelo Kenidy em 05/11 com ressalvas** (`v0.2.4`): falsos disparos 0 em 6 min (passou); bipe sem chiado (ouvido do Kenidy, 7 clipes); acertos: rodada solta sem contagem exata, aceita por ele no lugar das 50 falas contadas; as 3 palavras escolhíveis e testadas na `v0.2.5` (12 de 12 comandos); **falta só:** exercitar o religar do reconhecedor (espera longa em Comando) |
| 3 — Interface | Início, Câmera, Ajustes iguais ao web app; em pé e deitado | Igual ao web app nas telas e textos; funciona nas duas orientações | **Fechada** em 05/11 (tudo validado até `v0.3.12`: Início, Recentes, Câmera, gesto de borda, Ajustes, voz com a câmera, orientação, Diagnóstico completo, "ouvi" verde e revisão de textos) |
| 4 — Galeria e gestos | Galeria dentro do app (só os clipes do álbum "Ei Clip"), player, seleção em lote, transições de tela e gestos de arrastar, idênticos ao web app | Cada tela, efeito e gesto igual ao web app, validado no iPhone | **Fechada** em 05/11 (`v0.4.17`: Galeria, player, seleção em lote, gestos, transições e som do player, tudo validado no iPhone) |
| 5 — Refatoração | Sem recurso novo: navegação como regra pura (Core), gesto de borda nativo, player em partes, miniaturas com cache, preferências num lugar só, captura parametrizável, CI com relatório | Diagnóstico antes e depois igual (câmera abre em < 450 ms, 0 quadros descartados, pico do microfone > 0,0008, voz religando); cada versão `v0.5.x` com uma mudança só | **Fechada** em 05/11 (`v0.5.0` a `v0.5.8`, validada no iPhone na `v0.5.8`) |
| 6 — Recursos da câmera (antiga etapa 5) | Gravação longa direta, 4K30/1080p60, troca de lentes (ultra-angular), frontal, nível, foco por toque, estabilização, recuperação | Cada item validado no iPhone | **Feita e em teste** (`v0.6.0` a `v0.6.13`, CI verde; falta validar no iPhone, só a última é entregue) |
| 7 — Acabamento da câmera (Onda 7) | Topo novo (v0.7.1), lentes fluidas, flash, valor real na faixa; EV por último, isolado no ramo `onda7-ev` | Cada versão sem travar a tela (20 trocas de lente seguidas) e o item funcionando no aparelho | **Em andamento (06/11): v0.7.15 estável; falta só o EV (v0.7.16, ramo `onda7-ev`)** |
| 8 — Polimento (Onda 8) | Sem funções novas: melhorar o que já existe (calor menos sensível, Ajustes organizado, tempos, textos) | Cada versão testada no aparelho, sem regressão na câmera, voz e Galeria | **Fechada em 07/11, 14:25** (v0.8.8 estável final; foco na troca de lente, miniatura escura e erro de áudio do player adiados por ele) |
| 9 — Zoom por pinça (Onda 9) | Pinça contínua de 0,5× a 6×, com a troca de lente automática; v0.9.0 parada, v0.9.1 gravando | Pinça fluida sem travar a tela; mesma imagem e áudio dos clipes de antes | **Fechada em 07/11, ~14:44** (v0.9.1 estável: pinça parada e gravando validadas no aparelho) |

Fora do escopo agora: Android. Publicação na App Store (conta, compra, TestFlight, códigos de oferta): plano em `docs/PUBLICACAO.md`, ainda não iniciado (depende do "pode seguir" dele).

## Princípios (acordados com o Kenidy em 05/11)

1. **O web app é a régua de paridade, não o limite.** Serve de base e de referência de produto; onde o nativo permite algo melhor, fazemos o melhor. Nem tudo precisa ser idêntico. Cada decisão já tomada "por ser igual ao web app" entra na revisão abaixo.
2. **Onda de refatoração própria** (qualidade e desempenho do código), depois de uma auditoria só de leitura que o Kenidy aprova antes de qualquer mudança. Mexer em área protegida (áudio e voz) segue indo sozinho numa versão, sem mudar comportamento, conferido pelo Diagnóstico.
3. **Recursos que só o nativo traz (foco, estabilização, lentes, 4K60, recuperação) vêm logo depois da Galeria**, para testar cedo o que nunca tivemos contato, em vez de deixar para o fim.

Ordem combinada: etapa 4 fechada → auditoria feita em 05/11 (`docs/AUDITORIA.md`) → aprovação do Kenidy → etapa 5 (refatoração, `v0.5.x`) → etapa 6 (recursos do nativo, `v0.6.x`; a antiga etapa 5). Numeração aprovada pelo Kenidy em 05/11: refatoração = etapa 5, recursos da câmera = etapa 6.

## Paridade de opções com o web app (pedido do Kenidy: ter TODAS as possibilidades)

Conferido no `index.html` do web app (Ajustes e tela da câmera). Cada opção entra na etapa indicada.

| Opção do web app | Onde fica | Etapa |
| ---------------- | --------- | ----- |
| Buffer 15 / 30 s | Ajustes (principal) | motor já tem (v0.1.0); tela de Ajustes na 3 |
| Sons de gravação (bipe) ligado/desligado | Ajustes > Sons | motor e opção provisória na v0.1.1; tela na 3 |
| Sons no vídeo (bipe gravado no clipe) | Ajustes > Sons | motor e opção provisória na v0.1.1; tela na 3 |
| Comando de voz ligado/desligado | Ajustes > Comando de voz | 2 |
| Palavra de ativação (Ei Clip / Câmera, ação / Ei Câmera) | Ajustes > Comando de voz | 2 |
| Resolução 720p / 1080p / 4K | Ajustes (principal) | motor na 5; tela na 3 |
| Fluidez 30 / 60 fps (4K só 30) | Ajustes (principal) | motor na 5; tela na 3 |
| Qualidade de imagem Padrão / Alta / Máxima | Ajustes (principal) | motor na 5; tela na 3 |
| Nível (linha do horizonte) | Ajustes > Câmera | 5 |
| Espelhar frontal | Ajustes > Câmera | 5 |
| Lente 0,5× / 1× e trocar câmera | Tela da câmera | 5 (botões na 3) |
| Informações (detalhes do clipe) | Ajustes | decidir na 3 (o clipe fica no Rolo; talvez só o último) |
| Gravação longa em disco (liga/desliga) | Ajustes > Armazenamento | **não precisa:** o nativo já grava direto num arquivo |
| Em uso (armazenamento) e Diagnóstico | Ajustes > Armazenamento | Diagnóstico já existe; "Em uso" decidir na 3 |

Melhorias que só o nativo permite (a incluir): foco por toque, estabilização, 4K60 de verdade, recuperação se o app fechar gravando (etapa 6). Outras ideias ficam em `docs/MELHORIAS_FUTURAS.md`.

## Ritmo prático

- **Você testa e cola o Diagnóstico**; eu leio, comparo com o critério e digo "passou" ou "falhou, e por quê".
- O teste principal é pelo **TestFlight** (`testflight.yml`, disparo manual); o Sideloadly ficou só como reserva.
- **Área protegida** (voz e sessão de áudio): mudanças vão sozinhas numa versão.

Detalhes das etapas 6 a 10 (escopo, andamento, pendências de 05 a 10/11): `docs/arquivo/ROADMAP_etapas_6_a_10.md`.

## Fase atual: pré-lançamento (novembro/2026)

| Bloco | O que entrega | Estado (24/11) |
| ----- | ------------- | -------------- |
| Versões v0.9.6 a v0.9.13 | Bundle ID `app.eiclip`, privacidade, Compartilhar no Diagnóstico, calor (a escolha vale; reserva por falha da câmera), voz sem fala de fundo no log | **Estáveis** (v0.9.13 no Beta 1) |
| v0.9.14 | Padrão de fábrica 1080p60 Máxima, pré-gravação 30 s | **Estável** (19/11) |
| v0.9.15 | Aviso de calor espera 60 s quando o app abre já quente | **Estável** (19/11) |
| v0.9.16 | Faixa fixa de espaço (amarela < 15 min, vermelha < 3 min) na tela inicial | **Estável** (19/11); faixa ainda sem teste real |
| v0.9.17 | Ajustes marcam a pré-gravação que vale (30 s em 4K) e guardam a escolha | **Estável** (19/11) |
| P1 a P5 (publicação) | Conta, TestFlight, Beta 1 (`docs/PUBLICACAO.md`, seção 2) | P1 a P5 feitas; Beta 1 com 5 testadores (build 9) |
| C0, C1 | Planejamento comercial; Apple Negócios ativo | **Concluídas** (C1 em 19/11) |
| C2 (etapas 1 a 6) | Gate de 10 clipes grátis, StoreKit 2, tela "Escolha seu acesso", chip e avisos, "Meu plano" final, leitura da assinatura, tolerância offline, resultado da compra (v0.9.18 a v0.9.34) | **Estáveis**; a tolerância offline teve correções em v0.9.39 a v0.9.43 (abaixo) |
| v0.9.28 | Folha de Ajustes só com 580 pt, sem tela cheia (sem piscar) | **Estável** (21/11) |
| v0.9.29 | C2 etapa 5a: leitura da assinatura com permanente, renovação, carência x nova tentativa, releitura ao trocar a loja (Engine, sem tela) | **Estável** (21/11) |
| v0.9.30 a v0.9.32 | Aviso de espaço e "loja mudou" (v0.9.30); C2 etapa 5b, Meu plano final (v0.9.31); aviso de rolagem e folha de 640 pt (v0.9.32) | **Estáveis** (22/11) |
| v0.9.33 e v0.9.34 | Texto "até 60 segundos" + C2 etapa 6, tolerância offline com último acesso no Keychain (v0.9.33); resultado da compra em folha própria (v0.9.34) | **Estáveis** (22/11) |
| v0.9.35 a v0.9.38 | Tutorial de primeiro acesso (v0.9.35); resumo do Meu plano e Ajuda (v0.9.36); marca na tela de compra (v0.9.37); "Acesso permanente" e rodapé novo (v0.9.38) | **Estáveis** (22/11; v0.9.38 era a estável até 24/11) |
| v0.9.39 a v0.9.42 | Correção offline (renovação ligada sem rede = não confirmada, v0.9.39); tela "Enviar feedback" (v0.9.40, v0.9.41); lista de assinaturas vazia sem rede = não confirmada (v0.9.42) | **Estável: v0.9.42** (24/11, no `main`); teste A offline passou; lista vazia com leitura velha falta provar (25/11) |
| v0.9.43 e v0.9.44 | Permanente guardado sem rede fica liberado sem prazo (v0.9.43); etapa 7, prazo de 7 dias no Meu plano e "Verificar novamente" (v0.9.44) | **No TestFlight, fora do `main`**; provas em 25/11 e 26/11 (`docs/TESTE_OFFLINE.md`) |
| Melhorias de rede e limpeza | v0.9.45 (reler a assinatura quando a internet volta), v0.9.46 (tela de planos sem internet), v0.9.47 (tirar a simulação "Só para teste") | **A fazer**, uma por vez, só com o "pode seguir" dele, depois das provas de 25/11 e 26/11 |
| C3 a C5 | Teste geral e Beta 2 (Permanente por último), Termos com advogado e contador, loja e lançamento (`docs/PLANO_C2.md`, `docs/PUBLICACAO.md`, seção 2) | Depois da v0.9.47 |
| Condicionais | B′ (crítico reduz 60→30 fps), limpeza do log de voz, 4K 60, botão "i", simulador de calor/espaço | Ideias em `docs/MELHORIAS_FUTURAS.md`, esperam dados do Beta |
