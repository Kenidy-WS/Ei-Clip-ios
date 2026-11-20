import XCTest
@testable import EiClipCore

final class RecordingIDTests: XCTestCase {
    private var cal: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "America/Cuiaba")!
        return c
    }

    func testNomeTrazOIdentificador() {
        let id = UUID()
        let date = DateComponents(calendar: cal, year: 2026, month: 11, day: 19, hour: 23, minute: 55, second: 1).date!
        let name = RecordingID.fileName(date, id: id, calendar: cal)
        XCTAssertEqual(name, "clip-20261119-235501-\(id.uuidString).mp4")
        XCTAssertTrue(RecordingFiles.isClipFile(name))
    }

    func testLeOIdentificadorDoNome() {
        let id = UUID()
        let name = RecordingID.fileName(id: id)
        XCTAssertEqual(RecordingID.id(fromFileName: name), id)
        XCTAssertEqual(RecordingID.idOrLegacy(fromFileName: name), id)
    }

    func testNomeAntigoNaoTemIdentificador() {
        XCTAssertNil(RecordingID.id(fromFileName: "clip-20261029-070509.mp4"))
        XCTAssertNil(RecordingID.id(fromFileName: "outro.txt"))
        XCTAssertNil(RecordingID.id(fromFileName: "clip-20261029-070509-NAO-E-UUID-NENHUM-AQUI-XXXXXX.mp4"))
    }

    func testNomeAntigoGeraSempreOMesmoIdentificador() {
        let a = RecordingID.idOrLegacy(fromFileName: "clip-20261029-070509.mp4")
        let b = RecordingID.idOrLegacy(fromFileName: "clip-20261029-070509.mp4")
        let c = RecordingID.idOrLegacy(fromFileName: "clip-20261029-070510.mp4")
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }

    func testIdentificadoresDeGravacoesDiferentesSaoDiferentes() {
        XCTAssertNotEqual(RecordingID.fileName(id: UUID()), RecordingID.fileName(id: UUID()))
    }
}
