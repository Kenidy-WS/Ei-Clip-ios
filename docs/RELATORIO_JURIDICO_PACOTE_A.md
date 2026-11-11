# Relatório para validação jurídica: Política de Privacidade (Pacote A)

Para levar ao chat jurídico antes de publicar. Data: 11/11/2026. App: Ei Clip v0.9.5 (iOS). Titular: pessoa física (Kenidy Wiquerson Pereira dos Santos). O Kenidy não é advogado; o texto abaixo é rascunho e **não está publicado** (ramo `rascunho-politica` do repositório `ei-clip/ei-clip-legal`).

## 1. O que pedir ao chat jurídico
Revisar o texto da seção 4 e responder às perguntas da seção 3. Dizer o que mudar antes de publicar.

## 2. Fatos conferidos no código (v0.9.5, 10 e 11/11/2026)
- **Sem rede, login, analytics ou SDK de terceiros.** Nenhum uso de rede no código; sem dependências externas (só frameworks da Apple). Única abertura externa: Ajustes do iOS.
- **Voz no aparelho:** `requiresOnDeviceRecognition = true` (`Engine/VoiceProbe.swift`). Se o aparelho não reconhece pt-BR sem internet, o app para e não usa servidor.
- **Buffer retroativo:** na memória (`ReplayBuffer`); só vai a disco quando um clipe é acionado. *(a confirmar o caminho de descarte na revisão final)*
- **Clipes:** gravados em Application Support (pasta de gravações, fora do backup do iCloud), salvos no álbum "Ei Clip" (PhotoKit) e a cópia interna é apagada; se o salvamento falha, fica para nova tentativa.
- **Miniaturas próprias (JPG)** em Application Support/Miniaturas. *(a confirmar se são apagadas junto com o clipe)*
- **Preferências** em UserDefaults (ajustes, aviso de bateria, permissões).
- **Compartilhamento:** cópia temporária em pasta temporária, apagada ao fechar a folha (`App/ClipShare.swift`). Se o clipe está no iCloud Fotos, o iOS pode baixá-lo (rede do sistema).
- **Diagnóstico:** log local (arquivos "atual" e "anterior", teto de 3 MB por rodada). Cabeçalho: versão do app, modelo do aparelho, versão do iOS, Bundle ID. **Registra o texto reconhecido da fala (parcial, final e gatilhos).** Só sai se o usuário tocar em "Copiar" e enviar.
- **Permissões (Info.plist):** câmera, microfone, reconhecimento de voz, Fotos (leitura e escrita) e Fotos (só adicionar). Sensor de movimento usado para orientação, sem aviso de permissão.
- **Sem localização e sem contatos.**

## 3. Divergências e pontos para o advogado
Divergências em relação ao que se supunha:
1. Os clipes **não** ficam em pasta temporária: ficam em Application Support até serem salvos nas Fotos.
2. Existem **miniaturas próprias** e **preferências** guardadas no aparelho (incluídas no texto).
3. O Diagnóstico grava o **texto da fala reconhecida**. Decisão de 10/11: a versão da loja não terá tela de Diagnóstico, nem log em arquivo, nem esse texto. O **beta (TestFlight) terá**, por isso a seção 5 do texto trata das versões de teste.

Perguntas:
- A afirmação "não coleta nem envia dados pessoais" é adequada, já que a voz e a imagem são tratadas **apenas no aparelho** do próprio usuário? Há risco jurídico em usar "não coleta"?
- Como pessoa física responsável, preciso nomear um **encarregado** (LGPD art. 41) ou indicar só o contato? O texto usa só o e-mail.
- Citar o **nome completo** do responsável e só o e-mail de contato (sem endereço) é suficiente?
- A seção 5 (Diagnóstico nas versões de teste) é suficiente e posso removê-la quando o beta acabar?
- Como tratar o direito de imagem de **terceiros gravados**: basta o aviso curto da seção 7 aqui e o detalhe nos Termos de Uso?
- A cláusula sobre crianças (seção 7) é suficiente à luz do **ECA Digital** (Lei 15.211/2025)?
- A menção ao iCloud Fotos (seção 4) isenta o app de responsabilidade pela sincronização feita pelo sistema?
- A lei aplicável (só "lei brasileira, em especial a LGPD") dispensa foro nesta política?

## 4. Texto proposto

# Política de Privacidade do Ei Clip

**Vigência:** a partir de [data da publicação].

## 1. Quem é o responsável

O Ei Clip é desenvolvido e publicado por **Kenidy Wiquerson Pereira dos Santos**, pessoa física, que responde por esta política.

Contato para qualquer dúvida sobre privacidade: **eiclip.suporte@gmail.com**

## 2. Resumo

**O Ei Clip não coleta nem envia dados pessoais.** Não existe conta, login, anúncio, rastreamento nem serviço de terceiros dentro do app. Tudo o que o app faz acontece no seu iPhone.

## 3. O que o app acessa e para quê

O app pede autorização ao iOS e só usa cada recurso para a finalidade abaixo.

- **Câmera:** gravar os vídeos (clipes).
- **Microfone:** gravar o som dos clipes e ouvir o comando de voz.
- **Reconhecimento de voz:** detectar a palavra de ativação ("Ei Clip"). O reconhecimento é feito **no próprio aparelho**, sem enviar áudio para a Internet. Se o seu aparelho não conseguir reconhecer o português do Brasil sem Internet, o app não usa nenhum servidor: o comando de voz simplesmente não funciona.
- **Fotos:** salvar os clipes no álbum "Ei Clip" e permitir que você veja, compartilhe e apague os clipes desse álbum.
- **Sensores de movimento:** saber a orientação do aparelho, para gravar o vídeo na posição certa. Esses dados não são guardados nem enviados.

Você pode negar ou retirar qualquer autorização a qualquer momento, em Ajustes do iOS. Sem algumas delas, partes do app deixam de funcionar.

## 4. Onde ficam os dados

Tudo fica no seu aparelho.

- **Gravação retroativa (buffer):** os últimos segundos de imagem e som ficam apenas na memória do aparelho enquanto a câmera está aberta. Se você não acionar um clipe, esse material é descartado continuamente.
- **Clipes:** ao acionar, o clipe é gravado numa pasta interna do app e salvo no álbum "Ei Clip" das suas Fotos. Depois de salvo, a cópia interna é apagada. Se o salvamento falhar, a cópia interna é mantida para nova tentativa na próxima abertura.
- **Miniaturas e configurações:** o app guarda, só no aparelho, imagens pequenas de visualização dos clipes e as suas preferências (por exemplo, formato e ajustes).
- **Compartilhar:** ao compartilhar um clipe, o app faz uma cópia temporária para entregá-lo ao aplicativo escolhido por você e a apaga ao fechar a tela de compartilhamento. O que o outro aplicativo faz com o arquivo segue as regras dele.
- **iCloud Fotos:** se você usa o iCloud Fotos, o próprio iOS pode sincronizar os clipes do álbum conforme as suas configurações. Isso é feito pelo sistema da Apple, não pelo Ei Clip.

## 5. Diagnóstico (versões de teste)

As versões de teste do app (TestFlight) têm uma tela de **Diagnóstico**. Ela mostra e guarda, **só no aparelho**, um registro técnico: eventos do app, versão do iOS, modelo do aparelho, temperatura, bateria, espaço e, nessas versões de teste, o texto que o reconhecimento de voz entendeu.

Esse registro **só sai do aparelho se você tocar em "Copiar" e enviá-lo a alguém**, por exemplo ao suporte. Se não quiser enviar, não copie. Desinstalar o app apaga esse registro.

## 6. Anúncios, rastreamento e terceiros

O Ei Clip não tem anúncios, não rastreia você e não usa serviços de análise ou de terceiros.

Se o app oferecer compra, ela é feita e processada pela **Apple (App Store)**. O Ei Clip não recebe nem guarda dados de pagamento.

## 7. Crianças

O Ei Clip não é dirigido a crianças e não coleta dados de ninguém, inclusive de menores. Quem grava pessoas, em especial crianças, deve respeitar o direito de imagem e a lei.

## 8. Seus direitos

A Lei Geral de Proteção de Dados (LGPD, Lei 13.709/2018, art. 18) garante direitos como saber, corrigir e apagar dados pessoais. Em linguagem simples:

- **Eu não guardo dados seus.** Não há nada retido comigo para consultar, corrigir ou apagar.
- **Os dados estão no seu aparelho** e você os controla. **Desinstalar o app apaga** as miniaturas, as configurações, o registro de Diagnóstico e eventuais gravações pendentes.
- **Os clipes salvos nas Fotos continuam** depois de desinstalar. Para apagá-los, use o próprio app Ei Clip ou o app Fotos.
- Para qualquer dúvida ou pedido, escreva para **eiclip.suporte@gmail.com**.

## 9. Segurança

Como o app não envia dados, a proteção dos seus clipes depende das proteções do seu aparelho e da sua conta: senha ou biometria, bloqueio de tela e configurações do iCloud.

## 10. Mudanças nesta política

Se o app passar a tratar dados de outra forma (por exemplo, com análise de uso, sincronização ou relatório de falhas), esta política será atualizada **antes** da mudança, com nova data de vigência no topo. Avisaremos também na ficha do app na App Store.

## 11. Lei aplicável

Esta política é regida pela lei brasileira, em especial pela LGPD.

[Voltar](../)
