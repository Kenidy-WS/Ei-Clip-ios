# Status

**Atualizado em:** 2026-11-06 · **Estável:** v0.6.26 · **Em teste:** v0.6.27 · **Etapa:** 7 (Onda 7: escopo proposto, aguardando o OK final do Kenidy depois do teste da v0.6.27). Etapas 0 a 6 fechadas. Histórico completo em `docs/HISTORICO.md`.

## Próximo passo (retomar aqui)

1. O Kenidy testa a **v0.6.27**: 3 minutos de uso normal (abrir a câmera, trocar lente e câmera, zoom, gravar por voz, parar) e a câmera parada por 1 minuto. Depois **Diagnóstico → Copiar** e cola no chat.
2. Conferir no log: linhas `vida:` a cada 30 s, nenhuma `tela: TRAVADA`, `pilha:`, `SEM QUADROS` nem erro do codificador. Dizer "passou" ou "falhou, e por quê".
3. Passando, o Kenidy aprova a v0.6.27 (aí ela vira "Versão estável" aqui).
4. O Kenidy dá o OK final no escopo da **Onda 7** (`docs/ROADMAP.md`). Esperar o "pode seguir" e começar a **v0.7.0**.
5. Antes de cada versão nova: esperar o "pode seguir" dele.

## Versão estável (para voltar se uma nova quebrar)

- **Estável: v0.6.26** (aprovada pelo Kenidy em 05/11, 23:57: 34 aberturas da câmera em 4 min com troca de lente, de câmera e zoom, câmera parada por mais de 1 min, 3 idas ao segundo plano, 2 gravações por voz salvas no Rolo; nenhuma linha TRAVADA, SEM QUADROS ou erro do codificador): https://github.com/Kenidy-WS/Ei-Clip-ios/releases/download/v0.6.26/EiClip.ipa
- Estáveis anteriores: v0.6.17 (travava a tela no iOS 27.0.1): https://github.com/Kenidy-WS/Ei-Clip-ios/releases/download/v0.6.17/EiClip.ipa · v0.5.8: https://github.com/Kenidy-WS/Ei-Clip-ios/releases/download/v0.5.8/EiClip.ipa · v0.4.17: https://github.com/Kenidy-WS/Ei-Clip-ios/releases/download/v0.4.17/EiClip.ipa
- Instalar sempre com o **mesmo Apple ID** no Sideloadly.
- Regra: uma versão só vira "estável" depois de testada no aparelho e com o OK do Kenidy; este bloco é atualizado nesse momento.

## Em teste

- **v0.6.26 aprovada pelo Kenidy e marcada como estável** (ver "Versão estável"). Causa do travamento: o aviso `isReconfiguring` publicado para a tela a cada troca de lente, em impasse com a atualização de layout do SwiftUI no iOS 27.0.1.
- **Mudança (só Diagnóstico, nada muda no app):** a linha `vida:` do vigia sai a cada 30 s em vez de 10 s (o Registro enche menos). As fotografias de pilha já só saem quando a tela trava ou os quadros param (no máximo 8 por rodada); o vigia continua ligado igual.

## Lição do travamento da tela (v0.6.17 a v0.6.26, resolvido)

- **Sintoma:** a tela do app congelava (câmera seguia rodando) e os quadros paravam 5 a 25 s depois; só fechando o app. Acontecia sobretudo logo depois de trocar de lente ou de câmera, em todas as versões a partir da v0.6.17, também depois de reiniciar o iPhone.
- **Causa (iOS 27.0.1, SwiftUI):** a linha principal ficava presa em `ObservableObjectPublisher.send()` publicando `isReconfiguring = true` (a cada troca de lente), enquanto o SwiftUI atualizava a tela numa linha fora da principal e esperava a principal. Impasse dentro do SwiftUI. O fim da v0.6.26 tirou esse aviso da tela e acabou o travamento.
- **Hipóteses descartadas pelo caminho:** nível, frontal, versão do app, iPhone em mau estado, leitura de espaço livre, quantidade de publicações (v0.6.23), tamanho da prévia (v0.6.25).
- **Regra que fica (vale para toda versão nova de tela):** não publicar (`@Published`) estado novo enquanto a câmera é reconfigurada, e não mudar `.disabled`/`.opacity` de vários botões de uma vez nesse momento. Estado novo da tela só em resposta a toque, ou lendo o que já existe (`chosen`, `lens`, `bufferSec`).
- **Ferramentas de diagnóstico que ficam:** vigia da tela (`MainThreadWatch`, linhas `tela:` e `câmera:`), `MainMark`/`mainAsync` (nomeiam a atualização de tela que estava rodando), fotografia das linhas de execução (`ThreadSampler`, linhas `pilha:`, só quando há travamento, no máximo 8 por rodada).

## Testes anotados para o Kenidy fazer quando puder (05/11)

1. Teste A3 da rodada da v0.6.16: falhou, sem detalhe do que era; dizer o que acontece se repetir.
2. Clipe longo (5 min ou mais): partes de 5 s, arquivo final e recuperação se o app fechar gravando.
3. Avisos de pouco espaço e de bateria baixa.
4. Estabilização em movimento (o enquadramento muda um pouco, esperado).
5. Voz: religamento do reconhecedor após 30 min ou mais em Comando.
6. Calor em dia quente (4K Máxima esquenta um pouco): trazer o Diagnóstico com "Redução por calor".

## Pendências abertas

- 4K 30 ainda lento nos primeiros usos (medir antes: travamentos da tela no Diagnóstico); 4K 60 bloqueado até isso (fora da Onda 7).
- Limites de redução por calor: esperar Diagnóstico de dia quente (fora da Onda 7).
- Pré-gravação 60 s no 4K 30: marcada 60 s, janela real 30 s, com nota nos Ajustes (decisão do Kenidy).
- Pequenos: migrar "Falha na sessão de áudio." para `Textos.swift` (área protegida, versão própria); registrar no log comandos de voz barrados pela regra de 3 s.
- Teste longo da voz (≥ 30 min em Comando, religar do reconhecedor): o Kenidy adiou; fazer quando ele pedir.

## Notas operacionais

- O repositório mudou de endereço no GitHub (`Kenidy-WS/Ei-Clip-ios`); o antigo redireciona e o push funciona. Para a API, `Kenidy-WS/ei-clip-ios` ainda responde.
- Sem toolchain Swift no ambiente: só o CI valida compilação e testes. Commits só de docs levam `[skip ci]`.
- `gh release view` falha (GraphQL 403): usar `gh api repos/Kenidy-WS/ei-clip-ios/releases/tags/vX.Y.Z`.
- Web app de referência (somente leitura): https://github.com/Kenidy-WS/clip (clonar raso para ler `src/core/` e `tests/`).
- O Diagnóstico agora é gravado em `Application Support/Diagnostico/atual.txt` (e a rodada anterior em `anterior.txt`); "Limpar" zera a tela e o arquivo da rodada atual.

## Decisões

- **Textos do usuário:** tom formal e claro; TODO texto novo entra em `Engine/Textos.swift` (revisão geral feita na v0.3.12). O Diagnóstico segue técnico.
- Bundle ID: `br.com.wpstecnologia.eiclip` (definitivo).
- Salvar sempre no álbum "Ei Clip" do Rolo. A galeria própria deixou de ser "não" e virou a etapa 4 (decisão do Kenidy em 05/11): ela lista só os clipes desse álbum (PhotoKit), sem copiar arquivos.
- Sem toolchain Swift no ambiente de desenvolvimento: lógica pura testada no CI macOS (`swift test` em `Core/`, o IPA só sai se passar).
- **Áudio do anel em PCM, não AAC:** cabe fácil na memória (~6 MB em 30 s) e o próprio arquivo codifica o AAC na gravação (sem trabalho de empacotar AAC à mão). Diverge do texto do plano ("H.264/AAC já codificados"); o vídeo continua codificado.
- 1080p30 fixo na etapa 1 (60 fps só na etapa 4); taxa/resolução vêm de `Core/VideoProfile.swift`.
- Reabrir a câmera sozinha ao voltar ao app é o comportamento desejado (hoje só o botão); entra depois de resolver o defeito de gravação.

## Onde está o resto

- `docs/ROADMAP.md`: etapas, critérios e a **proposta da Onda 7**.
- `docs/HISTORICO.md`: tudo que já foi feito e testado, versão por versão (antigo STATUS).
- `docs/ARCHITECTURE.md`: como o app é feito. `docs/MELHORIAS_FUTURAS.md`: ideias adiadas. `docs/AUDITORIA.md`: auditoria da etapa 4. `docs/RETOMADA.md`: texto para abrir um chat novo.
