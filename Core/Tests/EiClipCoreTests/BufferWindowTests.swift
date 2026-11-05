import XCTest
@testable import EiClipCore

final class BufferWindowTests: XCTestCase {
    func testValoresValidosSaoMantidos() {
        XCTAssertEqual(BufferWindow.sanitized(15), 15)
        XCTAssertEqual(BufferWindow.sanitized(30), 30)
        XCTAssertEqual(BufferWindow.sanitized(60), 60)
        XCTAssertEqual(BufferWindow.options, [15, 30, 60])
    }

    func testAusenteOuInvalidoVoltaAoPadrao() {
        XCTAssertEqual(BufferWindow.sanitized(nil), 15)
        XCTAssertEqual(BufferWindow.sanitized(0), 15)
        XCTAssertEqual(BufferWindow.sanitized(20), 15)
        XCTAssertEqual(BufferWindow.sanitized(45), 15)
        XCTAssertEqual(BufferWindow.sanitized(-30), 15)
    }
}
