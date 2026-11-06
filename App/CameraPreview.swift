import AVFoundation
import SwiftUI

/// Prévia da câmera em tela cheia.
struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    /// v0.6.7: toque na prévia (ponto da câmera 0...1 e ponto na tela, em pontos).
    var onTap: ((CGPoint, CGPoint) -> Void)? = nil

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        view.backgroundColor = .black
        view.onTap = onTap
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) { uiView.onTap = onTap }

    /// v0.6.25: a prévia ocupa o que o SwiftUI oferecer, sem consultar o UIKit. Sem isso, o cálculo de layout do SwiftUI
    /// (que roda fora da tela principal) precisava esperar a linha principal para saber o tamanho da prévia, e na v0.6.24
    /// a tela travou num impasse com um aviso do motor (`isReconfiguring`) que a linha principal estava publicando.
    func sizeThatFits(_ proposal: ProposedViewSize, uiView: PreviewView, context: Context) -> CGSize? {
        proposal.replacingUnspecifiedDimensions(by: CGSize(width: 390, height: 844))
    }
}

final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    var onTap: ((CGPoint, CGPoint) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(tapped(_:))))
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) não usado") }

    @objc private func tapped(_ g: UITapGestureRecognizer) {
        let point = g.location(in: self)
        guard FocusRules.isFocusArea(y: Double(point.y), height: Double(bounds.height)) else { return }
        onTap?(previewLayer.captureDevicePointConverted(fromLayerPoint: point), point)
    }
}
