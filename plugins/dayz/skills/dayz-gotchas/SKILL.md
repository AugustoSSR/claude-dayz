---
name: dayz-gotchas
description: 'Use ANTES de escrever, revisar ou diagnosticar código, layout, config ou build de mod DayZ (Enforce Script, RPC, UI/.layout, ciclo de vida de entidade, Central Economy, AddonBuilder, servidor local). Índice de armadilhas confirmadas na prática, com um arquivo de referência por tema.'
license: PolyForm-Noncommercial-1.0.0
metadata:
  version: "1.0.0"
---

# DayZ: armadilhas confirmadas (engine e Enforce Script)

> Achados empíricos, sem versão de build fixada: revalide na sua.

Só o que custou retrabalho real, escrito como regra. Vale para qualquer mod ou servidor DayZ; nada aqui depende de um
mod específico. O catálogo de "API errada → API certa" fica em `dayz-api-corrections` (ternário, `Close()`,
`JsonLoadFile` void, assinatura de `OnRPC`, `ClearItems`...). Esta skill cobre o resto: semântica, rede, UI, ciclo de
vida, economia e build. Cada item de referência foi visto quebrando algo; quando um item é hipótese, o texto diz.

## Método (vale para tudo)

1. **Nunca use campo, método, classe ou assinatura sem ver o uso real**: procure a mesma chamada nos scripts vanilla
   extraídos ou num mod que já roda em produção. Vale também para métodos de tipos primitivos (`string`, `int`).
   Analogia com C#, C++ ou outro engine já gerou API que nunca existiu.
2. **Só o primeiro erro de compile importa.** "Bad type", "Undefined function" e erros em templates de módulos sem
   relação costumam ser cascata do parser. Corrija o primeiro, recompile, releia.
3. **Erro idêntico depois de corrigir a sintaxe = a premissa está errada** (a API nunca existiu). Compare com código
   que funciona em vez de reescrever a mesma linha.
4. **Servidor compilando não prova UI.** `.layout`, menu, widget e blocos de client só rodam no client. "Subiu sem
   erro" não é "a tela funciona".
5. **Meça antes de culpar o código**: leia o `.RPT`, o `script.log` do servidor **e** o do client, e confira se o log é
   mais novo que o `.pbo`. Log velho não reflete o código atual.
6. **Auditoria estática antes de dizer "pronto"** num módulo inteiro (greps em `references/verificacao-e-metodo.md`).

## As regras mais caras (leia mesmo sem abrir as referências)

- Sem ternário `? :` (nem dentro de concatenação). O erro enganoso é `Broken expression (missing ';'?)`.
- Escopo é a **função inteira**: `foreach`/`for (int i` com o mesmo nome em blocos irmãos derruba o boot.
- `enum` fecha com `}` sem `;`, e o membro se acessa qualificado (`MeuEnum.MEMBRO`).
- `map`, `ref`, `owned`, `local`, `out` não servem de nome de variável nem de parâmetro.
- `override` repete o **nome** do parâmetro vanilla (`timeslice`, não `delta`).
- Chamada de função e `new Param...<...>(...)` numa linha só.
- Nunca `ref` em tipo nativo do engine (`EntityAI`, `RestApi`...): destrutor privado.
- `modded class` só na **mesma camada** (`3_Game`/`4_World`/`5_Mission`) da classe original; classe selada do engine
  falha no boot do servidor, não no build do PBO.
- Mesma camada entre mods diferentes não tem ordem garantida, mesmo com `requiredAddons`. Camada posterior chamando
  camada anterior é segura.
- `ActionCondition` roda no client **e** no servidor dedicado: estado que só existe num dos lados faz a ação sumir ou
  ser recusada, sem erro nenhum.
- RPC: ID colide em silêncio entre módulos; não serialize `Object`/`EntityAI` (chega `null`); payload de string acima
  de ~1 KB corrompe; sincronize por jogador na conexão, não só no boot.
- `.layout`: `userID` com `ID` maiúsculo (`userid` carrega e devolve 0); keyword errada crasha o client; `hexactpos`
  e `vexactpos` têm de bater com o tipo de valor (fração ou pixel); arquivo é CRLF.
- Toda tecla é input registrado em `inputs.xml`; `KeyState` direto "gruda" e quebra com modificador.
- `JsonLoadFile` com alvo `null` falha em silêncio e o "default" sobrescreve o arquivo real; campo novo de config
  precisa do próprio bloco de migração por versão.
- A Central Economy persiste objetos entre reinícios: objeto "duplicado" em teste local costuma ser resíduo do
  `storage_1`, não bug de spawn.
- AddonBuilder: sucesso é o texto `Build Successful`, nunca o exit code; build bom não prova compile do script.
- Sem `config.cpp` com `CfgMods`/`defs`, o PBO empacota e nada compila, sem erro.

## Quando abrir cada referência

| Tema | Arquivo em `references/` |
|---|---|
| Sintaxe, nomes reservados, strings, números, operadores | `enforce-sintaxe.md` |
| `ref`, coleções, `foreach`, `modded`, `static`, `CallLater` | `enforce-tipos-e-colecoes.md` |
| JSON, config, migração por versão, `OnStoreSave/Load`, `config.cpp` de item | `json-e-config.md` |
| RPC e rede, sincronização, `InvokeOnConnect` | `rpc-e-rede.md` |
| Ações, `ActionCondition`, input de ação, hooks de servidor | `acoes-e-actioncondition.md` |
| Camadas, ordem de compilação, `#ifdef SERVER`, `requiredAddons` | `camadas-e-compilacao.md` |
| `.layout`: widgets, keywords, posição, CRLF, listbox, estilos | `layout-widgets.md` |
| Textura, cor, gamma, fonte bitmap | `layout-textura-cor-fonte.md` |
| `UIScriptedMenu`, foco, fechar, teclas e `inputs.xml` | `menus-e-input.md` |
| `MapWidget`, HUD vanilla, overlays | `mapa-e-hud.md` |
| Entidade, inventário, anexos, dano, delete, canais de chat | `entidades-e-inventario.md` |
| Central Economy, persistência, eventos em coordenada fixa | `central-economy.md` |
| AddonBuilder, PBO, assinatura, chaves | `build-addonbuilder-pbo.md` |
| Servidor local de teste, logs, veredito de boot | `servidor-local-de-teste.md` |
| Windows + Git Bash, CRLF, barra invertida, git compartilhado | `ambiente-windows-git-bash.md` |
| Método, greps de auditoria, como provar o que se afirma | `verificacao-e-metodo.md` |

Protocolo de consulta do servidor (A2S): `docs/a2s-query-protocol.md` na raiz do repositório.
