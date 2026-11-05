# Status

**Atualizado em:** 2026-11-04 · **Versão:** v0.0.2 · **Etapa:** 0 (preparação)

## Estado atual

- App mínimo "olá" (tela preta com a marca) só para validar o ciclo: compilar → baixar IPA → instalar → abrir.
- Workflow `Compilar IPA` (GitHub Actions, macOS) gera o IPA não assinado como artefato `EiClip-ipa` **e** o publica numa Release (`vX.Y.Z`) com link direto de download (a tabela de artefatos do GitHub não funcionou para o Kenidy no navegador).

## Etapa 0: validada em 05/11 (iPhone do Kenidy)

Ciclo compilar → baixar IPA (Release no GitHub) → Sideloadly → confiar no perfil → abrir: funcionou.

**Bundle ID real no aparelho:** o Sideloadly acrescenta o ID da equipe do Apple ID: `br.com.wpstecnologia.eiclip.<ID da equipe>`. Esse sufixo é fixo para o mesmo Apple ID, então **sempre instalar com o mesmo Apple ID** (reinstalar por cima mantém as permissões). Se mudar de Apple ID (ou assinar com o Apple Developer Program pago), o iOS trata como outro app e as permissões são pedidas de novo uma vez.

O app expira em 7 dias: reinstalar pelo Sideloadly antes disso (com o mesmo Apple ID).

## Pendências

1. Etapa 1 (motor mínimo): câmera 1080p30 + mic, anel retroativo, gravar/parar, bipe, salvar no álbum "Ei Clip", Diagnóstico.

## Decisões

- Bundle ID: `br.com.wpstecnologia.eiclip` (definitivo).
- Sem galeria própria: salvar no álbum "Ei Clip" do Rolo.
- Sem toolchain Swift no ambiente de desenvolvimento: lógica pura testada no CI macOS.
