import XCTest
@testable import EiClipCore

final class ProductsLoadRulesTests: XCTestCase {
    func testZeroProdutosSemRedeEFalhaDeRede() {
        XCTAssertTrue(ProductsLoadRules.emptyMeansNetworkFailure(count: 0, definitelyOffline: true))
    }

    func testZeroProdutosComRedeContinuaSendoLojaSemProdutos() {
        XCTAssertFalse(ProductsLoadRules.emptyMeansNetworkFailure(count: 0, definitelyOffline: false))
    }

    func testComProdutosNuncaEFalha() {
        XCTAssertFalse(ProductsLoadRules.emptyMeansNetworkFailure(count: 3, definitelyOffline: true))
        XCTAssertFalse(ProductsLoadRules.emptyMeansNetworkFailure(count: 1, definitelyOffline: false))
    }
}
