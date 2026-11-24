# Teste offline da etapa 6 (tolerância de 7 dias) — roteiro e pendências

Para entregar ao Kenidy quando ele perguntar pela "lista de testes do offline". Janela principal: **23/11/2026 depois das 06:39** (fim do período do Anual de teste dele, já cancelado).

## Resultado de 23/11 e correção (v0.9.39)
- **Teste de 23/11 10:11 (v0.9.38):** offline, o StoreKit disse `expired` e o app bloqueou. **Para aquele caso o bloqueio estava certo:** o Anual estava CANCELADO (`willAutoRenew=false` desde 22/11, motivo da Apple 1 = cancelado pelo cliente). O aparelho já sabia que não ia renovar.
- **Mas a análise mostrou o risco real:** offline, o StoreKit também diria `expired` para quem tem a renovação LIGADA (o aparelho não sabe da renovação), e o app bloquearia quem paga.
- **v0.9.39 (`StoreTrustRules` no Core):** "terminou" só vale como resposta da Apple se a renovação estava desligada ou se a Apple informou o motivo do término. Renovação ligada e sem motivo = **não confirmado** (último período confirmado + 7 dias; o registro do Keychain não é apagado). Sem dados de renovação, vale o comportamento anterior (reserva), com linha no Diagnóstico.
- **Relógio atrasado (v0.9.39):** "ativa" com fim antes da maior data vista = registro do aparelho com relógio atrasado: vale como não confirmada (7 dias), e a maior data vista não volta.
- **Limites (quem não paga):** em todo caminho offline o acesso termina no máximo 7 dias depois do último período confirmado; voltar o relógio não devolve acesso; com internet, a resposta da Apple vale na hora.
- **"Maior data vista": resolvido.** Avançou 13:46 → 18:25 (22/11) → 10:11 (23/11). O "registro lido" do início mostra o último valor gravado (gravado a cada 1 h), não estava parado.

## Teste da v0.9.39 (Mensal de teste assinado em 23/11 ~10:30)
**Atenção:** no TestFlight a renovação é **1 vez por dia** (até 6), qualquer duração (não 5 min). A conta Sandbox existe, mas não entrou no iPhone (sem Mac, o menu Desenvolvedor não aparece). Então: **A em 24/11** no horário do "período até"; **B depois** (cancelar com internet, avião antes do fim, abrir offline depois do fim).
- Ajuste do roteiro A: avião uns 15 min ANTES do "período até" de 24/11; abrir offline uns 15 min DEPOIS.
**A. Quem paga (renovação ligada):**
1. Com internet, assinar o **Mensal** (Sandbox, sem cobrança). Abrir o app e esperar "acesso: liberado (assinatura)".
2. Anotar o "período até HH:MM" no Diagnóstico. Ligar o **modo avião** e fechar o app.
3. Esperar passar esse horário (uns 10 min). Abrir **offline**: deve **gravar**. No Diagnóstico: "término SEM confirmação" e "acesso: liberado (assinatura, sem confirmação, tolerância de 7 dias)"; Meu plano: "Não confirmado".
4. Desligar o modo avião e voltar ao app (ou fechar e abrir): a Apple confirma a renovação: "acesso: liberado (assinatura)" com período novo.
**B. Quem cancelou (o aparelho sabe):**
5. Cancelar o Mensal (Ajustes do iPhone > App Store > Conta Sandbox > Gerenciar, ou Meu plano > Gerenciar assinatura). Abrir o app com internet: "renovação CANCELADA".
6. Modo avião, fechar, esperar o fim do período, abrir offline: deve **bloquear** ("término confirmado", "assinatura terminou").
7. Enviar o Diagnóstico (Compartilhar) depois de A e depois de B (ou um só, ao fim).

## PENDÊNCIA (22/11, resolvida em 23/11): "maior data vista"
- No Diagnóstico de 22/11 15:31 a linha `acesso confirmado: registro lido do Keychain: ... maior data vista=22/11/2026 13:46` estava **parada em 13:46**, embora o app tivesse aberto às 15:26 (e lido a assinatura às 15:26 e 15:31).
- **O que conferir amanhã:** no Diagnóstico do teste, a "maior data vista" deve **avançar** a cada leitura confirmada (online) e nunca recuar. Se ficar parada, ou recuar com o relógio atrasado, **corrigir antes da etapa 7**: relógio atrasado esticaria o acesso offline.
- Também comparar com o código (`AccessRecord`/tolerância no Core e `StoreManager`): quando a data vista é gravada.
- O Kenidy pediu para **não esquecer** este ponto.

## Roteiro principal (o que ele faz)
1. Antes das 06:39, abrir o app **com internet** e deixar carregar (a linha "acesso confirmado" deve mostrar fim do período 23/11 06:39).
2. Ligar o **modo avião** e **fechar o app** (deslizar para fora).
3. Depois das 06:39, abrir **ainda offline**: deve **gravar** (tolerância de 7 dias; não pode bloquear).
4. Desligar o avião e abrir: se a Apple responder "terminou", deve **bloquear na hora** (sem os 7 dias).
5. Enviar o Diagnóstico (Compartilhar, .txt).

## Como eu leio o Diagnóstico
- Linhas: `acesso confirmado`, `compras: assinatura`, `acesso:` e `meu plano:`.
- **Passou:** offline depois das 06:39 mostra acesso liberado por tolerância; online depois da expiração, acesso bloqueado na hora.
- **Risco conhecido:** offline, o StoreKit responde pelo cache local. Se, passado o fim, ele responder "terminou" sem rede, o app trataria como resposta oficial e a tolerância não valeria; nesse caso ajustar a etapa 6 (tratar "terminou" sem rede como "não confirmado").

## Lista completa de testes da etapa 6 (PLANO_C2.md, linha 6)
- Modo avião com assinatura expirando (o roteiro acima).
- Relógio **adiantado** e relógio **atrasado** (atrasado não pode esticar o acesso: ver a pendência da "maior data vista").
- **Reinstalar offline** (o registro do Keychain deve valer; a contagem de clipes grátis também; conferir se sobrevive à reinstalação).
- **Restaurar backup** do iPhone.
- **Cancelamento percebido só ao conectar** (offline segue valendo até o fim + 7 dias).
- **Online com assinatura expirada ou revogada = sem tolerância** (bloqueia na hora).
- **Offline que depois conecta e descobre a expiração** = acesso termina na hora.
- O permanente **não** depende da tolerância (sem Permanente comprado, não dá para testar no aparelho; só testes automáticos por ora).

## Depois
Se tudo passar: **etapa 7** (mostrar o prazo de 7 dias na tela e estado "Assinatura não confirmada"; remover `AccessSimulation`), só com o "pode seguir" dele.

## Resultado de 24/11 (v0.9.42) e lista atualizada
**Falhou (v0.9.41, 10:13):** offline, com o último registro online do dia anterior (18:11), `Product.SubscriptionInfo.status` veio VAZIA sem erro; o app entendeu "sem assinatura", bloqueou e apagou o período guardado. **v0.9.42** (`StoreTrustRules.emptyListUntrusted`, `NetworkPathWatcher`): lista vazia + período pago guardado + sem sinal de rede = NÃO CONFIRMADA (registro mantido, tolerância de 7 dias).
**Teste A passou (10:32, v0.9.42, offline depois do fim do período 10:31:30):** `término SEM confirmação`, `acesso: liberado (assinatura, sem confirmação, tolerância de 7 dias)`, Meu plano "Assinatura não confirmada agora". Online, "Verificar de novo" renovou (relato dele; internet voltou com o app aberto e o app só releu no toque).
**Offline com leitura guardada recente (10:29 e 10:30):** o StoreKit respondeu "ativa até 10:31:30" sem rede e liberou. Isso mostra que a leitura guardada some/envelhece: o cenário da lista vazia só aparece com leitura velha (no 10:13 eram ~16 h).
| Item | Estado |
|---|---|
| Offline, antes do fim, leitura recente | Passou (24/11) |
| Offline, passou do fim, renovação ligada (A) | Passou (24/11) |
| Online volta e renova (manual) | Passou (relato 24/11) |
| Cancelada + offline passou do fim bloqueia (B) | Provado na v0.9.38 (23/11); refazer na v0.9.42 só como regressão |
| Online + expirada bloqueia na hora | Passou (22/11) |
| Lista vazia offline com leitura velha (v0.9.42) | **Pendente:** abrir offline sem ter aberto online nas últimas ~20 h (25/11 cedo, antes das 10:31) e achar `lista VAZIA… NÃO CONFIRMADA` |
| Gravar um clipe de verdade no estado "não confirmada" | **Pendente** (o gate liberou; falta o clipe) |
| Relógio adiantado/atrasado | **Pendente, fazer por último** (suja a "maior data vista"; usar avanço de no máximo 5 dias) |
| Reinstalar offline; restaurar backup | Pendente |
| Permanente | Só testes automáticos |

