# RPC, rede e sincronização

## IDs de RPC

- IDs de RPC de mod são `const int` escolhidos à mão, **sem registro e sem validação em compilação**. Duas colisões
  reais deixaram dados "nunca chegando", sem crash e sem log: a cadeia de `PlayerBase.OnRPC` roda todos os `modded`
  em sequência, e o primeiro `ctx.Read` consome o cursor do `ParamsReadContext`; o outro módulo falha em silêncio
  (`if (!ctx.Read(...)) return;`).
- Convenção que evitou reincidência: um bloco numérico próprio por módulo (por exemplo `-9NNNXXXX`, com NNN único por módulo).
  **Antes de cunhar um ID novo**, procure duplicatas no workspace inteiro:
  `grep -rhoE "\-9[0-9]{7}" <workspace> --include=*.c | sort | uniq -d` (ajuste o padrão ao seu esquema de IDs) e descarte as
  ocorrências que são só comentário.
- RPC servidor→client sem enum próprio: `RPCSingleParam` aceita `int` puro. Não dependa de gerenciador de RPC de
  framework de terceiros (e não use `modded enum` do engine, que não é suportado).

## O que enviar

- **Não serialize `Object`/`EntityAI`/`Man`**: chega `null` no client, sem erro (a ação nunca aparece). Mande um
  snapshot serializável (posição, classname, índice) e case no client por posição com tolerância (~0,5 m).
- **Payload curto.** Um `Param1<string>` de ~2 KB chegou como `String CORRUPTED` no `ctx.Read`; 780 bytes passou. O
  limite prático é ~1 KB. Mande `Param1<array<string>>` com um registro curto por elemento. Vale para extrato,
  grupo, histórico, catálogo: qualquer coisa que cresce com o uso.
- Campo do meio que pode ser vazio: placeholder (`-`), porque `Split` descarta vazios e desloca os índices.
- Estado de pedido (aguardando resposta, tipo de janela aberta, instância) deve zerar no fim da ação e no fim da
  missão. Um `static ref` de menu **sobrevive à troca de missão** (a VM do client não reinicia ao reconectar): limpe em
  `OnMissionFinish`, senão uma referência velha faz o atalho abrir a janela errada ou nenhuma.

## Quando enviar

- **Sincronize por jogador, no momento da conexão**, nunca só no boot. No boot não há jogador: o RPC vai para "0
  players" e quem entra depois nunca recebe. O hook de conexão que existe é
  `override void InvokeOnConnect(PlayerBase player, PlayerIdentity identity)` em `modded MissionServer` (o player vem
  primeiro). `PlayerConnected` não existe neste build.
- Mantenha também o broadcast para recarga de configuração com jogadores já conectados.
- Dado **por entidade** escrito no servidor e lido no client (índice de garagem, de armário) precisa de
  `RegisterNetSyncVariableInt` + `SetSynchDirty`. Sem isso o client lê o valor inicial (por exemplo `-1`) para sempre.

## Diagnóstico

- "Funciona no servidor, nada no client" → suspeite de `ActionCondition` com estado só do servidor, RPC que nunca chega
  (colisão de ID, payload grande), `userID` do layout, `FindAnyWidget` nulo. Leia o `script.log` **do client**; o erro
  não aparece no do servidor.
- Chat: os canais (`CCSystem`, `CCDirect`, `CCAdmin`...) são flags nativas do engine, não um enum de script. Um canal
  novo é descartado (`Chat: Unknown channel`). Simule por audiência (RPC para quem deve receber) mais prefixo e cor.
