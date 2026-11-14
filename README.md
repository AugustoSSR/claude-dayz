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
| `skills/dayz-api-corrections` | APIs e padrões que parecem certos e quebram compile ou runtime |
| `skills/dayz-layout-diagnosis` | Método para diagnosticar bug visual em `.layout` sem chutar |
| `skills/dayz-command-flow-review` | Bug intermitente de timing e ciclo de vida do player |
| `skills/dayz-duplicate-detector` | Duplicação e comentário obsoleto entre módulos |
| `shared/dayz-conventions.md` | Estrutura do servidor, `types.xml`, eventos, gotchas confirmados |
| `docs/restcallback-lifetime.md` | Estudo de caso: callback REST sem referência forte derrubou o servidor |
| `docs/a2s-query-protocol.md` | Notas do protocolo A2S para consultar um servidor de fora do jogo |
| `tools/local-build/` | Scripts PowerShell de exemplo: empacotar com AddonBuilder, assinar, subir servidor de teste, veredito |

## Instalação

```
claude plugin marketplace add AugustoSSR/claude-dayz
claude plugin install dayz@claude-dayz --scope user
```

Os agentes ficam como `dayz:modding`, `dayz:buildtest` e `dayz:server`. As skills disparam pela descrição.

Mantenedor, antes de cada commit: `claude plugin validate .`

## Licença

[PolyForm Noncommercial 1.0.0](LICENSE): uso não comercial. Veja também [NOTICE.md](NOTICE.md).
