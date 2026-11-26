# Testes offline da etapa 6 (tolerância de 7 dias): lista, roteiro e resultados

Para entregar ao Kenidy quando ele perguntar pela "lista de testes do offline". Atualizado em 24/11/2026 (v0.9.44, build 67, no iPhone dele).

## Lista de 25/11 e 26/11 (a próxima rodada)

**Antes de tudo:** o TestFlight renova a assinatura de teste **1 vez por dia**, perto das 10:31. Por isso cada prova ligada ao fim do período só dá para fazer uma vez por dia. O fim do período atual aparece no Diagnóstico, linha "acesso confirmado" (período até); usar essa hora no lugar de "10:31". **A e B não cabem no mesmo dia:** cancelar a assinatura muda o resultado do outro teste. Por isso B fica para 26/11.

**Hoje à noite [ELE]:**
1. Fechar o app (deslizar para fora) e **não abrir mais com internet** (abrir online renova o cache e zera a espera de ~16 h). Manter o **modo avião** até amanhã. (Ele já abriu offline às 19:06 de 24/11; isso não renova o cache.)

**25/11, de manhã cedo [ELE], app aberto SEM internet, antes do fim do período (antes das 10:31):**
2. **Teste 1, lista vazia com leitura velha.** Abrir o app em modo avião (de preferência depois das 07:00, ~16 h ou mais depois da última leitura online). Esperado: acesso liberado e, no Diagnóstico, uma destas duas: (a) `assinaturas: a Apple devolveu lista VAZIA… NÃO CONFIRMADA` (prova a correção da v0.9.42) ou (b) "ativa até…" (o StoreKit ainda tinha cache; não prova nada, e a prova fica para outro dia). Em qualquer caso o app deve **liberar** e **não** abrir a tela de planos.
3. Gravar um clipe curto, parar e conferir que foi para o álbum "Ei Clip".

**25/11, depois do fim do período (~10:31), ainda SEM internet [ELE]:**
4. **Teste 4, fim natural.** Fechar e abrir o app. Esperado: acesso liberado; Meu plano com o título **"Assinatura não confirmada"** e o texto "Sem conexão. Você pode continuar gravando até DD/MM/AAAA, às HH:mm. Conecte-se à internet para confirmar." (a data é o fim do período + 7 dias). Tirar **print do Meu plano**.
5. **Teste 3, clipe em "não confirmada".** Gravar um clipe curto nesse estado e conferir que salvou.
6. **Com o app ainda aberto**, desligar o modo avião e tocar em **"Verificar novamente"**. Esperado: volta a "assinatura" com período novo. Em seguida **Compartilhar o Diagnóstico** (sem fechar o app, para a rodada offline não ir para "anterior").

**25/11, à tarde, com internet [ELE]:**
7. Meu plano > Gerenciar assinatura: **cancelar o Mensal** (prepara o B). Abrir o app e conferir no Diagnóstico "renovação CANCELADA".
8. Ligar o modo avião antes do fim do novo período (26/11 ~10:31) e fechar o app.

**26/11, depois do fim, SEM internet [ELE]:**
9. **Teste B (regressão).** Abrir o app: deve **bloquear** (tela de planos; Diagnóstico "término confirmado" e "assinatura terminou"). Compartilhar o Diagnóstico.

**Teste das v0.9.45 e v0.9.46 [ELE], com a build da v0.9.46 no TestFlight:**
- **v0.9.46 (planos sem internet):** com o **modo avião ligado**, abrir o app e olhar a seção de produtos (tela de planos, ou Ajustes > Meu plano sem assinatura ativa): deve aparecer "Não foi possível carregar as opções de acesso. Verifique a conexão e tente novamente." com o botão "Tentar novamente". Diagnóstico: `produtos: 0 de 3 sem rede … FALHA DE REDE`. (Com assinatura ativa a tela de planos não oferece os planos; nesse caso vale a linha do Diagnóstico.)
- **v0.9.45 (reler ao voltar a internet):** com o app aberto em Meu plano, ligar o avião por ~10 s e desligar. Esperado no Diagnóstico: `rede: voltou (…)`, `releitura em 2 s` e a leitura `internet voltou`. Se estava em "não confirmada", volta a "assinatura" sozinha, sem tocar em "Verificar novamente".

**Eu [EU]:** leio cada Diagnóstico e digo "passou" ou "falhou, e por quê". Nada de versão nova antes das provas; depois delas e do OK dele, uno v0.9.43 e v0.9.44 ao `main` e abro a v0.9.45.

**Para o fim (sempre por último, avançar no máximo 5 dias; sujam a "maior data vista"):** relógio adiantado; relógio atrasado (não pode esticar o acesso); reinstalar offline; restaurar backup.

## Estado dos testes

| Item | Estado |
|---|---|
| Offline, antes do fim, leitura recente | Passou (24/11) |
| Offline, passou do fim, renovação ligada (A) | Passou (24/11, v0.9.42) |
| Online volta e renova (toque em "Verificar") | Passou (relato 24/11) |
| Cancelada + offline passou do fim (B) | **PASSOU em 26/11 10:58 (v0.9.46, build 70):** offline depois do fim, o StoreKit respondeu `expired` com `willAutoRenew=false` e motivo 1; `término confirmado`, `acesso: escolha de acesso (assinatura terminou)`, `meu plano: ended`, gravação NÃO iniciada, tela de planos aberta, período guardado apagado. (Às 10:20, antes do fim, a mesma conta tinha dado lista vazia e liberado: cada resposta do StoreKit offline foi tratada certo.) |
| Online + expirada bloqueia na hora | Passou (22/11) |
| Offline, antes do fim, ~8,5 h depois da última leitura online (v0.9.44, 24/11 19:06) | Passou: StoreKit ainda respondeu "ativa até 25/11 10:31:30" pelo cache, acesso liberado, clipe gravado e salvo. Não provou a lista vazia (cache ainda bom) |
| Offline 25/11 09:30 (v0.9.44, ~23 h depois da última leitura online) | Passou: StoreKit ainda respondeu "ativa até 10:31:30" pelo cache; acesso liberado; clipe de 9 s gravado e salvo. Lista vazia de novo não apareceu |
| Offline 25/11 09:36, depois de reiniciar o iPhone (v0.9.44) | Passou: cache respondeu "ativa até 10:31:30", acesso liberado, clipe de 6,4 s gravado. Lista vazia não apareceu |
| Lista vazia offline com leitura velha (v0.9.42) | **PASSOU NO APARELHO em 26/11 10:20 (v0.9.46, build 70):** offline, ERRO -1009 nos produtos, `assinaturas: a Apple devolveu lista VAZIA… tratada como NÃO CONFIRMADA (registro mantido)`, `acesso: liberado (assinatura, sem confirmação agora, dentro do período pago)`, `meu plano: renewalUnknown(until 26/11 10:31)`; clipe de 5,8 s gravado. Era a cancelada (cancelou em 25/11). Em 24 e 25/11 não tinha aparecido (cache de 8,5 h, 23 h e reinício) |
| Gravar um clipe de verdade em "não confirmada" | **Passou (25/11 10:41, v0.9.44):** offline depois do fim, `término SEM confirmação`, `acesso: liberado (assinatura, sem confirmação, tolerância de 7 dias)`, `meu plano: unconfirmed(until 02/12 10:31)`; 2 clipes gravados (9,1 s e 4,3 s) e salvos no álbum |
| Texto novo do Meu plano com data e hora (v0.9.44) | **Falta o print** do Meu plano (o log mostra `unconfirmed` até 02/12 10:31) e o passo "Verificar novamente" com internet |
| Relógio adiantado/atrasado | Pendente, por último |
| Reinstalar offline; restaurar backup | Pendente |
| Permanente offline (v0.9.43) | Só testes automáticos; sem Permanente comprado não dá para testar no aparelho |
| Recarregar sozinho quando a internet volta (v0.9.45) e tela de planos sem internet (v0.9.46) | **Passaram em 26/11** (v0.9.46 build 70): 10:58 `produtos: 0 de 3 sem rede: FALHA DE REDE`; 11:00:54 `rede: voltou (rede: disponível); releitura em 2 s`; 11:00:57 `produtos relidos (releitura silenciosa)`, `3 de 3 carregados` com preços; 11:00:59 `direitos lidos (internet voltou)` (cancelada, segue "terminou"). Sem tocar em nada |

## Resultados anteriores

**23/11 (v0.9.38):** offline, o StoreKit disse `expired` e o app bloqueou. Para aquele caso estava certo: o Anual estava cancelado (`willAutoRenew=false`, motivo 1). Mas a análise mostrou o risco real: offline o StoreKit diz `expired` também para quem tem renovação LIGADA, e o app bloquearia quem paga. **v0.9.39** (`StoreTrustRules`): "terminou" só vale se a renovação estava desligada ou a Apple informou o motivo; renovação ligada e sem motivo = **não confirmado** (último período + 7 dias). Relógio atrasado não estende.

**24/11 (v0.9.41, 10:13): falhou.** Offline, com último registro online do dia anterior (18:11), `Product.SubscriptionInfo.status` veio VAZIA sem erro; o app entendeu "sem assinatura", bloqueou e apagou o período guardado. **v0.9.42** (`emptyListUntrusted`, `NetworkPathWatcher`): lista vazia + período pago guardado + sem sinal de rede = não confirmada (registro mantido).

**24/11 (v0.9.42, 10:32): teste A passou.** Offline depois do fim (10:31:30): `término SEM confirmação`, `acesso: liberado (assinatura, sem confirmação, tolerância de 7 dias)`, Meu plano "não confirmada". Offline com leitura guardada recente (10:29 e 10:30) o StoreKit respondeu "ativa até 10:31:30" sem rede e liberou; ou seja, a lista vazia só aparece com leitura velha (no 10:13 eram ~16 h).

**"Maior data vista":** resolvido em 23/11 (avançou 13:46 → 18:25 → 10:11; o "registro lido" no início mostra o último valor gravado, que é gravado a cada 1 h).

**Limites (quem não paga):** em todo caminho offline o acesso termina no máximo 7 dias depois do último período confirmado; voltar o relógio não devolve acesso; com internet, a resposta da Apple vale na hora.

## Roteiro-base dos testes A e B (referência)

**A. Quem paga (renovação ligada):**
1. Com internet, assinar o Mensal (Sandbox, sem cobrança) e esperar "acesso: liberado (assinatura)".
2. Anotar o "período até HH:MM". Ligar o modo avião e fechar o app, uns 15 min ANTES desse horário.
3. Abrir offline uns 15 min DEPOIS: deve gravar; Diagnóstico "término SEM confirmação" e "acesso: liberado (assinatura, sem confirmação, tolerância de 7 dias)"; Meu plano "Assinatura não confirmada".
4. Desligar o avião e tocar em "Verificar novamente": volta a "assinatura" com período novo.

**B. Quem cancelou (o aparelho sabe):**
5. Cancelar o Mensal (Meu plano > Gerenciar assinatura). Abrir o app com internet: "renovação CANCELADA".
6. Modo avião, fechar, esperar o fim do período, abrir offline: deve bloquear ("término confirmado", "assinatura terminou").
7. Compartilhar o Diagnóstico.

## Lista completa da etapa 6 (de `docs/PLANO_C2.md`)

- Modo avião com assinatura expirando (A).
- Relógio adiantado e atrasado.
- Reinstalar offline (o registro do Keychain deve valer; conferir se a contagem de clipes grátis também sobrevive).
- Restaurar backup do iPhone.
- Cancelamento percebido só ao conectar (offline segue valendo até o fim + 7 dias).
- Online com assinatura expirada ou revogada = sem tolerância (bloqueia na hora).
- Offline que depois conecta e descobre a expiração = acesso termina na hora.
- O Permanente **não** depende da tolerância: offline fica liberado sem prazo (v0.9.43); só uma resposta válida da Apple com rede o tira.

## Como eu leio o Diagnóstico

- Linhas: `acesso confirmado`, `compras: assinatura`, `assinaturas:`, `rede:`, `acesso:` e `meu plano:`.
- **Passou:** offline depois do fim mostra acesso liberado por tolerância ("sem confirmação"); online depois da expiração, acesso bloqueado na hora; cancelada + offline depois do fim, bloqueado.
- **Falhou:** bloqueio offline de quem tem renovação ligada, período guardado apagado (`acesso confirmado` sem "período até" depois do teste), ou liberar depois do fim em assinatura cancelada.
