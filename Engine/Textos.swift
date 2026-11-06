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

    // MARK: - Permissões (v0.7.5)
    static let permissaoNecessaria = "Permissão necessária"
    static let abrirAjustes = "Abrir Ajustes"
    static let agoraNao = "Agora não"
    static let semRespostaCamera =
        "O iPhone não mostrou o pedido de permissão da câmera. Abra os Ajustes, toque em Ei Clip e confira se Câmera e Microfone aparecem e estão ligados. Se não aparecerem, reinicie o iPhone e tente de novo."
    static let semRespostaMicrofone = "O iPhone não mostrou o pedido do microfone. A câmera abriu sem som."
    static let fotosSemResposta =
        "O iPhone não mostrou o pedido de acesso às Fotos. O clipe fica guardado no app até você liberar o acesso."
    static let fotosDesligadas =
        "O acesso às Fotos está desligado. Você pode gravar, mas o clipe só entra no álbum Ei Clip depois que o acesso for liberado nos Ajustes."

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

    // MARK: - Estabilização (v0.6.6)
    static let estabilizacao = "Estabilização de imagem"
    static let estabilizacaoAjuda = "Reduz tremidas do vídeo. Pode cortar um pouco das bordas da imagem."

    // MARK: - Tópicos dos Ajustes (v0.6.14, como no web app)
    static let camera = "Câmera"
    static let armazenamento = "Armazenamento"
    static let gravacaoLonga = "Gravação longa"
    static let gravacaoLongaAjuda = "Grava direto no aparelho, em partes. Se o app fechar, o clipe é recuperado."
    static let sempreLigada = "Sempre ligada"
    static let espacoLivre = "Espaço livre"
    static let semLeitura = "Sem leitura"

    static let fluidez4K = "Em 4K a fluidez é de 30 quadros por segundo."
    static func limitadaPelaMemoria(_ segundos: Int) -> String {
        "Nesta qualidade a pré-gravação fica limitada a \(segundos) s, pela memória do iPhone."
    }

    // MARK: - Recuperação (v0.6.13)
    static func clipesRecuperados(_ quantidade: Int) -> String {
        quantidade == 1
            ? "Um clipe que ficou incompleto quando o app fechou foi recuperado e salvo no álbum Ei Clip."
            : "\(quantidade) clipes que ficaram incompletos quando o app fechou foram recuperados e salvos no álbum Ei Clip."
    }

    // MARK: - Resolução e fluidez (v0.6.11)
    static let resolucao = "Resolução"
    static let fluidez = "Fluidez"
    static let qualidadeDaImagem = "Qualidade"
    static let qualidadePadrao = "Padrão"
    static let qualidadeAlta = "Alta"
    static let qualidadeMaxima = "Máxima"
    static let resolucaoAjuda = "Resolução maior usa mais espaço e esquenta mais o iPhone. Em 4K a câmera grava a 30 quadros."
    static func fpsIndisponivel(_ pedido: Int) -> String {
        "Esta câmera não grava a \(pedido) quadros por segundo nesta resolução. Foi usado 30."
    }

    // MARK: - Câmera frontal (v0.6.9)
    static let trocarCamera = "Trocar de câmera"
    static let frontalNaoAbriu = "Não foi possível abrir a câmera frontal. A câmera traseira foi mantida."

    // MARK: - Faixa do topo (v0.7.0)
    static let gravando = "Gravando"
    static func preGravacaoAcumulada(_ texto: String) -> String { "Pré-gravação: \(texto)" }
    static func qualidadeDaGravacao(_ faixa: String) -> String { "Qualidade da gravação: \(faixa)" }

    // MARK: - Espelhar frontal (v0.6.28)
    static let espelharFrontal = "Espelhar a câmera frontal"
    static let espelharFrontalAjuda = "O vídeo da câmera frontal sai espelhado, como a prévia (efeito selfie). Vale a partir do próximo clipe."

    // MARK: - Nível (v0.6.8)
    static let nivel = "Nível"
    static let nivelAjuda = "Mostra uma linha na câmera para você manter o horizonte reto."

    // MARK: - Tela escura (v0.6.3)
    static let escurecerATela = "Escurecer a tela"
    static let toqueParaAcender = "Toque para acender a tela"

    // MARK: - Temperatura (v0.6.2)
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
