# Plano de implementação da C2 (compra no app) — RASCUNHO para aprovação

**Criado em 19/11/2026.** Nada aqui foi implementado. Cada etapa é **uma versão própria** (uma mudança por versão), testada no TestFlight antes da próxima. Só começa com o "pode seguir" explícito do Kenidy. Decisões de base: `docs/PUBLICACAO.md`, seção 1, "19/11/2026".

## Antes de qualquer código (sem versão)
- **[ELE]** Criar no App Store Connect os produtos Mensal e Anual (mesmo grupo de assinatura) e o Acesso Permanente (não consumível), com IDs definidos juntos (ex.: `app.eiclip.mensal`, `.anual`, `.permanente`; ficam fixos). Preço oficial do permanente R$ 179,90. Compartilhamento em Família desligado. Criar um testador de ambiente de testes (sandbox).
- **[JUNTOS]** Conferir, na criação do produto, que o "Temporary Price Change" (R$ 149,90 por 30 dias) está disponível para o permanente. Agendar só perto do lançamento.
- Dados bancários e fiscais só no site da Apple, nunca no chat.

## Etapas
| # | Versão (uma mudança) | Quem | Testes previstos |
|---|---|---|---|
| 1 | **Core: regra de acesso.** `AccessGate`, fontes de direito (grátis, assinatura, permanente, código), tabela de produtos, contador como lógica pura (lista de UUIDs). Sem tela e sem efeito no app. | EU | Testes automáticos do Core (matriz completa de `PUBLICACAO.md`, 3.13 + acréscimos de 19/11). Conta CI verde. |
| 2 | **Keychain + contagem em modo sombra.** Gravação cria UUID; um único ponto de contagem (clipe finalizado, válido, guardado no app); recuperação de órfãos reaproveita o UUID. A regra **não bloqueia** nada ainda; só conta e registra no Diagnóstico. Erro de leitura libera e registra. | EU | No aparelho: contar 1 a 3 clipes; gravação cancelada/curta não conta; **reinstalar mantém a contagem**; recuperar órfão não duplica; Diagnóstico mostra a contagem. |
| 3 | **StoreKit 2 + iOS 16.3.** Carregar produtos, comprar, restaurar, ouvir atualizações, resgatar código, estados (ativo, cancelado, terminou, em análise, problema de pagamento). Preços vêm do StoreKit. Mínimo do iOS sobe de 16.0 para 16.3. Sem a tela final ainda (tela mínima em Ajustes). | EU + ELE (produtos prontos) | TestFlight no ambiente de testes: comprar cada produto, restaurar após reinstalar, cancelar, deixar expirar (renovação acelerada), assinante compra o permanente. |
| 4 | **Gate ativo + tela "Escolha seu acesso".** `AccessGate` chamado no início de `startRecording()`; todos os gatilhos abrem a tela; chip no Início; avisos a partir do 7º clipe; cartões empilhados, botão fixo, nada pré-selecionado. Se o tratamento do comando de voz precisar mudar, vira **versão própria** (área protegida). | EU | Botão, voz e volume depois do 10º abrem a tela uma vez, sem repetir; nada é gravado; câmera, galeria e compartilhar seguem; fechar a tela volta à câmera; teste do 7º ao 10º clipe. |
| 5 | **Ajustes > Acesso e aviso do assinante.** Situação, validade, próxima renovação (valor e data), Gerenciar assinatura, Restaurar compras, Resgatar código; aviso antes de comprar o permanente com assinatura ativa e atalho depois. | EU | Cada estado no aparelho: ativa, cancelada, terminou, problema de pagamento, permanente; textos conferidos em `Engine/Textos.swift`. |
| 6 | **Tolerância offline de 7 dias (opção B).** Guarda fim do período confirmado e maior data vista; acesso até o fim do período + 7 dias quando não confirma; permanente não depende disso. **O prazo não aparece na tela.** | EU | Modo avião com assinatura expirando; relógio adiantado e atrasado; reinstalar offline; restaurar backup; cancelamento percebido só ao conectar. |
| 7 | **Mostrar o prazo de 7 dias na interface** (só se a etapa 6 passar em todos os testes). | EU | Conferir textos e o estado "Assinatura não confirmada". |
| C3 | **Teste geral no TestFlight** (com o Beta 2). | JUNTOS | Lista de `PUBLICACAO.md`: compra, restauração, cancelamento, renovação, offline, reembolso, código, limite de 10 clipes. |

## Decidido em 19/11 (antes da etapa 4)
- Botão fixo sem plano escolhido: desativado, texto "Escolha um acesso".
- Avisos em laranja discreto, **sem vermelho** (vermelho sugere erro).
- Ação "Abrir câmera" (App Intents): **mantida**. Não aparece na tela de compra, nos cartões, nos Termos nem na divulgação; só uma menção neutra e curta onde for pertinente (ajuda ou informações), avisando que exige configurar no app Atalhos. Nada de apresentá-la como grande benefício.

## Riscos
- O Keychain sobreviver à reinstalação depende do comportamento do iOS, não de promessa da Apple: testar na etapa 2.
- Cartão recusado e reembolso são difíceis de reproduzir no ambiente de testes.
- Termos de Uso precisam estar publicados antes de enviar à revisão (C5), não antes dos testes internos.
