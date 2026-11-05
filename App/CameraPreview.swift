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
        onTap?(previewLayer.captureDevicePointConverted(fromLayerPoint: point), point)
    }
}
