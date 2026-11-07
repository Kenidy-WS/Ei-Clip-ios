import Foundation

/// Uma linha "rótulo: valor" do painel do Diagnóstico.
public struct DiagRow: Equatable, Identifiable {
    public let label: String
    public let value: String
    public var id: String { label }

    public init(_ label: String, _ value: String) {
        self.label = label
        self.value = value
    }
}

/// Uma seção do painel do Diagnóstico (como as do web app, `src/ui/diagnostics.ts`).
public struct DiagSection: Equatable, Identifiable {
    public let title: String
    public var rows: [DiagRow]
    /// Linhas soltas (registros), da mais antiga para a mais nova.
    public var lines: [String]
    /// Seção de problemas (destacada).
    public var alert: Bool
    public var id: String { title }

    public init(title: String, rows: [DiagRow] = [], lines: [String] = [], alert: Bool = false) {
        self.title = title
        self.rows = rows
        self.lines = lines
        self.alert = alert
    }
}

/// Tudo que o painel mostra, em valores simples (o motor preenche; aqui não há câmera nem tela, então tem teste).
public struct DiagSnapshot {
    // Resumo
    public var appVersion = "?"
    public var device = "?"
    public var appState = "?"
    public var appOpenSec = 0
    public var thermal = "normal"
    public var thermalSevere = false
    /// v0.6.1: bateria ("62% · na bateria") e se está baixa / muito baixa.
    public var battery = "-"
    public var batteryLow = false
    public var batteryCritical = false
    public var cameraOpen = false
    public var cameraOpenSec = 0.0
    public var openCount = 0
    public var recording = false
    // Voz
    public var voiceMode = "desligada"
    public var voiceEnabled = true
    public var voiceWord = "?"
    public var voiceLog: [String] = []
    // Vídeo
    public var requested = "-"
    public var delivered = "-"
    public var codec = "-"
    public var framesIn = 0
    public var framesEncoded = 0
    public var fpsOut = 0.0
    public var dropped = 0
    public var encoderErrors = 0
    public var lastClip = "-"
    /// v0.6.0: espaço livre e o nível (ok / pouco / quase esgotado).
    public var storageText = "-"
    /// v0.6.2: "-" ou o que mudou na qualidade por causa do calor ("2160p… → 1080p…").
    public var heatReduction = "-"
    /// v0.6.6: "desligada" / "ligada (modo ativo: …)".
    public var stabilization = "-"
    public var storageLow = false
    public var storageCritical = false
    public var bufferVideoFrames = 0
    public var bufferAudioBlocks = 0
    public var bufferSec = 0.0
    // Áudio
    public var micPeak: Float = 0
    public var audioBlocks = 0
    public var audioCopyFails = 0
    public var audioFormat = "-"
    public var audioSession = "-"
    public var beepOn = true
    public var beepInClip = false
    // Ajustes
    public var windowSec = 15
    /// v0.6.5: janela que vale de fato (menor que a pedida quando a qualidade pede mais memória).
    public var windowEffectiveSec = 15
    /// v0.6.8: "desligado", "reto" ou a inclinação.
    public var levelText = "-"
    /// v0.6.10: "1× · ultra-angular: sim".
    public var lensText = "-"
    /// v0.6.5: memória do app agora e estimativa do anel cheio, em MB (0 = desconhecido).
    public var appMemoryMB = 0
    public var ringEstimateMB = 0
    // Orientação
    public var holdLabel = "-"
    public var holdReading = "-"
    public var fileRotationDegrees = 90
    // Permissões e ciclo de vida
    public var permCamera = "?"
    public var permMic = "?"
    public var permPhotos = "?"
    /// v0.7.6: reconhecimento de voz e quais permissões o app já pediu ao sistema (para ver o caso "pediu e o iOS não mostrou").
    public var permSpeech = "?"
    public var permAsked = "-"
    public var cameraDenied = false
    public var micDenied = false
    public var photosNotFull = false
    public var launches = "-"
    public var lifecycle: [String] = []
    // Aviso do app (o texto que aparece na tela)
    public var message = ""

    public init() {}
}

/// Monta as seções do Diagnóstico a partir de um `DiagSnapshot`. Ordem: da mais importante para a menos importante.
public enum DiagPanel {
    /// Depois de quantos segundos de câmera aberta a falta de quadros ou o microfone mudo viram problema.
    static let graceSec = 3.0

    private static func yesNo(_ on: Bool) -> String { on ? "ligados" : "desligados" }

    /// Estado do microfone para o painel.
    static func micState(_ s: DiagSnapshot) -> String {
        guard s.cameraOpen else { return "-" }
        if s.audioBlocks == 0 { return s.cameraOpenSec > graceSec ? "SEM BLOCOS" : "aguardando" }
        if s.cameraOpenSec > graceSec && isMicSilent(peak: s.micPeak) { return "MUDO" }
        return "ativo"
    }

    /// "60 s" ou "60 s pedidos · 30 s em uso (limite de memória)".
    static func windowText(_ s: DiagSnapshot) -> String {
        s.windowEffectiveSec < s.windowSec
            ? "\(s.windowSec) s pedidos · \(s.windowEffectiveSec) s em uso (limite de memória)" : "\(s.windowSec) s"
    }

    /// "app 182 MB · anel cheio ≈ 138 MB" (v0.6.5).
    static func memoryText(_ s: DiagSnapshot) -> String {
        guard s.appMemoryMB > 0 else { return "-" }
        return "app \(s.appMemoryMB) MB · anel cheio ≈ \(s.ringEstimateMB) MB"
    }

    /// Problemas que o painel destaca no topo. Contadores de captura só valem com a câmera aberta.
    public static func alerts(_ s: DiagSnapshot) -> [String] {
        var out: [String] = []
        if s.cameraDenied { out.append("Câmera: permissão negada ou restrita (libere em Ajustes do iPhone)") }
        if s.micDenied { out.append("Microfone: permissão negada ou restrita; os clipes saem sem som") }
        if s.photosNotFull { out.append("Fotos: é preciso acesso completo para salvar no álbum Ei Clip") }
        if s.cameraOpen {
            if s.cameraOpenSec > graceSec && s.framesIn == 0 {
                out.append("A câmera está aberta mas não entregou nenhum quadro")
            }
            let mic = micState(s)
            if mic == "SEM BLOCOS" { out.append("O microfone não entregou nenhum bloco de áudio") }
            if mic == "MUDO" { out.append("Microfone MUDO (pico \(String(format: "%.4f", s.micPeak)))") }
            if s.dropped > 0 { out.append("\(s.dropped) quadro(s) de vídeo descartado(s)") }
            if s.encoderErrors > 0 { out.append("\(s.encoderErrors) erro(s) do codificador de vídeo") }
            if s.audioCopyFails > 0 { out.append("\(s.audioCopyFails) bloco(s) de áudio não copiado(s)") }
            if s.storageCritical {
                out.append("Espaço quase esgotado (\(s.storageText))")
            } else if s.storageLow {
                out.append("Pouco espaço (\(s.storageText))")
            }
        }
        if s.thermalSevere { out.append("Temperatura do aparelho: \(s.thermal)") }
        if s.heatReduction != "-" { out.append("Qualidade reduzida por calor: \(s.heatReduction)") }
        if s.batteryCritical {
            out.append("Bateria muito baixa (\(s.battery))")
        } else if s.batteryLow {
            out.append("Bateria baixa (\(s.battery))")
        }
        if !s.message.isEmpty { out.append("Aviso do app: \(s.message)") }
        return out
    }

    public static func sections(_ s: DiagSnapshot) -> [DiagSection] {
        var out: [DiagSection] = []

        let problems = alerts(s)
        if !problems.isEmpty { out.append(DiagSection(title: "Atenção", lines: problems, alert: true)) }

        var resumo: [DiagRow] = [
            DiagRow("App", s.appVersion),
            DiagRow("Aparelho", s.device),
            DiagRow("Câmera", s.cameraOpen ? "ligada há \(Int(s.cameraOpenSec)) s" : "desligada"),
            DiagRow("Gravando", s.recording ? "sim" : "não"),
            DiagRow("Voz", s.voiceEnabled ? s.voiceMode : "desativada nos Ajustes"),
            DiagRow("Temperatura", s.thermal),
            DiagRow("Bateria", s.battery),
        ]
        if !s.cameraOpen {
            resumo.append(DiagRow("Dica", "Câmera desligada: abra a câmera para ver vídeo e áudio ao vivo"))
        }
        resumo.append(DiagRow("App aberto há", "\(s.appOpenSec) s"))
        out.append(DiagSection(title: "Resumo", rows: resumo))

        out.append(
            DiagSection(
                title: "Vídeo",
                rows: [
                    DiagRow("Pedido", s.requested),
                    DiagRow("Entregue pela câmera", s.delivered),
                    DiagRow("Codificação", s.codec),
                    DiagRow("Lente", s.lensText),
                    DiagRow("Estabilização", s.stabilization),
                    DiagRow("Redução por calor", s.heatReduction == "-" ? "nenhuma" : s.heatReduction),
                    DiagRow(
                        "Quadros",
                        "entrada \(s.framesIn) · codificados \(s.framesEncoded) (\(String(format: "%.1f", s.fpsOut))/s)"),
                    DiagRow("Descartados / erros", "\(s.dropped) / \(s.encoderErrors)"),
                    DiagRow("Último clipe", s.lastClip),
                    DiagRow("Espaço livre", s.storageText),
                    DiagRow("Memória", memoryText(s)),
                    DiagRow(
                        "Buffer",
                        "\(String(format: "%.1f", s.bufferSec)) s · \(s.bufferVideoFrames) quadros · \(s.bufferAudioBlocks) blocos de áudio"),
                ]))

        out.append(
            DiagSection(
                title: "Áudio",
                rows: [
                    DiagRow("Microfone", micState(s)),
                    DiagRow("Sinal", "pico \(String(format: "%.4f", s.micPeak)) · \(s.audioBlocks) blocos"),
                    DiagRow("Formato", s.audioFormat),
                    DiagRow("Cópias que falharam", "\(s.audioCopyFails)"),
                    DiagRow("Sons", "\(s.beepOn ? "de gravação ligados" : "de gravação desligados") · \(s.beepInClip ? "no vídeo" : "fora do vídeo")"),
                ],
                lines: [s.audioSession]))

        out.append(
            DiagSection(
                title: "Comando de voz",
                rows: [
                    DiagRow("Estado", s.voiceEnabled ? s.voiceMode : "desativada nos Ajustes"),
                    DiagRow("Palavra", s.voiceWord),
                ],
                lines: s.voiceLog))

        out.append(
            DiagSection(
                title: "Ajustes",
                rows: [
                    DiagRow("Pré-gravação", windowText(s)),
                    DiagRow("Sons de gravação", yesNo(s.beepOn)),
                    DiagRow("Sons no vídeo", yesNo(s.beepInClip)),
                    DiagRow("Comando de voz", s.voiceEnabled ? "ligado" : "desligado"),
                ]))

        out.append(
            DiagSection(
                title: "Orientação",
                rows: [
                    DiagRow("Aparelho", s.holdLabel),
                    DiagRow("Sensor (gravidade)", s.holdReading),
                    DiagRow("Nível", s.levelText),
                    DiagRow("Giro do próximo clipe", "\(s.fileRotationDegrees)°"),
                ]))

        out.append(
            DiagSection(
                title: "Permissões e ciclo de vida",
                rows: [
                    DiagRow("Câmera (permissão)", s.permCamera),
                    DiagRow("Microfone (permissão)", s.permMic),
                    DiagRow("Fotos (permissão)", s.permPhotos),
                    DiagRow("Reconhecimento de voz (permissão)", s.permSpeech),
                    DiagRow("Já pedidas pelo app", s.permAsked),
                    DiagRow("Estado do app", s.appState),
                    DiagRow("Aberturas da câmera", "\(s.openCount) desde que o app abriu"),
                    DiagRow("Inícios do app", s.launches),
                ],
                lines: s.lifecycle))

        return out
    }

    /// O mesmo conteúdo em texto simples (botão "Copiar").
    public static func text(_ sections: [DiagSection]) -> String {
        sections.map { (sec: DiagSection) -> String in
            var parts = ["== \(sec.title) =="]
            parts += sec.rows.map { "\($0.label): \($0.value)" }
            parts += sec.lines.map { "  \($0)" }
            return parts.joined(separator: "\n")
        }.joined(separator: "\n\n")
    }
}
