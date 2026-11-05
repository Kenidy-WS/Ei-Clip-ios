# Status

**Atualizado em:** 2026-11-04 · **Versão:** v0.0.2 · **Etapa:** 0 (preparação)

## Estado atual

- App mínimo "olá" (tela preta com a marca) só para validar o ciclo: compilar → baixar IPA → instalar → abrir.
- Workflow `Compilar IPA` (GitHub Actions, macOS) gera o IPA não assinado como artefato `EiClip-ipa` **e** o publica numa Release (`vX.Y.Z`) com link direto de download (a tabela de artefatos do GitHub não funcionou para o Kenidy no navegador).

## Pendências

1. Kenidy: Sideloadly no PC, Apple ID secundário, instalar o IPA, Modo Desenvolvedor, confiar no perfil.
2. Confirmar se o Sideloadly mantém o Bundle ID `br.com.wpstecnologia.eiclip` ao assinar (a tela "olá" mostra o Bundle ID real).
3. Etapa 1 (motor mínimo) só começa depois do ciclo validado.

## Decisões

- Bundle ID: `br.com.wpstecnologia.eiclip` (definitivo).
- Sem galeria própria: salvar no álbum "Ei Clip" do Rolo.
- Sem toolchain Swift no ambiente de desenvolvimento: lógica pura testada no CI macOS.
