import AVFoundation
import UIKit

// v0.5.6: movido de CaptureEngine.swift, sem mudar nada no que faz.
// MARK: - Painel do Diagnóstico (v0.3.10)

extension CaptureEngine {
    /// Tudo que o painel do Diagnóstico mostra, de uma vez. Chamar na fila principal (lê o estado do app e do Diagnóstico).
    func diagnosticsSnapshot() -> DiagSnapshot {
        var s = DiagSnapshot()
        let now = ProcessInfo.processInfo.systemUptime
        let v = ProcessInfo.processInfo.operatingSystemVersion

        s.appVersion = Diagnostics.appVersion
        s.device = "\(Diagnostics.machineName) · iOS \(v.majorVersion).\(v.minorVersion).\(v.patchVersion)"
        s.appState = DiagSystemInfo.appStateName(UIApplication.shared.applicationState)
        s.appOpenSec = Int(now - launchedAtUptime)
        let thermal = DiagSystemInfo.thermal()
        s.thermal = thermal.text
        s.thermalSevere = thermal.severe
        s.recording = isRecording
        s.message = message

        // Voz
        s.voiceEnabled = voiceEnabled
        s.voiceWord = voiceWord.label
        switch voiceMode {
        case .off: s.voiceMode = "desligada"
        case .measure: s.voiceMode = "só medir (não grava)"
        case .command: s.voiceMode = "comando (\(voiceWord.label) liga e para a gravação)"
        }

        // Pedido e ajustes
        s.requested = config.summary
        s.codec = "H.264 (hardware) · \(videoBitrate(quality, fps: fps, level: imageLevel) / 1_000_000) Mbps"
        s.windowSec = windowSec
        s.beepOn = beepEnabled
        s.beepInClip = beepInClip

        // Captura (sob o trava do motor)
        withLock { () -> Void in
            s.cameraOpen = opened
            s.openCount = openCount
            s.cameraOpenSec = opened ? now - openedAtUptime : 0
            s.framesIn = cVideoFrames
            s.framesEncoded = cEncoded
            s.dropped = cDropped
            s.encoderErrors = cEncoderErrors
            s.audioBlocks = cAudioBuffers
            s.audioCopyFails = cAudioCopyFails
            s.micPeak = peak.peak
            s.bufferSec = ring.spanSec()
            s.bufferVideoFrames = ring.video.count
            s.bufferAudioBlocks = ring.audio.count
            s.delivered = opened ? deliveredFormat : "-"
            s.lastClip = lastClipText
            s.storageText = opened ? storageText : "-"
            s.storageLow = opened && storageLevel == .low
            s.storageCritical = opened && storageLevel == .critical
            if let fd = audioFormat { s.audioFormat = describeAudioFormat(fd) }
            // Quadros codificados por segundo, medidos entre duas leituras do painel (mínimo 0,9 s entre elas).
            if !opened {
                fpsLast = 0
                fpsSampleAt = 0
            } else if fpsSampleAt == 0 {
                fpsSampleAt = now
                fpsSampleFrames = cEncoded
            } else if now - fpsSampleAt >= 0.9 {
                fpsLast = Double(max(0, cEncoded - fpsSampleFrames)) / (now - fpsSampleAt)
                fpsSampleAt = now
                fpsSampleFrames = cEncoded
            }
            s.fpsOut = fpsLast
        }

        // Áudio e orientação
        s.audioSession = AudioSessionConfig.describe()
        let hold = orientation.snapshot()
        s.holdLabel = hold.hold.label
        s.holdReading = hold.readingText
        s.fileRotationDegrees = hold.hold.fileRotationDegrees

        // Permissões
        let cam = DiagSystemInfo.permission(AVCaptureDevice.authorizationStatus(for: .video))
        let mic = DiagSystemInfo.permission(AVCaptureDevice.authorizationStatus(for: .audio))
        let photos = DiagSystemInfo.photos()
        s.permCamera = cam.text
        s.cameraDenied = cam.blocked
        s.permMic = mic.text
        s.micDenied = mic.blocked
        s.permPhotos = photos.text
        s.photosNotFull = photos.notFull

        // Linhas do registro: voz (sem os textos parciais) e ciclo de vida (idas e voltas ao app, câmera fechada/reaberta)
        let lines = Diagnostics.shared.lines
        s.voiceLog = Array(lines.filter { $0.contains("] voz: ") && !$0.contains("parcial") }.suffix(6))
        let lifecycleMarks = ["] app: estado", "] sessão: ", "câmera: fechada", "câmera: reabertura"]
        s.lifecycle = Array(lines.filter { line in lifecycleMarks.contains { line.contains($0) } }.suffix(6))
        s.launches = LaunchLog.text()
        return s
    }
}
