import XCTest
@testable import EiClipCore

final class RecordingFilesTests: XCTestCase {
    func testReconheceArquivoDeClipe() {
        XCTAssertTrue(RecordingFiles.isClipFile("EiClip_2026-11-05_10-00-00.mp4"))
        XCTAssertTrue(RecordingFiles.isClipFile("a.MP4"))
        XCTAssertFalse(RecordingFiles.isClipFile(".DS_Store"))
        XCTAssertFalse(RecordingFiles.isClipFile(".oculto.mp4"))
        XCTAssertFalse(RecordingFiles.isClipFile("nota.txt"))
    }

    func testSoRecuperaArquivoComConteudo() {
        XCTAssertFalse(RecordingFiles.isWorthRecovering(name: "a.mp4", bytes: 0))
        XCTAssertFalse(RecordingFiles.isWorthRecovering(name: "a.mp4", bytes: 19_999))
        XCTAssertTrue(RecordingFiles.isWorthRecovering(name: "a.mp4", bytes: 20_000))
        XCTAssertFalse(RecordingFiles.isWorthRecovering(name: "a.txt", bytes: 5_000_000))
    }

    func testPartesDe5Segundos() {
        XCTAssertEqual(RecordingFiles.fragmentSeconds, 5.0)
    }
}
