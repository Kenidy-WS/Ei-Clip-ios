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
}
