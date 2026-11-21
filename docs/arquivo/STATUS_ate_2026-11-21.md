# STATUS: trechos arquivados em 21/11/2026

## Fatos úteis (de 19/11)

- Padrão de fábrica 1080p60 Máxima, pré-gravação 30 s (`CaptureConfig.factoryDefault`); `CaptureConfig.standard` (1080p30) é o piso da redução por calor. O 4K fica sempre em 30 fps.
- Estimativa de espaço: (livre − 150 MB) ÷ ((taxa/8 + 24.000 B/s) × 2 cópias); "pouco espaço" em 1080p60 Máxima vale com menos de ~8 GB livres.
- Aviso de calor espera 60 s se o app abre já quente (`ThermalGovernor.quietOpening`); faixa de espaço na tela inicial (v0.9.16, ainda não vista no aparelho). Resumo das versões v0.9.14 a v0.9.17 e testes de calor A/B: `docs/arquivo/STATUS_ate_2026-11-20.md`.


Itens removidos do "Próximo passo" em 21/11:

2. **Design aprovado (v0.9.27):** anel/rádio amarelo `#ffd60a` na seleção, ícones de benefícios amarelos, vermelho só para falha de compra, verde só para acesso confirmado; "Acesso permanente" (nunca "vitalício"); texto legal mínimo 12 pt; botão X sobre o canto; gestos por `.edgeGestures`.
3. **Teste de tela bloqueada:** com o app em segundo plano a câmera e a voz fecham, então nenhum gatilho dispara (log de 21/11 confirma).
