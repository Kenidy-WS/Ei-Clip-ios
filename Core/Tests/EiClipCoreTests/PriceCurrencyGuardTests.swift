import XCTest
@testable import EiClipCore

final class PriceCurrencyGuardTests: XCTestCase {
    func testMoedasIguaisMostram() {
        XCTAssertEqual(PriceCurrencyGuard.decide(storeCurrency: "BRL", productCurrency: "BRL"), .show)
        XCTAssertEqual(PriceCurrencyGuard.decide(storeCurrency: "USD", productCurrency: "USD"), .show)
    }

    func testMoedasDiferentesOcultam() {
        XCTAssertEqual(
            PriceCurrencyGuard.decide(storeCurrency: "BRL", productCurrency: "USD"),
            .hide(productCurrency: "USD", storeCurrency: "BRL"))
    }

    func testMaiusculasEEspacosNaoCausamFalsoPositivo() {
        XCTAssertEqual(PriceCurrencyGuard.decide(storeCurrency: " brl ", productCurrency: "BRL"), .show)
        XCTAssertEqual(PriceCurrencyGuard.decide(storeCurrency: "eur", productCurrency: "EUR\n"), .show)
    }

    func testSemInformacaoDeUmaDasMoedasMostra() {
        XCTAssertEqual(PriceCurrencyGuard.decide(storeCurrency: nil, productCurrency: "USD"), .show)
        XCTAssertEqual(PriceCurrencyGuard.decide(storeCurrency: "BRL", productCurrency: nil), .show)
        XCTAssertEqual(PriceCurrencyGuard.decide(storeCurrency: nil, productCurrency: nil), .show)
        XCTAssertEqual(PriceCurrencyGuard.decide(storeCurrency: "", productCurrency: "USD"), .show)
        XCTAssertEqual(PriceCurrencyGuard.decide(storeCurrency: "BRL", productCurrency: "  "), .show)
    }
}
