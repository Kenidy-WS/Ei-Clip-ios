import XCTest
@testable import EiClipCore

final class StorageNoticeRulesTests: XCTestCase {
    func testComEspacoDeSobraOAvisoAntigoSai() {
        XCTAssertEqual(StorageNoticeRules.onOpen(level: .ok), .clearOld)
    }

    func testComPoucoEspacoOAvisoNovoSubstitui() {
        XCTAssertEqual(StorageNoticeRules.onOpen(level: .low), .replaceOld)
        XCTAssertEqual(StorageNoticeRules.onOpen(level: .critical), .replaceOld)
    }

    /// As qualidades do teste de 21/11 (5,9 GB livres): 720p e 1080p padrão têm espaço de sobra; as demais, não.
    func testQualidadesDoTesteDe21DeNovembro() {
        let free: Int64 = 5_900_000_000
        let expected: [(VideoQuality, Int, ImageQuality, StorageNoticeOnOpen)] = [
            (.p720, 60, .standard, .clearOld), (.p720, 60, .high, .clearOld), (.p720, 60, .maximum, .clearOld),
            (.p1080, 60, .standard, .clearOld), (.p1080, 60, .high, .replaceOld), (.p1080, 60, .maximum, .replaceOld),
            (.p2160, 30, .standard, .replaceOld), (.p2160, 30, .high, .replaceOld), (.p2160, 30, .maximum, .replaceOld),
        ]
        for (quality, fps, level, action) in expected {
            let bitrate = videoBitrate(quality, fps: fps, level: level)
            let storage = StorageRules.level(freeBytes: free, videoBitrate: bitrate)
            XCTAssertEqual(StorageNoticeRules.onOpen(level: storage), action, "\(quality) \(fps) \(level)")
        }
    }

    /// Os minutos mudam de verdade de uma qualidade para outra (conferido com o log do aparelho).
    func testMinutosMudamComAQualidade() {
        let free: Int64 = 5_900_000_000
        func minutes(_ q: VideoQuality, _ fps: Int, _ l: ImageQuality) -> Int {
            StorageRules.remainingSeconds(freeBytes: free, videoBitrate: videoBitrate(q, fps: fps, level: l)) / 60
        }
        XCTAssertEqual(minutes(.p2160, 30, .maximum), 8)
        XCTAssertEqual(minutes(.p2160, 30, .high), 10)
        XCTAssertEqual(minutes(.p2160, 30, .standard), 12)
        XCTAssertEqual(minutes(.p1080, 60, .maximum), 10)
        XCTAssertEqual(minutes(.p1080, 60, .high), 13)
        XCTAssertGreaterThanOrEqual(minutes(.p1080, 60, .standard), 15)
        XCTAssertGreaterThanOrEqual(minutes(.p720, 60, .maximum), 15)
    }

    // MARK: - Loja

    func testLojaIgualOuSemLeituraAnteriorNaoRele() {
        XCTAssertFalse(StorefrontRules.shouldReload(last: nil, current: "143503|BRL"))
        XCTAssertFalse(StorefrontRules.shouldReload(last: "143503|BRL", current: "143503|BRL"))
    }

    func testLojaOuMoedaDiferenteRele() {
        XCTAssertTrue(StorefrontRules.shouldReload(last: "143503|BRL", current: "143441|USD"))
        XCTAssertTrue(StorefrontRules.shouldReload(last: "143503|BRL", current: "143503|USD"))
    }
}
