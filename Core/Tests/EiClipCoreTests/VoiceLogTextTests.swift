import XCTest
@testable import EiClipCore

/// v0.9.13: o Diagnóstico não guarda conversa de fundo; só o que lembra a palavra de ativação.
final class VoiceLogTextTests: XCTestCase {
    func testConversaDeFundoViraResumo() {
        XCTAssertEqual(VoiceLogText.redacted("Bom dia tudo bem com você"), "[fala de fundo, 6 palavras]")
        XCTAssertEqual(VoiceLogText.redacted("Oi"), "[fala de fundo, 1 palavra]")
        XCTAssertEqual(VoiceLogText.redacted("Oi oi oi"), "[fala de fundo, 3 palavras]")
        XCTAssertEqual(VoiceLogText.redacted("8h59"), "[fala de fundo, 1 palavra]")
    }

    func testPalavraDeAtivacaoAparece() {
        XCTAssertEqual(VoiceLogText.redacted("Ei Clip"), "ei clip")
        XCTAssertEqual(VoiceLogText.redacted("Ei clipe"), "ei clipe")
        XCTAssertEqual(VoiceLogText.redacted("Ei cli"), "ei cli")
        XCTAssertEqual(VoiceLogText.redacted("Eclipse"), "eclipse")
        XCTAssertEqual(VoiceLogText.redacted("Ec clipe"), "ec clipe")
        XCTAssertEqual(VoiceLogText.redacted("ei, clip!"), "ei clip")
    }

    func testConversaAntesEDepoisFicaEscondida() {
        XCTAssertEqual(VoiceLogText.redacted("Testando a fluidez com a qualidade ei clipe"), "[…] ei clipe")
        XCTAssertEqual(VoiceLogText.redacted("bora lá ei clipe grava isso"), "[…] ei clipe […]")
        XCTAssertEqual(VoiceLogText.redacted("o clipe do vídeo"), "[…] clipe […]")
    }

    func testQuaseAcertoSemPalavraParecidaFicaEscondido() {
        // "Ei Candan" não lembra "clip": nada do texto aparece, só o tamanho.
        XCTAssertEqual(VoiceLogText.redacted("Ei Candan"), "[fala de fundo, 2 palavras]")
    }

    func testCameraAcaoEEiCamera() {
        XCTAssertEqual(VoiceLogText.redacted("Câmera, ação"), "camera acao")
        XCTAssertEqual(VoiceLogText.redacted("luz câmera e ação"), "[…] camera e acao")
        XCTAssertEqual(VoiceLogText.redacted("Ei câmera"), "ei camera")
        XCTAssertEqual(VoiceLogText.redacted("câmeraação"), "cameraacao")
        // "câmera" é palavra comum: sozinha, não aparece.
        XCTAssertEqual(VoiceLogText.redacted("a câmera está ligada"), "[fala de fundo, 4 palavras]")
    }

    func testVazio() {
        XCTAssertEqual(VoiceLogText.redacted(""), "(vazio)")
        XCTAssertEqual(VoiceLogText.redacted("..."), "(vazio)")
    }

    func testTudoQueODetectorAceitaContinuaAparecendo() {
        // O registro nunca pode esconder o que de fato disparou a gravação.
        let frases = ["Ei Clip", "Ei clipe", "Oi clipe", "Hey clipe", "Ec clipe", "hey click", "eiclip", "e clipe", "Eclipse", "a clip",
                      "bora lá ei clipe grava isso", "Câmera, ação", "luz, câmera, ação", "Ei câmera", "oi camera"]
        for f in frases {
            let r = VoiceLogText.redacted(f)
            XCTAssertFalse(r.hasPrefix("[fala de fundo"), "\"\(f)\" sumiu do registro: \(r)")
        }
    }
}
