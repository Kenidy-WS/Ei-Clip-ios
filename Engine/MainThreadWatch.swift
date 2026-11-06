import Foundation

/// v0.6.21: marcador de "o que a tela principal está fazendo". O trecho que roda na tela principal se anuncia com
/// `MainMark.run("nome") { ... }`; se a tela travar, o vigia lê o nome e o Diagnóstico diz onde parou. Só chamar na fila
/// principal. Nome vazio = fora das marcações (interface do SwiftUI ou sistema).
enum MainMark {
    private static let lock = NSLock()
    private static var current = ""
    private static var since = ProcessInfo.processInfo.systemUptime

    @discardableResult
    static func run<T>(_ name: String, _ body: () -> T) -> T {
        lock.lock()
        let previous = current
        current = name
        since = ProcessInfo.processInfo.systemUptime
        lock.unlock()
        defer {
            lock.lock()
            current = previous
            since = ProcessInfo.processInfo.systemUptime
            lock.unlock()
        }
        return body()
    }

    static func snapshot() -> (name: String, seconds: Double) {
        lock.lock()
        defer { lock.unlock() }
        return (current, ProcessInfo.processInfo.systemUptime - since)
    }
}

/// O que o vigia precisa saber do motor.
struct WatchProbe {
    var opened = false
    var frames = 0
    var encoded = 0
    var encoderErrors = 0
    var recording = false
    var level = false
}

/// v0.6.21: vigia que roda fora da tela principal. A cada 0,5 s pede um "sinal de vida" à tela principal; se ele não volta
/// em 1 s, registra "TRAVADA" com o trecho marcado em que ela está. Também vigia os quadros da câmera (2 s sem quadros) e
/// escreve uma linha de vida a cada 10 s com a câmera aberta. Não muda nada do comportamento do app.
final class MainThreadWatch {
    private let queue = DispatchQueue(label: "ei.watch", qos: .utility)
    private var timer: DispatchSourceTimer?
    private let lock = NSLock()
    private var mainStall = StallDetector(threshold: 1.0)
    private var frameStall = StallDetector(threshold: 2.0)
    private var lastFrames = -1
    private var ticks = 0
    private let log: (String, String) -> Void
    private let probe: () -> WatchProbe

    init(log: @escaping (String, String) -> Void, probe: @escaping () -> WatchProbe) {
        self.log = log
        self.probe = probe
    }

    func start() {
        guard timer == nil else { return }
        lock.lock()
        _ = mainStall.beat(at: now())
        lock.unlock()
        let t = DispatchSource.makeTimerSource(queue: queue)
        t.schedule(deadline: .now() + 0.5, repeating: 0.5)
        t.setEventHandler { [weak self] in self?.pulse() }
        timer = t
        t.resume()
    }

    private func now() -> Double { ProcessInfo.processInfo.systemUptime }

    private func seconds(_ value: Double) -> String {
        String(format: "%.1f", value).replacingOccurrences(of: ".", with: ",")
    }

    private func pulse() {
        ticks += 1
        // 1) Pede um sinal de vida à tela principal.
        DispatchQueue.main.async { [weak self] in self?.mainBeat() }
        let t = now()

        // 2) A tela principal ficou calada?
        lock.lock()
        let mainEvent = mainStall.check(at: t)
        lock.unlock()
        if case .stalled(let gap)? = mainEvent {
            let mark = MainMark.snapshot()
            let place =
                mark.name.isEmpty
                ? "fora das marcações (interface ou sistema)"
                : "dentro de \"\(mark.name)\" há \(seconds(mark.seconds)) s"
            log("tela", "TRAVADA há \(seconds(gap)) s · \(place)")
        }

        // 3) A câmera parou de entregar quadros?
        let p = probe()
        lock.lock()
        var frameEvent: StallEvent?
        if !p.opened {
            lastFrames = -1
            _ = frameStall.beat(at: t)
        } else if p.frames != lastFrames {
            lastFrames = p.frames
            frameEvent = frameStall.beat(at: t)
        } else {
            frameEvent = frameStall.check(at: t)
        }
        lock.unlock()
        switch frameEvent {
        case .stalled(let gap)?:
            log("câmera", "SEM QUADROS há \(seconds(gap)) s (quadros=\(p.frames) codificados=\(p.encoded) erros=\(p.encoderErrors) gravando=\(p.recording ? "sim" : "não"))")
        case .recovered(let gap)?:
            log("câmera", "os quadros voltaram depois de \(seconds(gap)) s")
        default:
            break
        }

        // 4) Linha de vida a cada 10 s com a câmera aberta.
        if ticks % 20 == 0, p.opened {
            log(
                "vida",
                "quadros=\(p.frames) codificados=\(p.encoded) erros=\(p.encoderErrors) · gravando=\(p.recording ? "sim" : "não") "
                    + "· nível=\(p.level ? "ligado" : "desligado") · temperatura=\(DiagSystemInfo.thermal().text)")
        }
    }

    /// Roda na tela principal: prova que ela está respondendo.
    private func mainBeat() {
        lock.lock()
        let event = mainStall.beat(at: now())
        lock.unlock()
        if case .recovered(let gap)? = event {
            log("tela", "voltou a responder depois de \(seconds(gap)) s")
        }
    }
}
