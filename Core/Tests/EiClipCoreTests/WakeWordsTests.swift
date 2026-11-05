import XCTest
@testable import EiClipCore

/// Casos portados de `tests/wake-word.test.ts` do web app, mais o que o iPhone 15 (iOS 27) devolveu na sonda da v0.2.0.
final class WakeWordsTests: XCTestCase {
    func testNormalize() {
        XCTAssertEqual(WakeWords.normalize("  Ei,  Clipe! "), "ei clipe")
        XCTAssertEqual(WakeWords.normalize("Ação"), "acao")
        XCTAssertEqual(WakeWords.normalize(""), "")
    }

    func testWakePhraseReconhece() {
        let casos = [
            "Ei Clip", "Ei clipe", "Oi clipe", "Hey clipe", "Ec clipe", "ei, clip!", "Ei clipe ei clipe",
            "hey click", "eiclip", "e clipe", "Eclipse", "a clip",
            "bora lá ei clipe grava isso",
        ]
        for t in casos { XCTAssertTrue(WakeWords.isWakePhrase(t), "deveria reconhecer \"\(t)\"") }
    }

    func testWakePhraseIgnora() {
        let casos = ["Ei Felipe", "Ei", "clipe", "o clipe do vídeo", "Ei cli", "", "oi tudo bem"]
        for t in casos { XCTAssertFalse(WakeWords.isWakePhrase(t), "deveria ignorar \"\(t)\"") }
    }

    func testLooseWakeStart() {
        for t in ["clip", "Clipe", "bora clipe", "ei clipe"] {
            XCTAssertTrue(WakeWords.isLooseWakeStart(t), "começa com \"\(t)\"")
        }
        for t in ["Felipe", "clipes do dia", "oi tudo bem", ""] {
            XCTAssertFalse(WakeWords.isLooseWakeStart(t), "ignora \"\(t)\"")
        }
    }

    func testEarlyWakePhrase() {
        for t in ["Ei cli", "Hey cli", "bora lá oi cli"] {
            XCTAssertTrue(WakeWords.isEarlyWakePhrase(t), "começo \"\(t)\"")
        }
        for t in ["Ei", "cli", "Ei clipe", "Ei clima", "ei cli ente", "Ei Felipe", ""] {
            XCTAssertFalse(WakeWords.isEarlyWakePhrase(t), "ignora \"\(t)\"")
        }
    }

    func testCameraAcao() {
        let sim = [
            "Câmera ação", "Câmera, ação!", "camera acao", "Luz, câmera, ação", "câmera e ação", "câmera a ação",
            "câmara ação", "cameraacao", "câmera action", "bora lá câmera ação grava isso",
        ]
        for t in sim { XCTAssertTrue(WakeWords.isCameraAcaoPhrase(t), "reconhece \"\(t)\"") }
        let nao = [
            "câmera", "ação", "a câmera frontal", "ligar a câmera e depois ação", "câmera lenta ação", "ação câmera",
            "Ei clipe", "",
        ]
        for t in nao { XCTAssertFalse(WakeWords.isCameraAcaoPhrase(t), "ignora \"\(t)\"") }
    }

    func testEiCamera() {
        let sim = ["Ei câmera", "Ei, câmera!", "Oi câmera", "Hey camera", "eicamera", "ei câmara", "bora lá ei câmera grava isso"]
        for t in sim { XCTAssertTrue(WakeWords.isEiCameraPhrase(t), "reconhece \"\(t)\"") }
        let nao = [
            "câmera", "a câmera está ligada", "e a câmera", "eu câmera", "ai câmera", "ei a câmera", "ligou a câmera",
            "Ei Felipe", "Ei", "Ei clipe", "",
        ]
        for t in nao { XCTAssertFalse(WakeWords.isEiCameraPhrase(t), "ignora \"\(t)\"") }
    }

    func testMatcherPorPalavra() {
        let clip = WakeWord.clip.matcher
        XCTAssertTrue(clip.full("Ei clipe"))
        XCTAssertTrue(clip.loose("clipe"))
        XCTAssertTrue(clip.early("Ei cli"))

        for w in [WakeWord.cameraAcao, .eiCamera] {
            let m = w.matcher
            XCTAssertFalse(m.loose("clipe"))
            XCTAssertFalse(m.loose("câmera"))
            XCTAssertFalse(m.early("Ei cli"))
        }
    }

    func testUmaPalavraNaoAcionaAOutra() {
        XCTAssertFalse(WakeWord.clip.matcher.full("Câmera ação"))
        XCTAssertFalse(WakeWord.clip.matcher.full("Ei câmera"))
        XCTAssertFalse(WakeWord.cameraAcao.matcher.full("Ei clipe"))
        XCTAssertFalse(WakeWord.cameraAcao.matcher.full("Ei câmera"))
        XCTAssertFalse(WakeWord.eiCamera.matcher.full("Ei clipe"))
        XCTAssertFalse(WakeWord.eiCamera.matcher.full("Câmera ação"))
    }

    func testValidaValoresGuardados() {
        XCTAssertEqual(WakeWord.allCases.map(\.rawValue), ["clip", "camera-acao", "ei-camera"])
        XCTAssertEqual(WakeWord.parse("camera-acao"), .cameraAcao)
        XCTAssertNil(WakeWord.parse("fisgou"))
        XCTAssertNil(WakeWord.parse(nil))
        XCTAssertEqual(WakeWord.defaultWord, .clip)
    }

    // MARK: - WakeGate

    func testGateAceitaOPrimeiroEIgnoraARepeticao() {
        var gate = WakeGate(minGapMs: 3000)
        XCTAssertTrue(gate.accept("0:0", nowMs: 1000))
        XCTAssertFalse(gate.accept("0:0", nowMs: 2800))  // parcial seguido do final da mesma fala
    }

    func testGateIgnoraOutraFalaDentroDoIntervalo() {
        var gate = WakeGate(minGapMs: 3000)
        XCTAssertTrue(gate.accept("0:0", nowMs: 1000))
        XCTAssertFalse(gate.accept("0:1", nowMs: 3500))
    }

    func testGateAceitaOutraFalaDepoisDoIntervalo() {
        var gate = WakeGate(minGapMs: 3000)
        XCTAssertTrue(gate.accept("0:0", nowMs: 1000))
        XCTAssertTrue(gate.accept("0:1", nowMs: 4100))
    }

    func testGateResetLiberaOProximo() {
        var gate = WakeGate(minGapMs: 3000)
        _ = gate.accept("0:0", nowMs: 1000)
        gate.reset()
        XCTAssertTrue(gate.accept("0:0", nowMs: 1100))
    }
}
