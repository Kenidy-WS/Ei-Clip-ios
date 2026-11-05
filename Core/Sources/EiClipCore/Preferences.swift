import Foundation

/// Onde as preferências são guardadas. No app é o `UserDefaults`; nos testes, uma memória simples.
public protocol KeyValueStore: AnyObject {
    func object(forKey key: String) -> Any?
    func set(_ value: Any?, forKey key: String)
}

extension UserDefaults: KeyValueStore {}

/// Preferências do usuário num lugar só (v0.5.5): chaves, padrões e validação. As chaves são as mesmas de antes (quem já
/// tinha escolhas guardadas as mantém).
public struct Preferences {
    public enum Key {
        public static let voiceEnabled = "voiceEnabled"
        public static let voiceWord = "voiceWord"
        public static let windowSec = "windowSec"
        public static let beepEnabled = "beepEnabled"
        public static let beepInClip = "beepInClip"
        public static let stabilization = "stabilization"
        public static let levelEnabled = "levelEnabled"
        public static let captureQuality = "captureQuality"
        public static let captureFps = "captureFps"
        public static let captureLevel = "captureLevel"
    }

    private let store: KeyValueStore

    public init(store: KeyValueStore) {
        self.store = store
    }

    /// Comando de voz: ligado por padrão.
    public var voiceEnabled: Bool {
        get { (store.object(forKey: Key.voiceEnabled) as? Bool) ?? true }
        nonmutating set { store.set(newValue, forKey: Key.voiceEnabled) }
    }

    /// Palavra de ativação: valor guardado inválido ou ausente vira o padrão.
    public var voiceWord: WakeWord {
        get { WakeWord.parse(store.object(forKey: Key.voiceWord) as? String) ?? WakeWord.defaultWord }
        nonmutating set { store.set(newValue.rawValue, forKey: Key.voiceWord) }
    }

    /// Pré-gravação em segundos (15 ou 30).
    public var windowSec: Int {
        get { BufferWindow.sanitized(store.object(forKey: Key.windowSec) as? Int) }
        nonmutating set { store.set(BufferWindow.sanitized(newValue), forKey: Key.windowSec) }
    }

    /// Sons de gravação: ligados por padrão.
    public var beepEnabled: Bool {
        get { (store.object(forKey: Key.beepEnabled) as? Bool) ?? true }
        nonmutating set { store.set(newValue, forKey: Key.beepEnabled) }
    }

    /// Sons no vídeo: desligados por padrão.
    public var beepInClip: Bool {
        get { (store.object(forKey: Key.beepInClip) as? Bool) ?? false }
        nonmutating set { store.set(newValue, forKey: Key.beepInClip) }
    }

    /// Estabilização de imagem (v0.6.6): desligada por padrão.
    public var stabilization: Bool {
        get { (store.object(forKey: Key.stabilization) as? Bool) ?? false }
        nonmutating set { store.set(newValue, forKey: Key.stabilization) }
    }

    /// Nível (linha de horizonte) na câmera (v0.6.8): desligado por padrão.
    public var levelEnabled: Bool {
        get { (store.object(forKey: Key.levelEnabled) as? Bool) ?? false }
        nonmutating set { store.set(newValue, forKey: Key.levelEnabled) }
    }

    /// Resolução, fluidez e qualidade de imagem escolhidas (v0.6.11). Guarda o que o usuário escolheu, sem as correções de
    /// `validated()` (assim, voltar do 4K para 1080p devolve os 60 fps que ele tinha escolhido). Padrão: 1080p, 30 fps, padrão.
    public var captureChoice: CaptureConfig {
        get {
            let quality = (store.object(forKey: Key.captureQuality) as? Int).flatMap(VideoQuality.init(rawValue:)) ?? .p1080
            let fps = (store.object(forKey: Key.captureFps) as? Int).flatMap { CaptureConfig.supportedFps.contains($0) ? $0 : nil } ?? 30
            let level = (store.object(forKey: Key.captureLevel) as? Int).flatMap(ImageQuality.init(rawValue:)) ?? .standard
            return CaptureConfig(quality: quality, fps: fps, imageLevel: level, position: .back, stabilize: stabilization)
        }
        nonmutating set {
            store.set(newValue.quality.rawValue, forKey: Key.captureQuality)
            store.set(newValue.fps, forKey: Key.captureFps)
            store.set(newValue.imageLevel.rawValue, forKey: Key.captureLevel)
        }
    }
}
