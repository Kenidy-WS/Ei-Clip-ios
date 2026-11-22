# Histórico (resumo)

Só consulta. O registro detalhado e antigo está em `docs/arquivo/`:

- `docs/arquivo/HISTORICO_ate_v0.9.5.md`: versões e testes de 05 a 10/11 (etapas 0 a 10, lições do travamento da tela, resultados de cada versão).
- `docs/arquivo/STATUS_ate_2026-11-19.md`: o STATUS inteiro até 19/11 (atualizações de 11 a 19/11, IPAs antigos do Sideloadly, Beta 1, calor, voz).
- `docs/arquivo/ROADMAP_etapas_6_a_10.md`: escopo e andamento das etapas 6 a 10.

## Versões recentes (resumo, uma linha cada)

| Versão | Data | O que mudou |
| ------ | ---- | ----------- |
| v0.9.6 | 11/11 | Bundle ID neutro `app.eiclip` |
| v0.9.7 | 12/11 | Manifesto de privacidade, `ITSAppUsesNonExemptEncryption=false`, textos de permissão revisados |
| v0.9.9 | 14/11 | Rolagem da Galeria (SDK iOS 26); primeira build do Beta 1 |
| v0.9.10 | 14/11 | "Sons no vídeo" ligado por padrão |
| v0.9.11 | 15/11 | Calor: a escolha vale, redução só após falha da câmera (reserva); Compartilhar no Diagnóstico; Lente |
| v0.9.12 | 15/11 | Linha "Reduzido pelo calor" nos Ajustes |
| v0.9.13 | 17/11 | Diagnóstico sem a fala de fundo; estável no Beta 1 (build 9) |
| v0.9.14 | 19/11 | Padrão de fábrica 1080p60 Máxima, pré-gravação 30 s |
| v0.9.15 | 19/11 | Aviso de calor espera 60 s quando o app abre já quente |
| v0.9.16 | 19/11 | Faixa fixa de espaço na tela inicial (amarela < 15 min, vermelha < 3 min) |
| v0.9.17 | 19/11 | Ajustes marcam a pré-gravação que vale (30 s em 4K), guardam a escolha |
| v0.9.18 a v0.9.26 | 19 a 20/11 | C2 etapas 1 a 3: `AccessGate` (Core), contador no Keychain, StoreKit 2 em modo sombra, proteção de moeda dos preços, reabertura da câmera |
| v0.9.27 | 21/11 | C2 etapa 4: gate ativo em `startRecording()`, tela "Escolha seu acesso", chip na Home, avisos do 7º ao 10º clipe, "Meu plano" acima de "Aparelho", simulação de teste |
| v0.9.28 | 21/11 | Folha de Ajustes só com 580 pt (sem tela cheia, sem piscar) |
| v0.9.29 | 21/11 | C2 etapa 5a: assinatura lida também com o permanente, `willAutoRenew`/`autoRenewPreference`, carência x nova tentativa, releitura de produtos ao trocar a loja (Engine, sem tela) |
| v0.9.30 | 21/11 | Aviso de espaço da câmera acompanha a qualidade; ignora o aviso de loja sem mudança |
| v0.9.31 | 22/11 | C2 etapa 5b: tela "Meu plano" final (situações, avisos e alerta ao comprar o permanente, Gerenciar assinatura) |
| v0.9.32 | 22/11 | "Meu plano": aviso de rolagem, folha de 640 pt, espaçamentos menores, grupo "Só para teste" |
| v0.9.33 | 22/11 | Texto "até 60 segundos"; C2 etapa 6: último acesso confirmado no Keychain e proteção de relógio (tolerância offline de 7 dias) |
| v0.9.34 | 22/11 | Resultado da compra em folha própria (aprovada, nenhuma compra nova, permanente com aviso, erro) |

Detalhes e o raciocínio de 19/11 (testes de calor A/B, decisões) estão no `docs/STATUS.md`.
