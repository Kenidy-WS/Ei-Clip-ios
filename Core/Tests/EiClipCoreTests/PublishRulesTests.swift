import XCTest
@testable import EiClipCore

final class PublishRulesTests: XCTestCase {
    func testArredondaParaBaixoEmMeioSegundo() {
        XCTAssertEqual(PublishRules.quantized(0), 0)
        XCTAssertEqual(PublishRules.quantized(0.49), 0)
        XCTAssertEqual(PublishRules.quantized(0.5), 0.5)
        XCTAssertEqual(PublishRules.quantized(29.99), 29.5)
    }

    func testNaoPublicaValorIgual() {
        XCTAssertNil(PublishRules.timeToPublish(shown: 12, new: 12.3))
        XCTAssertNil(PublishRules.timeToPublish(shown: 30, new: 30))
    }

    func testPublicaQuandoMuda() {
        XCTAssertEqual(PublishRules.timeToPublish(shown: 12, new: 12.6), 12.5)
        XCTAssertEqual(PublishRules.timeToPublish(shown: 12.5, new: 0), 0)
    }
}
