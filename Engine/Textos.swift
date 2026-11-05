import Foundation

/// Textos que o usuário lê no app. Tom formal e claro.
/// Regra: todo texto para o usuário entra aqui (um único arquivo facilita a revisão). Revisão geral feita na v0.3.12.
/// Exceção: o texto do Diagnóstico (rótulos do painel e linhas do registro) é técnico e fica no Core/Engine.
/// Exceção: "Falha na sessão de áudio." (CaptureEngine) fica onde está, por ser área protegida (áudio): migrar numa versão própria.
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

    // MARK: - Início e avisos (v0.3.12)
    static let slogan = "Câmera de ação com comando de voz."
    static let abrirCamera = "Abrir câmera"
    static let abrindo = "Abrindo…"
    static let nomeDoApp = "Ei Clip"

    static let semPermissaoCamera = "Sem permissão para usar a câmera. Libere o acesso nos Ajustes do iPhone."
    static let naoAbriuCamera = "Não foi possível abrir a câmera."
    static let aguardeUmSegundo = "Aguarde 1 segundo e tente novamente."
    static let naoIniciouGravacao = "Não foi possível iniciar a gravação. Tente novamente."
    static let clipeSalvo = "Clipe salvo no álbum Ei Clip."
    static let naoSalvouNasFotos = "Não foi possível salvar o clipe nas Fotos. Verifique a permissão de acesso às Fotos nos Ajustes do iPhone."

    // MARK: - Diagnóstico (telas e botões; v0.3.12)
    static let copiar = "Copiar"
    static let copiado = "Copiado ✓"
    static let limpar = "Limpar"
    static let copiarRodadaAnterior = "Copiar rodada anterior"
    static let semRodadaAnterior = "Sem rodada anterior"
    static func linhas(_ n: Int) -> String { "\(n) linhas" }
    static let testar20Aberturas = "Testar 20 aberturas"
    static let testando = "Testando…"
    static let vozTeste = "Voz (teste)"
    static let vozDesligada = "Desligada"
    static let vozSoMedir = "Só medir"
    static let vozComando = "Comando"
    static let palavra = "Palavra"
    static let abraACameraParaVoz = "Abra a câmera para ligar a voz."
    static let registro = "Registro"
    static func tituloDiagnostico(_ versao: String) -> String { "Diagnóstico · \(versao)" }
}
