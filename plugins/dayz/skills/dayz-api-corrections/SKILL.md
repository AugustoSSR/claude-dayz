---
name: dayz-api-corrections
description: 'Use ANTES de escrever ou revisar Enforce Script (DayZ): catalogo verificado de APIs e padroes que parecem certos mas quebram o compile ou o runtime (ternario, escopo por funcao, RPC, ActionCondition, UIScriptedMenu.Close, TextListboxWidget, JsonFileLoader, float->int grande, hifen em widget).'
license: PolyForm-Noncommercial-1.0.0
---

Catálogo de todo padrão/API que apareceu em código gerado, quebrou o compile (ou teria quebrado
em runtime), e foi corrigido depois de ler o código-fonte real (os scripts vanilla extraídos do jogo, `<DAYZ_SCRIPTS>`, ou
outro mod já em produção). Cada item aqui é **verificado**, não suposição — se um item futuro
usar qualquer coisa desta lista do lado "❌ errado", pare e corrija antes de reportar a tarefa como
concluída.

## Sintaxe da linguagem

| ❌ Errado | ✅ Correto | Por quê |
|---|---|---|
| `condição ? a : b` (ternário) | `if (condição) { x = a; } else { x = b; }` | Enforce Script não tem operador ternário. Erro do compiler é enganoso: `"Broken expression (missing ';'?)"`, mesmo com `;` presente. |
| Duas variáveis `string x`/`int x`/etc com o mesmo nome em `if`/`foreach` **irmãos** dentro da mesma função | Renomear uma delas | Escopo é **por função**, não por bloco como C/C++. Blocos irmãos (não aninhados) ainda colidem. Erro: `"Multiple declaration of variable 'x'"`. Vale pra variável de `foreach` também. |
| Dois métodos com o mesmo nome na mesma classe (ex. `static void Close()` + `override void Close()`) | Um nome por método na classe, mesmo que um seja estático | Erro: `"Multiple declaration of function 'X'"`. |
| Chamada de função/construtor com **um argumento por linha** (`new Classe(\n  arg1,\n  arg2\n);`), especialmente com generics (`Param5<...>`) | Sempre **uma linha só**, por mais longa que fique | Confirmado em campo: quebra o compile com `"Invalid statement ')'"` na linha do `);` de fechamento, mesmo com sintaxe/parênteses perfeitamente balanceados. Mods de referência em produção nunca quebram uma chamada `Param5<>` em multi-linha: sempre uma linha só, mesmo linhas longas. Se um erro "Invalid statement" persistir depois de reescrever a LÓGICA mas a formatação multi-linha continuar, suspeitar da formatação antes de reescrever de novo. |

## APIs de timestamp/relógio

| ❌ Errado | ✅ Correto |
|---|---|
| `GetGame().GetTime().Format("%H:%M:%S")` | `GetGame().GetTime()` é `int` puro (ms desde boot da missão) — **não tem `.Format()`**. Pra timestamp real de calendário: `GetYearMonthDayUTC(year, month, day)` + `GetHourMinuteSecondUTC(hour, minute, second)` (out-params). |

## Persistência JSON

| ❌ Errado | ✅ Correto |
|---|---|
| `if (!JsonFileLoader<T>.JsonLoadFile(path, obj))` / `if (JsonFileLoader<T>.JsonSaveFile(...))` | `JsonLoadFile`/`JsonSaveFile` são `static void` **neste build** — não têm retorno pra testar em `if`. Usar `FileExist(path)` antes de carregar, e checar `null` no objeto depois. |

## RPC

| ❌ Errado | ✅ Correto |
|---|---|
| `player.RPC(tipo, dadoSolto)` | Assinatura real: `void RPC(int rpc_type, array<ref Param> params, bool guaranteed, PlayerIdentity recipient = NULL)` — nunca usar direto com um `Param` solto. Usar `GetGame().RPCSingleParam(alvo, tipo, param, guaranteed, identity_ou_null)` — mesmo em client→server (`identity=null`). |
| `override void OnRPC(uint rpc_type, ParamsReadContext ctx)` | Não existe `uint` em Enforce Script. Assinatura real: `override void OnRPC(PlayerIdentity sender, int rpc_type, ParamsReadContext ctx)`, chamando `super.OnRPC(sender, rpc_type, ctx)`. |

## Ações customizadas (ActionInteractBase / ActionConstructor)

| ❌ Errado | ✅ Correto |
|---|---|
| `modded class ActionConstructorClient { override void RegisterActions(TNodeArray actions) { actions.Insert(new TNodeData(null, MinhaAcao)); } }` | Classe real é `ActionConstructor` (sem "Client"), método `RegisterActions(TTypenameArray actions)`, insere o typename direto: `actions.Insert(MinhaAcao);`. |
| `override bool ActionCondition(PlayerBase player, ActionTarget target)` (2 params) | Assinatura real tem 3: `ActionCondition(PlayerBase player, ActionTarget target, ItemBase item)`. Confirmado em `4_world/classes/useractionscomponent/actionbase.c` dos scripts vanilla. |
| Construtor vazio numa `ActionInteractBase` | Precisa setar `m_CommandUID`, `m_StanceMask`, `m_HUDCursorIcon` no construtor — senão fica com `m_CommandUID=-1` (sem bind de animação). |

## Menus (UIScriptedMenu)

| ❌ Errado | ✅ Correto |
|---|---|
| `override void Close() { ...; super.Close(); }` | **Nunca sobrescrever `Close()`** — é `proto native` no engine. Causa `"Multiple declaration of function 'Close'"` mesmo com uma única declaração aparente. Usar `override void OnShow()`/`override void OnHide()` pra lógica de abrir/fechar (trio `PlayerControlDisable`/`ShowCursor`/`ChangeGameFocus(1)` na abertura, espelhado no fechamento). |
| `GetGame().GetMissionServer()` | Não existe. Pra checar se é servidor: `GetGame().IsServer()`. |
| `GetGame().GetMissionBaseWorld()` | Não existe. Padrão real: `MissionBaseWorld.Cast(GetGame().GetMission())`. |
| `Class.CastTo(intVar, algumMetodoQueRetornaInt())` | `Class.CastTo` é só pra referência de objeto, nunca pra tipo primitivo (`int`/`float`/`bool`). Se o método já retorna `int`, usar direto: `int x = metodo();`. |

## Widgets — `TextListboxWidget` / `EditBoxWidget`

| ❌ Errado | ✅ Correto |
|---|---|
| `listbox.ClearAll()` | Não existe em `TextListboxWidget`. Método real (herdado de `BaseListboxWidget`): `ClearItems()`. |
| `listbox.GetSelectedItem()` | Não existe. Método real: `GetSelectedRow()`. |
| `listbox.AddItem(textoSó)` | `TextListboxWidget.AddItem` exige 4 args: `AddItem(string text, Class userData, int column, int row = -1)`. Uso real confirmado: `AddItem(texto, null, 0)`. |

## Acesso a campo `protected` entre classes

| ❌ Errado | ✅ Correto |
|---|---|
| Uma classe **A** lendo `objetoDeClasseB.m_CampoProtegido` onde o campo é `protected` em **B** e A não é subclasse de B | `protected` só libera acesso pra classe declarante + suas subclasses — nunca pra outra classe "vizinha". Se outro arquivo/classe precisa do dado, expor via singleton estático (`static X s_Instance; static X GetInstance() { return s_Instance; }`) na própria classe dona do estado. |

## Recursão infinita: log ↔ config circular

| ❌ Errado | ✅ Correto |
|---|---|
| `Write()` do logger chama `ConfigLoader.IsLogging()` (pra decidir se escreve em arquivo) → `IsLogging()` chama `GetConfig()` → `GetConfig()` chama `Load()` se `s_Config` for null → e `Load()` loga alguma mensagem (`MeuLog.Info(...)`) **antes** de atribuir `s_Config` | Nunca logar dentro de `Load()` antes de `s_Config` estar atribuído — mover toda chamada de log pra depois da atribuição. Reforçar com um guard de reentrância (`protected static bool s_Loading`) que faz `Load()` retornar de imediato se já estiver em execução na mesma pilha, como defesa contra qualquer edição futura reintroduzir o mesmo bug. |

Sintoma real: **`Stack overflow` / `Virtual Machine Exception`** em runtime (não erro de compile) — o
stack trace mostra o mesmo ciclo de 4 funções (`Write` → `Info`/`Error` → `Load` → `GetConfig` →
`IsLogging` → `Write`...) se repetindo dezenas de vezes até estourar. Esse é o assinatura
característica — se aparecer esse padrão de 4-5 funções repetindo em loop no stack trace, é
recursão de bootstrap de config/log, não um bug de lógica de negócio.

## Protocolo de verificação (aplicar sempre, não só quando já quebrou)

1. Antes de escrever qualquer chamada de API do engine (`GetGame().*`, métodos de `Widget`/`EntityAI`/`PlayerBase`/`ActionBase`/`JsonFileLoader`/etc), procurar um uso real e confirmado da MESMA chamada em outro mod já em produção, ou nos scripts vanilla. Nunca assumir por analogia com C#/C++/outro engine.
2. Depois de escrever um módulo/arquivo inteiro, antes de reportar como concluído:
   - Grep por `\?.*:` (ternário) no que foi escrito.
   - Grep por `Json(Load|Save)File` em condição de `if`.
   - Rodar um scanner de variável duplicada por função (se `if`/`foreach` irmãos declaram a mesma variável).
   - Extrair todo `.NomeDeMetodo(` chamado em objeto de engine/widget e cross-checar cada um contra os scripts vanilla ou um mod já em produção — não só os que "parecem" arriscados.
   - Ler `ConfigLoader.Load()` de ponta a ponta e confirmar que **nenhuma chamada de log acontece antes de `s_Config` ser atribuído** (ver seção "Recursão infinita" acima) — esse é silencioso no compile, só quebra em runtime.
3. Quando um erro de compile **persistir idêntico** depois de já ter confirmado que o arquivo está sintaticamente correto (mesma linha, mesmo texto), a premissa pode estar errada, não a digitação — comparar com um mod irmão já funcionando é mais rápido que insistir na mesma abordagem.

## Gotchas adicionais confirmados (dinheiro como quantidade de item)

- **`EntityAI.AddQuantity()` não existe.** `AddQuantity()` é declarado só em `ItemBase`
  (`4_world/entities/itembase.c` dos scripts vanilla). `SetQuantity()` **e** `GetQuantity()`/`HasQuantity()`
  SIM existem na base `EntityAI` (`entityai.c`). Se a variável está tipada `EntityAI` (comum
  ao vir de `EnumerateInventory()`), usar `item.SetQuantity(item.GetQuantity() - unidades)` em vez de
  `.AddQuantity(-unidades)` — evita precisar de cast pra `ItemBase` só pra isso.
- **`Math.Ceil(int / int)` é um no-op silencioso.** Divisão inteira trunca ANTES do `Ceil` rodar — ex:
  `Math.Ceil(101 / 50)` dá `2` (não `3`), porque `101/50` já virou `2` como int antes do Ceil ver
  qualquer fração. É bug de lógica, não erro de compile — não aparece em log de crash, só em
  comportamento errado silencioso. Fix: cast um operando pra `float` antes de dividir —
  `Math.Ceil(a / (float)b)`.
- **Reincidência real do gotcha de escopo por função**: mesmo já sabendo da regra, uma segunda passada de troco/fallback dentro da MESMA
  função redeclarou `denom`/`item`/`coin`/`available` que a primeira passada já tinha "reivindicado" —
  cada redeclaração gerou seu próprio crash de compile em rodadas separadas (não pegou tudo de uma vez
  nem revisando o código antes de mandar testar). Lição prática: depois de escrever qualquer função com
  2+ blocos de loop (ex: "passe 1 / passe 2" de um algoritmo greedy), fazer um grep de TODOS os nomes de
  variável já declarados na função inteira antes de reusar qualquer nome numa segunda passada — não
  confiar em estar "num bloco `if` diferente" como isolamento de escopo.
- **`Param1<MinhaClasse>` via RPC pareceu não-confiável, mas a causa raiz real era outra (ver próximo
  item).** Suspeitei disso por dois números grandes saírem errados em sequência (2.000.000.000
  virou ~536M, depois 90.198.505 virou "2"), e troquei pra `Param1<string>` — o sintoma
  sumiu temporariamente mas VOLTOU idêntico depois. A troca de RPC não era o fix real (mantida mesmo
  assim, é o padrão mais robusto pra RPC em geral — só não era a causa desse bug específico).
- **A causa raiz real: conversão `float`→`int` (e aritmética de `int`) quebra nessa engine pra magnitudes
  grandes (~2^29 pra cima), fora de qualquer RPC.** Confirmado com log de diagnóstico direto: um valor de
  config (`2.000.000.000`) estava CORRETO logo após `JsonFileLoader` carregar (`2e+09`), e ficava
  `536870912` (exatamente `2^29`) um passo depois, só por passar por `Math.Floor(x+0.5)` convertido pra
  `int`. Nenhum RPC envolvido nesse passo — é puramente conversão `float`→`int` local. Fix: nunca fazer
  `int x = algumFloatGrande;` nem `Math.Floor()` casado com `int` pra número grande — extrair dígito por
  dígito via subtração de `float` (cada dígito sempre 0-9, faixa confirmada segura) e nunca converter o
  número INTEIRO pra `int` em lugar nenhum. `int` só é seguro pra contadores/dígitos pequenos (confirmado
  até pelo menos alguns milhões); qualquer coisa que possa passar de dezenas de milhões deve ficar em
  `float`/`string` o tempo todo.
- **Hífen no nome de um widget quebra `FindAnyWidget()` silenciosamente.** Um `CheckBoxWidgetClass` nomeado
  `sellall-check` no `.layout` compilou sem erro, mas `FindAnyWidget("sellall-check")` sempre retornava
  null (confirmado via log — todos os outros widgets do mesmo layout, sem hífen no nome, resolviam
  normal). Nenhum erro de compile acusa isso — só aparece como "widget não encontrado" em runtime. Fix:
  renomear o widget no `.layout` pra camelCase/underscore (ex: `sellallCheck`), nunca hífen. Regra geral:
  nomear todo widget novo em camelCase, nunca com `-`.
