# Melhorias futuras (além do web app)

Ideias que só o app nativo permite, ou que o web app não tem. **Nada daqui está aprovado nem em andamento:** é a lista para o Kenidy escolher depois da etapa 6. Em 05/11 o Kenidy trouxe para a etapa 6 a pré-gravação de 60 s, a Galeria por dia e os 4 itens de proteção em campo; eles saíram desta lista e estão em `docs/ROADMAP.md` (etapa 6). Cada item vira uma versão própria quando for aprovado.

## Decisões de 06/11

- **Adiadas pelo Kenidy (sem versão marcada):** vibração e cortar clipe. (Os atalhos do sistema foram feitos na Onda 10, v0.9.2 a v0.9.5.) Os atalhos (botão de Ação, Siri) são os que mais interessam; exigem verificar a conta gratuita e, para o botão de Ação, subir o iOS mínimo de 16 para 17 (não afeta o iPhone do Kenidy, que está no iOS 27).
- **Saiu desta lista e foi para a Onda 7 (`docs/ROADMAP.md`):** EV (compensação de exposição), isolado e por último.

## Câmera e gravação

- **Pré-gravação de 10 s** (o de 60 s foi para a etapa 6).
- **Palavra de ativação personalizada:** o usuário escolhe a própria frase (hoje são 3 fixas). Área protegida (voz): vai sozinha numa versão.
- **Retorno tátil (vibração)** ao começar e ao parar a gravação, útil com o aparelho no suporte ou dentro de capa.

- **Foco ao trocar de lente — o desfoque rápido e sutil na troca (Kenidy, 06/11: "possibilidade futura").** Visto mais com objeto na frente; coincidiu uma vez com foco ajustando (F na trilha do zoom da v0.7.12). Duas ideias, nenhuma feita:
  - **Fixar o ponto de foco no centro ao trocar de lente (a que o Kenidy achou mais interessante):** ao trocar de lente, apontar foco e exposição para o centro (como o `setFocus` do toque, sem o monitor de mudança de cena), mas **sem sobrescrever um foco que o usuário tocou** (se houver foco tocado ativo, mantê-lo). Tira do iPhone a decisão de "o que focar" no sensor novo, que é o que parece causar o desfoque; o toque para focar já deixava a troca normal nos testes dele. Com decisão pela capacidade do aparelho, reserva e registro no Diagnóstico (usar F/E da trilha para conferir).
  - **Foco automático suave para vídeo** (`isSmoothAutoFocusEnabled`, com checagem de capacidade e reserva): reduz a caça de foco na gravação; custo: o foco fica um pouco mais lento (avaliar para ação).

## Galeria e player

- **Cortar o clipe** (início e fim) direto no player.
- **Passar quadro a quadro** e **ampliar (zoom)** no player.
- **Rolagem automática** ao selecionar arrastando perto da borda da grade.
- **Seleção seguindo o trajeto do dedo** (hoje seleciona pelo ponto atual).

## Atalhos do sistema

- **FEITO (Onda 10, 07/11 a 10/11):** ação "Abrir câmera" (App Intents) para toque nas costas, Atalhos, Siri e Botão de Ação; tela preta no lugar do Início; botões de volume como obturador (v0.9.2 a v0.9.5). Ver `docs/ARCHITECTURE.md`.
- **"Iniciar gravação" pelo atalho (só se ele pedir):** abre a câmera e já grava; com o app fechado o buffer retroativo recomeça do zero (sem pré-clipe), então o texto da ação precisa dizer isso. Versão própria.
- **Camera Control (iPhone 16 em diante) e Botão de Ação como obturador dentro do app:** o mesmo `AVCaptureEventInteraction` (alças primária e secundária) recebe esses botões; testar quando houver um aparelho com eles (o iPhone dele não tem). Ideia: um botão liga/para, o outro marca um momento.
- **Siri em português:** o app ainda não declara o idioma (pt-BR) para as frases do Atalhos; a frase por voz pode não funcionar. Só se ele quiser, avaliando o efeito de declarar o idioma em todo o app (textos do sistema).
- **Botão no Centro de Controle/tela bloqueada e abrir pela tela bloqueada:** exigem extensão e permissão especial da Apple; só depois da conta paga (`docs/PUBLICACAO.md`).

## App definitivo

- **Esconder o Diagnóstico** na versão final (ou deixá-lo só em um modo de suporte).
- **Publicação, compra única, teste por uso e códigos de oferta para influenciadores (07/11):** plano completo em `docs/PUBLICACAO.md`.

## Ajuda e primeira abertura (18/11, ideia do Kenidy após ver o Fisgou Câmera; só registro, nada implementado)

- **Tela de primeira abertura:** só na primeira vez, com no máximo 4 pontos e botão "Entendi" (não travar com o botão lateral; manter o app aberto com a tela ligada; como acionar o clipe; aviso de calor). Texto novo em `Engine/Textos.swift`.
- **"Como usar" nos Ajustes:** linha que reabre o mesmo texto.
- **Botão "i" na câmera, a testar na prática:** posição escolhida pelo Kenidy (18/11): **logo abaixo do botão de Ajustes (engrenagem)**, na barra de cima. Alternativa descartada por ora: entre a galeria e o obturador (área de gesto rápido, risco de toque acidental). Regras: ícone pequeno e discreto, abre o mesmo texto curto, **sem painel que empurre os outros botões** (o que ele estranhou no concorrente). Só fixar depois de testar o visual e ouvir o Beta.
- **Outras ideias vindas do concorrente (18/11):** opção "abrir direto na câmera" (hoje abre na tela inicial com galeria; avaliar como ajuste opcional), frase de voz personalizada, controle remoto Bluetooth, Android, 4K só depois de dados de calor.

## Visão externa (Codex, 07/11)

- **Refatorar o `CaptureEngine` aos poucos (primeira sugestão dele; o Kenidy concorda no ritmo, não em fazer tudo de uma vez):** o arquivo passou de 2.100 linhas. Objetivo: corrigir e acrescentar funções mexendo em partes pequenas. Hipótese de método, a avaliar quando ele pedir: uma onda própria, com auditoria só de leitura antes; uma peça por versão, **sem mudar comportamento**, conferida pelo Diagnóstico (mesmos números de antes); começar pelos blocos mais isolados (zoom/lentes, EV/foco, lanterna, calor) como tipos próprios; áudio e voz (área protegida) por último e cada um sozinho numa versão. Atenção: propriedades armazenadas não ficam em `extension`, e o que hoje é `private` precisaria ser reorganizado; manter a regra de não publicar (`@Published`) durante a reconfiguração da câmera.
- Outras observações dele entram aqui conforme o Kenidy colar, marcadas como hipótese até serem conferidas.

## Calor, espaço e voz (19/11, após os testes A/B de calor)

- **Primeiro aviso de calor ao abrir o app:** hoje abrir já "morno/quente" dispara o aviso. Entra na v0.9.15 (decisão a tomar: atraso de N segundos e/ou avisar só se piorar depois da abertura). O aviso dá cerca de 6 a 16 min de antecedência antes do crítico, por isso fica.
- **B′ (crítico reduz 60→30 fps):** só se o Beta mostrar interrupções por calor com o novo padrão. A chave de redução automática segue desligada de fábrica.
- **Aviso de espaço (versão própria, teste a definir por ele):** (a) mostrar o aviso uma vez só, na tela onde está o usuário (Home ou câmera), sem repetir ao trocar de tela; (b) duração maior e fixa para esse aviso (hoje 6 s no nível atenção), ou aviso que fica até o toque. Dependência: decidir depois do teste.
- **Voz:** limpar o log (só registrar `voz: parcial` quando o texto filtrado mudar, ~85% menos linhas), versão própria na área protegida. Observação de campo: ruído de torneira e batidas mascaram o comando; música baixa não dispara sozinha, só se formar a palavra de ativação.
- **Simular calor e pouco espaço (19/11):** os avisos de calor (abrir já quente) e de espaço são difíceis de testar no aparelho. Ideia (opcional, a avaliar): ferramenta no Diagnóstico para simular "espaço livre = X GB" e "estado térmico = quente", só para teste, sem afetar o uso normal. Nasceu de não ter conseguido ver a faixa de espaço da v0.9.16.
- **Pré-gravação limitada pela memória (19/11, observação dele):** em 4K a janela máxima é 30 s, mas nos Ajustes dá para tocar em 60 s; aparece o aviso "limitada a 30 s" e o botão 60 s continua marcado. Proposta: mostrar marcado o valor **efetivo** (30 s) e guardar a escolha (60 s), para voltar a 60 s quando ele trocar para 1080p. Alternativa: gravar 30 s de fato (perde o 60 s ao voltar). Versão própria, só na tela de Ajustes (`SettingsSheet.swift`, `BufferWindow.effective`).
- **4K 60 fps (19/11, pergunta dele):** hoje `CaptureConfig.validated()` força 4K em 30 fps (não existe 4K60 no app). Viável tecnicamente, decidindo pela capacidade do formato do aparelho (reserva: 4K30), taxa teto de 50 Mbps (anel de 30 s ≈ 190 MB, cabe), mas pesa em calor e exige testar a codificação H.264 4K60 no aparelho. Versão própria, depois de dados de calor do Beta; mexe em `validated()`, `FormatPicker`, lista de fps nos Ajustes e na escada de redução por calor.
- **Feedback com envio 100% automático (23/11, ideia dele):** hoje (v0.9.40) o relato e o Diagnóstico vão por e-mail pronto, e a pessoa toca em enviar. Envio automático exigiria servidor próprio para receber, aviso e consentimento na tela, política de privacidade e declaração de dados de diagnóstico na App Store Connect (junto da etapa de Termos com advogado). Fazer no lançamento público, se valer a pena.
