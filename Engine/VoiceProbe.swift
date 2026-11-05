import AVFoundation
import Foundation
import Speech
import UIKit

/// ÁREA PROTEGIDA (voz): mudanças aqui vão sozinhas numa versão.
///
/// v0.2.0 — SONDA de reconhecimento de voz. Não dispara gravação: só escuta e registra no Diagnóstico,
/// para medirmos no aparelho se o `SFSpeechRecognizer` pt-BR serve:
///  - reconhece no aparelho (`requiresOnDeviceRecognition = true`, sem internet e sem enviar áudio)?
///  - escuta contínua: quanto tempo cada tarefa vive e o que acontece quando ela termina?
///  - usa o MESMO áudio da captura (sem segundo microfone), como o anel e o arquivo do clipe?
///  - o que o iOS escreve quando alguém diz "Ei Clip" (variações) e com que atraso?
///
/// Se o reconhecimento no aparelho não for suportado, a sonda PARA e avisa (não cai para o servidor sem você escolher).
final class VoiceProbe {
    private let lock = NSLock()
    private let queue = DispatchQueue(label: "ei.voiceprobe")
    private let log: (String, String) -> Void

    private var recognizer: SFSpeechRecognizer?
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    private var running = false
    private var runId = 0
    private var generation = 0
    private var taskStartedAt = Date()
    private var runStartedAt = Date()
    private var restartGuard = RestartGuard()

    private var buffersFed = 0
    private var resultCount = 0
    private var taskCount = 0
    private var restartCount = 0
    private var lastLoggedText = ""

    /// Chamado (em qualquer fila) quando a sonda liga ou desliga.
    var onState: ((Bool) -> Void)?

    init(log: @escaping (String, String) -> Void) {
        self.log = log
    }

    var isRunning: Bool {
        lock.lock()
        defer { lock.unlock() }
        return running
    }

    // MARK: - Ligar e desligar

    func start() {
        lock.lock()
        if running {
            lock.unlock()
            return
        }
        running = true
        runId += 1
        let myRun = runId
        runStartedAt = Date()
        buffersFed = 0
        resultCount = 0
        taskCount = 0
        restartCount = 0
        lastLoggedText = ""
        restartGuard.reset()
        lock.unlock()

        onState?(true)
        log("voz", "sonda ligada (v0.2.0): pedindo permissão de reconhecimento de voz…")
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            self?.queue.async { self?.afterAuthorization(status, run: myRun) }
        }
    }

    func stop(reason: String) {
        lock.lock()
        guard running else {
            lock.unlock()
            return
        }
        running = false
        runId += 1
        let t = task
        let r = request
        task = nil
        request = nil
        let secs = Date().timeIntervalSince(runStartedAt)
        let summary =
            "tarefas=\(taskCount) religadas=\(restartCount) resultados=\(resultCount) "
            + "blocos de áudio entregues=\(buffersFed) em \(String(format: "%.1f", secs)) s"
        lock.unlock()

        r?.endAudio()
        t?.cancel()
        log("voz", "sonda desligada (\(reason)): \(summary)")
        onState?(false)
    }

    // MARK: - Entrega de áudio (chamado a cada bloco da captura)

    /// Recebe o MESMO bloco de áudio que vai para o anel/arquivo (já com o silêncio do bipe aplicado).
    func append(_ sampleBuffer: CMSampleBuffer) {
        lock.lock()
        let req = running ? request : nil
        if req != nil { buffersFed += 1 }
        lock.unlock()
        req?.appendAudioSampleBuffer(sampleBuffer)
    }

    // MARK: - Permissão e verificação do aparelho

    private func afterAuthorization(_ status: SFSpeechRecognizerAuthorizationStatus, run: Int) {
        guard isCurrent(run) else { return }
        let name: String
        switch status {
        case .authorized: name = "autorizado"
        case .denied: name = "NEGADO"
        case .restricted: name = "RESTRITO (bloqueado no aparelho)"
        case .notDetermined: name = "não decidido"
        @unknown default: name = "desconhecido(\(status.rawValue))"
        }
        log("voz", "permissão de reconhecimento de voz: \(name)")
        guard status == .authorized else {
            stop(reason: "sem permissão")
            return
        }

        let pt = Locale(identifier: "pt-BR")
        let supported = SFSpeechRecognizer.supportedLocales().contains { $0.identifier.replacingOccurrences(of: "_", with: "-") == "pt-BR" }
        log("voz", "pt-BR na lista de idiomas do iOS: \(supported ? "sim" : "NÃO")")
        guard let rec = SFSpeechRecognizer(locale: pt) else {
            log("voz", "ERRO: o iOS não criou o reconhecedor pt-BR")
            stop(reason: "reconhecedor pt-BR indisponível")
            return
        }
        let onDevice = rec.supportsOnDeviceRecognition
        log(
            "voz",
            "reconhecedor pt-BR: disponível=\(rec.isAvailable) no aparelho=\(onDevice ? "SIM" : "NÃO") "
                + "iOS \(UIDevice.current.systemVersion)")
        guard onDevice else {
            log("voz", "RESULTADO: este aparelho NÃO reconhece pt-BR sem internet. A sonda não usa o servidor por conta própria.")
            stop(reason: "sem reconhecimento no aparelho")
            return
        }
        lock.lock()
        recognizer = rec
        lock.unlock()
        startTask(reason: "início", run: run)
        scheduleStats(run: run)
    }

    private func isCurrent(_ run: Int) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return running && runId == run
    }

    // MARK: - Tarefas de reconhecimento

    private func startTask(reason: String, run: Int) {
        lock.lock()
        guard running, runId == run, let rec = recognizer else {
            lock.unlock()
            return
        }
        generation += 1
        taskCount += 1
        let gen = generation
        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        req.requiresOnDeviceRecognition = true
        req.addsPunctuation = false
        request = req
        taskStartedAt = Date()
        lastLoggedText = ""
        lock.unlock()

        let t = rec.recognitionTask(with: req) { [weak self] result, error in
            self?.queue.async { self?.handle(gen: gen, run: run, result: result, error: error) }
        }

        lock.lock()
        if generation == gen, running, runId == run {
            task = t
        } else {
            t.cancel()
        }
        lock.unlock()
        log("voz", "tarefa nº \(gen) iniciada (\(reason))")
    }

    private func handle(gen: Int, run: Int, result: SFSpeechRecognitionResult?, error: Error?) {
        lock.lock()
        let current = running && runId == run && generation == gen
        let age = Date().timeIntervalSince(taskStartedAt)
        lock.unlock()
        guard current else { return }

        var ended = false
        var endText = ""
        if let result {
            let text = result.bestTranscription.formattedString
            lock.lock()
            resultCount += 1
            let changed = text != lastLoggedText
            if changed { lastLoggedText = text }
            lock.unlock()
            if changed || result.isFinal {
                let conf = result.bestTranscription.segments.last.map { String(format: "%.2f", $0.confidence) } ?? "-"
                log(
                    "voz",
                    "\(result.isFinal ? "FINAL" : "parcial") (tarefa \(gen), \(String(format: "%.1f", age)) s): "
                        + "\"\(text)\" confiança do último trecho=\(conf)")
            }
            if result.isFinal {
                ended = true
                endText = "resultado final"
            }
        }
        if let error {
            let ns = error as NSError
            ended = true
            endText = "erro \(ns.domain) \(ns.code): \(ns.localizedDescription)"
        }
        guard ended else { return }

        log("voz", "tarefa nº \(gen) terminou após \(String(format: "%.1f", age)) s (\(endText))")
        restartAfterEnd(age: age, run: run)
    }

    private func restartAfterEnd(age: Double, run: Int) {
        lock.lock()
        guard running, runId == run else {
            lock.unlock()
            return
        }
        let again = restartGuard.taskEnded(lifeSec: age)
        let oldTask = task
        let oldRequest = request
        task = nil
        request = nil  // enquanto não há tarefa nova, os blocos de áudio não são entregues (lacuna curta, medida abaixo)
        restartCount += 1
        lock.unlock()

        oldRequest?.endAudio()
        oldTask?.cancel()

        guard again else {
            log("voz", "ERRO: as tarefas morrem quase na hora, várias vezes seguidas. A sonda desistiu de religar.")
            stop(reason: "tarefas morrendo rápido")
            return
        }
        queue.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.startTask(reason: "religada (lacuna ≈ 0,2 s sem escuta)", run: run)
        }
    }

    // MARK: - Resumo periódico

    private func scheduleStats(run: Int) {
        queue.asyncAfter(deadline: .now() + 30) { [weak self] in
            guard let self, self.isCurrent(run) else { return }
            self.lock.lock()
            let secs = Date().timeIntervalSince(self.runStartedAt)
            let line =
                "a cada 30 s: \(String(format: "%.0f", secs)) s ligada · tarefas=\(self.taskCount) "
                + "religadas=\(self.restartCount) resultados=\(self.resultCount) blocos entregues=\(self.buffersFed) "
                + "· temperatura do aparelho=\(VoiceProbe.thermalName(ProcessInfo.processInfo.thermalState))"
            self.lock.unlock()
            self.log("voz", line)
            self.scheduleStats(run: run)
        }
    }

    private static func thermalName(_ s: ProcessInfo.ThermalState) -> String {
        switch s {
        case .nominal: return "normal"
        case .fair: return "morno"
        case .serious: return "quente"
        case .critical: return "crítico"
        @unknown default: return "?"
        }
    }
}
