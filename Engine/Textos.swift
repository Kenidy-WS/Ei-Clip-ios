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

    // MARK: - Galeria (v0.4.0)
    static func quantidadeDeClipes(_ n: Int) -> String { n == 1 ? "1 clipe" : "\(n) clipes" }
    /// Tentou abrir a Galeria com uma gravação em andamento (v0.4.1).
    static let terminePrimeiro = "Termine a gravação primeiro."

    // MARK: - Player (v0.4.3)
    static let reproduzir = "Reproduzir"
    static let pausar = "Pausar"
    static let velocidade = "Velocidade"
    static let ligarOSom = "Ligar o som"
    static let desligarOSom = "Desligar o som"
    static let posicaoDoVideo = "Posição do vídeo"
    static let naoFoiPossivelReproduzir = "Não foi possível reproduzir o clipe."

    // MARK: - Detalhes do clipe (v0.4.4)
    static let detalhesDoVideo = "Detalhes do vídeo"
    static let infoData = "Data"
    static let infoDuracao = "Duração"
    static let infoTamanho = "Tamanho"
    static let infoResolucao = "Resolução"
    static let infoFluidez = "Fluidez"
    static let infoTaxa = "Taxa"
    static let infoAudio = "Áudio"
    static let infoAudioSim = "Sim"
    static let infoAudioNao = "Sem áudio"

    // MARK: - Compartilhar (v0.4.10)
    static let compartilhar = "Compartilhar"
    static let naoFoiPossivelCompartilhar = "Não foi possível preparar o clipe para compartilhar."

    // MARK: - Apagar (v0.4.11)
    static let apagar = "Apagar"

    // MARK: - Seleção em lote (v0.4.12)
    static let selecionar = "Selecionar"
    static let cancelar = "Cancelar"
    static let todos = "Todos"
    static let nenhum = "Nenhum"
    static let selecioneClipes = "Selecione clipes"
    static func selecionados(_ n: Int) -> String { n == 1 ? "1 selecionado" : "\(n) selecionados" }

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

    // MARK: - Espaço livre (v0.6.0)
    private static func tempoRestante(_ minutos: Int) -> String {
        minutos < 1 ? "menos de 1 min" : "cerca de \(minutos) min"
    }
    static func poucoEspaco(_ minutos: Int) -> String {
        "Pouco espaço no iPhone: restam \(tempoRestante(minutos)) de gravação."
    }
    static func espacoCritico(_ minutos: Int) -> String {
        "Espaço quase esgotado: restam \(tempoRestante(minutos)) de gravação. Libere espaço para não perder clipes."
    }
    static let gravacaoEncerradaPorEspaco = "Espaço insuficiente. A gravação foi encerrada e salva para não perder o clipe."
    static let clipeSalvoPoucoEspaco = "Clipe salvo. A gravação foi encerrada porque o espaço estava acabando."

    // MARK: - Bateria (v0.6.1)
    static func bateriaBaixa(_ percentual: Int) -> String {
        "Bateria em \(percentual)%. Conecte o carregador para não perder a gravação."
    }
    static func bateriaCritica(_ percentual: Int) -> String {
        "Bateria em \(percentual)%. Conecte o carregador agora: o iPhone pode desligar a qualquer momento."
    }

    // MARK: - Tela escura (v0.6.3)
    static let escurecerATela = "Escurecer a tela"
    static let toqueParaAcender = "Toque para acender a tela"

    // MARK: - Temperatura (v0.6.2)
    static let esquentando = "O iPhone está esquentando. Se continuar, a qualidade será reduzida sozinha."
    static func qualidadeReduzida(_ resumo: String) -> String {
        "O iPhone está quente. A qualidade foi reduzida para \(resumo)."
    }
    static let reducaoAdiada = "O iPhone está quente. A qualidade será reduzida quando a gravação terminar."
    static let quenteNoPiso = "O iPhone está quente. Proteja-o do sol e deixe-o ventilado."
    static let muitoQuente = "O iPhone está muito quente e a câmera pode desligar. Proteja-o do sol e do calor."
    static func muitoQuenteReduzida(_ resumo: String) -> String {
        "O iPhone está muito quente. A qualidade foi reduzida para \(resumo). Proteja-o do sol e do calor."
    }

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
