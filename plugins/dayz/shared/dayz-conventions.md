# Convenções DayZ

> Leia antes de qualquer trabalho de servidor ou de mod DayZ. Referenciado pelos agentes e skills do plugin.

---

## Estrutura de Arquivos do Servidor DayZ

```
<servidor>/
├── serverDZ.cfg                    ← Configuração principal do servidor
├── BattlEye/                       ← Configs do BattlEye (anti-cheat)
├── Profiles/
│   ├── DayZServer_x64.RPT         ← LOG PRINCIPAL — verificar aqui primeiro
│   └── script.log                  ← Erros de script Enfusion
└── mpmissions/
    └── <missao>.chernarusplus/
        ├── init.c                  ← Inicialização server-side
        ├── cfggameplay.json
        └── db/
            ├── types.xml           ← Economy PRINCIPAL
            ├── events.xml          ← Spawners de eventos
            ├── cfgeventspawns.xml  ← Entidades por evento
            ├── cfgspawnabletypes.xml
            ├── globals.xml
            └── mapgrouppos.xml
```

---

## Convenções XML — types.xml

```xml
<type name="AKM">
    <nominal>3</nominal>        <!-- Quantidade ALVO no mapa -->
    <lifetime>14400</lifetime>  <!-- Segundos antes de desaparecer -->
    <restock>1800</restock>     <!-- Segundos entre restocks -->
    <min>1</min>                <!-- Mínimo para disparar restock -->
    <quantmin>-1</quantmin>
    <quantmax>-1</quantmax>
    <cost>100</cost>
    <flags count_in_map="1" count_in_player="1" count_in_cargo="1"
           count_in_hoarder="1" crafted="0" deloot="0"/>
    <category name="weapons"/>
    <tag name="Military"/>
    <usage name="Military"/>
</type>
```

`count_in_map="0"` = engine não conta instâncias → itens se multiplicam. Use "1" para itens normais.
`deloot="1"` = item só aparece via evento, nunca spawn natural.

### Tags de zona

| Tag | Zona | Loot típico |
|-----|------|-------------|
| `Military` | Bases militares | Armas militares, munição |
| `Police` | Delegacias | Pistolas |
| `Medic` | Hospitais | Kits médicos |
| `Farm` | Fazendas | Ferramentas, comida |
| `Town` | Cidades | Mix civil |
| `Hunting` | Caças | Armas de caça |

---

## Regra CRÍTICA — modded class (Enforce Script)

```c
// CORRETO — sem cláusula extends
modded class PlayerBase { ... }

// ERRADO — causa no-op silencioso (zero erros, zero efeito)
modded class PlayerBase extends PlayerBase { ... }
```

Esta é a armadilha #1. `extends` numa `modded class` silencia todo o override.

Sempre chamar `super.Método()` como primeira linha em overrides, exceto intencionalmente.

Verificação de null SEMPRE antes de acessar objeto:
```c
PlayerBase player = GetGame().GetPlayer();
if (player) { player.GetInventory().CreateInInventory("AKM"); }
```

### Estrutura de diretórios de mod

```
MeuMod/scripts/
├── 3_Game/    ← Classes de item e entidade
├── 4_World/   ← Lógica de mundo, eventos
└── 5_Mission/ ← Server/Client, HUD, UI
    └── GUI/layouts/  ← Arquivos .layout
```

---

## Diagnóstico — Onde Procurar Primeiro

| Sintoma | Arquivo | String |
|---------|---------|--------|
| Servidor não inicia | `DayZServer_x64.RPT` | `ERROR`, `Cannot open file` |
| Script não funciona | `script.log` | `SCRIPT ERR` |
| Loot não spawna | `DayZServer_x64.RPT` | `CentralEconomy` |
| Crash | `DayZServer_x64.RPT` | `Segmentation fault` |
| BattlEye kick | `BattlEye/BEServer.log` | `0x000xxxxx` |

`0x00020005` (BattlEye mais comum) = filePatching mismatch → `allowFilePatching = 1;` em `serverDZ.cfg`

---

## Convenções de Evento (events.xml)

Cadeia de arquivos obrigatória para evento funcionar:
1. `events.xml` → spawner (nome, quantidade, lifetime)
2. `cfgeventspawns.xml` → entidades do evento
3. `mapgrouppos.xml` → posições (se `position="fixed"`)

Um XML mal-formado em qualquer arquivo derruba toda a Central Economy silenciosamente.

---

## Validação de XML — Regras

1. Todo `<tag>` aberto tem fechamento correspondente
2. Encoding UTF-8 sem BOM
3. Caracteres especiais escapados (`&amp;`, `&lt;`)
4. Um único erro de sintaxe quebra o arquivo inteiro

---

## Gotchas confirmados

Confirmados contra vanilla e produção, não suposição.

### `EnterScriptedMenu(id)` retorna NULL silenciosamente sem dispatch
`GetGame().GetUIManager().EnterScriptedMenu(int id, ...)` não resolve `id` pra classe
sozinho — não existe registro tipo `CfgUIRootMenus`. A cadeia real é: engine chama
`CGame.CreateScriptedMenu(id)` → `DayZGame` delega pra `mission.CreateScriptedMenu(id)` →
`MissionBase.CreateScriptedMenu` é um `switch(id)` hard-coded só com os ~46 `MENU_*` da
vanilla. Se o ID customizado do mod não estiver nesse switch, cai no vazio: `menu` fica
NULL, `EnterScriptedMenu` retorna NULL **sem crash, sem log** — o menu simplesmente nunca
abre. **Causa raiz confirmada da maioria dos bugs "menu não aparece".**

Fix: `modded class MissionGameplay { override UIScriptedMenu CreateScriptedMenu(int id) {
UIScriptedMenu menu = super.CreateScriptedMenu(id); if (!menu && id == MY_ID) menu = new
MyMenu(); return menu; } }` — sempre chamar `super` primeiro (múltiplos mods empilham esse
override na mesma classe).

Alternativa que evita a classe inteira de bug: `GetGame().GetUIManager().ShowScriptedMenu(new
MyMenu(), null)` — recebe instância já construída, sem ID nem dispatch. Trade-off: não ganha
o ESC/back automático da vanilla, precisa pollar `UAUIBack` e chamar `HideScriptedMenu` na mão.

### Spawn de veículo completo via script (não carcaça vazia)
`GetGame().CreateObjectEx(class, pos, ECE_PLACE_ON_SURFACE)` spawna o veículo **sem
rodas/portas/capô/porta-malas**. As entradas de `CfgVehicles <class> attachments[]` (ex.:
`NivaWheel_1_1`, `NivaHood`) são **nomes de slot**, não classnames de item spawnável —
alimentar isso em `CreateAttachment()` faz no-op silencioso. Padrão certo (é como o próprio
engine faz, `PluginDeveloper.SpawnEntityInPlayerInventory`): spawnar bare com
`CreateObjectEx`, depois chamar `vehicle.OnDebugSpawnEx(DebugSpawnParams.None())` —
método normal de `EntityAI`, não tem guard de `#ifdef DEVELOPER`, roda em servidor dedicado
normal. Efeito colateral: `OnDebugSpawnEx` também joga um repair kit + 2 rodas sobressalentes
no cargo — avisar quem pediu; remover se quiser porta-malas vazio.
Quando já se tem os classnames reais capturados de um veículo vivo, usar
`CreateInInventory(classname)` pra reanexar — não `CreateAttachment` (resolução de slot
ambígua pode deixar a peça sem encaixar).

### `OnStoreLoad`'s `version` é global do engine, não por mod
O parâmetro `int version` de `ItemBase.OnStoreLoad(ctx, version)` é o formato de
persistência **global do engine** (110, 114, 132...), não um contador por mod/classe. Não
existe versionamento nativo por mod nesse build. Se um mod mudar o FORMATO do próprio bloco
salvo entre releases, `version` não muda — saves antigos e o novo reader dessincronizam
silenciosamente. **Fix obrigatório**: mod escreve seu PRÓPRIO int de versão como primeiro
campo do bloco (`static const int MEU_STORE_VERSION = 1;`), gateando cada campo novo com
`if (meuVersion >= N)`.

**Regra crítica de segurança pra dados salvos por mod** (classe de bug "carro sumiu da
garagem"): uma leitura curta/falha dos campos do MOD deve **retornar `true` com defaults
seguros, NUNCA `false`** — a vanilla trata `false` de `OnStoreLoad` como "storage corrompido",
e como itens no inventário compartilham UM stream de save, isso desincroniza os itens
IRMÃOS lidos logo depois. Sempre sanity-clampar um `count` lido antes de um loop de array
(`count < 0 || count > MAX -> bail`) — um count-lixo consome o número errado de leituras do
stream compartilhado. Resetar membros pra default + `array.Clear()` ANTES do loop de leitura.

### Nunca deletar o item principal de uma ação contínua a partir de callback assíncrono
Uma `ActionContinuousBase` rastreia `action_data.m_MainItem` durante a animação END/OUT
client-side depois de `UA_FINISHED`. Se algo deleta esse item de um caminho ASSÍNCRONO
(`RestCallback.OnSuccess`, timer `CallLater`) alguns frames/segundos depois, o item é
arrancado da mão do jogador no meio da animação de fim e o `HumanCommandActionCallback`
nunca recebe um final limpo — **jogador trava no meio da animação**, com a barra de
progresso presa (o sucesso server-side, toast/log, ainda roda — por isso o sintoma é "toast
aparece mas jogador fica preso"). A vanilla NUNCA deleta um item principal consumido de
caminho assíncrono — ou deleta síncrono dentro de `OnFinishProgressServer` (mesmo tick de
`UA_FINISHED`), ou defere via fila: `GetGame().GetCallQueue(CALL_CATEGORY_SYSTEM).Call(
GetGame().ObjectDelete, item);`. Se a lógica exige confirmar algo assíncrono (ex.: REST)
antes de consumir, deferir o delete pra `CALL_CATEGORY_SYSTEM` dentro do callback, não
deletar direto nele.

### `config.cpp` raiz sem `#include` pode ser válido nesse pipeline
Alguns mods têm `config.cpp` raiz sem nenhum `#include` de sub-config, com cada módulo
declarando seu próprio `CfgPatches` independente em pasta separada — só funciona se o
pipeline de build (PBO Manager/Mikero) concatenar por convenção de pasta, não por include
explícito. Não assumir automaticamente que é erro ao reauditar um mod assim — confirmar o
fluxo de build real antes de flaggar.

### 5 gotchas de Enforce Script (caso completo em `docs/restcallback-lifetime.md`)
1. `RestContext`/`RestApi` têm destrutor `private` — nunca declarar como `ref` (o
   compilador tenta gerar chamada de destrutor e falha: "Method '~X' is private").
2. `array<string>` e `array<ref string>` são tipos NÃO relacionados — sem cast implícito,
   precisa de overload explícito pra função aceitar os dois.
3. `map` não tem `.Delete()` — o método real é `.Remove(key)`.
4. `protected` só libera acesso pra classe declarante + subclasses — NUNCA pra outra classe
   "irmã" no mesmo arquivo, mesmo que pareça razoável logicamente.
5. **Nunca criar `RestCallback` inline sem referência forte** — se a resposta demorar, o
   a contagem de referência zera e o callback é liberado antes da resposta chegar, e o engine invoca `OnSuccess`/`OnError`
   em memória já liberada → SIGABRT/heap corruption. Guardar em campo `ref` estático,
   limpar no terminal state (`OnSuccess`/`OnError`/`OnTimeout`) do próprio callback.
