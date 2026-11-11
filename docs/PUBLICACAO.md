# Publicação do Ei Clip na App Store (documento único)

**Criado em:** 07/11/2026, a pedido seu. **Reorganizado em:** 10/11/2026.
**Estado:** plano para consulta. **Nada aqui começa sem o seu "pode seguir".**
Este é o ÚNICO documento de publicação. Ele NÃO substitui o `ROADMAP.md` (etapas de código): quando a publicação começar, cada fase de código vira uma Onda nova lá, uma mudança por versão.

> **Jurídico validado em 10/11/2026 e revalidado em 11/11/2026 (modelo híbrido: 3.3 e 3.13); revalidar a cada mudança de dados coletados, de modelo de cobrança ou de titular (PF para empresa).**

Legenda: **[VOCÊ]** só você pode fazer (conta, banco, aceitar contratos; nos chats antigos aparecia como ELE) · **[EU]** o Claude faz no código/CI · **[JUNTOS]** · *(a confirmar)* = não foi verificado e precisa ser conferido na hora.
Aviso: você não é advogado nem contador. Tudo marcado **"contador"** ou **"advogado"** precisa dessa confirmação antes de valer.

## Sumário
1. Decisões tomadas
2. Status por fase
3. Jurídico
4. Fases 0 a 7
5. Riscos
6. Ideias

---

## 1. Decisões tomadas

### 07/11/2026
- Publicar primeiro como **pessoa física** (conta individual); migrar para organização depois, se valer a pena. A Apple permite a conversão sob pedido. *(Confirmada e detalhada em 10/11, ver abaixo.)*
- Modelo: baixar de graça, **teste por uso**, depois **compra única** para desbloquear. Ideia de teste: cerca de 10 a 15 clipes (valor a decidir), contados no Keychain. O teste grátis nativo da Apple só existe para assinatura.
- Antes de publicar: terminar a validação em campo (Fase 0).
- Influenciadores com acesso grátis por código: Fase 4 e Fase 7.

### 10/11/2026 (chat jurídico; ver seção 3)
- **Titular:** pessoa física. MEI **não serve** para vender software.
- **Marca "Ei Clip":** sem registro no INPI por ora (risco aceito).
- **Modelo:** compra única; sem promessa de atualização eterna. *(Substituído em 11/11 pelo híbrido; ver abaixo e 3.3.)*
- **Repositório:** público por ora; fechar perto do envio.
- **Páginas legais:** em repositório público separado.
- **Idade (ECA Digital):** responder a classificação etária com cuidado.
- **Influenciadores:** publicidade identificada como tal.
- **Diagnóstico (10/11):** completo só no beta; na versão da loja, sem tela, sem log em arquivo e sem gravar o texto da fala.
- **Sem custo extra por ora (10/11):** sem domínio e sem registro no INPI até haver tração. Só o que é grátis fica neutro (3.12); o nome do vendedor é o seu.
- **Apple ID (10/11):** usar o pessoal do Kenidy (2FA e recuperação já ativos). O que se transfere numa venda é o app, não a conta.
- **Já criados (11/11):** organização GitHub `ei-clip`, repositório `ei-clip-legal` com GitHub Pages e e-mail de suporte `eiclip.suporte@gmail.com`.
- **Identidade portátil (10/11):** criar tudo como pessoa física, mas de forma neutra, para poder migrar para empresa ou vender o app sem refazer nada (3.12).
- **Bundle ID (10/11, escolhido em 11/11):** `app.eiclip`, neutro e sem WPS. A troca no app (hoje `br.com.wpstecnologia.eiclip`) acontece **antes** de registrar o app na App Store Connect; depois disso é permanente (Fase 1, item 1a; onda P2).
- **Nova ordem (10/11):** TestFlight antes da compra. Beta 1 (sem pagamento) → Fase 2 (compra) → Beta 2 (com compra). Ver a nota de ordem na seção 4.

### 11/11/2026 (chat de estratégia e mercado; ver 3.13)
- **Decisão sua (11/11, no chat jurídico): modelo HÍBRIDO desde o início, anual + vitalício**, com o teste por uso valendo para os dois. Motivo: o anual dá alguma recorrência, e o vitalício mantém a compra definitiva para quem não quer assinar. **Substitui a "compra única" de 10/11** (3.3).
- **Revalidação jurídica feita em 11/11** (3.3): o híbrido não cria risco legal novo, mas exige as travas de 3.3 (nomenclatura "Acesso permanente", regra da assinatura vencida, cobrança em duplicidade). Risco que continua em aberto: a Apple aceitar a assinatura num app offline (3.13, pergunta 6; plano B em 3.3, trava 5).
- **Regra sua: nunca mexer com quem já pagou.** Quem comprou o vitalício ou o anual mantém o que pagou; mudança de regra ou de preço vale só para quem chega depois.
- **Arquitetura aprovada em princípio:** regra de acesso pura no `Core`, baseada em fontes de direito, com tabela de produtos; o código nasce pronto para os dois modelos (3.13), para a decisão de preço não amarrar.

### Fatos pesquisados (07/11/2026)
- Programa de Desenvolvedor: US$ 99/ano; apps ilimitados na mesma conta.
- Individual: sem D-U-N-S; o nome do vendedor na loja é o nome legal da pessoa. Organização: exige D-U-N-S (grátis, até ~5 dias úteis) e a aprovação leva de dias a ~2 semanas.
- Liberar recursos exige **compra dentro do app (StoreKit)**. Chave de licença própria ou QR code próprio para liberar função não é permitido.
- Login só é obrigatório se o app tiver conta; se tiver, precisa de exclusão de conta. **O Ei Clip não precisa de login.**
- URL da **política de privacidade** é obrigatória na App Store Connect.
- Brasil (acordo com o CADE, desde 18/06/2026, iOS 26.2): pagamentos alternativos, links externos e lojas alternativas são permitidos, com comissões próprias. Para app pequeno, o pagamento da Apple é o caminho simples; avaliar alternativas só depois.
- Códigos de Oferta para compra dentro do app (inclui compra única, iOS 16.3+): até 1 milhão de códigos por app por trimestre, até 10 ofertas ativas, um resgate por pessoa por oferta, validade máxima de 6 meses; códigos de uso único ou personalizados; resgate pela App Store, por link ou por tela dentro do app.
- Códigos promocionais antigos (100 por versão) só liberam o download de app pago, não a compra interna.
- TestFlight: até 10.000 testadores externos (e-mail ou link público), builds valem 90 dias, uma revisão da Apple na primeira vez para teste externo.

### Fatos pesquisados (11/11/2026, modelo de cobrança)
- **Small Business Program:** comissão de 15% (em vez de 30%) para quem fatura até US$ 1 milhão por ano; é preciso se inscrever, e vale a partir de ~15 dias depois do fim do mês da aprovação *(a confirmar na inscrição)*.
- **Trocar o modelo com o app publicado é suportado** (versão nova do app + produtos novos). Assinatura → compra única é simples; compra única → assinatura exige **manter o acesso de quem já pagou** (diretriz 3.1.2(a) da Apple; caso Notability, 2021). Acrescentar uma opção nova nunca prejudica ninguém.
- **Retirar uma assinatura da venda** no App Store Connect: a documentação da Apple diz que impede novas assinaturas **e renovações**; relatos de desenvolvedores divergem. Para manter os assinantes atuais, o caminho seguro é **só parar de exibir o produto no app**. *(a confirmar na hora)*
- **Preço de assinatura:** se baixar, os assinantes atuais renovam pelo preço menor e não há como manter o antigo; aumento pode exigir consentimento. Regra nova só para novos assinantes = criar **produto novo** e deixar o antigo. O preço do vitalício só afeta quem compra depois.
- **`AppTransaction.originalAppVersion`** (versão em que o usuário baixou o app pela 1ª vez) reconhece compradores antigos; no sandbox e na revisão da Apple o campo pode vir fixo em "1.0", então essa lógica não se testa só pelo TestFlight.
- A Apple espera que assinatura entregue **valor contínuo**; um app sem conteúdo novo pode ser questionado na revisão *(a confirmar; ver pergunta 6 em 3.13)*.
- **Concorrentes** (câmera retroativa/replay): vários, quase todos "grátis + compra no app", focados em esporte e replay. Nicho pesca/outdoor, comando de voz, botões de volume e atalho com a mão molhada são o diferencial a provar.

---

## 2. Status por fase

Atualizar esta lista a cada avanço. "Pendente" = ainda não começou; só vira "feito" com você confirmando.

| Fase | Status |
|---|---|
| 0 Validação em campo | Pendente |
| 1 Burocracia | Pendente. Item 6: **fatos de voz e rede conferidos no código em 10/11** (resolvido); política ainda não escrita. **Em andamento (11/11):** organização GitHub, repositório legal e e-mail de suporte criados; Bundle ID escolhido (`app.eiclip`), troca no app na onda P2 (item 1a) |
| 2 App pronto para o público | Parcial: v0.9.5 já tem pinça, "Abrir câmera" e botões de volume (validado). Itens 1 a 13 pendentes |
| 3 Assinatura e CI | Pendente. **Antecipada:** vem logo depois da Fase 1 e dos Pacotes A e B, antes da compra |
| 4 Beta (TestFlight) | Pendente. Em duas rodadas: Beta 1 (sem compra) e Beta 2 (com compra) |
| 5 Ficha e revisão | Pendente |
| 6 Lançamento | Pendente |
| 7 Depois do lançamento | Pendente |

Pacotes jurídicos:

| Pacote | O quê | Fase | Status |
|---|---|---|---|
| A | Política de privacidade | 1 | Fatos conferidos no código (10/11); texto a escrever. **Antes do Beta 1** |
| B | Privacy manifest, criptografia, permissões | 2 | Pendente. **Antes do Beta 1** |
| C | "Informações" em Ajustes e primeira abertura | 2 (item 6) | Pendente. O link dos Termos precisa estar ativo antes da tela de compra (3.3) |
| D | Termos de Uso | 2 (junto dos itens 1 a 4) | Pendente. Inclui as regras do híbrido (3.3 e 3.11) |

### Ondas de publicação (P1 a P5), criadas em 11/11

**Como você quer trabalhar (padrão, vale para código e para qualquer assunto):** blocos pequenos, cada um com **começo, meio e fim**, para dar sensação de progresso e aliviar a cabeça. Cada onda tem **um objetivo só**, 2 a 4 passos, dono de cada passo e um **"pronto quando"**. Mostrar só a onda atual (o mapa completo fica aqui). Dizer o progresso ("onda 2 de 5") e, ao fechar, o que foi concluído antes de abrir a próxima, sempre depois do seu "pode seguir". Termos, textos finais e a compra ficam para as ondas deles, mais adiante. As ondas P1 a P5 **cobrem só o caminho até o Beta 1** (sem compra). Elas não substituem as Fases: apontam para os itens delas.

| Onda | Objetivo | Quem | Pronto quando | Fase / itens | Status |
|---|---|---|---|---|---|
| **P1** Conta e nomes | Abrir a conta de desenvolvedor e decidir os nomes neutros | VOCÊ e JUNTOS | Inscrição enviada e nomes decididos (Bundle ID, organização do GitHub, e-mail de suporte) | Fase 1: itens 1a (decidir), 2, 3 | **Em andamento (11/11):** organização `ei-clip`, e-mail de suporte e Apple ID (o pessoal) definidos. Bundle ID escolhido: `app.eiclip`. **Inscrição na conta de desenvolvedor adiada (11/11, decisão sua):** será feita só na hora de pagar. A tentativa pelo app foi recusada na verificação do documento; pelo site o fluxo chegou ao pagamento, sem concluir |
| **P2** App pronto para a loja | Trocar o Bundle ID e preparar manifesto e criptografia | EU (uma versão por mudança) | App novo abre e a câmera funciona igual | Fase 1, item 1a (trocar) · Fase 2, item 13 (Pacote B) | Pendente |
| **P3** Páginas legais | Política de privacidade com endereço público | JUNTOS | A política tem URL pública (e a revisão do jurídico feita) | Fase 1: itens 5 e 6 (Pacote A) | **Em andamento (11/11):** repositório `ei-clip-legal` criado, com GitHub Pages. Falta escrever a política |
| **P4** Entrega ao TestFlight | Registrar o app e enviar um build assinado | VOCÊ e EU | O app aparece no TestFlight e instala no seu iPhone | Fase 1, item 7 · Fase 3 | Pendente |
| **P5** Beta 1 | Colocar pessoas de fora para testar | VOCÊ | As primeiras pessoas de fora instalaram | Fase 4 (rodada Beta 1) | Pendente |

**Ordem:** P1 primeiro. Enquanto a Apple analisa a conta, **P2 e P3 andam** (dependem só de nós). **P4** exige a conta aprovada e o Bundle ID já trocado (P2). **P5** vem por último. A **Fase 0** (testes em campo) corre em paralelo, sem onda própria. **Depois do Beta 1** vêm as ondas da compra (Fase 2, itens 1 a 4, Pacotes C e D, Beta 2), a definir quando chegar a hora.

---

## 3. Jurídico

Conteúdo validado no chat jurídico em 10/11/2026. Você não é advogado nem contador: o que diz **contador** ou **advogado** precisa dessa confirmação.

### 3.1 Titular e imposto
- Publicar como **pessoa física**.
- O **MEI não serve** para vender software: nenhum CNAE de desenvolvimento ou licenciamento de software é permitido ao MEI. **Não** registrar a venda como "suporte de TI".
- **Contador:** carnê-leão, formulários fiscais da Apple e quando abrir ME.
- O nome do vendedor na loja é o seu nome legal.
- Alinhar o `LICENSE` (hoje cita "Kenidy (WPS Tecnologia)") ao titular real. **[VOCÊ]** decide o texto; **[EU]** edito.

### 3.2 Marca "Ei Clip"
- **Sem registro no INPI por ora** (decisão sua: caro, demorado, é protótipo).
- Risco aceito: se outro registrar antes, pode ser preciso trocar o nome.
- Mitigação mínima, antes de investir em divulgação: consulta grátis no INPI (classes 9 e 42) e checagem do nome na App Store.
- Registrar quando houver tração.
- "Clip" é descritivo e lembra o app "Clips" da Apple. O **logotipo** protege mais que o nome.
- O ícone foi criado com IA: autoria incerta. **Guardar o histórico de criação** (prompts, versões, datas). *(advogado)*

### 3.3 Modelo de cobrança e descontinuação
> **Revalidado em 11/11:** você decidiu o **híbrido, anual + acesso permanente** (ver 3.13). Vale o texto abaixo. *(advogado e contador: confirmar antes de publicar.)*

**Base legal comum**
- Nenhuma lei fixa prazo "vitalício" para um app vendido; vale a boa-fé do CDC (informação clara e expectativa razoável de uso).
- Como o app é offline e sem servidor, **parar de vender não desliga** quem já comprou.
- Reembolso e arrependimento (7 dias, CDC): tratados pela Apple.

**Acesso permanente (compra única)**
- Termos: sem garantia de atualização eterna nem de compatibilidade com todo iOS futuro; aviso prévio razoável; retirada da venda; o app continua funcionando onde já está instalado, na medida do possível.

**Anual (assinatura)**
- Compromisso até o fim do período pago. Se o app for descontinuado no meio do período, **reembolso proporcional** do restante.
- Renovação automática e cancelamento: pela Apple; o app informa preço, duração e renovação com clareza.

**Travas do híbrido (tratar na hora certa; cada uma tem seu lugar nas fases):**
1. **Nomenclatura.** Não usar "vitalício", "para sempre", "ilimitado" nem "atualizações grátis para sempre" no app, na ficha da loja, nos termos ou na divulgação. Usar **"Acesso permanente"**. Risco: propaganda enganosa (CDC, art. 37), porque o consumidor entende "para sempre, com atualizações". Nos Termos, definir: vale enquanto o app existir e funcionar no iOS, sem garantia de atualizações futuras. *(Neste documento, "vitalício" é só o nome interno do produto.)*
2. **Assinatura vencida:** bloquear **apenas a gravação de novos clipes**; manter Galeria, reprodução e exportação do que já foi gravado (mesma regra do fim do teste). Os clipes estão nas Fotos e são do usuário.
3. **Cobrança em duplicidade:** quem tem o acesso permanente não vê a oferta de assinatura. Assinante que compra o permanente continua pagando até cancelar (a Apple não cancela sozinha): aviso na tela e atalho para gerenciar assinaturas.
4. **Tela de compra da assinatura:** título, duração, preço, forma de renovação e como cancelar, com links funcionais para a Política e para os Termos *(confirmar o texto atual da diretriz 3.1.2 da Apple)*. **Dependência:** o link dos Termos precisa estar ativo antes da tela de compra (Pacotes C e D).
5. **Aprovação da Apple *(a confirmar, diretriz 3.1.2)*:** assinatura deve entregar valor continuado. "Anual ou permanente" com as mesmas funções costuma ser aceito, mas não há certeza para app offline. Explicar na ficha do revisor o que a assinatura entrega (acesso enquanto pago, preço menor que o permanente). **Plano B se for recusada:** estrear só com o acesso permanente e acrescentar o anual depois (acrescentar opção nova não prejudica ninguém; ver "Fatos pesquisados (11/11)").
6. **Testes:** só o teste por uso. Não ligar o período grátis nativo da assinatura (dois testes na mesma tela confundem).
7. **Preço (comercial, não legal):** o permanente deve valer vários anos de anual (referência de 2 a 3 vezes), senão cria obrigação de manutenção sem receita correspondente.
8. **Impostos (contador):** continua pessoa física, carnê-leão mensal; receita recorrente pode antecipar a hora de abrir ME; revisar nos primeiros meses.

### 3.4 Repositório
- **Público por ora** (ninguém conhece o projeto).
- Perto do envio:
  1. varrer o histórico do Git atrás de segredos;
  2. tornar **privado**, ciente de que as compilações macOS no Actions passam a consumir a cota paga;
  3. o histórico já público e eventuais forks/clones **não são afetados**.

### 3.5 Páginas legais
- Ficam em repositório público **separado** (ex.: `ei-clip-legal`, com GitHub Pages), **nunca** no `ei-clip-ios`, para a URL não cair quando ele for fechado.
- A URL da política vai na App Store Connect e **não pode mudar**.

### 3.6 ECA Digital (Lei 15.211/2025, em vigor desde 17/03/2026)
- O app não coleta dados nem é rede social: risco parece **baixo**.
- As lojas têm obrigações de sinal de idade.
- Responder a classificação etária com cuidado. *(advogado)*

### 3.7 Influenciadores
- Publicidade identificada como tal (CDC/CONAR).

### 3.8 Pacote A: Política de privacidade (Fase 1)
Local: repositório separado (3.5). Escrever só depois de conferir o código (feito em 10/11, v0.9.5).

**Fatos conferidos no código (10/11/2026, v0.9.5):**
- **Sem rede, login, analytics ou SDK de terceiros.** Nenhum uso de rede no código; nenhuma dependência externa (só frameworks da Apple). Única abertura externa: os Ajustes do iOS.
- **Voz no aparelho:** `requiresOnDeviceRecognition = true` (`Engine/VoiceProbe.swift`). Se o aparelho não reconhece pt-BR sem internet, o app **para** e não usa o servidor. **Isso resolve o "a conferir" do item 6 da Fase 1.**
- **Buffer retroativo:** guardado **na memória** (`ReplayBuffer`), não em disco. O que sai do buffer some. Só vai a disco quando um clipe é acionado. *(a confirmar na revisão final do caminho de descarte)*
- **Clipes:** divergência do que se supunha. Não ficam na pasta temporária: são gravados em **Application Support** (pasta de gravações, fora do backup do iCloud), salvos no álbum **"Ei Clip"** das Fotos (PhotoKit) e o arquivo local é apagado depois. Se o salvamento falhar, o arquivo fica e é tentado de novo na próxima abertura.
- **Miniaturas próprias** (JPG) em Application Support/Miniaturas: **não estavam na lista**, entram na política. *(a confirmar se são apagadas quando o clipe é apagado)*
- **Diagnóstico:** log **local** (arquivos "atual" e "anterior" em Application Support, teto de 3 MB por rodada). Só sai do aparelho se o usuário copiar e enviar. O cabeçalho tem versão do app, modelo do aparelho, versão do iOS e Bundle ID.
- **ATENÇÃO (decidido em 10/11):** hoje o Diagnóstico registra o **texto reconhecido da fala** (parcial e final) e o texto dos gatilhos. É local, mas é fala em texto. **Decisão:** na versão da loja não há tela de Diagnóstico nem log em arquivo, e o texto da fala não é gravado (versão própria; é área protegida de voz). A política da loja, portanto, **não precisa descrever o log**. Já o **beta** tem o log completo: avisar os testadores (Fase 4) de que o Diagnóstico existe e só sai do aparelho se eles copiarem e enviarem.
- **Compartilhamento:** o clipe é copiado para uma pasta temporária e **apagado ao fechar** a folha de compartilhar. Se o clipe estiver no iCloud Fotos, o iOS pode baixá-lo (rede do sistema, não do app).
- **Permissões (Info.plist, via `project.yml`):** câmera, microfone, reconhecimento de voz, Fotos (acesso) e Fotos (só adicionar).
- Sem localização e sem contatos. O app lê o sensor de movimento (orientação); *(a confirmar se isso pede aviso)*.

**Conteúdo, nesta ordem:**
1. Responsável e contato.
2. Resumo: "não coleta nem envia dados pessoais".
3. O que o app acessa e para quê.
4. Onde ficam os dados.
5. Diagnóstico: só se a versão da loja ainda o tiver (decisão atual: não tem; ver item 5 da Fase 2). Então vale só como nota do beta.
6. Sem anúncios, sem rastreamento, sem terceiros; compras processadas pela Apple.
7. Crianças.
8. Direitos LGPD (art. 18) em linguagem simples: nada retido por mim, desinstalar apaga, contato para dúvidas.
9. Segurança.
10. Mudanças e data de vigência.
11. Lei brasileira.

**Ao final:** "Relatório para validação jurídica" (texto + fatos conferidos + divergências), para você levar ao chat jurídico **antes de publicar**.

### 3.9 Pacote B: Versão própria do app (Fase 2, item 13)
- `PrivacyInfo.xcprivacy` no bundle: `NSPrivacyTracking = false`, domínios vazios, `CollectedDataTypes` vazio.
- `AccessedAPITypes` com as APIs de motivo obrigatório **realmente usadas**, com códigos **conferidos na documentação oficial da Apple, não de memória**. Candidatas vistas no código:
  - UserDefaults (preferências, bateria, permissões, diagnóstico);
  - uptime do sistema (`systemUptime`, usado em muitos pontos);
  - espaço em disco (`volumeAvailableCapacityForImportantUsageKey`);
  - atributos de arquivo (`attributesOfItem`, só para tamanho) *(conferir se conta como "timestamp de arquivo")*;
  - teclado: **não achei campo de texto no código**, então provavelmente não se aplica. Divergência da lista inicial.
- `ITSAppUsesNonExemptEncryption = false` no Info.plist via `project.yml`, **confirmando** que não há criptografia própria. Hoje o arquivo não tem esse campo nem o manifesto.
- Revisar os textos de permissão (**sugerir, não implementar sem aprovação**).
- Substitui o "(a confirmar)" da conformidade de exportação da Fase 5.

### 3.10 Pacote C: Informações e primeira abertura (Fase 2, item 6)
- Seção **"Informações"** em Ajustes: Política (abre no navegador), versão e lugar reservado para os Termos. Sem publicar estado novo durante a reconfiguração da câmera.
- **Primeira abertura** formal e curta: por que pede cada permissão, voz no aparelho, nada sai do aparelho, o que acontece se negar. Sem atrapalhar o atalho que abre direto na câmera.
- Textos em `Engine/Textos.swift`, **mostrados a você antes de implementar**.
- **Dependência da compra (3.3, trava 4):** o link dos **Termos de Uso** precisa estar ativo antes da tela de compra da assinatura. Os textos do app seguem a regra de nomenclatura ("Acesso permanente", nunca "vitalício").

### 3.11 Pacote D: Termos de Uso (Fase 2, junto dos itens 1 a 4)
Itens, nesta ordem:
1. Licença de **uso pessoal e intransferível**; EULA padrão da Apple em complemento.
2. Teste por uso, **acesso permanente** e assinatura anual descritos **exatamente** como o app se comporta. Definir "acesso permanente" (3.3, trava 1); nunca usar "vitalício".
3. Reembolso e arrependimento pela Apple; renovação automática e cancelamento da assinatura pela Apple.
4. Disponibilidade e descontinuação por tipo de compra (3.3) e regra da assinatura vencida (o que continua funcionando, trava 2).
5. Limitações: iOS, calor, bateria, espaço. **Sem exclusão total de responsabilidade** (o CDC anularia).
6. Uso responsável: consentimento de pessoas gravadas, direito de imagem, leis locais.
7. Propriedade intelectual.
8. Suporte por e-mail.
9. Lei e foro brasileiros.

Também termina com "Relatório para validação jurídica".

### 3.12 Identidade portátil (pessoa física hoje; empresa ou venda depois)
Objetivo: criar tudo como pessoa física, mas **sem amarrar o app a você nem à WPS**, para migrar para uma empresa ou vender sem refazer nada.

**O que dá para deixar neutro:**
- **Bundle ID neutro** (sem WPS e sem nome pessoal; **escolhido: `app.eiclip`**). Sem domínio, o ID é só um texto; a Apple não confere a posse do domínio *(a confirmar)*. É permanente depois do registro e acompanha o app em qualquer transferência.
- **Sem domínio por ora** (decisão de 10/11: custo; o nome está livre, mas fica para quando houver tração). Efeito: as páginas legais usam o endereço gratuito do GitHub Pages.
- **Organização gratuita do GitHub com nome neutro** (ex.: `ei-clip`; *(a confirmar disponibilidade)*) para o repositório legal (e, se quiser, o do app depois), em vez da conta pessoal. O endereço da política fica `https://<organização>.github.io/<repositório>/` e **só muda se o nome da organização mudar**: numa venda, a organização inteira pode mudar de dono e a URL continua a mesma. Escolher o nome com cuidado, porque ele aparece na URL da política e do suporte.
- **E-mail de suporte gratuito e dedicado** ao app (sem WPS e sem uso pessoal). Numa venda, o novo dono troca o endereço nos textos legais.
- **Apple ID pessoal** (decisão de 10/11, em vez de um dedicado). Numa venda, o que se transfere é o **app**, entre contas; a conta de desenvolvedor em si não passa para outra pessoa *(a confirmar)*, então um Apple ID dedicado não traria portabilidade. Manter verificação em duas etapas e recuperação ligadas, e não usar o Apple ID da WPS.
- **LICENSE, política e termos** citam o responsável real (você, pessoa física). Ao migrar, atualizar os três.
- Guardar **fora do GitHub**: histórico de criação do ícone, chave `.p8`, dados da conta e cópias dos textos legais.

**O que NÃO dá para esconder:**
- Como pessoa física, o **nome do vendedor na loja é o seu nome legal**, e a Apple verifica sua identidade. "Neutro" vale só para o que é técnico e interno.
- A política precisa nomear o responsável.
- Numa venda, depois da transferência o nome do vendedor na loja passa a ser o do **novo dono**; política, termos e `LICENSE` precisam ser atualizados por ele.

**Fica para depois (custo, decisão de 10/11):** domínio próprio e registro da marca no INPI. Ao registrar o domínio, trocar a URL da política numa versão do app e na App Store Connect.

**Transferência ou venda:** a App Store Connect permite transferir o app para outra conta (inclusive de empresa); o Bundle ID acompanha. Os requisitos exatos *(a confirmar na hora: contratos ativos, TestFlight em andamento, compras dentro do app)*. A marca "Ei Clip", se ainda não registrada, deve ser registrada já no nome do novo titular. Revalidar o jurídico (topo do documento) e falar com o contador.

### 3.13 Modelo de acesso e preços (11/11; **híbrido decidido, detalhes em aberto**)
Origem: chat de estratégia e mercado. **Híbrido confirmado por você e revalidado no chat jurídico em 11/11** (3.3, com as travas); preços, escopo e demais detalhes seguem em aberto.

**Regras de ouro (valem para qualquer modelo):**
1. Quem pagou mantém o que pagou, para sempre. Nunca tirar função de quem comprou.
2. Produto aposentado **some da tela, mas nunca sai da tabela do código**: o app continua reconhecendo quem o comprou (com teste automático para cada produto antigo).
3. Mudança de regra ou de preço vale só para quem chega depois (produto novo, versão nova do app).
4. Assinatura antiga: não retirar da venda; só parar de exibir (ver "Fatos pesquisados (11/11)").

**Produtos (nomes e IDs a definir):**
- **Anual:** assinatura auto-renovável, em um grupo de assinatura.
- **Vitalício "Ei Clip Completo":** compra única (não consumível). Nome visível no app e na loja: **"Acesso permanente"**, não "vitalício" (3.3, trava 1).
- **Teste por uso** (10 a 15 clipes, no Keychain) vale para os dois. O app **não usa o teste grátis nativo** da Apple, para haver um só mecanismo de teste.
- Futuro opcional: nível **"Pro"** separado (assinatura) para funções grandes novas, sem tirar nada de quem tem o Completo.

**Arquitetura (para não ficar amarrado a nenhum modelo):**
- **`Core` (regra pura, com testes):** a regra de acesso não pergunta "assina?", pergunta "de onde vem o direito?". Fontes: teste por uso (restam N clipes), assinatura ativa, vitalício, código de oferta, comprador antigo (se um dia houver). Saída: acesso completo, em teste (N) ou bloqueado, e o que ainda funciona bloqueado.
- **Tabela de produtos (configuração no `Core`):** liga cada ID de produto a um tipo de direito e diz quais produtos aparecem na tela de compra. Criar ou aposentar um produto muda só essa tabela.
- **`Engine` (StoreKit 2):** lê os direitos atuais do usuário (assinaturas e compras únicas vêm juntas), traduz pela tabela e entrega à regra pura. Inclui restaurar compras, estados de erro e de espera, reembolso/revogação.
- **Qual produto aparece = configuração da versão** (o app não usa rede). Trocar a oferta = versão nova, uma mudança por versão, revisão da Apple de 1 a 3 dias.
- **Sem `@Published` novo durante a reconfiguração da câmera** (regra do projeto): o estado de acesso é lido em momentos seguros (abrir a câmera, tocar em gravar), não publicado no meio da reconfiguração.
- **Comprou o vitalício com assinatura ativa:** aviso na tela e atalho para gerenciar a assinatura (a Apple não cancela sozinha), para evitar cobrança dupla.

**Matriz de testes do `Core` (cada linha com teste):** teste com N clipes restantes · teste esgotado · assinatura ativa · assinatura expirada · vitalício · os dois ao mesmo tempo · reembolsado/revogado · produto antigo aposentado ainda reconhecido · código de oferta · o que funciona bloqueado.

**Preços (só ponto de partida, a testar):** âncora de 2 a 3 vezes o anual no vitalício; exemplo: anual R$ 19,90 e vitalício R$ 49,90. Com 15% de comissão sobram cerca de R$ 25 por venda de R$ 30 (antes de impostos); US$ 99/ano de conta Developer (~R$ 500 a 600, conforme o câmbio) pedem ~20 a 25 vendas por ano para se pagar. Conversão típica citada por uma fonte: 0,5% a 3% dos instalados (hipótese, validar no beta). Fontes de mercado divergem entre "assinatura rende mais" e "compra única converte mais": tratar como hipótese e decidir com dados próprios.

**Como decidir com dados (depois do Beta 2 e do primeiro mês de loja):** % que escolhe anual × vitalício, reembolsos, avaliações e comentários sobre preço. Se uma opção não for escolhida, cortar (aposentando só da tela) ou reajustar o preço para novos compradores.

**Perguntas em aberto (definir juntos):**
1. Teste por uso: quantos clipes (10, 15)? Conta clipes gravados ou só salvos?
2. O que funciona depois do teste? (sugestão: abrir Galeria e exportar o que já foi gravado; bloquear gravar clipes novos.)
3. Preços finais do anual e do vitalício; âncora; preço de lançamento por tempo limitado.
4. **Escopo do vitalício**, escrito na descrição do produto ("tudo que o app faz hoje, mais correções"); funções grandes futuras podem ir para um "Pro" separado? Isso também entra nos Termos (3.11). *Jurídico (11/11): descrever o escopo com precisão e sem "para sempre"; um "Pro" separado é seguro se estiver descrito desde o início na loja e nos Termos.*
5. **Compartilhamento em Família** para o vitalício: sim ou não? *(a confirmar se pode ser desligado depois de ligado; tratar como decisão cuidadosa.)*
6. **Valor contínuo do anual:** o que justifica a assinatura para o usuário e para a Apple (atualizações para novos iPhones e iOS, novos recursos, suporte)? Escrever o texto e avaliar o risco na revisão. *Jurídico (11/11): o híbrido é viável, mas a aprovação da Apple é incerta para app offline (3.3, trava 5); plano B: estrear só com o acesso permanente e acrescentar o anual depois.*
7. **Termos (3.11) e 3.3:** com assinatura entram regras próprias (compromisso até o fim do período pago; descontinuar no meio exige reembolso proporcional). *Resolvido em 11/11: ver 3.3 e 3.11.*
8. Código de oferta para influenciadores: sobre o vitalício, o anual ou os dois? (Fase 7)
9. Nível "Pro" no futuro: reservar nome/ID desde já ou deixar para depois?
10. Quanto o teste grátis de uso e o anual podem confundir o usuário na tela de compra? Definir o texto e, se preciso, testar no beta.

**Fiscal:** já respondido no 3.1 (pessoa física; MEI não serve para vender software; contador para carnê-leão e formulários da Apple). Vale também para anual e vitalício.

---

## 4. Fases 0 a 7

> **Nota de ordem (10/11):** as fases mantêm os números, mas a execução segue esta sequência: Fase 0 + Fase 1 (inclui o item 1a, Bundle ID) → Pacotes A e B → **Fase 3** (pipeline) → **Beta 1** (Fase 4, sem compra) → **Fase 2** (compra, Pacotes C e D, resto) → **Beta 2** (com compra) → Fase 5 → Fase 6 → Fase 7. Motivo: sem Mac, a compra só pode ser testada numa versão assinada do TestFlight, então o pipeline vem antes.

### Fase 0 — Validação em campo (hoje, sem versão nova)
Critério para sair: você diz que está estável o bastante para outras pessoas.
1. **[VOCÊ]** Gravação longa (30 a 60 min) com a chave de calor ligada, num dia quente.
2. **[VOCÊ]** Clipes longos (5 min ou mais) e recuperação se o app fechar gravando.
3. **[VOCÊ]** Voz por 30 min ou mais em Comando.
4. **[VOCÊ]** Pouco espaço e bateria baixa (avisos).
5. **[VOCÊ]** iPhone 16 e iPhone 17 de amigos: pedir "Copiar" do Diagnóstico; **[EU]** leio e comparo com os critérios.
6. **[EU]** Caminhos de reserva nunca exercitados em aparelho (sem câmera combinada, sem ultra-angular, iOS mais antigo): listar o que dá para simular e o que só um aparelho real prova.
7. Adiados por você, decidir se entram antes do lançamento: foco na troca de lente, miniatura escura no Fotos, erro de áudio do player (área protegida, sozinha numa versão).

### Fase 1 — Burocracia (pode andar em paralelo à Fase 0)
1. **[VOCÊ]** Nome "Ei Clip": **sem registro no INPI por ora** (3.2). Fazer a consulta grátis no INPI (classes 9 e 42) e checar o nome na App Store antes de investir em divulgação. Registrar quando houver tração.
1a. **[JUNTOS]** **Bundle ID e identidade portátil (decidir antes do item 7):** o ID atual (`br.com.wpstecnologia.eiclip`) **não é mais considerado definitivo**. Trocar por `app.eiclip` (escolhido em 11/11; 3.12). **[VOCÊ]** já escolheu o texto; **[EU]** troco em `project.yml` numa versão própria e atualizo a regra "nunca mudar" do `CLAUDE.md`. Custo: o app instalado vira "novo" (permissões pedidas de novo; miniaturas locais perdidas; os clipes ficam nas Fotos). Depois do item 7, é permanente.
2. **[VOCÊ]** Apple ID **pessoal** (decisão de 10/11; ver 3.12), com verificação em duas etapas ligada. Usar sempre o **mesmo** Apple ID (hoje o Sideloadly usa outro, de conta grátis; ao entrar na conta paga o ID da equipe muda, então a instalação por Sideloadly deixa de ser o caminho).
3. **[VOCÊ]** Inscrever-se no Programa de Desenvolvedor (individual). Pagar US$ 99/ano. Acompanhar a aprovação.
4. **[VOCÊ]** Acordos, impostos e banco na App Store Connect: contrato de apps pagos, dados bancários e formulários fiscais. **Banco:** conta em nome da pessoa física (a conta PJ do MEI não deve servir *(a confirmar)*). **Decisão:** publicar como **pessoa física**; abrir **ME** só se precisar; o **MEI não serve** (3.1). *(contador: carnê-leão e formulários fiscais da Apple.)*
5. **[VOCÊ]** **Sem domínio por ora.** E-mail de suporte gratuito e dedicado ao app (não o da WPS) e **organização gratuita no GitHub** com nome neutro. A URL de suporte e as páginas legais ficam em **repositório separado** dessa organização, no GitHub Pages (3.5 e 3.12).
6. **[JUNTOS]** **Pacote A:** política de privacidade (3.8). **[EU]** redijo a partir do que o app realmente faz (fatos já conferidos: sem rede, voz no aparelho); **[VOCÊ]** leva o "Relatório para validação jurídica" ao chat jurídico e publica. *(O "a conferir" sobre voz no aparelho foi resolvido em 10/11.)*
7. **[VOCÊ]** Criar o registro do app na App Store Connect (nome, idioma principal pt-BR, Bundle ID, SKU).

### Fase 2 — O app pronto para o público (código, Onda de publicação)
Já pronto e validado (v0.9.5): zoom por pinça, ação "Abrir câmera" (toque nas costas/Atalhos/Siri), botões de volume como obturador. Ao entrar na conta paga, rever as ações do sistema (o ID da equipe do Sideloadly deixa de valer) e pensar em declarar pt-BR para a Siri.
Cada item é uma versão própria, testada no aparelho. Pela nota de ordem (seção 4), esta fase vem **depois do Beta 1**, exceto o Pacote B (item 13), que vem antes. Os itens 1 a 4 (acesso e compra) formam o **Beta 2**. Ordem sugerida:
1. **[EU] Núcleo de acesso (Core, com testes):** regra pura baseada em **fontes de direito** (teste por uso, assinatura, vitalício, código), com tabela de produtos e matriz de testes (3.13); nasce pronta para compra única, híbrido ou assinatura. Decisão em aberto: o que o app faz quando acaba o teste (sugestão: continua abrindo a Galeria e exportando o que já foi gravado; bloqueia gravar novos clipes).
2. **[EU] Contador de clipes no Keychain** (sobrevive à reinstalação). Sem conta e sem rede.
3. **[EU] Compra com StoreKit 2:** dois produtos (híbrido decidido em 11/11, ver 3.13): **acesso permanente** (compra única, "Ei Clip completo") e **anual** (assinatura), com as travas de 3.3 (nomenclatura, assinatura vencida, cobrança em duplicidade); tela de compra com textos formais, botão **Restaurar compras** (exigência da Apple), estados de erro e de espera. Testar no sandbox (lembrar: `originalAppVersion` fixo em "1.0" lá).
4. **[EU] Tela de resgate de código** (Códigos de Oferta, `presentOfferCodeRedeemSheet`): botão discreto em Ajustes. Ver Fase 7.
5. **[EU] Diagnóstico (decidido em 10/11, caminho híbrido):** a tela e o log completos ficam só no **beta (TestFlight)**. Na **versão da loja** a tela sai e o log deixa de ir para arquivo (configuração de compilação, sem mexer no comportamento da câmera). O **texto da fala reconhecida deixa de ser gravado** na versão pública. Se o usuário comum der problema depois do lançamento, reativar um modo de suporte numa atualização (e atualizar a política).
6. **[EU] Pacote C, primeira abertura e "Informações" em Ajustes** (3.10): por que pede câmera, microfone, voz e Fotos; textos de permissão (`Info.plist`) revisados; o que fazer se negar.
7. **[JUNTOS] Textos finais:** revisão geral, migração para `Textos.swift` (já prevista na etapa 3), pt-BR e, se quiser, inglês.
8. **[JUNTOS] Ícone, nome na tela inicial e tela de abertura** definitivos. Guardar o histórico de criação do ícone (3.2).
9. **[EU] Acessibilidade e aparelhos:** tamanho de texto grande, VoiceOver nos botões principais, iPad (decidir: só iPhone ou também iPad; só iPhone simplifica a revisão).
10. **[EU] Pedido de avaliação** (`requestReview`) só depois de um clipe bem-sucedido, nunca durante a gravação.
11. **[EU] Auditoria de pré-envio (só leitura):** **privacy manifest**, permissões declaradas × usadas, APIs sensíveis, **varredura de segredos no histórico do Git**, textos que citem "teste"/"beta"/"Sideloadly", links quebrados, e **varredura de todos os textos do app, da ficha e das páginas legais** por "vitalício", "para sempre", "ilimitado" e "grátis para sempre" (3.3, trava 1).
12. **[JUNTOS] Pacote D, Termos de Uso** (3.11), junto da onda da compra (itens 1 a 4). Você leva o relatório ao chat jurídico.
13. **[EU] Pacote B, privacy manifest e criptografia** (3.9). **Entra ANTES do Beta 1:** a Apple pergunta sobre criptografia a cada envio e reclama de APIs sem manifesto *(a confirmar)*.

### Fase 3 — Assinatura e entrega automática (CI)
O workflow atual gera IPA **não assinado**. Para a loja, precisa de assinatura da Apple. **Antecipada (10/11):** vem logo depois da Fase 1 e dos Pacotes A e B, antes da compra.
1. **[VOCÊ]** Criar a **chave da API da App Store Connect** (arquivo `.p8`, baixa uma única vez; guardar com segurança) e anotar o Issuer ID e o Key ID.
2. **[VOCÊ]** Cadastrar os segredos no GitHub Secrets (eu guio passo a passo). Nada de chave no código.
3. **[EU]** Novo workflow: `xcodebuild archive` com assinatura automática pela chave da API, exportar e **enviar ao TestFlight** em cada tag; número de build automático (hoje `CURRENT_PROJECT_VERSION` é manual).
4. **[EU]** Manter o workflow atual (IPA não assinado) como reserva até o novo estar validado.
5. **[JUNTOS]** Primeira entrega ao TestFlight; conferir que instala e abre.
*(a confirmar: detalhes de certificados e perfis; podem ser criados pela API na primeira execução.)*

### Fase 4 — Beta externo (TestFlight)
**Duas rodadas (10/11):** **Beta 1** = app atual, sem compra (valida assinatura, instalação e estabilidade; exige política e e-mail de contato, *(a confirmar)*). **Beta 2** = com a compra (híbrido: acesso permanente e anual, ver 3.13), testada no ambiente de teste da Apple *(a confirmar: pode exigir o contrato de apps pagos ativo)*. Cada rodada usa o critério de saída abaixo.
1. **[VOCÊ]** Preencher as informações de teste (descrição, e-mail de contato, o que testar).
2. **[VOCÊ]** Enviar para a revisão de beta (uma vez); costuma levar poucos dias.
3. **[VOCÊ]** Grupo 1: amigos e família (e-mail). Grupo 2: **influenciadores** com **link público** do TestFlight (dá para limitar a quantidade de vagas). Teste não passa pela compra; é só para avaliar e divulgar a versão. Publicidade deve ser **identificada como tal** (CDC/CONAR).
4. **[JUNTOS]** Canal simples para feedback (o beta mantém o Diagnóstico completo; avisar os testadores): pedir "Copiar" do Diagnóstico + o que aconteceu. Eu leio os logs e classifico (bug, ajuste, ideia).
5. **Critério para sair:** semana sem travamento, sem perda de clipe e sem erro novo no Diagnóstico nos aparelhos de teste.
6. Lembrete: o build do TestFlight vale 90 dias; manter builds novos.

### Fase 5 — Ficha da loja e revisão
1. **[JUNTOS]** Textos: nome, subtítulo, descrição, palavras-chave, categoria (Foto e Vídeo), novidades da versão.
2. **[JUNTOS]** Imagens: capturas de tela nos tamanhos exigidos *(a confirmar os tamanhos vigentes)* e vídeo de pré-visualização curto. Sugestão: mostrar o clipe retroativo em ação (pescaria).
3. **[VOCÊ]** Preço: escolher na tabela da Apple (acesso permanente e anual; ver 3.13; nome do produto "Acesso permanente", sem "vitalício") *(decidir valores)*; Compartilhamento em Família (decidir).
4. **[VOCÊ]** Questionário de **Privacidade do app**: responder **"dados não coletados"** (dado que fica só no aparelho não conta como coletado), coerente com a política (Pacote A). **Classificação etária:** responder com cuidado, à luz do **ECA Digital** (3.6). *(advogado)*
5. **[VOCÊ]** Conformidade de exportação (criptografia): resolvida pelo **Pacote B** (`ITSAppUsesNonExemptEncryption = false`, depois de confirmar que não há criptografia própria).
6. **[VOCÊ]** Informações para o revisor: como testar (o que fazer, como acionar a voz) e, como o app não tem login, nenhuma conta de teste; explicar o teste por uso e como ver a compra. Explicar também o que a assinatura entrega (acesso enquanto pago, preço menor que o acesso permanente) e que as duas liberam as mesmas funções (3.3, trava 5).
7. **[VOCÊ]** **Repositório, perto do envio** (3.4): varredura de segredos feita (Fase 2, item 11), depois tornar o repositório **privado**. Conferir que a URL da política (repositório separado) continua no ar.
8. **[VOCÊ]** Enviar para revisão. Costuma levar de 1 a 3 dias; prever pelo menos uma rejeição e um ajuste.
9. **[EU]** Se rejeitar: ler o motivo, propor correção (uma mudança por versão) e responder.
10. Escolher liberação **manual** após aprovação, para marcar a data do lançamento.

### Fase 6 — Lançamento
1. **[VOCÊ]** Liberar a versão. Conferir que o app baixa, abre e a compra funciona com uma conta real (compra de teste, depois reembolso se quiser).
2. **[JUNTOS]** Divulgação: ver Ideias. Antes de investir nela, a checagem do nome (item 1 da Fase 1) precisa estar feita.
3. **[EU]** Marcar a versão como estável em `docs/STATUS.md` com o link, como já fazemos, mais o número aprovado pela Apple.

### Fase 7 — Depois do lançamento e manutenção
1. **[JUNTOS] Programa de influenciadores:** Códigos de Oferta grátis (sobre o vitalício, o anual ou os dois: ver 3.13, pergunta 8), um código personalizado por pessoa (para saber de quem veio cada resgate). Eles devem identificar como publicidade (CDC/CONAR). Respeitar o limite de 10 ofertas ativas e validade de até 6 meses.
2. **[VOCÊ]** Acompanhar na App Store Connect: downloads, conversão para compra, avaliações, falhas (relatórios da Apple).
3. **[EU]** Corrigir falhas por versão pequena; manter a regra de uma mudança por versão e o ritmo de estável.
4. **[JUNTOS]** Renovar a conta (US$ 99/ano) e o build do TestFlight a cada 90 dias se continuar o beta.
5. **[EU]** **Política de privacidade atualizada sempre que mudar o que o app coleta** (analytics, iCloud, relatório de falhas), junto do privacy manifest e do questionário da loja. Revalidar o jurídico (topo do documento).
6. Reavaliar: migrar para conta de organização, pagamento alternativo no Brasil, outras lentes e aparelhos. **Se migrar de pessoa física para empresa, planejar a transferência do app** (vendedor, impostos, política e termos com novo titular, `LICENSE`; ver 3.12).
7. Se o registro do nome "Ei Clip" no INPI ficar para depois, reavaliar quando houver tração (3.2).

### Ordem prática resumida
Fase 0 e Fase 1 juntas (com o Bundle ID, item 1a) → Pacotes A e B → Fase 3 → Beta 1 (Fase 4) → Fase 2 (compra, C, D) → Beta 2 → Fase 5 → Fase 6 → Fase 7.
Dá para começar a Fase 1 (conta, política, repositório legal) a qualquer momento, sem gastar compilação.

---

## 5. Riscos a vigiar
- **Revisão da Apple** pode estranhar: gravação retroativa (buffer sempre ligado) → explicar claramente na ficha e na política que o buffer fica só no aparelho (memória) e é descartado; microfone sempre ativo em modo Comando → texto de uso claro.
- **Conta nova e pagamento:** o contrato de apps pagos e os dados bancários podem atrasar a loja; começar cedo (Fase 1).
- **iOS novo (27.x)** mudando comportamento da câmera ou do SwiftUI: manter a regra de não publicar estado durante a reconfiguração e o Diagnóstico como termômetro.
- **Aparelhos que nunca vimos:** decidir sempre pela capacidade informada, com reserva registrada no Diagnóstico.
- **Marca sem registro:** se outro registrar "Ei Clip" antes, pode ser preciso trocar o nome (risco aceito, 3.2). Mitigação: consulta grátis no INPI e checagem na App Store antes de divulgar.
- **Descontinuação:** sem lei de prazo, vale a boa-fé do CDC. Termos claros, aviso prévio; como o app é offline, quem comprou continua usando (3.3).
- **Repositório público até o envio:** qualquer segredo no histórico fica exposto, e o histórico já público não pode ser "des-publicado". Varredura antes de fechar (3.4).
- **ECA Digital:** risco parece baixo, mas a classificação etária e o sinal de idade das lojas exigem resposta cuidadosa (3.6).
- **Diagnóstico com texto da fala:** hoje o log local registra o que o microfone reconheceu. Decisão de 10/11: some da versão da loja (híbrido, Fase 2 item 5). Risco restante: sem o log, defeitos de câmera, calor e voz ficam mais difíceis de diagnosticar depois do lançamento; por isso o beta precisa ser completo (Fase 4).
- **Titular pessoa física:** o nome legal aparece na loja e responde pelo app. Trocar de titular depois exige planejamento (Fase 7). Mitigação: identidade portátil (3.12).
- **Bundle ID permanente:** depois do registro na App Store Connect não muda. Decidir antes (Fase 1, item 1a).
- **Sem domínio:** o nome, hoje livre, pode ser registrado por outra pessoa antes de você. Risco aceito (junto com a marca, 3.2); a URL da política não depende dele (fica no GitHub Pages da organização).
- **Inscrição na Apple:** em 11/11 o app recusou a verificação do documento (motivo não informado). Antes de pagar: nome da conta idêntico ao documento, país e endereço certos, cartão em seu nome com compras internacionais; se travar, chamado em developer.apple.com/contact (Membership and Account). A P4 depende dessa conta.
- **Compra sem Mac:** a compra só se testa por TestFlight; se o pipeline (Fase 3) atrasar, a compra atrasa junto. Por isso ele vem primeiro.
- **Nomenclatura enganosa:** "vitalício", "para sempre" ou "ilimitado" no app, na ficha ou na divulgação pode configurar propaganda enganosa (CDC, art. 37). Usar "Acesso permanente" e a varredura da Fase 2, item 11 (3.3, trava 1).
- **Assinatura recusada pela Apple** por falta de valor continuado num app offline. Plano B: estrear só com o acesso permanente e acrescentar o anual depois (3.3, trava 5).
- **Cobrança em duplicidade:** assinante que compra o acesso permanente segue pagando até cancelar. Aviso e atalho na tela de compra (3.3, trava 3).

---

## 6. Ideias (não prometidas, para avaliar depois)
- **Divulgação própria:** usar clipes reais feitos com o app no seu perfil de pesca como demonstração; vídeo curto "como funciona o clipe retroativo".
- **Página de divulgação** simples com lista de espera (e-mail) antes do lançamento.
- **Teste por uso em vez de por dias:** 10 a 15 clipes, sem relógio; evita o usuário perder o teste por não usar a semana inteira. Pode mostrar "restam N clipes de teste" em Ajustes (sem publicar estado novo durante a reconfiguração da câmera).
- **Preço de lançamento** por tempo limitado, via oferta da loja *(a confirmar o que vale para compra única)*.
- **Compartilhar o clipe com marca discreta** (opcional, desligável) para divulgação orgânica.
- **Inglês** como segundo idioma, depois de estável em português.
- **Avaliar o canal Brasil de pagamento alternativo** só se o volume justificar; começa simples com o pagamento da Apple.
- **Mini-site de suporte** com FAQ (permissões, calor, espaço, voz) para reduzir dúvidas. Pode morar no repositório legal separado.
