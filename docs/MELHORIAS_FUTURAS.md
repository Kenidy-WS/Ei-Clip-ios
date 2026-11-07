# Melhorias futuras (além do web app)

Ideias que só o app nativo permite, ou que o web app não tem. **Nada daqui está aprovado nem em andamento:** é a lista para o Kenidy escolher depois da etapa 6. Em 05/11 o Kenidy trouxe para a etapa 6 a pré-gravação de 60 s, a Galeria por dia e os 4 itens de proteção em campo; eles saíram desta lista e estão em `docs/ROADMAP.md` (etapa 6). Cada item vira uma versão própria quando for aprovado.

## Decisões de 06/11

- **Adiadas pelo Kenidy (sem versão marcada):** vibração, cortar clipe e atalhos do sistema. Os atalhos (botão de Ação, Siri) são os que mais interessam; exigem verificar a conta gratuita e, para o botão de Ação, subir o iOS mínimo de 16 para 17 (não afeta o iPhone do Kenidy, que está no iOS 27).
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

- **Botão de Ação, Siri, Atalhos e toque nas costas** para abrir a câmera ou iniciar a gravação. *A verificar se a conta Apple gratuita permite* (App Intents costumam funcionar, mas é preciso testar no aparelho).

## App definitivo

- **Esconder o Diagnóstico** na versão final (ou deixá-lo só em um modo de suporte).
