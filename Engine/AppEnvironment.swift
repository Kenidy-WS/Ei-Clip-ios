import Foundation

/// Ambiente do app aberto (v0.9.48): TestFlight = Sandbox, App Store = produção.
/// Decidido pelo recibo que a Apple põe no app (funciona sem internet); se não der para saber, é nil e nada é descartado.
enum AppEnvironment {
    static let current: RecordEnvironment? = EnvironmentRules.detect(receiptFileName: Bundle.main.appStoreReceiptURL?.lastPathComponent)

    /// Texto para o Diagnóstico.
    static var logText: String {
        let file = Bundle.main.appStoreReceiptURL?.lastPathComponent ?? "sem recibo"
        switch current {
        case .sandbox?: return "ambiente do app: TESTE (TestFlight), recibo \(file)"
        case .production?: return "ambiente do app: LOJA, recibo \(file)"
        case nil: return "ambiente do app: desconhecido (recibo: \(file)); nada será descartado"
        }
    }
}
