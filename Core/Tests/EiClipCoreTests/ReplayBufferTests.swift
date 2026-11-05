import XCTest
@testable import EiClipCore

// Gabarito: tests/replay-buffer.test.ts do web app.
final class ReplayBufferTests: XCTestCase {
    private let S: Int64 = 1_000_000

    private func chunk(_ sec: Double, key: Bool = false) -> Chunk<Int> {
        Chunk(ts: Int64((sec * 1e6).rounded()), isKey: key, payload: 0)
    }

    /// Preenche o buffer com `seconds` s de vídeo a 10 quadros/s, keyframe a cada 1 s.
    private func fill(_ buf: ReplayBuffer<Int>, seconds: Int, start: Double = 1) {
        for i in 0..<(seconds * 10) {
            let t = start + Double(i) / 10
            buf.pushVideo(chunk(t, key: i % 10 == 0))
            buf.pushAudio(chunk(t))
        }
    }

    func testMantemSoAJanelaMaisAFolga() {
        let buf = ReplayBuffer<Int>(windowSec: 15)
        fill(buf, seconds: 40)
        XCTAssertLessThanOrEqual(buf.spanSec(), 18.01)
        XCTAssertGreaterThan(buf.spanSec(), 17)
    }

    func testSelecionaUltimoKeyframeAPeloMenosWindowSecDoFim() throws {
        let buf = ReplayBuffer<Int>(windowSec: 15)
        fill(buf, seconds: 30)
        let cut = try buf.selectCut().get()
        XCTAssertTrue(cut.video[0].isKey)
        XCTAssertGreaterThanOrEqual(cut.preSec, 15)
        XCTAssertLessThan(cut.preSec, 16.1)
        XCTAssertTrue(cut.audio.allSatisfy { $0.ts >= cut.t0 })
    }

    func testFuncionaDesdeOPrimeiroSegundoComBufferIncompleto() throws {
        let buf = ReplayBuffer<Int>(windowSec: 15)
        fill(buf, seconds: 3)
        let cut = try buf.selectCut().get()
        XCTAssertEqual(cut.video[0].ts, 1 * S)
        XCTAssertGreaterThan(cut.preSec, 2)
    }

    func testInformaBufferVazioEAusenciaDeKeyframe() {
        let buf = ReplayBuffer<Int>(windowSec: 15)
        XCTAssertEqual(buf.selectCut().failureValue, .empty)
        buf.pushVideo(chunk(1, key: false))
        XCTAssertEqual(buf.selectCut().failureValue, .noKeyframe)
    }

    func testDiscardUntilEsvaziaEIgnoraQuadrosAntigos() {
        let buf = ReplayBuffer<Int>(windowSec: 15)
        fill(buf, seconds: 5)
        let lastTs = buf.video[buf.video.count - 1].ts
        buf.discardUntil(lastTs)
        XCTAssertEqual(buf.video.count, 0)
        buf.pushVideo(chunk(Double(lastTs) / 1e6 - 1, key: true))  // quadro atrasado do encoder
        buf.pushAudio(chunk(Double(lastTs) / 1e6 - 1))
        XCTAssertEqual(buf.video.count, 0)
        XCTAssertEqual(buf.audio.count, 0)
        buf.pushVideo(chunk(Double(lastTs) / 1e6 + 0.1, key: true))
        XCTAssertEqual(buf.video.count, 1)
    }

    func testDescartaOBufferVelhoQuandoHaLacuna() {
        let buf = ReplayBuffer<Int>(windowSec: 15)
        fill(buf, seconds: 5)
        buf.pushVideo(chunk(60, key: true))
        XCTAssertEqual(buf.video.count, 1)
        XCTAssertEqual(buf.audio.count, 0)
    }

    func testRemoveAudioAnteriorAoPrimeiroVideoGuardado() {
        let buf = ReplayBuffer<Int>(windowSec: 5)
        fill(buf, seconds: 30)
        let firstVideo = buf.video[0].ts
        XCTAssertGreaterThanOrEqual(buf.audio[0].ts, firstVideo - 1_000_000)
    }
}

private extension Result {
    var failureValue: Failure? {
        if case .failure(let e) = self { return e }
        return nil
    }
}
