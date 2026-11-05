# Auditoria (05/11, fim da etapa 4)

Só leitura: nada foi alterado no código por causa dela. Base: 4.741 linhas de Swift (Engine 2.100 · App 2.640 · Core com 14 arquivos de testes). Serve de base para a onda de refatoração e para a revisão das decisões presas ao web app (ver `ROADMAP.md`, "Princípios").

## Veredito

**A refatoração vale a pena, em fatias pequenas e antes da etapa de recursos do nativo.** Nada está quebrado: o app passou em todos os testes do aparelho. O motivo é preparar o terreno: foco, estabilização, lentes e 4K60 vão mexer no mesmo arquivo (`CaptureEngine`, 932 linhas) e hoje ele tem a resolução, os fps e a câmera traseira escritos no código.

## Achados

**Bug (corrigir primeiro)**
- A pré-gravação de 30 s **não é salva**: `windowSec` começa sempre em 15 (`CaptureEngine.swift:47`; as outras preferências usam `UserDefaults`). Escolher 30 s e reabrir o app volta para 15 s.

**Estrutura (pesa nas próximas etapas)**
1. `CaptureEngine` (932 linhas) faz tudo: preferências (5 chaves), captura, gravação, bipe, voz, observadores do sistema e o painel do Diagnóstico. Resolução, fps, lente e câmera estão fixos em `configureAndStart`.
2. `RootView` controla a navegação com 6 variáveis soltas (`inGallery`, `parked`, `galleryFromCamera`, `cameraPlayer`, `opening`, `closingTask`). Funciona, mas não tem teste e cada tela nova multiplica os casos. Dá para virar uma máquina de estados no Core (como `ScreenFlow`), testável.
3. `ClipPlayerView` (445 linhas) mistura vídeo, barras, gestos, detalhes, compartilhar e apagar. O aviso curto ("toast") está duplicado na Galeria e no player.
4. Os gestos de borda são **faixas de 28 pt** por cima da tela: funcionam, mas tomam os toques daquela borda (por isso as margens de 28 pt nos botões). O iOS tem o gesto de borda nativo (`UIScreenEdgePanGestureRecognizer`), que não bloqueia nada.
5. As miniaturas pedem a imagem sem cache e sem cancelar (`RecentClips.swift:122`). Com dezenas de clipes está bom; com centenas, não.
6. Só o Core tem testes (14 arquivos). A interface e o motor dependem do teste no iPhone.
7. O CI só testa e compila. Não confere estilo nem avisos do compilador.

**Bom como está (não mexer)**: separação Core/Engine/App, lógica pura testada (buffer, voz, seleção, gestos), Diagnóstico completo, sessão de áudio centralizada em `AudioSessionConfig`, trava única (`lock`) no motor, nenhuma falha de captura nos logs.

## Proposta: onda de refatoração (etapa 5, `v0.5.x`)

Cada versão muda **uma coisa, sem mudar o comportamento**; o Diagnóstico antes e depois deve bater (abertura < 450 ms, 0 quadros descartados, pico do microfone > 0,0008, voz religando). A etapa de recursos do nativo passa a ser a **6** (`v0.6.x`).

| Versão | O que faz | Risco |
| ------ | --------- | ----- |
| v0.5.0 | Corrige a pré-gravação (salva 15/30 s) | baixo |
| v0.5.1 | Navegação vira máquina de estados no Core, com testes | baixo |
| v0.5.2 | Gesto de borda nativo no lugar das faixas (margens voltam a 14 pt) | médio |
| v0.5.3 | Divide o player e cria um aviso curto único | baixo |
| v0.5.4 | Miniaturas com cache e cancelamento | baixo |
| v0.5.5 | Preferências num lugar só (testável) | baixo |
| v0.5.6 | Diagnóstico do motor vai para arquivo próprio (só mover) | baixo |
| v0.5.7 | Captura parametrizável (resolução, fps, lente), sem mudar o padrão: prepara a etapa 6 | médio |
| v0.5.8 | CI confere estilo e avisos | baixo |

Voz e sessão de áudio ficam de fora, a menos que você queira: se entrarem, vão sozinhas, uma por versão, no fim.

## Revisão das decisões presas ao web app

| Tema | Hoje | Limite do web? | Alternativa nativa |
| ---- | ---- | -------------- | ------------------ |
| Pré-gravação | 15 ou 30 s | sim (RAM do Safari) | 10/15/30/60 s: o anel guarda vídeo já codificado (~2 MB/s), 60 s ≈ 120 MB |
| Palavra de ativação | 3 fixas | sim | palavra própria (o reconhecedor aceita qualquer texto) |
| Galeria | grade corrida | sim | agrupar por dia ("Hoje", "Ontem"), já temos o rótulo |
| Player | 1×, 1,5×, 2×, 0,5× | sim | cortar o trecho (aparar), passar quadro a quadro, zoom |
| Compartilhar | folha do iOS | já superado | manter |
| Câmera na Galeria | fecha (web estaciona 60 s) | não | manter: voz não escuta lá |
| Abrir/gravar | só pelo app | sim | Botão de Ação, Siri/Atalhos e toque nas costas (a verificar com conta grátis) |
| Retorno tátil | nenhum | sim | vibração ao iniciar e parar (útil com a tela longe) |
| Diagnóstico | visível nos Ajustes | herdado | esconder atrás de gesto no app definitivo |
| Ajustes | folha com páginas | herdado | manter (funciona bem) |
