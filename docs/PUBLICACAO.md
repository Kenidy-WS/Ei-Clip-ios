# Publicação do Ei Clip na App Store (documento único)

**Criado em:** 07/11/2026, a pedido do Kenidy. **Reorganizado em:** 10/11/2026.
**Estado:** plano para consulta. **Nada aqui começa sem o "pode seguir" dele.**
Este é o ÚNICO documento de publicação. Ele NÃO substitui o `ROADMAP.md` (etapas de código): quando a publicação começar, cada fase de código vira uma Onda nova lá, uma mudança por versão.

> **Jurídico validado em 10/11/2026; revalidar a cada mudança de dados coletados, de modelo de cobrança ou de titular (PF para empresa).**

Legenda: **[ELE]** só o Kenidy pode fazer (conta, banco, aceitar contratos) · **[EU]** o Claude faz no código/CI · **[JUNTOS]** · *(a confirmar)* = não foi verificado e precisa ser conferido na hora.
Aviso: o Kenidy não é advogado nem contador. Tudo marcado **"contador"** ou **"advogado"** precisa dessa confirmação antes de valer.

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
- **Modelo:** compra única; sem promessa de atualização eterna.
- **Repositório:** público por ora; fechar perto do envio.
- **Páginas legais:** em repositório público separado.
- **Idade (ECA Digital):** responder a classificação etária com cuidado.
- **Influenciadores:** publicidade identificada como tal.
- **Diagnóstico (10/11):** completo só no beta; na versão da loja, sem tela, sem log em arquivo e sem gravar o texto da fala.

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

---

## 2. Status por fase

Atualizar esta lista a cada avanço. "Pendente" = ainda não começou; só vira "feito" com o Kenidy confirmando.

| Fase | Status |
|---|---|
| 0 Validação em campo | Pendente |
| 1 Burocracia | Pendente. Item 6: **fatos de voz e rede conferidos no código em 10/11** (resolvido); política ainda não escrita |
| 2 App pronto para o público | Parcial: v0.9.5 já tem pinça, "Abrir câmera" e botões de volume (validado). Itens 1 a 13 pendentes |
| 3 Assinatura e CI | Pendente |
| 4 Beta (TestFlight) | Pendente |
| 5 Ficha e revisão | Pendente |
| 6 Lançamento | Pendente |
| 7 Depois do lançamento | Pendente |

Pacotes jurídicos:

| Pacote | O quê | Fase | Status |
|---|---|---|---|
| A | Política de privacidade | 1 | Fatos conferidos no código (10/11); texto a escrever |
| B | Privacy manifest, criptografia, permissões | 2 | Pendente |
| C | "Informações" em Ajustes e primeira abertura | 2 (item 6) | Pendente |
| D | Termos de Uso | 2 (junto dos itens 1 a 4) | Pendente |

---

## 3. Jurídico

Conteúdo validado no chat jurídico em 10/11/2026. O Kenidy não é advogado nem contador: o que diz **contador** ou **advogado** precisa dessa confirmação.

### 3.1 Titular e imposto
- Publicar como **pessoa física**.
- O **MEI não serve** para vender software: nenhum CNAE de desenvolvimento ou licenciamento de software é permitido ao MEI. **Não** registrar a venda como "suporte de TI".
- **Contador:** carnê-leão, formulários fiscais da Apple e quando abrir ME.
- O nome do vendedor na loja é o nome legal dele.
- Alinhar o `LICENSE` (hoje cita "Kenidy (WPS Tecnologia)") ao titular real. **[ELE]** decide o texto; **[EU]** edito.

### 3.2 Marca "Ei Clip"
- **Sem registro no INPI por ora** (decisão dele: caro, demorado, é protótipo).
- Risco aceito: se outro registrar antes, pode ser preciso trocar o nome.
- Mitigação mínima, antes de investir em divulgação: consulta grátis no INPI (classes 9 e 42) e checagem do nome na App Store.
- Registrar quando houver tração.
- "Clip" é descritivo e lembra o app "Clips" da Apple. O **logotipo** protege mais que o nome.
- O ícone foi criado com IA: autoria incerta. **Guardar o histórico de criação** (prompts, versões, datas). *(advogado)*

### 3.3 Modelo de cobrança e descontinuação
- **Compra única** (assinatura não se justifica para app offline, sem servidor).
- Nenhuma lei fixa prazo "vitalício"; vale a boa-fé do CDC.
- Como o app é offline, **parar de vender não desliga** quem já comprou.
- Termos: sem garantia de atualização eterna, aviso prévio e retirada da venda.
- Reembolso e arrependimento (7 dias): pela Apple.
- Se um dia houver assinatura: compromisso até o fim do período pago; descontinuar no meio exige reembolso proporcional.

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

**Ao final:** "Relatório para validação jurídica" (texto + fatos conferidos + divergências), para o Kenidy levar ao chat jurídico **antes de publicar**.

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
- Textos em `Engine/Textos.swift`, **mostrados ao Kenidy antes de implementar**.

### 3.11 Pacote D: Termos de Uso (Fase 2, junto dos itens 1 a 4)
Itens, nesta ordem:
1. Licença de **uso pessoal e intransferível**; EULA padrão da Apple em complemento.
2. Teste por uso e compra única descritos **exatamente** como o app se comporta.
3. Reembolso e arrependimento pela Apple.
4. Disponibilidade e descontinuação (3.3).
5. Limitações: iOS, calor, bateria, espaço. **Sem exclusão total de responsabilidade** (o CDC anularia).
6. Uso responsável: consentimento de pessoas gravadas, direito de imagem, leis locais.
7. Propriedade intelectual.
8. Suporte por e-mail.
9. Lei e foro brasileiros.

Também termina com "Relatório para validação jurídica".

---

## 4. Fases 0 a 7

### Fase 0 — Validação em campo (hoje, sem versão nova)
Critério para sair: ele diz que está estável o bastante para outras pessoas.
1. **[ELE]** Gravação longa (30 a 60 min) com a chave de calor ligada, num dia quente.
2. **[ELE]** Clipes longos (5 min ou mais) e recuperação se o app fechar gravando.
3. **[ELE]** Voz por 30 min ou mais em Comando.
4. **[ELE]** Pouco espaço e bateria baixa (avisos).
5. **[ELE]** iPhone 16 e iPhone 17 de amigos: pedir "Copiar" do Diagnóstico; **[EU]** leio e comparo com os critérios.
6. **[EU]** Caminhos de reserva nunca exercitados em aparelho (sem câmera combinada, sem ultra-angular, iOS mais antigo): listar o que dá para simular e o que só um aparelho real prova.
7. Adiados por ele, decidir se entram antes do lançamento: foco na troca de lente, miniatura escura no Fotos, erro de áudio do player (área protegida, sozinha numa versão).

### Fase 1 — Burocracia (pode andar em paralelo à Fase 0)
1. **[ELE]** Nome "Ei Clip": **sem registro no INPI por ora** (3.2). Fazer a consulta grátis no INPI (classes 9 e 42) e checar o nome na App Store antes de investir em divulgação. Registrar quando houver tração. O Bundle ID `br.com.wpstecnologia.eiclip` já é definitivo.
2. **[ELE]** Apple ID próprio para desenvolvedor, com verificação em duas etapas ligada. Usar sempre o **mesmo** Apple ID (hoje o Sideloadly usa outro, de conta grátis; ao entrar na conta paga o ID da equipe muda, então a instalação por Sideloadly deixa de ser o caminho).
3. **[ELE]** Inscrever-se no Programa de Desenvolvedor (individual). Pagar US$ 99/ano. Acompanhar a aprovação.
4. **[ELE]** Acordos, impostos e banco na App Store Connect: contrato de apps pagos, dados bancários e formulários fiscais. **Decisão:** publicar como **pessoa física**; abrir **ME** só se precisar; o **MEI não serve** (3.1). *(contador: carnê-leão e formulários fiscais da Apple.)*
5. **[ELE]** E-mail de suporte e domínio (ex.: página simples no domínio da WPS) para URL de suporte e página de divulgação. **As páginas legais ficam em repositório separado** (3.5).
6. **[JUNTOS]** **Pacote A:** política de privacidade (3.8). **[EU]** redijo a partir do que o app realmente faz (fatos já conferidos: sem rede, voz no aparelho); **[ELE]** leva o "Relatório para validação jurídica" ao chat jurídico e publica. *(O "a conferir" sobre voz no aparelho foi resolvido em 10/11.)*
7. **[ELE]** Criar o registro do app na App Store Connect (nome, idioma principal pt-BR, Bundle ID, SKU).

### Fase 2 — O app pronto para o público (código, Onda de publicação)
Já pronto e validado (v0.9.5): zoom por pinça, ação "Abrir câmera" (toque nas costas/Atalhos/Siri), botões de volume como obturador. Ao entrar na conta paga, rever as ações do sistema (o ID da equipe do Sideloadly deixa de valer) e pensar em declarar pt-BR para a Siri.
Cada item é uma versão própria, testada no aparelho. Ordem sugerida:
1. **[EU] Núcleo de acesso (Core, com testes):** regra pura do teste (quantos clipes, quando bloqueia, o que ainda funciona depois do teste). Decisão em aberto: o que o app faz quando acaba o teste (sugestão: continua abrindo a Galeria e exportando o que já foi gravado; bloqueia gravar novos clipes).
2. **[EU] Contador de clipes no Keychain** (sobrevive à reinstalação). Sem conta e sem rede.
3. **[EU] Compra única com StoreKit 2:** produto "Ei Clip completo", tela de compra com textos formais, botão **Restaurar compras** (exigência da Apple), estados de erro e de espera. Testar no sandbox.
4. **[EU] Tela de resgate de código** (Códigos de Oferta, `presentOfferCodeRedeemSheet`): botão discreto em Ajustes. Ver Fase 7.
5. **[EU] Diagnóstico (decidido em 10/11, caminho híbrido):** a tela e o log completos ficam só no **beta (TestFlight)**. Na **versão da loja** a tela sai e o log deixa de ir para arquivo (configuração de compilação, sem mexer no comportamento da câmera). O **texto da fala reconhecida deixa de ser gravado** na versão pública. Se o usuário comum der problema depois do lançamento, reativar um modo de suporte numa atualização (e atualizar a política).
6. **[EU] Pacote C, primeira abertura e "Informações" em Ajustes** (3.10): por que pede câmera, microfone, voz e Fotos; textos de permissão (`Info.plist`) revisados; o que fazer se negar.
7. **[JUNTOS] Textos finais:** revisão geral, migração para `Textos.swift` (já prevista na etapa 3), pt-BR e, se quiser, inglês.
8. **[JUNTOS] Ícone, nome na tela inicial e tela de abertura** definitivos. Guardar o histórico de criação do ícone (3.2).
9. **[EU] Acessibilidade e aparelhos:** tamanho de texto grande, VoiceOver nos botões principais, iPad (decidir: só iPhone ou também iPad; só iPhone simplifica a revisão).
10. **[EU] Pedido de avaliação** (`requestReview`) só depois de um clipe bem-sucedido, nunca durante a gravação.
11. **[EU] Auditoria de pré-envio (só leitura):** **privacy manifest**, permissões declaradas × usadas, APIs sensíveis, **varredura de segredos no histórico do Git**, textos que citem "teste"/"beta"/"Sideloadly", links quebrados.
12. **[JUNTOS] Pacote D, Termos de Uso** (3.11), junto da onda da compra (itens 1 a 4). O Kenidy leva o relatório ao chat jurídico.
13. **[EU] Pacote B, privacy manifest e criptografia** (3.9).

### Fase 3 — Assinatura e entrega automática (CI)
O workflow atual gera IPA **não assinado**. Para a loja, precisa de assinatura da Apple.
1. **[ELE]** Criar a **chave da API da App Store Connect** (arquivo `.p8`, baixa uma única vez; guardar com segurança) e anotar o Issuer ID e o Key ID.
2. **[ELE]** Cadastrar os segredos no GitHub Secrets (eu guio passo a passo). Nada de chave no código.
3. **[EU]** Novo workflow: `xcodebuild archive` com assinatura automática pela chave da API, exportar e **enviar ao TestFlight** em cada tag; número de build automático (hoje `CURRENT_PROJECT_VERSION` é manual).
4. **[EU]** Manter o workflow atual (IPA não assinado) como reserva até o novo estar validado.
5. **[JUNTOS]** Primeira entrega ao TestFlight; conferir que instala e abre.
*(a confirmar: detalhes de certificados e perfis; podem ser criados pela API na primeira execução.)*

### Fase 4 — Beta externo (TestFlight)
1. **[ELE]** Preencher as informações de teste (descrição, e-mail de contato, o que testar).
2. **[ELE]** Enviar para a revisão de beta (uma vez); costuma levar poucos dias.
3. **[ELE]** Grupo 1: amigos e família (e-mail). Grupo 2: **influenciadores** com **link público** do TestFlight (dá para limitar a quantidade de vagas). Teste não passa pela compra; é só para avaliar e divulgar a versão. Publicidade deve ser **identificada como tal** (CDC/CONAR).
4. **[JUNTOS]** Canal simples para feedback (o beta mantém o Diagnóstico completo; avisar os testadores): pedir "Copiar" do Diagnóstico + o que aconteceu. Eu leio os logs e classifico (bug, ajuste, ideia).
5. **Critério para sair:** semana sem travamento, sem perda de clipe e sem erro novo no Diagnóstico nos aparelhos de teste.
6. Lembrete: o build do TestFlight vale 90 dias; manter builds novos.

### Fase 5 — Ficha da loja e revisão
1. **[JUNTOS]** Textos: nome, subtítulo, descrição, palavras-chave, categoria (Foto e Vídeo), novidades da versão.
2. **[JUNTOS]** Imagens: capturas de tela nos tamanhos exigidos *(a confirmar os tamanhos vigentes)* e vídeo de pré-visualização curto. Sugestão: mostrar o clipe retroativo em ação (pescaria).
3. **[ELE]** Preço: escolher na tabela da Apple (compra única) *(decidir valor)*; Compartilhamento em Família (decidir).
4. **[ELE]** Questionário de **Privacidade do app**: responder **"dados não coletados"** (dado que fica só no aparelho não conta como coletado), coerente com a política (Pacote A). **Classificação etária:** responder com cuidado, à luz do **ECA Digital** (3.6). *(advogado)*
5. **[ELE]** Conformidade de exportação (criptografia): resolvida pelo **Pacote B** (`ITSAppUsesNonExemptEncryption = false`, depois de confirmar que não há criptografia própria).
6. **[ELE]** Informações para o revisor: como testar (o que fazer, como acionar a voz) e, como o app não tem login, nenhuma conta de teste; explicar o teste por uso e como ver a compra.
7. **[ELE]** **Repositório, perto do envio** (3.4): varredura de segredos feita (Fase 2, item 11), depois tornar o repositório **privado**. Conferir que a URL da política (repositório separado) continua no ar.
8. **[ELE]** Enviar para revisão. Costuma levar de 1 a 3 dias; prever pelo menos uma rejeição e um ajuste.
9. **[EU]** Se rejeitar: ler o motivo, propor correção (uma mudança por versão) e responder.
10. Escolher liberação **manual** após aprovação, para marcar a data do lançamento.

### Fase 6 — Lançamento
1. **[ELE]** Liberar a versão. Conferir que o app baixa, abre e a compra funciona com uma conta real (compra de teste, depois reembolso se quiser).
2. **[JUNTOS]** Divulgação: ver Ideias. Antes de investir nela, a checagem do nome (item 1 da Fase 1) precisa estar feita.
3. **[EU]** Marcar a versão como estável em `docs/STATUS.md` com o link, como já fazemos, mais o número aprovado pela Apple.

### Fase 7 — Depois do lançamento e manutenção
1. **[JUNTOS] Programa de influenciadores:** Códigos de Oferta grátis sobre a compra única, um código personalizado por pessoa (para saber de quem veio cada resgate). Eles devem identificar como publicidade (CDC/CONAR). Respeitar o limite de 10 ofertas ativas e validade de até 6 meses.
2. **[ELE]** Acompanhar na App Store Connect: downloads, conversão para compra, avaliações, falhas (relatórios da Apple).
3. **[EU]** Corrigir falhas por versão pequena; manter a regra de uma mudança por versão e o ritmo de estável.
4. **[JUNTOS]** Renovar a conta (US$ 99/ano) e o build do TestFlight a cada 90 dias se continuar o beta.
5. **[EU]** **Política de privacidade atualizada sempre que mudar o que o app coleta** (analytics, iCloud, relatório de falhas), junto do privacy manifest e do questionário da loja. Revalidar o jurídico (topo do documento).
6. Reavaliar: migrar para conta de organização, pagamento alternativo no Brasil, outras lentes e aparelhos. **Se migrar de pessoa física para empresa, planejar a transferência do app** (vendedor, impostos, política e termos com novo titular, `LICENSE`).
7. Se o registro do nome "Ei Clip" no INPI ficar para depois, reavaliar quando houver tração (3.2).

### Ordem prática resumida
Fase 0 e Fase 1 juntas → Fase 2 → Fase 3 → Fase 4 → Fase 5 → Fase 6 → Fase 7.
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
- **Titular pessoa física:** o nome legal aparece na loja e responde pelo app. Trocar de titular depois exige planejamento (Fase 7).

---

## 6. Ideias (não prometidas, para avaliar depois)
- **Divulgação própria:** usar clipes reais feitos com o app no perfil de pesca dele como demonstração; vídeo curto "como funciona o clipe retroativo".
- **Página de divulgação** simples com lista de espera (e-mail) antes do lançamento.
- **Teste por uso em vez de por dias:** 10 a 15 clipes, sem relógio; evita o usuário perder o teste por não usar a semana inteira. Pode mostrar "restam N clipes de teste" em Ajustes (sem publicar estado novo durante a reconfiguração da câmera).
- **Preço de lançamento** por tempo limitado, via oferta da loja *(a confirmar o que vale para compra única)*.
- **Compartilhar o clipe com marca discreta** (opcional, desligável) para divulgação orgânica.
- **Inglês** como segundo idioma, depois de estável em português.
- **Avaliar o canal Brasil de pagamento alternativo** só se o volume justificar; começa simples com o pagamento da Apple.
- **Mini-site de suporte** com FAQ (permissões, calor, espaço, voz) para reduzir dúvidas. Pode morar no repositório legal separado.
