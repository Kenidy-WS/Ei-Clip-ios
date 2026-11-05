# Ei Clip (iOS nativo) — guia para quem continua o desenvolvimento

App nativo (Swift/SwiftUI) do Ei Clip: câmera de ação com gravação retroativa (buffer de 15/30 s) e comando de voz.
Base e fonte de verdade do produto: o web app https://github.com/Kenidy-WS/clip (**somente leitura**: não alterar, não dar push, não mexer no deploy).
Este repositório é o protótipo grátis (conta Apple gratuita); se der certo, vira o app definitivo.

## Comece por aqui

1. Leia `docs/STATUS.md` (versão, etapa, pendências, o que o Kenidy deve testar), `docs/ROADMAP.md` (etapas e critérios) e `docs/ARCHITECTURE.md`.
2. Leia `CLAUDE.md` e `docs/` do web app para as armadilhas do iOS e as decisões de produto.

## Regras do projeto

- **Sem Mac/Xcode:** compila no GitHub Actions (macOS) com XcodeGen (`project.yml`; o `.xcodeproj` não é versionado). O workflow gera um **IPA não assinado** como artefato; o Kenidy assina na instalação com Sideloadly e um Apple ID gratuito.
- **Conta grátis:** o app expira em 7 dias, cerca de 3 apps ativos, sem TestFlight, sem push/iCloud. Usar só câmera, microfone, fala e Fotos.
- **Bundle ID definitivo:** `br.com.wpstecnologia.eiclip`. Nunca mudar (reinstalar por cima mantém as permissões). No aparelho o Sideloadly acrescenta o ID da equipe do Apple ID (`….eiclip.<equipe>`): instalar sempre com o **mesmo Apple ID**.
- **Segredos:** nunca colocar chaves, certificados ou senhas no código. Só em GitHub Secrets.
- **Uma mudança por versão**; a versão aparece no app. Commits em português: "vX.Y.Z: o que mudou". Subir a versão em `project.yml` (`MARKETING_VERSION`).
- **Versão estável:** `docs/STATUS.md` mantém o bloco "Versão estável" (última versão testada no aparelho, com o link do IPA para voltar). Atualizar quando o Kenidy aprovar uma versão testada.
- **Compilações macOS custam tempo:** não disparar uma por micro-mudança.
- **Lógica pura separada** de câmera/tela (como `src/core/` no web app), com testes (gabarito: `tests/` do web app).
- **Diagnóstico com botão "Copiar"** é o único log do aparelho.
- **Sem galeria própria:** ao parar, o clipe vai direto para o álbum "Ei Clip" do Rolo da Câmera (PhotoKit).
- O iOS não mantém a câmera em segundo plano: o app precisa ficar aberto com a tela ligada.

## Área protegida (voz e sessão de áudio)

Tudo que toca a sessão de áudio e o reconhecimento de voz (a criar nas etapas 1 e 2) vai **sozinho numa versão**, sem misturar com outro ajuste.

## Estilo de comunicação com o Kenidy

Ele tem conhecimento básico de front-end, não programa Swift, não tem Mac e usa iPhone + PC com Windows. Explicar em português simples, direto, listas curtas (lê no celular), tratando por "você". Quando precisar dele: "AÇÃO SUA", passo a passo numerado e o que ele deve ver na tela.
