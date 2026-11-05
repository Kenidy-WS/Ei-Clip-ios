import Foundation

/// Lacuna entre chunks acima disso = a câmera foi pausada (o buffer antigo é descartado).
public let replayGapUs: Int64 = 1_500_000
/// Folga mantida além da janela do buffer, para sempre existir um keyframe antes do corte.
public let replayRingSlackSec: Double = 3

/// Um pedaço já codificado (vídeo) ou um bloco de áudio. `ts` em microssegundos.
/// `Payload` é o dado real (no app, um CMSampleBuffer); aqui fica genérico para testar sem câmera.
public struct Chunk<Payload> {
    public let ts: Int64
    public let isKey: Bool
    public let payload: Payload

    public init(ts: Int64, isKey: Bool, payload: Payload) {
        self.ts = ts
        self.isKey = isKey
        self.payload = payload
    }
}

public struct CutSelection<Payload> {
    public let video: [Chunk<Payload>]
    public let audio: [Chunk<Payload>]
    /// Timestamp do keyframe escolhido como início do clipe.
    public let t0: Int64
    public let preSec: Double
}

public enum CutFailure: Error, Equatable {
    case empty
    case noKeyframe
}

/// Buffer circular de pre-roll: guarda os últimos segundos (vídeo codificado e áudio) para que o clipe
/// comece ANTES do toque. Porta de `src/core/replay-buffer.ts` do web app.
public final class ReplayBuffer<Payload> {
    public private(set) var video: [Chunk<Payload>] = []
    public private(set) var audio: [Chunk<Payload>] = []
    /// Chunks com timestamp <= isto são ignorados (não repetir imagens de um clipe anterior).
    public private(set) var dropBeforeTs: Int64 = 0
    public var windowSec: Double

    public init(windowSec: Double) {
        self.windowSec = windowSec
    }

    public func clear() {
        video.removeAll()
        audio.removeAll()
    }

    /// Esvazia e passa a ignorar tudo até `ts` (depois de gravar, ou ao voltar de uma pausa da câmera).
    public func discardUntil(_ ts: Int64) {
        dropBeforeTs = ts
        clear()
    }

    public func pushVideo(_ chunk: Chunk<Payload>) {
        if chunk.ts <= dropBeforeTs { return }
        if let last = video.last, chunk.ts - last.ts > replayGapUs { clear() }
        video.append(chunk)
        trim()
    }

    public func pushAudio(_ chunk: Chunk<Payload>) {
        if chunk.ts > dropBeforeTs { audio.append(chunk) }
    }

    /// Remove o que passou da janela (+ folga) e o áudio anterior ao primeiro vídeo guardado.
    public func trim() {
        guard let lastChunk = video.last else { return }
        let keep = Int64((windowSec + replayRingSlackSec) * 1e6)
        var drop = 0
        while drop < video.count - 1 && lastChunk.ts - video[drop].ts > keep { drop += 1 }
        if drop > 0 { video.removeFirst(drop) }
        let firstTs = video[0].ts
        var dropAudio = 0
        while dropAudio < audio.count && audio[dropAudio].ts < firstTs - 1_000_000 { dropAudio += 1 }
        if dropAudio > 0 { audio.removeFirst(dropAudio) }
    }

    /// Segundos de vídeo guardados (0 se vazio).
    public func spanSec() -> Double {
        guard let first = video.first, let last = video.last else { return 0 }
        return Double(last.ts - first.ts) / 1e6
    }

    /// Escolhe o início do clipe: o último keyframe que está a `windowSec` ou mais antes do último quadro.
    /// Se o buffer ainda não encheu, usa o primeiro keyframe disponível (grava desde o 1º segundo).
    public func selectCut() -> Result<CutSelection<Payload>, CutFailure> {
        guard let lastChunk = video.last else { return .failure(.empty) }
        let cutoff = lastChunk.ts - Int64(windowSec * 1e6)
        var idx = -1
        for i in 0..<video.count where video[i].isKey && video[i].ts <= cutoff {
            idx = i
        }
        if idx < 0 {
            idx = video.firstIndex(where: { $0.isKey }) ?? -1
        }
        if idx < 0 { return .failure(.noKeyframe) }
        let t0 = video[idx].ts
        return .success(
            CutSelection(
                video: Array(video[idx...]),
                audio: audio.filter { $0.ts >= t0 },
                t0: t0,
                preSec: Double(lastChunk.ts - t0) / 1e6
            ))
    }
}
