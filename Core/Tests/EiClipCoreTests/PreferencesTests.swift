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
