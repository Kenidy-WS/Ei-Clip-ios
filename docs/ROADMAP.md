# Roadmap por etapas

Uma etapa por vez. Cada etapa tem **critérios medidos**; só avança se todos baterem. Se algum falhar, paramos e escolhemos o caminho juntos (sem contornar).

## Regras (para o Kenidy acompanhar)

1. **Número da versão mostra a etapa:** etapa N = `v0.N.x`. Etapa 1 = `v0.1.0`, `v0.1.1`…; etapa 2 = `v0.2.0`…
2. **Uma mudança por versão**, com commit "vX.Y.Z: o que mudou". A versão aparece no app (Diagnóstico).
3. **Toda entrega termina igual:** (a) o que mudou, (b) o que testar no iPhone (lista numerada curta), (c) o que copiar do Diagnóstico, (d) o próximo passo.
4. **Estado sempre em `docs/STATUS.md`** (versão, etapa, pendências, o que falta testar). Este arquivo só muda quando o plano muda.

## Etapas

| Etapa | O que entrega | Critério de aprovação | Estado |
| ----- | ------------- | --------------------- | ------ |
| 0 — Preparação | Repositório, CI, instalação no iPhone | App "olá" compilado, instalado e aberto | **Concluída** (05/11) |
| 1 — Motor mínimo | Câmera 1080p30 + mic, buffer retroativo, gravar/parar, bipe, Rolo, Diagnóstico | (a) 20 aberturas, 0 microfones mudos · (b) clipe começa ±1 s do pré-tempo · (c) 5 min gravam e salvam sem travar · (d) áudio e vídeo em sincronia | **Em teste** (`v0.1.8`; a passou na v0.1.4; b, c, d passaram na v0.1.0, a refazer na versão final; defeito do arquivo que falhava ao começar corrigido na v0.1.6, 11 de 11 clipes salvaram) |
| 2 — Voz | Palavra de ativação (SFSpeechRecognizer pt-BR), 3 palavras | Taxa de acerto em 50 falas (perto, com ruído) · falsos disparos em 5 min de conversa · voz + bipe sem chiado | **Aprovada pelo Kenidy em 05/11 com ressalvas** (`v0.2.4`): falsos disparos 0 em 6 min (passou); bipe sem chiado (ouvido do Kenidy, 7 clipes); acertos: rodada solta sem contagem exata, aceita por ele no lugar das 50 falas contadas; as 3 palavras escolhíveis e testadas na `v0.2.5` (12 de 12 comandos); **falta só:** exercitar o religar do reconhecedor (espera longa em Comando) |
| 3 — Interface | Início, Câmera, Ajustes iguais ao web app; em pé e deitado | Igual ao web app nas telas e textos; funciona nas duas orientações | **Fechada** em 05/11 (tudo validado até `v0.3.12`: Início, Recentes, Câmera, gesto de borda, Ajustes, voz com a câmera, orientação, Diagnóstico completo, "ouvi" verde e revisão de textos) |
| 4 — Galeria e gestos | Galeria dentro do app (só os clipes do álbum "Ei Clip"), player, seleção em lote, transições de tela e gestos de arrastar, idênticos ao web app | Cada tela, efeito e gesto igual ao web app, validado no iPhone | **Fechada** em 05/11 (`v0.4.17`: Galeria, player, seleção em lote, gestos, transições e som do player, tudo validado no iPhone) |
| 5 — Refatoração | Sem recurso novo: navegação como regra pura (Core), gesto de borda nativo, player em partes, miniaturas com cache, preferências num lugar só, captura parametrizável, CI com relatório | Diagnóstico antes e depois igual (câmera abre em < 450 ms, 0 quadros descartados, pico do microfone > 0,0008, voz religando); cada versão `v0.5.x` com uma mudança só | **Fechada** em 05/11 (`v0.5.0` a `v0.5.8`, validada no iPhone na `v0.5.8`) |
| 6 — Recursos da câmera (antiga etapa 5) | Gravação longa direta, 4K30/1080p60, troca de lentes (ultra-angular), frontal, nível, foco por toque, estabilização, recuperação | Cada item validado no iPhone | A fazer (`v0.6.x`) |

Fora do escopo agora: Android, monetização, App Store, TestFlight.

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
- **A cada 7 dias** o app expira: reinstalar pelo Sideloadly com o mesmo Apple ID (primeira instalação em 05/11).
- **Área protegida** (voz e sessão de áudio): mudanças vão sozinhas numa versão.
