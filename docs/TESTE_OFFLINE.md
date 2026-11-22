# Teste offline da etapa 6 (tolerância de 7 dias) — roteiro e pendências

Para entregar ao Kenidy quando ele perguntar pela "lista de testes do offline". Janela principal: **23/11/2026 depois das 06:39** (fim do período do Anual de teste dele, já cancelado).

## PENDÊNCIA IMPORTANTE (22/11): "maior data vista"
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
