import XCTest

@testable import EiClipCore

final class ClipTagTests: XCTestCase {
    func testIdaEVolta() {
        for lens in Lens.allCases {
            let text = ClipTag.lensText(position: .back, lens: lens)
            XCTAssertEqual(ClipTag.lens(from: ClipTag.encode(lens: text)), lens.label)
        }
    }

    func testFrontal() {
        XCTAssertEqual(ClipTag.lensText(position: .front, lens: .wide), "Frontal")
        XCTAssertEqual(ClipTag.lens(from: ClipTag.encode(lens: "Frontal")), "Frontal")
    }

    func testTextoDeOutroAppNaoEEtiqueta() {
        XCTAssertNil(ClipTag.lens(from: "Gravado no iPhone"))
        XCTAssertNil(ClipTag.lens(from: ""))
        XCTAssertNil(ClipTag.lens(from: "EiClip;"))
        XCTAssertNil(ClipTag.lens(from: "EiClip;lente="))
    }

    func testIgnoraCamposDesconhecidos() {
        XCTAssertEqual(ClipTag.lens(from: "EiClip;v=1;lente=2×;zoom=3"), "2×")
    }
}
