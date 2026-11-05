// swift-tools-version:5.7
import PackageDescription

// Lógica pura do Ei Clip (sem câmera, sem tela). O app compila estes mesmos arquivos
// diretamente (ver project.yml) e o CI roda `swift test` aqui.
let package = Package(
    name: "EiClipCore",
    products: [
        .library(name: "EiClipCore", targets: ["EiClipCore"]),
    ],
    targets: [
        .target(name: "EiClipCore"),
        .testTarget(name: "EiClipCoreTests", dependencies: ["EiClipCore"]),
    ]
)
