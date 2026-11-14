# Entidades, inventário, dano e ciclo de vida

## Apagar e criar

- **`entity.Delete()`** (enfileira na CallQueue) ou `DeleteSafe()`. `GetGame().ObjectDelete()` direto é assíncrono, e
  um respawn no mesmo tick sobrepõe o objeto antigo (sintoma: veículo "duplicado"). Nunca apague de um callback
  assíncrono o item principal de uma ação contínua.
- **Evento em coordenada fixa** (queda de veículo, airdrop): antes de criar, varra a posição
  (`GetObjectsAtPosition3D`) por objeto já existente do mesmo classname. Espere alguns segundos (~8 s) entre detectar
  que o destroço está vazio e deletá-lo; apagar no mesmo tick faz o objeto sumir quando o jogador pega o último item.

## Desconexão

- Para expulsar ou desconectar: `player.ReleaseNetworkControls(); HandleBody(player);
  GetGame().DisconnectPlayer(identity, uid);`. Só `DisconnectPlayer` deixa um corpo fantasma.

## Anexos e inventário

- `AttachmentCount()`/`GetAttachmentFromIndex(i)` (itens **vestidos agora**) e
  `GetAttachmentSlotsCount()`/`GetAttachmentSlotId(i)` (slots **configurados**) são espaços de índice **diferentes**.
  Usar o mesmo `i` nos dois associa cada item a um slot errado, mas plausível (luva no slot de cabeça). Para obter
  pares (slot, item), itere os slots e chame `FindAttachment(slotId)`.
- Para recriar um anexo: `CreateAttachment(classe)` sem slot (o engine resolve pelo config do item), não
  `CreateAttachmentEx`. Os nomes em `attachments[]` do `CfgVehicles` são **slots**, não classnames.
- Ao salvar/restaurar um veículo ou item, guarde também vida e quantidade dos anexos; salvar só o classname devolve
  tudo com vida cheia e munição zerada.
- **`Magazine` não é `ItemBase`**: `ItemBase.Cast(mag)` é `null` e um snapshot que só olha `ItemBase` perde a munição em
  silêncio. Use `IsMagazine()`. Para ressincronizar a munição já replicada em multiplayer, mude entre
  `RemoteObjectDelete(mag)` e `RemoteObjectCreate(mag)`.
- `AddQuantity()` existe só em `ItemBase`; `SetQuantity`, `GetQuantity` e `HasQuantity` existem em `EntityAI`.
  Divisão inteira trunca **antes** de `Math.Ceil`: use `Math.Ceil(a / (float)b)`.

## Dano, visibilidade e estado do jogador

- **Deus-modo**: um `override EEHitBy` que não chama `super`. **Não agro de IA**:
  `override bool CanBeTargetedByAI(EntityAI ai)`. Voo com física real não existe em script (só `SetPosition` por tick).
- `SetInvisible` esconde a entidade; `SetInvisibleRecursive` esconde só os anexos. Para sumir com um jogador, os dois.
- Headshot em jogador é `dmgZone == "Brain"`; `"Head"` é de infectado.
- Vitals: `GetHealth`/`SetHealth(zona, tipo)` (obtenha as zonas por `GetDamageZones`, nunca fixe nomes) e
  `GetStatEnergy`/`GetStatWater`/etc.
- Confirme classes e métodos no vanilla antes de usar: `IsDeleted()` num veículo não existe (o real é `ToDelete()`),
  `GetEntityInHands()` é de `Man`/`PlayerBase` e não de `GameInventory`, e chamar um método com o tipo errado de
  argumento (por exemplo uma checagem de admin que recebe `string` steamId sendo chamada com `PlayerIdentity`) só
  aparece quando o arquivo compila até aquela linha pela primeira vez.

## Hooks de mensagem e ID

- `PlayerBase.MessageImportant(string)` recebe um argumento. Uma chamada com `(player, text)` nunca compilou.
- Um builder de embed/mensagem "fluente" (`new X(); .SetTitle().Send()`) é alucinação comum: confira que a API real
  existe antes de escrever.
