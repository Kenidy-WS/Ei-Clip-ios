import Foundation

/// Como o iPhone está segurado (mesmo sentido do `UIDeviceOrientation` do iOS).
///
/// - `landscapeLeft`: deitado, com o TOPO do aparelho apontando para a esquerda (a borda direita fica embaixo).
/// - `landscapeRight`: deitado, com o TOPO apontando para a direita (a borda esquerda fica embaixo).
///
/// A câmera traseira entrega o quadro "de lado" (como se o aparelho estivesse em `landscapeLeft`); por isso o arquivo
/// só precisa de giro quando o aparelho está em outra posição. O giro vai na matriz do arquivo (sem recodificar).
public enum DeviceHold: String, CaseIterable {
    case portrait
    case portraitUpsideDown
    case landscapeLeft
    case landscapeRight

    /// Giro (em graus, sentido horário) que o arquivo precisa para a imagem aparecer em pé.
    public var fileRotationDegrees: Int {
        switch self {
        case .portrait: return 90
        case .portraitUpsideDown: return 270
        case .landscapeLeft: return 0
        case .landscapeRight: return 180
        }
    }

    /// Matriz de giro do arquivo, valores exatos (sem o resíduo de `cos(π/2)`): [a b; c d], sem deslocamento.
    public var fileMatrix: (a: Double, b: Double, c: Double, d: Double) {
        switch self {
        case .portrait: return (0, 1, -1, 0)
        case .portraitUpsideDown: return (0, -1, 1, 0)
        case .landscapeLeft: return (1, 0, 0, 1)
        case .landscapeRight: return (-1, 0, 0, -1)
        }
    }

    /// Ângulo do centro desta posição no plano da tela (0 = em pé, 90 = topo para a esquerda), para a histerese.
    var centerAngle: Double {
        switch self {
        case .portrait: return 0
        case .landscapeLeft: return 90
        case .portraitUpsideDown: return 180
        case .landscapeRight: return -90
        }
    }

    /// Texto para o Diagnóstico.
    public var label: String {
        switch self {
        case .portrait: return "em pé"
        case .portraitUpsideDown: return "em pé, de cabeça para baixo"
        case .landscapeLeft: return "deitado, topo à esquerda"
        case .landscapeRight: return "deitado, topo à direita"
        }
    }

    /// A posição mais próxima de um ângulo (graus) no plano da tela.
    static func nearest(toAngle angle: Double) -> DeviceHold {
        let quarter = ((Int((angle / 90).rounded()) % 4) + 4) % 4
        switch quarter {
        case 0: return .portrait
        case 1: return .landscapeLeft
        case 2: return .portraitUpsideDown
        default: return .landscapeRight
        }
    }
}

/// Descobre como o aparelho está segurado a partir da gravidade medida pelo acelerômetro (x, y, z em "g",
/// no sistema do iOS: em pé y = -1; topo à esquerda x = +1; deitado na mesa, tela para cima, z = -1).
///
/// Regras (pensadas para o arquivo do clipe, que só olha a posição no começo da gravação):
/// - **Aparelho quase deitado na mesa** (pouca inclinação no plano da tela): ignora a leitura e mantém a
///   última posição. É o caso "iPhone na mesa filmando para cima ou para baixo".
/// - **Histerese:** só troca de posição depois de passar 55° do centro da atual (a fronteira "justa" é 45°).
/// - **Confirmação:** a nova posição precisa se repetir em `confirmSamples` leituras seguidas; um movimento
///   brusco ou um solavanco não troca a posição.
public struct OrientationTracker {
    /// Abaixo disto, a gravidade no plano da tela é pequena demais (aparelho quase deitado): mantém a posição.
    public let minPlanar: Double
    public let switchDegrees: Double
    public let confirmSamples: Int
    public private(set) var current: DeviceHold

    private var candidate: DeviceHold?
    private var candidateCount = 0

    public init(initial: DeviceHold = .portrait, minPlanar: Double = 0.5, switchDegrees: Double = 55, confirmSamples: Int = 3) {
        self.current = initial
        self.minPlanar = minPlanar
        self.switchDegrees = switchDegrees
        self.confirmSamples = max(1, confirmSamples)
    }

    /// Alimenta uma leitura do acelerômetro. Devolve verdadeiro se a posição mudou agora.
    @discardableResult
    public mutating func feed(x: Double, y: Double, z: Double) -> Bool {
        let planar = (x * x + y * y).squareRoot()
        guard planar >= minPlanar else {
            clearCandidate()
            return false
        }
        let angle = atan2(x, -y) * 180 / .pi
        let target = DeviceHold.nearest(toAngle: angle)
        guard target != current, Self.angularDistance(angle, current.centerAngle) > switchDegrees else {
            clearCandidate()
            return false
        }
        if candidate == target {
            candidateCount += 1
        } else {
            candidate = target
            candidateCount = 1
        }
        guard candidateCount >= confirmSamples else { return false }
        current = target
        clearCandidate()
        return true
    }

    private mutating func clearCandidate() {
        candidate = nil
        candidateCount = 0
    }

    static func angularDistance(_ a: Double, _ b: Double) -> Double {
        let d = abs(a - b).truncatingRemainder(dividingBy: 360)
        return d > 180 ? 360 - d : d
    }
}
