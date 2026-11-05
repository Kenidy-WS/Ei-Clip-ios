# Roadmap por etapas

Uma etapa por vez. Cada etapa tem **critérios medidos**; só avança se todos baterem. Se algum falhar, paramos e escolhemos o caminho juntos (sem contornar).

## Regras (para o Kenidy acompanhar)

1. **Número da versão mostra a etapa:** etapa N = `v0.N.x`. Etapa 1 = `v0.1.0`, `v0.1.1`…; etapa 2 = `v0.2.0`…
2. **Uma mudança por versão**, com commit "vX.Y.Z: o que mudou". A versão aparece no app (Diagnóstico).
3. **Toda entrega termina igual:** (a) o que mudou, (b) o que testar no iPhone (lista numerada curta), (c) o que copiar do Diagnóstico, (d) o próximo passo.
4. **Estado sempre em `docs/STATUS.md`** (versão, etapa, pendências, o que falta testar). Este arquivo só muda quando o plano muda.

## Etapas

| Etapa | O que entrega | Critério de aprovação | Estado |
| ----- | ------------- | --------------------- | ------ |
| 0 — Preparação | Repositório, CI, instalação no iPhone | App "olá" compilado, instalado e aberto | **Concluída** (05/11) |
| 1 — Motor mínimo | Câmera 1080p30 + mic, buffer retroativo, gravar/parar, bipe, Rolo, Diagnóstico | (a) 20 aberturas, 0 microfones mudos · (b) clipe começa ±1 s do pré-tempo · (c) 5 min gravam e salvam sem travar · (d) áudio e vídeo em sincronia | **Em teste** (`v0.1.0`) |
| 2 — Voz | Palavra de ativação (SFSpeechRecognizer pt-BR), 3 palavras | Taxa de acerto em 50 falas (perto, com ruído) · falsos disparos em 5 min de conversa · voz + bipe sem chiado | A fazer |
| 3 — Interface | Início, Câmera, Ajustes iguais ao web app; em pé e deitado | Igual ao web app nas telas e textos; funciona nas duas orientações | A fazer |
| 4 — Paridade | Gravação longa direta, 4K30/1080p60, ultra-angular, frontal, nível, foco por toque, estabilização, recuperação | Cada item validado no iPhone | A fazer |

Fora do escopo agora: Android, monetização, App Store, TestFlight.

## Ritmo prático

- **Você testa e cola o Diagnóstico**; eu leio, comparo com o critério e digo "passou" ou "falhou, e por quê".
- **A cada 7 dias** o app expira: reinstalar pelo Sideloadly com o mesmo Apple ID (primeira instalação em 05/11).
- **Área protegida** (voz e sessão de áudio): mudanças vão sozinhas numa versão.
