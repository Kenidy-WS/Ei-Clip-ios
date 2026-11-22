import Foundation

/// Textos que o usuário lê no app. Tom formal e claro.
/// Regra: todo texto para o usuário entra aqui (um único arquivo facilita a revisão). Revisão geral feita na v0.3.12.
/// Exceção: o texto do Diagnóstico (rótulos do painel e linhas do registro) é técnico e fica no Core/Engine.
/// (v0.7.20: o aviso de falha da sessão de áudio migrou para cá; só o texto mudou, a sessão de áudio não foi tocada.)
enum Textos {
    /// O arquivo do clipe falhou durante ou ao fim da gravação.
    static let falhaGravacao = "Falha na gravação. Tente novamente."

    // MARK: - Início (v0.3.1)
    static let recentes = "Recentes"
    static let verTodos = "Ver todos"
    static let semClipes = "Nenhum clipe ainda."
    static let voltar = "Voltar"

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
    static let infoLente = "Lente"
    static let infoAudio = "Áudio"
    static let infoAudioSim = "Sim"
    static let infoAudioNao = "Sem áudio"

    // MARK: - Compartilhar (v0.4.10)
    static let compartilhar = "Compartilhar"
    static let naoFoiPossivelCompartilhar = "Não foi possível compartilhar."

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
    static let diagnostico = "Diagnóstico"
    static let preGravacao = "Pré-gravação"
    static let palavraDeAtivacao = "Palavra de ativação"
    static let escolhaOGatilho = "Diga a palavra para iniciar ou parar a gravação."
    static let sonsDeGravacao = "Sons de gravação"
    static let sonsNoVideo = "Sons no vídeo"
    static let sonsNoVideoAjuda = "Os sons de início e de fim também ficam no clipe."
    static let desligados = "Desligados"
    static let desligado = "Desligado"
    static let fechar = "Fechar"

    // MARK: - Início e avisos (v0.3.12)
    static let slogan = "Câmera de ação com comando de voz."
    static let abrirCamera = "Abrir câmera"
    static let abrindo = "Abrindo…"
    static let nomeDoApp = "Ei Clip"
    static func versaoDoApp(_ versao: String) -> String { "Ei Clip \(versao)" }
    static func lente(_ nome: String) -> String { "Lente \(nome)" }
    static func zoomAtual(_ valor: String) -> String { "Zoom \(valor)" }

    static let semPermissaoCamera = "Sem acesso à câmera. Libere em Ajustes."
    static let falhaSessaoAudio = "Não foi possível ativar o áudio. Encerre chamadas ou apps que usem o microfone."
    static let naoAbriuCamera = "Não foi possível abrir a câmera."
    static let aguardeUmSegundo = "Aguarde 1 segundo e tente de novo."
    static let naoIniciouGravacao = "Não foi possível gravar. Tente novamente."
    static let clipeSalvo = "Clipe salvo"
    static let naoSalvouNasFotos = "Clipe não salvo nas Fotos. Verifique o acesso em Ajustes."

    // MARK: - Permissões (v0.7.6)
    static let permissaoNecessaria = "Permissão necessária"
    static let abrirAjustes = "Abrir Ajustes"
    static let agoraNao = "Agora não"
    static let continuar = "Continuar"
    /// No Início, no lugar de "Nenhum clipe ainda." quando as Fotos não estão liberadas.
    static let fotosSemAcessoInicio = "Libere o acesso às Fotos para ver seus clipes."

    /// v0.7.7: aviso rápido ao tocar em gravar com o microfone desligado.
    static let gravandoSemSom = "Microfone desligado: clipe sem som."

    // MARK: - Lanterna (v0.7.13)
    static let ligarLanterna = "Ligar a lanterna"
    static let apagarLanterna = "Apagar a lanterna"
    static let lanternaIndisponivel = "Lanterna indisponível agora."
    static let lanternaApagadaBateria = "Lanterna apagada: bateria muito baixa."
    static let lanternaApagadaCalor = "Lanterna apagada: iPhone muito quente."

    // MARK: - Brilho / EV (v0.7.16)
    static let ajustarBrilho = "Ajustar o brilho (exposição)"

    /// O aviso único antes de abrir a câmera: uma linha por permissão com problema e o que fazer.
    static func avisoPermissoes(_ issues: [PermissionIssue]) -> String {
        func name(_ kind: PermissionKind) -> String {
            switch kind {
            case .camera: return "Câmera"
            case .microphone: return "Microfone"
            case .speech: return "Reconhecimento de voz"
            case .photos: return "Fotos"
            }
        }
        func line(_ issue: PermissionIssue) -> String {
            switch issue.problem {
            case .unanswered:
                return "\(name(issue.kind)): aguardando a sua resposta ao pedido do iPhone."
            case .limited:
                return "Fotos: acesso limitado. Libere o acesso completo para salvar no álbum Ei Clip."
            case .denied:
                switch issue.kind {
                case .camera: return "Câmera: negada. Sem ela, o app não funciona."
                case .microphone: return "Microfone: negado. Os clipes ficam sem som."
                case .speech: return "Reconhecimento de voz: negado. O comando de voz não funciona."
                case .photos:
                    return "Fotos: negadas. Os clipes ficam no app e só vão para o álbum Ei Clip depois da liberação."
                }
            }
        }
        var text = issues.map(line).joined(separator: "\n")
        text += "\n\nPara liberar: Ajustes → Ei Clip."
        if issues.contains(where: { $0.problem == .unanswered }) {
            text += " Se o pedido não aparecer, libere pelos Ajustes."
        }
        return text
    }

    // MARK: - Espaço livre (v0.6.0)
    private static func tempoRestante(_ minutos: Int) -> String {
        minutos < 1 ? "menos de 1 min" : "cerca de \(minutos) min"
    }
    static func poucoEspaco(_ minutos: Int) -> String {
        "Pouco espaço: restam \(tempoRestante(minutos)) de gravação."
    }
    static func espacoCritico(_ minutos: Int) -> String {
        "Espaço quase esgotado: restam \(tempoRestante(minutos))."
    }
    /// v0.9.16: aviso fixo do Início (título e texto). Não bloqueia a câmera.
    static let avisoPoucoEspacoTitulo = "Pouco espaço"
    static let avisoEspacoCriticoTitulo = "Espaço quase esgotado"
    static func avisoPoucoEspaco(_ minutos: Int) -> String {
        "Restam \(tempoRestante(minutos)) de gravação. Libere espaço no iPhone."
    }
    static func avisoEspacoCritico(_ minutos: Int) -> String {
        "Restam \(tempoRestante(minutos)). Libere espaço antes de gravar."
    }
    /// O aviso temporário de espaço (o mesmo que a câmera mostra): o Início o esconde quando o aviso fixo já está na tela.
    static func ehAvisoDeEspaco(_ texto: String) -> Bool {
        texto.hasPrefix("Pouco espaço") || texto.hasPrefix("Espaço quase esgotado")
    }
    static let gravacaoEncerradaPorEspaco = "Gravação encerrada por falta de espaço. Clipe salvo."
    static let clipeSalvoPoucoEspaco = "Clipe salvo. Gravação encerrada: pouco espaço."

    // MARK: - Bateria (v0.6.1)
    // v0.7.19: sem número. O iOS só informa a bateria aos apps de 5 em 5 (confirmado no aparelho em 06/11: 14% e 13% chegam como
    // 15%), então um percentual no aviso podia contradizer a barra do sistema.
    static let bateriaBaixa = "Bateria baixa. Conecte o carregador."
    static let bateriaCritica = "Bateria muito baixa. Conecte o carregador."

    // MARK: - Estabilização (v0.6.6)
    static let estabilizacao = "Estabilização de imagem"
    static let estabilizacaoAjuda = "Reduz tremidas. Pode cortar um pouco das bordas."

    // MARK: - Tópicos dos Ajustes (v0.6.14, como no web app)
    static let camera = "Câmera"
    static let vozESons = "Voz e sons"
    static let aparelho = "Aparelho"
    static let espacoLivre = "Espaço livre"
    static let semLeitura = "Sem leitura"

    static let fluidez4K = "Em 4K, a fluidez é fixa em 30 fps."
    static func limitadaPelaMemoria(_ segundos: Int) -> String {
        "Nesta qualidade, a pré-gravação é limitada a \(segundos) s pela memória do iPhone."
    }

    // MARK: - Recuperação (v0.6.13)
    static func clipesRecuperados(_ quantidade: Int) -> String {
        quantidade == 1
            ? "Clipe recuperado e salvo no álbum Ei Clip."
            : "\(quantidade) clipes recuperados e salvos no álbum Ei Clip."
    }

    // MARK: - Resolução e fluidez (v0.6.11)
    static let resolucao = "Resolução"
    static let fluidez = "Fluidez"
    static let qualidadeDaImagem = "Qualidade"
    static let qualidadePadrao = "Padrão"
    static let qualidadeAlta = "Alta"
    static let qualidadeMaxima = "Máxima"
    static func fpsIndisponivel(_ pedido: Int) -> String {
        "Sem \(pedido) fps nesta resolução. Usando 30."
    }

    // MARK: - Câmera frontal (v0.6.9)
    static let trocarCamera = "Trocar de câmera"
    static let frontalNaoAbriu = "Frontal indisponível. Mantida a traseira."

    // MARK: - Faixa do topo (v0.7.0)
    static let gravando = "Gravando"
    static func preGravacaoAcumulada(_ texto: String) -> String { "Pré-gravação: \(texto)" }
    static func qualidadeDaGravacao(_ faixa: String) -> String { "Qualidade da gravação: \(faixa)" }

    // MARK: - Espelhar frontal (v0.6.28)
    static let espelharFrontal = "Espelhar a câmera frontal"
    static let espelharFrontalAjuda = "Grava a frontal espelhada, como na prévia."

    // MARK: - Botões de volume (v0.9.5)
    static let botoesDeVolume = "Botões de volume como obturador"
    static let botoesDeVolumeAjuda = "Com a câmera aberta, aperte + ou − para iniciar e parar a gravação."

    // MARK: - Nível (v0.6.8)
    static let nivel = "Nível"
    static func cameraResumo(_ ligados: Int) -> String { ligados == 1 ? "1 ligado" : "\(ligados) ligados" }
    static let nivelAjuda = "Mostra uma linha para manter o horizonte reto."

    // MARK: - Tela escura (v0.6.3)
    static let escurecerATela = "Escurecer a tela"
    static let toqueParaAcender = "Toque para acender a tela"

    // MARK: - Temperatura (v0.6.2)
    static let qualidadeReduzida = "iPhone quente. Qualidade reduzida."
    /// v0.8.5: com a redução automática, o aviso diz o que mudou (por exemplo "60 → 30 fps").
    static func qualidadeReduzida(_ detalhe: String?) -> String {
        detalhe.map { "iPhone quente. Reduzido: \($0)." } ?? qualidadeReduzida
    }
    static let reducaoAdiada = "iPhone quente. A qualidade será reduzida ao parar."
    static let quenteNoPiso = "iPhone quente. Proteja-o do sol."
    static let quenteSoAvisa = "iPhone quente. Considere reduzir a qualidade."
    /// v0.9.12: linha nos Ajustes enquanto o calor mantém a qualidade reduzida.
    static func reduzidoPeloCalorAjustes(_ detalhe: String) -> String {
        "Reduzido pelo calor (\(detalhe)). Toque em uma das opções acima para voltar à sua escolha."
    }
    static let reduzirComCalor = "Reduzir qualidade com calor"
    static let reduzirComCalorAjuda = "Desligado: só avisa. Ligado: reduz a qualidade automaticamente."
    static let muitoQuente = "iPhone muito quente. A câmera pode desligar."
    static let muitoQuenteReduzida = "iPhone muito quente. Qualidade reduzida."
    static func muitoQuenteReduzida(_ detalhe: String?) -> String {
        detalhe.map { "iPhone muito quente. Reduzido: \($0)." } ?? muitoQuenteReduzida
    }

    // MARK: - Diagnóstico (telas e botões; v0.3.12)
    static let limpar = "Limpar"
    static let compartilharRodadaAnterior = "Compartilhar rodada anterior"
    static let diagnosticoNaoCompartilhado = "Não foi possível preparar o arquivo do Diagnóstico."
    static let semRodadaAnterior = "Sem rodada anterior."
    static func linhasDaRodadaAnterior(_ n: Int) -> String { "Rodada anterior: \(n) linhas" }
    static let registro = "Registro"
    static func tituloDiagnostico(_ versao: String) -> String { "Diagnóstico · \(versao)" }

    // MARK: - Acesso e compras (C2, etapa 3; página provisória nos Ajustes)
    static let acesso = "Meu plano"
    static let acessoSituacao = "Situação"
    static let carregandoProdutos = "Carregando opções de acesso…"
    static let produtosFalhou = "Não foi possível carregar as opções de acesso. Verifique a conexão e tente novamente."
    static let produtosNenhum = "As opções de acesso ainda não estão disponíveis."
    static let tentarNovamente = "Tentar novamente"
    static let restaurarCompras = "Restaurar compras"
    static let resgatarCodigo = "Resgatar código"
    static let assinaturaMensal = "Assinatura mensal"
    static let assinaturaAnual = "Assinatura anual"
    static let pagamentoUnico = "Pagamento único, sem renovação"
    static let verPreco = "Ver preço"
    static let precoNaFolhaDaApple = "O valor é exibido pela App Store ao confirmar a compra."
    static let compraConcluida = "Compra concluída. Obrigado!"
    static let compraEmAnalise = "Compra em análise. O acesso será liberado quando a Apple confirmar."
    static let compraNaoVerificada = "Não foi possível verificar a compra. O acesso não foi liberado."
    static let compraFalhou = "Não foi possível concluir a compra. Tente novamente."
    static let comprasRestauradas = "Compras restauradas."
    static let nenhumaCompraEncontrada = "Nenhuma compra encontrada para esta conta."
    static let restaurarFalhou = "Não foi possível restaurar as compras. Tente novamente."
    static let resgatarFalhou = "Não foi possível abrir o resgate de código. Tente novamente."

    // MARK: - Meu plano final (C2, etapa 5b; v0.9.31)
    static let secaoSituacao = "Situação"
    static let secaoGerenciamento = "Gerenciamento"
    static let secaoEscolhaPlano = "Escolha como continuar"
    static let secaoAcessoPermanente = "Acesso permanente"
    static let gerenciarAssinatura = "Gerenciar assinatura"
    static let resolverPagamento = "Resolver pagamento na Apple"
    static let resolverPagamentoLegenda = "Abre a assinatura na Apple. Lá você também pode cancelar."
    static let verificarDeNovo = "Verificar de novo"
    static let gerenciarFalhou = "Não foi possível abrir o gerenciamento da assinatura. Tente novamente."
    static let comprarPermanente = "Comprar acesso permanente"
    static let rotuloPagamentoUnico = "Pagamento único"
    static let rotuloRenovaEm = "Renova em"
    static let rotuloValor = "Valor"
    static let rotuloAcessoAte = "Acesso até"
    static let rotuloRenovacao = "Renovação"
    static let rotuloPlanoAtual = "Plano atual"
    static let rotuloProximoPlano = "Próximo plano"
    static let rotuloMudancaEm = "Mudança em"
    static let rotuloNovaTentativa = "Nova tentativa"
    static let rotuloAcesso = "Acesso"
    static let rotuloAssinatura = "Assinatura"
    static let rotuloProximaRenovacao = "Próxima renovação"
    static let rotuloValidaAte = "Válida até"
    static let valorNaoRenova = "Não renova"
    static let valorPelaApple = "Pela Apple"
    static let valorPausado = "Pausado"
    static let valorRenovacaoAtiva = "Renovação ativa"
    static let valorComProblema = "Problema no pagamento"
    static let acessoPermanenteAtivo = "Acesso permanente ativo"

    static let tituloVerificando = "Verificando…"
    static let subtituloVerificando = "Lendo a sua situação na Apple."
    static let tituloTeste = "Teste grátis"
    static func subtituloTeste(_ restantes: Int) -> String {
        switch restantes {
        case 0: return "Seus clipes gratuitos acabaram. Escolha um acesso para continuar gravando."
        case 1: return "Resta 1 clipe gratuito."
        default: return "Restam \(restantes) clipes gratuitos."
        }
    }
    static func tituloAssinaturaAtiva(_ plano: String?) -> String {
        if let plano { return "Assinatura \(plano) ativa" }
        return "Assinatura ativa"
    }
    static let nomeMensalMinusculo = "mensal"
    static let nomeAnualMinusculo = "anual"
    static let subtituloRenova = "Renova automaticamente. Cancele a qualquer momento."
    static func subtituloTroca(de: String, para: String, data: String) -> String {
        "Você fica no \(de) até \(data). Depois passa para o \(para)."
    }
    static let subtituloRenovacaoDesconhecida = "Não foi possível confirmar se ela renova agora."
    static let tituloCancelada = "Assinatura cancelada"
    static let subtituloCancelada = "Você mantém o acesso até o fim do período pago."
    static let tituloProblemaPagamento = "Problema no pagamento"
    static func subtituloCarencia(_ data: String) -> String {
        "A Apple não conseguiu cobrar sua assinatura. Seu acesso continua até \(data). Regularize o pagamento para não perdê-lo."
    }
    static let tituloPausado = "Acesso pausado"
    static let subtituloPausado = "O acesso está pausado devido a um problema no pagamento. Seus clipes continuam no app Fotos."
    static let tituloPermanente = "Acesso permanente"
    static let subtituloPermanente = "Seu acesso não vence."
    static let avisoPermanenteRenovando = "Sua assinatura continua renovando. Cancele-a separadamente para parar as cobranças."
    static let avisoPermanenteProblema = "A Apple ainda pode cobrar sua assinatura. Cancele-a separadamente para parar as cobranças."
    static let tituloNaoConfirmada = "Assinatura não confirmada agora"
    static func subtituloNaoConfirmada(_ data: String) -> String {
        "Sem conexão com a Apple. Último período pago confirmado até \(data)."
    }
    static let tituloNaoConfirmadaFim = "Assinatura não confirmada"
    static let subtituloNaoConfirmadaFim = "Não foi possível confirmar sua assinatura com a Apple. Verifique a conexão e tente de novo."
    static let tituloEncerrada = "Assinatura encerrada"
    static let subtituloEncerrada = "Seu acesso terminou. Escolha um plano para voltar a gravar."
    static let tituloRevogada = "Acesso reembolsado ou revogado"
    static let subtituloRevogada = "A Apple encerrou o acesso desta compra. Escolha um plano para voltar a gravar."
    static let tituloEmAnalise = "Compra em análise"
    static let subtituloEmAnalise = "A Apple ainda não confirmou o pagamento. O acesso libera assim que for aprovado."
    static func precoPorMesCurto(_ preco: String) -> String { "\(preco)/mês" }
    static func precoPorAnoCurto(_ preco: String) -> String { "\(preco)/ano" }

    // Avisos antes de comprar o permanente (nota fixa) e alerta ao tocar em comprar.
    static let avisoCompraRenovando = "A compra não cancela a assinatura. Cancele antes ou depois em Gerenciar assinatura."
    static let avisoCompraPodeCobrar = "A Apple ainda pode cobrar sua assinatura. Para parar as renovações, cancele-a na Apple. Comprar o acesso permanente não a cancela."
    static let alertaAntesDeContinuar = "Antes de continuar"
    static func alertaRenovando(_ data: String) -> String {
        "Sua assinatura renova em \(data). Comprar o acesso permanente não a cancela. Cancele em Gerenciar assinatura para não pagar duas vezes."
    }
    static let alertaPodeCobrar = "A Apple ainda pode cobrar sua assinatura. Comprar o acesso permanente não a cancela."
    static let alertaContinuarCompra = "Continuar para a compra"
    static let alertaVoltar = "Voltar"
    static let roleParaVerMais = "Role para ver mais"
    static let secaoSoParaTeste = "Só para teste"

    // MARK: - Escolha seu acesso, chip e avisos (C2, etapa 4; v0.9.27)
    static let escolhaTitulo = "Escolha seu acesso"
    static func planosSubtitulo(_ motivo: PlansReason) -> String {
        switch motivo {
        case .freeClipsUsed: return "Você usou seus 10 clipes gratuitos."
        case .subscriptionEnded: return "Sua assinatura foi encerrada."
        case .subscriptionNotConfirmed: return "Não foi possível confirmar sua assinatura."
        case .billingProblem: return "Há um problema no pagamento da sua assinatura."
        case .accessRevoked: return "Seu acesso foi reembolsado ou revogado."
        }
    }
    /// Linha extra sob o subtítulo; nil = não mostra (nos 10 clipes usados, encerrada e revogada o subtítulo basta).
    static func planosComplemento(_ motivo: PlansReason) -> String? {
        switch motivo {
        case .subscriptionNotConfirmed: return "Conecte-se à internet para confirmar. Seus clipes continuam na Galeria."
        case .billingProblem: return "Atualize a forma de pagamento na App Store ou escolha outro acesso. Seus clipes continuam na Galeria."
        default: return nil
        }
    }
    static let simularDezUsados = "Simular: sem acesso, 10 clipes usados"
    static let simularSeisUsados = "Simular: sem acesso, 6 clipes usados"
    static let mostrarPrecosEmDolar = "Mostrar preços mesmo em dólar"
    static let esconderPrecosEmDolar = "Voltar a esconder preços em dólar"
    static let simularVoltar = "Voltar ao acesso real"
    static let simulacaoAjuda = "Só para teste. Finge que você não tem acesso pago, sem mexer na assinatura, e deixa ver os preços do catálogo de teste (em dólar). Some ao fechar o app."
    static func situacaoSimulada(_ texto: String) -> String { "Simulação: \(texto)" }
    static let acessoLiberado = "Acesso liberado"
    static let acessoLiberadoTexto = "Obrigado! Você já pode gravar sem limite de clipes."
    // v0.9.34: resultado da compra (folha de resultado; protótipo da etapa 4, 19/11)
    static let continuarGravando = "Continuar gravando"
    static func compraAssinaturaAtiva(plano: String) -> String { "Sua assinatura \(plano) está ativa." }
    static func compraProximaRenovacao(_ data: String) -> String { "Próxima renovação em \(data)." }
    static let compraPermanenteTitulo = "Acesso permanente liberado"
    static let compraPermanenteTexto = "Acesso permanente ativo. Pagamento único, sem renovação."
    static let compraAssinaturaContinuaTitulo = "Sua assinatura continua ativa"
    static func compraAssinaturaContinuaRenova(_ data: String) -> String {
        "Ela será renovada em \(data). Comprar o acesso permanente não cancela a assinatura. Para não ser cobrado de novo, cancele em Ajustes do iPhone > Assinaturas."
    }
    static let compraAssinaturaContinuaPodeCobrar =
        "A Apple ainda pode cobrar a assinatura. Comprar o acesso permanente não cancela a assinatura. Para não ser cobrado de novo, resolva ou cancele em Ajustes do iPhone > Assinaturas."
    static let compraNenhumaNovaTitulo = "Nenhuma compra nova foi feita"
    static let compraNenhumaNovaTexto = "Você já tem uma assinatura. Para trocar de plano ou renovar, use Gerenciar assinatura."
    static let compraNaoConcluidaTitulo = "Não foi possível concluir a compra"
    static let compraNaoConcluidaTexto = "A compra não foi concluída. Tente novamente em instantes."
    static let beneficioSemLimite = "Gravações sem limite de clipes"
    static let beneficioRetroativa = "Gravação retroativa de até 60 segundos, conforme a qualidade"
    static let beneficioControle = "Controle por voz ou botões de volume"
    static let beneficioSemAnuncios = "Sem anúncios e sem cadastro"
    static let periodoPorMes = "por mês"
    static let periodoPorAno = "por ano"
    static let periodoUnico = "pagamento único"
    static let planoMensalNome = "Mensal"
    static let planoAnualNome = "Anual"
    static let planoPermanenteNome = "Acesso permanente"
    static let planoMensalDetalhe = "Renova todo mês. Cancele quando quiser."
    static let planoAnualDetalhe = "Renova todo ano. Cancele quando quiser."
    static let planoPermanenteDetalhe = "Pagamento único, sem renovação."
    static func precoPorMes(_ preco: String) -> String { "\(preco) por mês" }
    static func precoPorAno(_ preco: String) -> String { "\(preco) por ano" }
    static func equivaleAPorMes(_ preco: String) -> String { "Equivale a \(preco) por mês" }
    static func economiaDe(_ percentual: Int) -> String { "Economia de cerca de \(percentual)%" }
    static let valorNaConfirmacao = "Valor na confirmação"
    static let escolhaUmAcesso = "Escolha um acesso"
    static let processando = "Processando…"
    static func botaoAssinarAnual(_ preco: String?) -> String {
        preco.map { "Assinar anual · \(precoPorAno($0))" } ?? "Assinar anual"
    }
    static func botaoAssinarMensal(_ preco: String?) -> String {
        preco.map { "Assinar mensal · \(precoPorMes($0))" } ?? "Assinar mensal"
    }
    static func botaoComprarPermanente(_ preco: String?) -> String {
        preco.map { "Comprar acesso permanente · \($0)" } ?? "Comprar acesso permanente"
    }
    static let termosDeUso = "Termos de Uso"
    static let politicaDePrivacidade = "Política de Privacidade"
    static let planosNotaLegal = "Assinaturas renovadas automaticamente até o cancelamento. Gerencie em Ajustes do iPhone > Seu nome > Assinaturas. A cobrança é feita pela sua conta Apple."
    static let emAnaliseTitulo = "Compra em análise"
    static let emAnaliseTexto = "A Apple ainda está confirmando o pagamento. Seu acesso será liberado automaticamente."
    static let entendi = "Entendi"
    // Chip do Início
    static func chipRestam(_ n: Int) -> String { n == 1 ? "Resta 1 clipe gratuito" : "Restam \(n) clipes gratuitos" }
    static let chipUsados = "Clipes gratuitos usados"
    static let chipEncerrada = "Assinatura encerrada"
    static let chipPagamento = "Problema no pagamento"
    static let chipNaoConfirmada = "Assinatura não confirmada"
    static let chipRevogado = "Acesso revogado"
    // Avisos da câmera (a partir do 7º clipe gratuito)
    static func clipeSalvoRestam(_ n: Int) -> String {
        switch n {
        case 0: return "Clipe salvo. Você usou seus 10 clipes gratuitos."
        case 1: return "Clipe salvo. Resta 1 clipe gratuito."
        default: return "Clipe salvo. Restam \(n) clipes gratuitos."
        }
    }

    // MARK: - Tutorial de primeiro acesso (v0.9.35)
    static let tutorialMarca = "Ei Clip"
    static func tutorialPasso(_ n: Int, de total: Int) -> String { "Passo \(n) de \(total)" }

    // Tela 1: como funciona
    static let tutorialFuncionaTitulo = "Grave o que já aconteceu"
    static let tutorialFuncionaDescricao = "O Ei Clip guarda os últimos segundos. Ao salvar, o clipe já começa antes do seu toque."
    static let tutorialFuncionaPontos: [(titulo: String, texto: String)] = [
        ("Mantenha o app aberto", "Deixe a tela ligada e não bloqueie o iPhone enquanto grava."),
        ("Salve o momento", "Toque no botão de gravação, diga a palavra de ativação ou use os botões de volume."),
        ("O clipe vai para as Fotos", "Seus clipes são salvos no app Fotos, no álbum “Ei Clip”."),
        ("10 clipes grátis", "Grave até 10 clipes gratuitamente. Depois, escolha como continuar."),
    ]

    // Tela 2: permissões
    static let tutorialPermissoesTitulo = "O que o app vai pedir"
    static let tutorialPermissoesDescricao = "O iPhone vai mostrar alguns avisos. Veja para que serve cada permissão."
    static let tutorialPermissoesPontos: [(titulo: String, texto: String)] = [
        ("Câmera", "Para gravar os seus clipes."),
        ("Microfone", "Para gravar o som do clipe."),
        ("Reconhecimento de voz", "Só para reconhecer a palavra de ativação. Feito no próprio aparelho."),
        ("Fotos", "Para salvar e mostrar os clipes no álbum “Ei Clip”."),
    ]

    // Tela 3: calor e qualidade
    static let tutorialCalorTitulo = "Calor e qualidade"
    static let tutorialCalorDescricao = "Gravar com muita qualidade aquece o aparelho. Escolha conforme o uso."
    static let tutorialCalorPontos: [(titulo: String, texto: String)] = [
        ("Mais qualidade, mais calor", "Resoluções maiores e 60 fps fazem o iPhone esquentar mais."),
        ("Ao sol, escolha menos", "Em dias quentes, prefira uma qualidade menor. Se esquentar, o app avisa e você pode reduzir em Ajustes."),
        ("Escureça a tela", "Toque na lua. A gravação continua, a bateria rende mais e a tela esquenta um pouco menos."),
        ("Já vem equilibrado", "A configuração inicial do app já equilibra qualidade e calor."),
    ]

    // MARK: - Resumo do Meu plano e Ajuda (v0.9.36)
    static func resumoClipesGratis(_ n: Int) -> String { n == 1 ? "1 clipe grátis" : "\(n) clipes grátis" }
    static let resumoSemClipesGratis = "Sem clipes grátis"
    static let resumoMensal = "Mensal"
    static let resumoAnual = "Anual"
    static func resumoAte(_ dia: String) -> String { "Até \(dia)" }
    static let resumoPermanente = "Acesso permanente"
    static let resumoVerificarPagamento = "Verificar pagamento"
    static let resumoNaoConfirmado = "Não confirmado"
    static let resumoEncerrada = "Encerrada"
    static let resumoEmAnalise = "Em análise"
    static let resumoRevogada = "Revogada"

    /// Texto à direita da linha "Meu plano" nos Ajustes; `nil` = sem resumo (carregando).
    static func resumoDoPlano(_ resumo: PlanSummary) -> String? {
        switch resumo {
        case .none: return nil
        case .freeClips(let n): return resumoClipesGratis(n)
        case .noFreeClips: return resumoSemClipesGratis
        case .monthly: return resumoMensal
        case .yearly: return resumoAnual
        case .endsOn(let date): return resumoAte(date.formatted(.dateTime.day(.twoDigits).month(.twoDigits)))
        case .permanent: return resumoPermanente
        case .checkPayment: return resumoVerificarPagamento
        case .notConfirmed: return resumoNaoConfirmado
        case .ended: return resumoEncerrada
        case .pending: return resumoEmAnalise
        case .revoked: return resumoRevogada
        }
    }

    static let ajuda = "Ajuda"
    static let ajudaSecoes: [(titulo: String, textos: [String])] = [
        ("Como funciona", [
            "O Ei Clip guarda os últimos segundos da câmera. Ao salvar, o clipe já começa antes do seu toque.",
            "Em Ajustes, a pré-gravação define quantos segundos ficam guardados (15, 30 ou 60, conforme a qualidade).",
        ]),
        ("Salvar o momento", [
            "Toque no botão de gravação, diga a palavra de ativação ou use os botões de volume. A palavra e os botões podem ser ligados ou desligados em Ajustes.",
            "Pelo app Atalhos, também é possível criar uma ação que abre a câmera do Ei Clip. Ela precisa ser configurada no próprio Atalhos.",
        ]),
        ("Manter o app aberto", [
            "O iPhone não permite gravar com o app em segundo plano. Mantenha o Ei Clip aberto e não bloqueie o iPhone enquanto grava.",
            "Para poupar bateria, toque na lua na tela da câmera. A tela escurece e a gravação continua. Toque na tela para acendê-la.",
        ]),
        ("Onde ficam os clipes", [
            "Os clipes são salvos no app Fotos, no álbum “Ei Clip”. Você também pode vê-los na Galeria do Ei Clip.",
        ]),
        ("Calor e qualidade", [
            "Resoluções maiores e 60 fps fazem o iPhone esquentar mais. Em dias quentes ou sob sol forte, prefira uma qualidade menor.",
            "Se o iPhone esquentar, o app mostra um aviso. Em Ajustes, Aparelho, é possível ligar a redução automática da qualidade.",
        ]),
        ("Permissões", [
            "Câmera: para gravar os clipes. Microfone: para gravar o som. Reconhecimento de voz: só para a palavra de ativação, feito no próprio aparelho. Fotos: para salvar e mostrar os clipes no álbum “Ei Clip”.",
            "Se você negar alguma permissão, o app explica o que deixa de funcionar e leva você aos Ajustes do iPhone, onde ela pode ser ativada.",
        ]),
        ("Clipes grátis", [
            "O Ei Clip inclui até 10 clipes gratuitos para testar. Depois, escolha como continuar em Meu plano.",
        ]),
    ]
}
