import CoreMotion
import Foundation

/// v0.3.8: lê o acelerômetro (não pede permissão) só para saber como o iPhone está segurado.
///
/// A tela fica sempre em pé. A posição lida aqui só decide o giro do ARQUIVO, e só no começo de cada clipe
/// (o motor chama `snapshot()` uma vez ao iniciar a gravação). Aparelho deitado na mesa mantém a última posição
/// (regras em `OrientationTracker`, no Core). A posição é guardada enquanto o app está aberto: fechar e reabrir a
/// câmera não a zera.
final class OrientationSensor {
    struct Snapshot {
        let hold: DeviceHold
        /// Última leitura da gravidade (em g); nula se o sensor ainda não entregou nada.
        let reading: (x: Double, y: Double, z: Double)?
        var readingText: String {
            guard let r = reading else { return "sem leitura do sensor" }
            return String(format: "x=%.2f y=%.2f z=%.2f", r.x, r.y, r.z)
        }
    }

    private let motion = CMMotionManager()
    private let queue: OperationQueue = {
        let q = OperationQueue()
        q.name = "ei.orientation"
        q.maxConcurrentOperationCount = 1
        return q
    }()
    private let lock = NSLock()
    private var tracker = OrientationTracker()
    /// v0.6.19: o rastreador de orientação segue recebendo ~10 leituras por segundo (1 a cada 3).
    private var trackerFeed = Decimator(every: LevelRules.orientationEvery)
    private var lastReading: (x: Double, y: Double, z: Double)?
    private var running = false
    private let log: (String, String) -> Void
    /// v0.6.8: cada leitura da gravidade (30 por segundo desde a v0.6.19, na fila do sensor); o nível da câmera usa isto.
    var onReading: ((Double, Double, Double) -> Void)?

    init(log: @escaping (String, String) -> Void) {
        self.log = log
    }

    /// Começa a ler (30 vezes por segundo; a orientação usa 1 a cada 3). Sem efeito se já estiver lendo.
    func start() {
        lock.lock()
        if running {
            lock.unlock()
            return
        }
        running = true
        let hold = tracker.current
        lock.unlock()

        guard motion.isAccelerometerAvailable else {
            log("orientação", "acelerômetro indisponível: os clipes saem sempre com a posição \(hold.label)")
            return
        }
        motion.accelerometerUpdateInterval = 1.0 / LevelRules.sampleRate
        motion.startAccelerometerUpdates(to: queue) { [weak self] data, _ in
            guard let self, let a = data?.acceleration else { return }
            self.feed(x: a.x, y: a.y, z: a.z)
        }
        log("orientação", "sensor ligado (posição atual: \(hold.label))")
    }

    func stop() {
        lock.lock()
        let was = running
        running = false
        lock.unlock()
        guard was else { return }
        motion.stopAccelerometerUpdates()
    }

    /// A posição agora (e a última leitura, para o Diagnóstico).
    func snapshot() -> Snapshot {
        lock.lock()
        defer { lock.unlock() }
        return Snapshot(hold: tracker.current, reading: lastReading)
    }

    private func feed(x: Double, y: Double, z: Double) {
        lock.lock()
        lastReading = (x, y, z)
        let changed = trackerFeed.pass() ? tracker.feed(x: x, y: y, z: z) : false
        let hold = tracker.current
        lock.unlock()
        onReading?(x, y, z)
        if changed {
            log(
                "orientação",
                "mudou para \(hold.label) (x=\(String(format: "%.2f", x)) y=\(String(format: "%.2f", y)) z=\(String(format: "%.2f", z)))")
        }
    }
}
