# claude-dayz

Plugin do Claude Code com o que aprendemos fazendo mods e servidor de DayZ: um catálogo de armadilhas do Enforce Script
e do engine confirmadas na prática, diagnóstico de `.layout`, revisão de fluxo de comando, três agentes de trabalho
(código de mod, build e teste local, configuração de servidor) e um pipeline de exemplo para compilar e testar
localmente.

## O que tem

| Item | Para que serve |
|---|---|
| `agents/modding` | Código de mod (Enforce Script, RPC, `.layout`, `config.cpp`) e causa raiz por log |
| `agents/buildtest` | Compila, sobe um servidor de teste, vigia o log e dá PASS ou FAIL com `arquivo:linha` |
| `agents/server` | `types.xml`, `events.xml`, `init.c`, `cfggameplay.json`, Central Economy, mods no servidor |
| `skills/dayz-gotchas` | Índice de armadilhas confirmadas, com 16 referências por tema (sintaxe, tipos, JSON, RPC, ações, camadas, layout, input, mapa, entidades, economia, build, servidor local, ambiente, método) |
| `skills/dayz-prompt-menu-claude-design` | Da ideia de um menu ao prompt de arte para o Claude Design; formatos PAA/EDDS, conversão, caminhos de imagem, imageset e montagem do `.layout` |
| `skills/dayz-api-corrections` | APIs e padrões que parecem certos e quebram compile ou runtime |
| `skills/dayz-layout-diagnosis` | Método para diagnosticar bug visual em `.layout` sem chutar |
| `skills/dayz-command-flow-review` | Bug intermitente de timing e ciclo de vida do player |
| `skills/dayz-duplicate-detector` | Duplicação e comentário obsoleto entre módulos |
| `shared/dayz-conventions.md` | Estrutura do servidor, `types.xml`, eventos, gotchas confirmados |
| `docs/restcallback-lifetime.md` | Estudo de caso: callback REST sem referência forte derrubou o servidor |
| `docs/a2s-query-protocol.md` | Notas do protocolo A2S para consultar um servidor de fora do jogo |
| `tools/local-build/` | Scripts PowerShell de exemplo: empacotar com AddonBuilder, assinar, subir servidor de teste, veredito |

## Como criamos menus: da ideia ao Claude Design (DayZ)

A arte de um menu de mod nasce de **um prompt único e controlado**, para que painéis, botões e ícones saiam no mesmo estilo
e no tamanho exato que o `.layout` vai usar. O fluxo:

1. **A ideia vira telas e medidas.** Descrevemos o menu (abas, slots, botões, estados) e medimos no layout, numa
   resolução de referência: tamanho de painel, slot, botão. Texto e números **não** entram na arte; o jogo os desenha.
2. **A IA escreve o prompt** em três partes: **bloco 1** (estilo fixo do projeto, igual em todos os prompts, e as regras
   técnicas: PNG RGBA, tamanho exato, sem texto, estados `_n/_h/_p/_s/_d` com a mesma silhueta, sombra dentro do tamanho,
   moldura de slot com área central lisa), **bloco 2** (ícones de item) e a **lista de peças** (nome exato do arquivo,
   tamanho, estados e a peça de destino no imageset).
3. **O usuário cola no Claude Design** (claude.ai), em lotes de um tipo de peça por vez.
4. **Os PNG voltam e são conferidos** (nome, tamanho em pixels, transparência, sem texto, estados com a mesma silhueta).
5. **Imagem para o jogo.**
   - **Formato:** o DayZ usa **PAA** e **EDDS**. O padrão do projeto é **PAA**, porque o `ImageToPAA` (DayZ Tools) converte
     por linha de comando e dá para automatizar. **EDDS** (o formato do vanilla, que o mantenedor considera o melhor para arte
     final) só se cria **à mão** no TexView2: é uma etapa manual declarada.
   - **Conversão:** `ImageToPAA.exe entrada.png saida.paa` exige lados em potência de 2 e **sempre grava PAA**. O build com
     `-packonly` não converte nada: o `.paa` tem de existir antes de empacotar.
   - **Volta:** `.paa` → PNG pelo TexView2; `.edds` → PNG pelo `edds2png` (de terceiros) ou TexView2.
   - **Folha e imageset:** as peças pequenas vão numa folha de potência de 2; o `.imageset` guarda textura, `Pos` e `Size`
     de cada peça, e é registrado no `config.cpp` (`imageSets`).
   - **Caminhos:** peça solta com o prefixo completo do PBO (`image0 "MeuMod/Client/gui/data/x.paa"`), ou `set:nome
     image:peca`, ou `LoadImageFile` no script. Prefixo ou nome errado = imagem vazia, sem erro de compile.
6. **Montagem.** O `.layout` (CRLF) usa as peças pelos nomes da lista; o script cria o layout com
   `GetWorkspace().CreateWidgets`, guarda os widgets em `Init` e trata `OnClick`, `OnMouseEnter`, `OnMouseLeave`.
7. **Teste no client** (o servidor não valida UI), em mais de uma resolução.

A skill [`dayz-prompt-menu-claude-design`](plugins/dayz/skills/dayz-prompt-menu-claude-design/SKILL.md) conduz o fluxo;
os detalhes de **formatos, conversão e todos os padrões de caminho** estão em
[`references/imagens-formatos-conversao-caminhos.md`](plugins/dayz/skills/dayz-prompt-menu-claude-design/references/imagens-formatos-conversao-caminhos.md),
e um exemplo trabalhado em
[`references/exemplo-menu-loja.md`](plugins/dayz/skills/dayz-prompt-menu-claude-design/references/exemplo-menu-loja.md).
O estilo do exemplo (sobrevivência militar desgastada) é só um modelo: **o estilo é do seu projeto**. Detalhes de engine
sem confirmação estão marcados "não verificado".

## Instalação

```
claude plugin marketplace add AugustoSSR/claude-dayz
claude plugin install dayz@claude-dayz --scope user
```

Os agentes ficam como `dayz:modding`, `dayz:buildtest` e `dayz:server`. As skills disparam pela descrição.

Mantenedor, antes de cada commit: `claude plugin validate .`

## Licença

[PolyForm Noncommercial 1.0.0](LICENSE): uso não comercial. Veja também [NOTICE.md](NOTICE.md).
