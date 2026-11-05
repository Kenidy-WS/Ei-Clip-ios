import Foundation

/// Textos que o usuário lê no app. Tom formal e claro.
/// Regra: todo texto novo para o usuário entra aqui (um único arquivo facilita a revisão geral de textos da etapa 3).
/// Os demais textos (ainda no código) serão migrados para cá nessa revisão.
enum Textos {
    /// O arquivo do clipe falhou durante ou ao fim da gravação.
    static let falhaGravacao = "Não foi possível gravar o clipe. A gravação foi encerrada; tente novamente."

    // MARK: - Início (v0.3.1)
    static let recentes = "Recentes"
    static let verTodos = "Ver todos"
    static let semClipes = "Nenhum clipe ainda."
    static let voltar = "Voltar"
    static func abrirClipe(_ quando: String) -> String { "Abrir o clipe de \(quando)" }

    // MARK: - Câmera (v0.3.4)
    static let comandoDeVoz = "Comando de voz"
    static let ajustes = "Ajustes"
    static let clipes = "Clipes"
    static let gravar = "Gravar"
    static let pararESalvar = "Parar e salvar"

    // MARK: - Ajustes (v0.3.6)
    static let sons = "Sons"
    static let diagnostico = "Diagnóstico"
    static let preGravacao = "Pré-gravação"
    static let palavraDeAtivacao = "Palavra de ativação"
    static let escolhaOGatilho = "Escolha o gatilho de voz."
    static let sonsDeGravacao = "Sons de gravação"
    static let sonsNoVideo = "Sons no vídeo"
    static let sonsNoVideoAjuda = "O som de início e de fim também fica gravado no clipe."
    static let ligados = "Ligados"
    static let desligados = "Desligados"
    static let desligado = "Desligado"
    static let fechar = "Fechar"
}
