# Camadas de script e ordem de compilação

Camadas, da primeira para a última a compilar: `1_Core`, `2_GameLib`, `3_Game`, `4_World`, `5_Mission`. Uma camada
enxerga as anteriores, nunca as posteriores.

## Entre mods, na mesma camada: inseguro

Uma correção histórica ficou registrada porque a conclusão inicial estava errada. O que se confirmou:

1. **Mesma camada entre mods diferentes é insegura, mesmo com `requiredAddons`.** `4_World` de A usando `4_World` de B
   e `3_Game` de A usando `3_Game` de B quebraram com `Can't find variable '...'` / `Unknown type '...'`, apesar de B
   estar no `requiredAddons` de A. `requiredAddons` garante que B é carregado, não a ordem de compilação **dentro da
   mesma camada**.
2. **Camada posterior chamando camada anterior de outro mod é segura**: `4_World` de A usando `3_Game` de B funciona,
   porque `3_Game` compila antes de `4_World` independentemente da ordem dos mods.
3. A regra vale também **dentro de um único mod**, e é simétrica: uma classe de `3_Game` não pode chamar uma de
   `4_World`, nem `4_World` uma de `5_Mission`.

Consequências práticas:

- Utilitário compartilhado entre mods → coloque numa camada **anterior** à de quem o usa (por exemplo,
  `3_Game`) e chame da camada posterior.
- Se a lógica precisa de API só de `4_World` (por exemplo, `PlayerBase`), não dá para descê-la a `3_Game`. Receba `Man`
  e faça o cast em `4_World`; se não for possível mover, **duplique localmente** em cada mod em vez de depender de
  outro.
- O mesmo vale para `modded class`: ela precisa estar na camada da classe original (ver `enforce-tipos-e-colecoes.md`).

## Guardas de compilação (`#ifdef SERVER`)

- Uma classe inteira sob `#ifdef SERVER` não existe no client. **Todo chamador dela precisa do mesmo guarda** (arquivo
  inteiro ou, no mínimo, o trecho que a usa). Um gerenciador sem guarda chamando um helper de webhook guardado
  compilou no servidor e quebrou no client com `Can't find variable '...'`, e o servidor local nunca acusou. Varra:
  cruze toda classe guardada com os arquivos que a chamam.
- O servidor dedicado não compila menus e UI do jeito que o client compila: erro de `UIScriptedMenu` só aparece no
  client (ver `servidor-local-de-teste.md`).

## Config e carga

- `requiredAddons` com o nome exato do `CfgPatches` do addon de que depende.
- Módulo precisa do bloco `class defs` e de `CfgMods` no `config.cpp` (ver `json-e-config.md`).
- Dependência opcional: `modded class` + `requiredAddons` + fallback quando o terceiro está ausente. Estado do terceiro
  que vive só no servidor não existe no client: o servidor precisa enviá-lo.
- Terceiro sem `CfgMods` nunca tem os scripts compilados: reporte como bloqueador, não edite o terceiro.
- Mod de comportamento pronto: use a configuração dele antes de escrever um mod novo.

## Atualizações do jogo

- Atualizar o servidor dedicado (`steam://validate/223350`) pode mudar a API de script. Exemplos vistos na 1.30:
  `CombinationLock.UnlockServer` virou `UnlockOnServer(player, parent, isInsideLock)`; as funções de verificação de
  posse de DLC de mundo sumiram em favor do serviço de DLC de conteúdo. Erro novo sem mudança de código = confira a
  versão do servidor e do client.
- Os scripts vanilla decompilados ajudam como pista e podem estar **desalinhados do build real** (alguns tipos que
  aparecem neles não existem ou não funcionam no servidor). O compilador do servidor é a verdade.
