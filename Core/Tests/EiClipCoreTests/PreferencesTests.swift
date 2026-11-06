import XCTest
@testable import EiClipCore

private final class MemoryStore: KeyValueStore {
    var values: [String: Any] = [:]
    func object(forKey key: String) -> Any? { values[key] }
    func set(_ value: Any?, forKey key: String) { values[key] = value }
}

final class PreferencesTests: XCTestCase {
    func testPadroes() {
        let prefs = Preferences(store: MemoryStore())
        XCTAssertTrue(prefs.voiceEnabled)
        XCTAssertEqual(prefs.voiceWord, WakeWord.defaultWord)
        XCTAssertEqual(prefs.windowSec, 15)
        XCTAssertTrue(prefs.beepEnabled)
        XCTAssertFalse(prefs.beepInClip)
        XCTAssertFalse(prefs.stabilization)
        XCTAssertFalse(prefs.levelEnabled)
        XCTAssertTrue(prefs.mirrorFront)  // v0.6.28: frontal espelhada por padrão
    }

    func testEspelharFrontalGuardaELe() {
        let store = MemoryStore()
        Preferences(store: store).mirrorFront = false
        XCTAssertFalse(Preferences(store: store).mirrorFront)
        Preferences(store: store).mirrorFront = true
        XCTAssertTrue(Preferences(store: store).mirrorFront)
    }

    func testCapturaPadraoEGuardada() {
        let store = MemoryStore()
        let prefs = Preferences(store: store)
        XCTAssertEqual(prefs.captureChoice.quality, .p1080)
        XCTAssertEqual(prefs.captureChoice.fps, 30)
        XCTAssertEqual(prefs.captureChoice.imageLevel, .standard)
        var c = prefs.captureChoice
        c.quality = .p2160
        c.fps = 60
        c.imageLevel = .maximum
        prefs.captureChoice = c
        let again = Preferences(store: store).captureChoice
        XCTAssertEqual(again.quality, .p2160)
        XCTAssertEqual(again.fps, 60)  // a escolha crua é guardada; a correção (4K = 30 fps) vem do validated()
        XCTAssertEqual(again.validated().fps, 30)
        XCTAssertEqual(again.imageLevel, .maximum)
    }

    func testCapturaInvalidaVoltaAoPadrao() {
        let store = MemoryStore()
        store.set(999, forKey: Preferences.Key.captureQuality)
        store.set(45, forKey: Preferences.Key.captureFps)
        store.set(7, forKey: Preferences.Key.captureLevel)
        let c = Preferences(store: store).captureChoice
        XCTAssertEqual(c.quality, .p1080)
        XCTAssertEqual(c.fps, 30)
        XCTAssertEqual(c.imageLevel, .standard)
    }

    func testNivelGuardaELe() {
        let store = MemoryStore()
        Preferences(store: store).levelEnabled = true
        XCTAssertTrue(Preferences(store: store).levelEnabled)
    }

    func testEstabilizacaoGuardaELe() {
        let store = MemoryStore()
        Preferences(store: store).stabilization = true
        XCTAssertTrue(Preferences(store: store).stabilization)
    }

    func testGuardaELe() {
        let store = MemoryStore()
        let prefs = Preferences(store: store)
        prefs.voiceEnabled = false
        prefs.windowSec = 30
        prefs.beepEnabled = false
        prefs.beepInClip = true
        let again = Preferences(store: store)
        XCTAssertFalse(again.voiceEnabled)
        XCTAssertEqual(again.windowSec, 30)
        XCTAssertFalse(again.beepEnabled)
        XCTAssertTrue(again.beepInClip)
    }

    func testPalavraGuardadaEMantida() {
        let store = MemoryStore()
        for word in WakeWord.allCases {
            Preferences(store: store).voiceWord = word
            XCTAssertEqual(Preferences(store: store).voiceWord, word)
        }
    }

    func testValoresInvalidosVoltamAoPadrao() {
        let store = MemoryStore()
        store.values[Preferences.Key.windowSec] = 99
        store.values[Preferences.Key.voiceWord] = "xyz"
        store.values[Preferences.Key.voiceEnabled] = "sim"
        let prefs = Preferences(store: store)
        XCTAssertEqual(prefs.windowSec, 15)
        XCTAssertEqual(prefs.voiceWord, WakeWord.defaultWord)
        XCTAssertTrue(prefs.voiceEnabled)
    }

    func testJanelaInvalidaNaoEGuardada() {
        let store = MemoryStore()
        Preferences(store: store).windowSec = 20
        XCTAssertEqual(Preferences(store: store).windowSec, 15)
    }
}
