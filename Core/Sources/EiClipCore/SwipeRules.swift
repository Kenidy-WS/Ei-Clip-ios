import Foundation

/// Regras dos gestos de arrastar do player. Porta de `bindPlayerSwipeDown` em `ui/clips-view.ts` do web app
/// (medidas em pontos; velocidades em pontos por milissegundo).
public enum SwipeRules {
    // MARK: - Arrastar para baixo fecha (v0.4.5)

    /// O arrasto só conta como "para baixo" depois de 12 pt e se for mais vertical do que horizontal (1,2 vez).
    public static func isDownDrag(dx: Double, dy: Double) -> Bool {
        dy >= 12 && abs(dy) >= abs(dx) * 1.2
    }

    /// Quanto do arrasto já foi feito, de 0 a 1 (chega a 1 com 500 pt).
    public static func dismissProgress(dy: Double) -> Double {
        min(1, max(0, dy) / 500)
    }

    /// A tela encolhe até 88% e esmaece até 30% enquanto é arrastada.
    public static func dismissScale(progress: Double) -> Double { 1 - progress * 0.12 }
    public static func dismissOpacity(progress: Double) -> Double { 1 - progress * 0.7 }

    /// Soltando depois de 130 pt fecha; num arremesso rápido (mais de 0,6 pt/ms) fecha com mais de 50 pt.
    public static func shouldClose(dy: Double, elapsedMs: Double) -> Bool {
        let fast = dy / max(1, elapsedMs) > 0.6
        return dy > 130 || (fast && dy > 50)
    }

    // MARK: - Arrastar para os lados troca de clipe (v0.4.6)
    // Porta de `bindPlayerSwipeSides`: a ordem é a da Galeria (do mais novo para o mais antigo).

    /// O arrasto só conta como "para o lado" depois de 12 pt e se for mais horizontal do que vertical (1,2 vez).
    public static func isSideDrag(dx: Double, dy: Double) -> Bool {
        abs(dx) >= 12 && abs(dx) >= abs(dy) * 1.2
    }

    /// Não vale a partir da borda da tela (28 pt de cada lado): ali é o gesto de voltar.
    public static func startsOnEdge(x: Double, width: Double) -> Bool {
        x <= 28 || x >= width - 28
    }

    /// Para a esquerda (dx negativo) vai ao PRÓXIMO da lista (mais antigo, índice + 1); para a direita volta ao
    /// anterior (mais novo, índice − 1).
    public static func neighborDirection(dx: Double) -> Int {
        dx < 0 ? 1 : -1
    }

    /// O índice do vizinho, ou nil se não há clipe daquele lado (nas pontas da lista).
    public static func neighborIndex(current: Int, direction: Int, count: Int) -> Int? {
        let target = current + direction
        return (0..<count).contains(target) ? target : nil
    }

    /// Sem clipe do lado para onde o dedo vai, o vídeo "resiste": anda só um terço.
    public static func resistedOffset(dx: Double, hasNeighbor: Bool) -> Double {
        hasNeighbor ? dx : dx / 3
    }

    /// O vídeo esmaece até 50% enquanto desliza.
    public static func slideOpacity(offset: Double) -> Double {
        1 - min(0.5, abs(offset) / 600)
    }

    /// Soltando depois de 90 pt troca de clipe; num arremesso rápido (mais de 0,5 pt/ms) troca com mais de 40 pt.
    public static func shouldChangeClip(dx: Double, elapsedMs: Double) -> Bool {
        let fast = abs(dx) / max(1, elapsedMs) > 0.5
        return abs(dx) > 90 || (fast && abs(dx) > 40)
    }
}
