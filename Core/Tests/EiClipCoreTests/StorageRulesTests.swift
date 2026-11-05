import XCTest
@testable import EiClipCore

final class StorageRulesTests: XCTestCase {
    private let bitrate = 16_000_000  // 1080p30 padrão

    func testBytesPorSegundoSomaVideoEAudio() {
        XCTAssertEqual(StorageRules.bytesPerSecond(videoBitrate: 16_000_000), 2_024_000)
    }

    func testSegundosRestantesContamReservaECopia() {
        // (10 GB - 150 MB) / (2.024.000 x 2) = 2433 s
        XCTAssertEqual(StorageRules.remainingSeconds(freeBytes: 10_000_000_000, videoBitrate: bitrate), 2433)
        // Sem a cópia (uma vez só) cabe o dobro.
        XCTAssertEqual(StorageRules.remainingSeconds(freeBytes: 10_000_000_000, videoBitrate: bitrate, copies: 1), 4866)
    }

    func testSemEspacoUtilDaZero() {
        XCTAssertEqual(StorageRules.remainingSeconds(freeBytes: 100_000_000, videoBitrate: bitrate), 0)
        XCTAssertEqual(StorageRules.remainingSeconds(freeBytes: 0, videoBitrate: bitrate), 0)
        XCTAssertEqual(StorageRules.remainingSeconds(freeBytes: -5, videoBitrate: bitrate), 0)
    }

    func testNiveis() {
        XCTAssertEqual(StorageRules.level(freeBytes: 50_000_000_000, videoBitrate: bitrate), .ok)
        XCTAssertEqual(StorageRules.level(freeBytes: 3_000_000_000, videoBitrate: bitrate), .low)  // ≈ 11,7 min
        XCTAssertEqual(StorageRules.level(freeBytes: 1_000_000_000, videoBitrate: bitrate), .low)  // ≈ 3,5 min
        XCTAssertEqual(StorageRules.level(freeBytes: 600_000_000, videoBitrate: bitrate), .critical)  // ≈ 1,8 min
        XCTAssertEqual(StorageRules.level(freeBytes: 0, videoBitrate: bitrate), .critical)
    }

    func testQualidadeMaiorGastaMaisEspaco() {
        // 4K a 45 Mbps: os mesmos 10 GB duram bem menos.
        let seconds4k = StorageRules.remainingSeconds(freeBytes: 10_000_000_000, videoBitrate: 45_000_000)
        XCTAssertLessThan(seconds4k, 2433)
        XCTAssertGreaterThan(seconds4k, 0)
    }

    func testEncerraQuandoOEspacoNaoCobreACopia() {
        // Gravou 1 GB; precisa de 1 GB (cópia) + 150 MB (reserva) + ≈ 20 MB (10 s) = 1,17 GB livres.
        XCTAssertFalse(
            StorageRules.shouldStopRecording(freeBytes: 1_300_000_000, recordedBytes: 1_000_000_000, videoBitrate: bitrate))
        XCTAssertTrue(
            StorageRules.shouldStopRecording(freeBytes: 1_100_000_000, recordedBytes: 1_000_000_000, videoBitrate: bitrate))
    }

    func testClipeCurtoComEspacoSobrandoNaoEncerra() {
        XCTAssertFalse(
            StorageRules.shouldStopRecording(freeBytes: 20_000_000_000, recordedBytes: 50_000_000, videoBitrate: bitrate))
    }

    func testDescricaoParaODiagnostico() {
        XCTAssertEqual(
            StorageRules.describe(freeBytes: 10_000_000_000, videoBitrate: bitrate), "10.0 GB livres · ≈ 40 min de gravação")
    }

    // MARK: Aviso só quando piora

    func testAvisaSoQuandoPiora() {
        var tracker = StorageAlertTracker()
        XCTAssertNil(tracker.update(.ok))
        XCTAssertEqual(tracker.update(.low), .low)
        XCTAssertNil(tracker.update(.low))  // continua igual: não repete
        XCTAssertEqual(tracker.update(.critical), .critical)
        XCTAssertNil(tracker.update(.critical))
    }

    func testMelhorarNaoAvisaMasPiorarDeNovoAvisa() {
        var tracker = StorageAlertTracker()
        XCTAssertEqual(tracker.update(.critical), .critical)
        XCTAssertNil(tracker.update(.low))  // melhorou
        XCTAssertEqual(tracker.update(.critical), .critical)  // piorou de novo
        XCTAssertNil(tracker.update(.ok))
        XCTAssertEqual(tracker.update(.low), .low)
    }

    func testResetFazAvisarDeNovoAoAbrirACamera() {
        var tracker = StorageAlertTracker()
        XCTAssertEqual(tracker.update(.low), .low)
        tracker.reset()
        XCTAssertEqual(tracker.update(.low), .low)
    }
}
