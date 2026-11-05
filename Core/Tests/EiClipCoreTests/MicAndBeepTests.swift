import XCTest
@testable import EiClipCore

final class MicAndBeepTests: XCTestCase {
    func testMicMudoNoLimite() {
        XCTAssertTrue(isMicSilent(peak: 0))
        XCTAssertTrue(isMicSilent(peak: 0.0008))
        XCTAssertFalse(isMicSilent(peak: 0.0009))
        XCTAssertFalse(isMicSilent(peak: 0.2))
    }

    func testPicoDeFloatEInt16() {
        let f: [Float] = [0.1, -0.5, 0.25]
        let pf = f.withUnsafeBufferPointer { peakLevel(float: $0) }
        XCTAssertEqual(pf, 0.5, accuracy: 1e-6)

        let i: [Int16] = [100, -16384, 200]
        let pi = i.withUnsafeBufferPointer { peakLevel(int16: $0) }
        XCTAssertEqual(pi, 0.5, accuracy: 1e-4)

        let silent = [Float](repeating: 0, count: 100)
        XCTAssertEqual(silent.withUnsafeBufferPointer { peakLevel(float: $0) }, 0)
    }

    func testPeakTrackerGuardaOMaior() {
        var t = PeakTracker()
        t.feed(0.1)
        t.feed(0.4)
        t.feed(0.2)
        XCTAssertEqual(t.peak, 0.4, accuracy: 1e-6)
        t.reset()
        XCTAssertEqual(t.peak, 0)
    }

    func testDuracaoDosBipes() {
        XCTAssertEqual(beepDuration(.start), 0.12, accuracy: 1e-9)
        XCTAssertEqual(beepDuration(.stop), 0.25, accuracy: 1e-9)
    }

    func testBipeRespeitaOGanhoEComecaTerminaSuave() {
        for kind in [BeepKind.start, BeepKind.stop] {
            let s = renderBeep(kind, sampleRate: 48_000, gain: 0.7)
            XCTAssertEqual(s.count, Int((beepDuration(kind) * 48_000).rounded(.up)) + 1)
            XCTAssertLessThanOrEqual(s.map { abs($0) }.max() ?? 0, 0.7 + 1e-6)
            XCTAssertGreaterThan(s.map { abs($0) }.max() ?? 0, 0.5)
            XCTAssertEqual(s[0], 0, accuracy: 1e-6)
            XCTAssertLessThan(abs(s[s.count - 1]), 0.01)
        }
    }

    func testWavTemCabecalhoETamanhoCertos() {
        let samples = renderBeep(.start, sampleRate: 48_000)
        let data = wavData(samples: samples, sampleRate: 48_000)
        XCTAssertEqual(data.count, 44 + samples.count * 2)
        XCTAssertEqual(String(data: data.prefix(4), encoding: .ascii), "RIFF")
        XCTAssertEqual(String(data: data.subdata(in: 8..<12), encoding: .ascii), "WAVE")
    }
}
