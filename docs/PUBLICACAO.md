# Roadmap de publicação (App Store)

**Criado em:** 07/11, a pedido do Kenidy. **Estado:** plano para consulta futura. **Nada aqui começa sem o "pode seguir" dele.**
Isto NÃO substitui o `ROADMAP.md` (etapas de código). Quando a publicação começar, cada fase de código vira uma Onda nova lá, uma mudança por versão.

Legenda: **[ELE]** só o Kenidy pode fazer (conta, banco, aceitar contratos) · **[EU]** o Claude faz no código/CI · **[JUNTOS]** · *(a confirmar)* = não foi verificado e precisa ser conferido na hora.

## Decisões que ele já tomou ou inclinou (07/11)
- Publicar primeiro como **pessoa física** (conta individual); migrar para organização (WPS) depois, se valer a pena. A Apple permite a conversão sob pedido.
- Modelo: baixar de graça, **teste por uso**, depois **compra única** para desbloquear. Ideia de teste: cerca de 10 a 15 clipes (valor a decidir), contados no Keychain. O teste grátis nativo da Apple só existe para assinatura.
- Antes de publicar: terminar a validação em campo (ver Fase 0).
- Influenciadores com acesso grátis por código: ver Fase 4 e Fase 7.

## Fatos pesquisados (07/11/2026)
- Programa de Desenvolvedor: US$ 99/ano; apps ilimitados na mesma conta.
- Individual: sem D-U-N-S; o nome do vendedor na loja é o nome legal da pessoa. Organização: exige D-U-N-S (grátis, até ~5 dias úteis) e a aprovação leva de dias a ~2 semanas.
- Liberar recursos exige a **compra dentro do app (StoreKit)**. Chave de licença própria ou QR code próprio para liberar função não é permitido.
- Login só é obrigatório se o app tiver conta; se tiver, precisa de exclusão de conta. **O Ei Clip não precisa de login.**
- URL da **política de privacidade** é obrigatória na App Store Connect.
- Brasil (acordo com o CADE, desde 18/06/2026, iOS 26.2): pagamentos alternativos, links externos e lojas alternativas são permitidos, com comissões próprias. Para um app pequeno, usar o pagamento da Apple é o caminho simples; avaliar alternativas só depois (ver Ideias).
- Códigos de Oferta para compra dentro do app (inclui compra única, iOS 16.3+): até 1 milhão de códigos por app por trimestre, até 10 ofertas ativas, um resgate por pessoa por oferta, validade máxima de 6 meses; códigos de uso único ou personalizados; resgate pela App Store, por link ou por tela dentro do app.
- Códigos promocionais antigos (100 por versão) só liberam o download de app pago, não a compra interna.
- TestFlight: até 10.000 testadores externos (e-mail ou link público), builds valem 90 dias, uma revisão da Apple na primeira vez para teste externo.

---

## Fase 0 — Validação em campo (hoje, sem versão nova)
Critério para sair: ele diz que está estável o bastante para outras pessoas.
1. **[ELE]** Gravação longa (30 a 60 min) com a chave de calor ligada, num dia quente.
2. **[ELE]** Clipes longos (5 min ou mais) e recuperação se o app fechar gravando.
3. **[ELE]** Voz por 30 min ou mais em Comando.
4. **[ELE]** Pouco espaço e bateria baixa (avisos).
5. **[ELE]** iPhone 16 e iPhone 17 de amigos: pedir "Copiar" do Diagnóstico; **[EU]** leio e comparo com os critérios.
6. **[EU]** Caminhos de reserva nunca exercitados em aparelho (sem câmera combinada, sem ultra-angular, iOS mais antigo): listar o que dá para simular e o que só um aparelho real prova.
7. Adiados por ele, decidir se entram antes do lançamento: foco na troca de lente, miniatura escura no Fotos, erro de áudio do player (área protegida, sozinha numa versão).

## Fase 1 — Burocracia (pode andar em paralelo à Fase 0)
1. **[ELE]** Decidir o nome final e conferir disponibilidade: "Ei Clip" na App Store e no INPI *(a confirmar o procedimento)*. O Bundle ID `br.com.wpstecnologia.eiclip` já é definitivo.
2. **[ELE]** Apple ID próprio para desenvolvedor, com verificação em duas etapas ligada. Usar sempre o **mesmo** Apple ID (hoje o Sideloadly usa outro, de conta grátis; ao entrar na conta paga o ID da equipe muda, então a instalação por Sideloadly deixa de ser o caminho).
3. **[ELE]** Inscrever-se no Programa de Desenvolvedor (individual). Pagar US$ 99/ano. Acompanhar a aprovação.
4. **[ELE]** Acordos, impostos e banco na App Store Connect: contrato de apps pagos, dados bancários e formulários fiscais. *(a confirmar com contador: como receber e declarar renda de venda de app como pessoa física, e quando compensa abrir MEI/CNPJ.)*
5. **[ELE]** Domínio e e-mail de suporte (ex.: página simples no domínio da WPS). Serve para: URL de suporte, política de privacidade e página de divulgação.
6. **[JUNTOS]** Política de privacidade e termos. **[EU]** redijo o rascunho a partir do que o app realmente faz (câmera, microfone, reconhecimento de voz, Fotos; sem conta, sem rede própria, sem coleta); **[ELE]** revisa e publica na página. *(Conferir se o reconhecimento de voz roda no aparelho ou usa servidores da Apple; a política precisa dizer a verdade.)*
7. **[ELE]** Criar o registro do app na App Store Connect (nome, idioma principal pt-BR, Bundle ID, SKU).

## Fase 2 — O app pronto para o público (código, Onda de publicação)
Cada item é uma versão própria, testada no aparelho. Ordem sugerida:
1. **[EU] Núcleo de acesso (Core, com testes):** regra pura do teste (quantos clipes, quando bloqueia, o que ainda funciona depois do teste). Decisão em aberto: o que o app faz quando acaba o teste (sugestão: continua abrindo a Galeria e exportando o que já foi gravado; bloqueia gravar novos clipes).
2. **[EU] Contador de clipes no Keychain** (sobrevive à reinstalação). Sem conta e sem rede.
3. **[EU] Compra única com StoreKit 2:** produto "Ei Clip completo", tela de compra com textos formais, botão **Restaurar compras** (exigência da Apple), estados de erro e de espera. Testar no sandbox.
4. **[EU] Tela de resgate de código** (Códigos de Oferta, `presentOfferCodeRedeemSheet`): botão discreto em Ajustes. Ver Fase 7.
5. **[EU] Diagnóstico:** esconder no uso normal; deixar como **modo de suporte** (ex.: toques repetidos na versão, em Ajustes) para ele e para usuários mandarem o log.
6. **[EU] Primeira abertura:** explicar por que pede câmera, microfone, voz e Fotos; textos de permissão (`Info.plist`) revisados; o que fazer se negar.
7. **[JUNTOS] Textos finais:** revisão geral, migração para `Textos.swift` (já prevista na etapa 3), pt-BR e, se quiser, inglês.
8. **[JUNTOS] Ícone, nome na tela inicial e tela de abertura** definitivos.
9. **[EU] Acessibilidade e aparelhos:** tamanho de texto grande, VoiceOver nos botões principais, iPad (decidir: só iPhone ou também iPad; só iPhone simplifica a revisão).
10. **[EU] Pedido de avaliação** (`requestReview`) só depois de um clipe bem-sucedido, nunca durante a gravação.
11. **[EU] Auditoria de pré-envio (só leitura):** permissões declaradas × usadas, APIs sensíveis, textos que citem "teste"/"beta"/"Sideloadly", links quebrados.

## Fase 3 — Assinatura e entrega automática (CI)
O workflow atual gera IPA **não assinado**. Para a loja, precisa de assinatura da Apple.
1. **[ELE]** Criar a **chave da API da App Store Connect** (arquivo `.p8`, baixa uma única vez; guardar com segurança) e anotar o Issuer ID e o Key ID.
2. **[ELE]** Cadastrar os segredos no GitHub Secrets (eu guio passo a passo). Nada de chave no código.
3. **[EU]** Novo workflow: `xcodebuild archive` com assinatura automática pela chave da API, exportar e **enviar ao TestFlight** em cada tag; número de build automático (hoje `CURRENT_PROJECT_VERSION` é manual).
4. **[EU]** Manter o workflow atual (IPA não assinado) como reserva até o novo estar validado.
5. **[JUNTOS]** Primeira entrega ao TestFlight; conferir que instala e abre.
*(a confirmar: detalhes de certificados e perfis; podem ser criados pela API na primeira execução.)*

## Fase 4 — Beta externo (TestFlight)
1. **[ELE]** Preencher as informações de teste (descrição, e-mail de contato, o que testar).
2. **[ELE]** Enviar para a revisão de beta (uma vez); costuma levar poucos dias.
3. **[ELE]** Grupo 1: amigos e família (e-mail). Grupo 2: **influenciadores** com **link público** do TestFlight (dá para limitar a quantidade de vagas). Teste não passa pela compra; é só para avaliar e divulgar a versão.
4. **[JUNTOS]** Canal simples para feedback: pedir "Copiar" do Diagnóstico + o que aconteceu. Eu leio os logs e classifico (bug, ajuste, ideia).
5. **Critério para sair:** semana sem travamento, sem perda de clipe e sem erro novo no Diagnóstico nos aparelhos de teste.
6. Lembrete: o build do TestFlight vale 90 dias; manter builds novos.

## Fase 5 — Ficha da loja e revisão
1. **[JUNTOS]** Textos: nome, subtítulo, descrição, palavras-chave, categoria (Foto e Vídeo), novidades da versão.
2. **[JUNTOS]** Imagens: capturas de tela nos tamanhos exigidos *(a confirmar os tamanhos vigentes)* e vídeo de pré-visualização curto. Sugestão: mostrar o clipe retroativo em ação (pescaria).
3. **[ELE]** Preço: escolher na tabela da Apple (compra única) *(decidir valor)*; Compartilhamento em Família (decidir).
4. **[ELE]** Classificação etária e o questionário de **Privacidade do app** (rótulos): câmera, microfone, voz; sem rastreamento, sem coleta (se for verdade na hora).
5. **[ELE]** Conformidade de exportação (criptografia): o app não usa rede própria, mas confirmar as respostas *(a confirmar)*.
6. **[ELE]** Informações para o revisor: como testar (o que fazer, como acionar a voz) e, como o app não tem login, nenhuma conta de teste; explicar o teste por uso e como ver a compra.
7. **[ELE]** Enviar para revisão. Costuma levar de 1 a 3 dias; prever pelo menos uma rejeição e um ajuste.
8. **[EU]** Se rejeitar: ler o motivo, propor correção (uma mudança por versão) e responder.
9. Escolher liberação **manual** após aprovação, para marcar a data do lançamento.

## Fase 6 — Lançamento
1. **[ELE]** Liberar a versão. Conferir que o app baixa, abre e a compra funciona com uma conta real (compra de teste, depois reembolso se quiser).
2. **[JUNTOS]** Divulgação: ver Ideias.
3. **[EU]** Marcar a versão como estável em `docs/STATUS.md` com o link, como já fazemos, mais o número aprovado pela Apple.

## Fase 7 — Depois do lançamento
1. **[JUNTOS] Programa de influenciadores:** Códigos de Oferta grátis sobre a compra única, um código personalizado por pessoa (para saber de quem veio cada resgate). Lembrar a eles de identificar como publicidade (regra do CONAR). Respeitar o limite de 10 ofertas ativas e validade de até 6 meses.
2. **[ELE]** Acompanhar na App Store Connect: downloads, conversão para compra, avaliações, falhas (relatórios da Apple).
3. **[EU]** Corrigir falhas por versão pequena; manter a regra de uma mudança por versão e o ritmo de estável.
4. **[JUNTOS]** Renovar a conta (US$ 99/ano) e o build do TestFlight a cada 90 dias se continuar o beta.
5. Reavaliar: migrar para conta de organização (WPS), pagamento alternativo no Brasil, outras lentes e aparelhos.

---

## Ideias (não prometidas, para avaliar depois)
- **Divulgação própria:** usar clipes reais feitos com o app no perfil de pesca dele como demonstração; vídeo curto "como funciona o clipe retroativo".
- **Página de divulgação** simples com lista de espera (e-mail) antes do lançamento.
- **Teste por uso em vez de por dias:** 10 a 15 clipes, sem relógio; evita o usuário perder o teste por não usar a semana inteira. Pode mostrar "restam N clipes de teste" em Ajustes (sem publicar estado novo durante a reconfiguração da câmera).
- **Preço de lançamento** por tempo limitado, via oferta da loja (a confirmar o que vale para compra única).
- **Compartilhar o clipe com marca discreta** (opcional, desligável) para divulgação orgânica.
- **Inglês** como segundo idioma, depois de estável em português.
- **Avaliar o canal Brasil de pagamento alternativo** só se o volume justificar; começa simples com o pagamento da Apple.
- **Mini-site de suporte** com FAQ (permissões, calor, espaço, voz) para reduzir dúvidas.

## Riscos a vigiar
- Revisão da Apple pode estranhar: gravação retroativa (buffer sempre ligado) → explicar claramente na ficha e na política que o buffer fica só no aparelho e é apagado; microfone sempre ativo em modo Comando → texto de uso claro.
- Conta nova e pagamento: o contrato de apps pagos e os dados bancários podem atrasar a loja; começar cedo (Fase 1).
- iOS novo (27.x) mudando comportamento da câmera ou do SwiftUI: manter a regra de não publicar estado durante a reconfiguração e o Diagnóstico como termômetro.
- Aparelhos que nunca vimos: decidir sempre pela capacidade informada, com reserva registrada no Diagnóstico.

## Ordem prática resumida
Fase 0 e Fase 1 juntas → Fase 2 → Fase 3 → Fase 4 → Fase 5 → Fase 6 → Fase 7.
Dá para começar a Fase 1 (conta, política, domínio) a qualquer momento, sem gastar compilação.
