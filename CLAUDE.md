# Ei Clip (iOS nativo) — guia para quem continua o desenvolvimento

App nativo (Swift/SwiftUI) do Ei Clip: câmera de ação com gravação retroativa (buffer de 15/30 s) e comando de voz.
Base e fonte de verdade do produto: o web app https://github.com/Kenidy-WS/clip (**somente leitura**: não alterar, não dar push, não mexer no deploy).
Este repositório é o protótipo grátis (conta Apple gratuita); se der certo, vira o app definitivo.

## Comece por aqui

1. Leia `docs/STATUS.md` (versão, etapa, **próximo passo**, o que o Kenidy deve testar), `docs/ROADMAP.md` (etapas, critérios e a Onda 8) e `docs/ARCHITECTURE.md`. O que já foi feito está em `docs/HISTORICO.md` (só consulta). Para abrir um chat novo: `docs/RETOMADA.md`.
2. Leia `CLAUDE.md` e `docs/` do web app para as armadilhas do iOS e as decisões de produto.

## Regras do projeto

- **Sem Mac/Xcode:** compila no GitHub Actions (macOS) com XcodeGen (`project.yml`; o `.xcodeproj` não é versionado). O workflow gera um **IPA não assinado** como artefato; o Kenidy assina na instalação com Sideloadly e um Apple ID gratuito.
- **Conta grátis:** o app expira em 7 dias, cerca de 3 apps ativos, sem TestFlight, sem push/iCloud. Usar só câmera, microfone, fala e Fotos.
- **Bundle ID definitivo:** `br.com.wpstecnologia.eiclip`. Nunca mudar (reinstalar por cima mantém as permissões). No aparelho o Sideloadly acrescenta o ID da equipe do Apple ID (`….eiclip.<equipe>`): instalar sempre com o **mesmo Apple ID**.
- **Segredos:** nunca colocar chaves, certificados ou senhas no código. Só em GitHub Secrets.
- **Ramos e tags:** o trabalho vive no `main` (ramos antigos já unidos podem restar no GitHub; o proxy do ambiente não deixa apagar ramos remotos, quem apaga é o Kenidy pela página de ramos); cada versão `vX.Y.Z` nasce em ramo de mesmo nome e o CI cria tag e release `vX.Y.Z` (ficam para sempre). Como tag e ramo têm o mesmo nome, empurrar com `git push origin HEAD:refs/heads/vX.Y.Z` e unir com `git merge --ff-only refs/heads/vX.Y.Z` (o nome puro pega a tag, que não tem os commits de docs posteriores). Depois de unir e aprovar, apagar o ramo local.
- **Uma mudança por versão**; a versão aparece no app. Commits em português: "vX.Y.Z: o que mudou". Subir a versão em `project.yml` (`MARKETING_VERSION`).
- **Versão estável:** `docs/STATUS.md` mantém o bloco "Versão estável" (última versão testada no aparelho, com o link do IPA para voltar). Atualizar quando o Kenidy aprovar uma versão testada.
- **Compilações macOS custam tempo:** não disparar uma por micro-mudança. Commit só de documentos leva `[skip ci]` no fim da mensagem.
- **Tela (SwiftUI, iOS 27):** não publicar (`@Published`) estado novo enquanto a câmera é reconfigurada, nem mudar `.disabled`/`.opacity` de vários botões de uma vez nesse momento (travou a tela nas v0.6.17 a v0.6.25; ver `docs/ARCHITECTURE.md`). Trabalho do motor na fila principal usa `mainAsync`.
- **Vários aparelhos, sempre com reserva (Kenidy, 06/11):** não dá para testar em todos os iPhones. Decidir pela **capacidade** que o aparelho informa (formatos, fatores de zoom, câmeras disponíveis), nunca pelo nome do modelo. Todo caminho novo mantém o caminho atual como **reserva**, que entra sozinho se o aparelho não oferecer o necessário ou a abertura falhar, e **registra no Diagnóstico** o motivo.
- **Visão externa (Kenidy, 07/11):** o ChatGPT/Codex está conectado ao GitHub só para **avaliar** o projeto e os processos (não altera código; tudo é feito por aqui). A opinião dele é a que **menos pesa** nas decisões: tratar como hipótese, conferir no código e no Diagnóstico, avaliar junto com o Kenidy. Ideia aceita entra no funil de sempre (uma mudança por versão, depois do "pode seguir"). Ideias dele ficam em `docs/MELHORIAS_FUTURAS.md`.
- **Lógica pura separada** de câmera/tela (como `src/core/` no web app), com testes (gabarito: `tests/` do web app).
- **Diagnóstico com botão "Copiar"** é o único log do aparelho.
- **Sem galeria própria:** ao parar, o clipe vai direto para o álbum "Ei Clip" do Rolo da Câmera (PhotoKit).
- O iOS não mantém a câmera em segundo plano: o app precisa ficar aberto com a tela ligada.

## Área protegida (voz e sessão de áudio)

Tudo que toca a sessão de áudio e o reconhecimento de voz (a criar nas etapas 1 e 2) vai **sozinho numa versão**, sem misturar com outro ajuste.

## Estilo de comunicação com o Kenidy

Ele tem conhecimento básico de front-end, não programa Swift, não tem Mac e usa iPhone + PC com Windows. Explicar em português simples, direto, listas curtas (lê no celular), tratando por "você". Quando precisar dele: "AÇÃO SUA", passo a passo numerado e o que ele deve ver na tela.

- **Terceira pessoa × "você":** `CLAUDE.md`, `STATUS.md` e demais documentos de instrução falam do Kenidy em terceira pessoa (são para o próximo Claude). **`docs/PUBLICACAO.md` fala direto com ele ("você", tag [VOCÊ]), porque é ele quem o consulta.** Na conversa, sempre "você".
- **Textos que o usuário lê no app:** tom formal e claro; textos novos em `Engine/Textos.swift` (a migração dos demais e a revisão geral de textos ficam para a etapa 3).
- **Não lembrar** o Kenidy, a cada resposta, de que o app expira em 7 dias (ele pediu); só tratar do assunto se ele trouxer.
- **Fluxo de teste:** ele instala a versão, cola o Diagnóstico (Copiar); ler o log, comparar com os critérios do ROADMAP e dizer "passou" ou "falhou, e por quê". Esperar o "pode seguir" dele antes de cada versão nova.
- **Trabalho em ondas (padrão, pedido dele em 11/11, vale para código e para qualquer assunto):** muita coisa de uma vez o confunde. Quebrar o trabalho em blocos pequenos, cada um com **começo, meio e fim**: um objetivo só, 2 a 4 passos, dono de cada passo ([ELE], [EU], [JUNTOS]) e um **"pronto quando"** claro. Mostrar **só a onda atual** (o mapa completo fica no documento), dizer o progresso ("onda 2 de 5") e, ao fechar, resumir o que foi concluído e atualizar o status no documento antes de abrir a próxima, com o "pode seguir" dele. Se algo parecer grande demais, quebrar em blocos assim sem ele precisar pedir. A publicação já está organizada nas ondas P1 a P5 (`docs/PUBLICACAO.md`, seção 2).
