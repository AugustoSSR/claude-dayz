# Central Economy e persistência

## A CE persiste o mundo entre reinícios

- A Central Economy **persiste objetos de mundo** entre reinícios do servidor. Um módulo que cria objetos em
  **coordenadas fixas** (queda de veículo, evento) acumula uma cópia a cada boot de teste: depois de dezenas de
  reinícios num dia, o mesmo ponto tinha 2, 3, 4 veículos empilhados. Parece bug de spawn duplicado e não é.
- O armazenamento fica **dentro da pasta da missão**: `<servidor>/mpmissions/<missão>/storage_1/` (`players.db`,
  `spawnpoints.bin`, dados dos objetos), **não** em `profiles/`.
- **Diagnóstico antes de caçar bug de código**:
  1. O `.RPT` do boot atual tem a mensagem de spawn do seu módulo **uma vez por local**? Se sim, o código está certo e
     o excesso é resíduo de boots anteriores.
  2. A data de `storage_1` é mais antiga que o boot atual? Confirma acúmulo entre sessões.
- **Correção**: servidor parado, apague `storage_1` inteiro, suba de novo. É seguro **só em ambiente de teste**;
  em produção isso apaga o mundo e os jogadores.
- Proteção permanente no código do evento: varrer a posição por objeto do mesmo tipo antes de criar e atrasar a
  limpeza (ver `entidades-e-inventario.md`).

## Missão por stack de mods

- `storage_1` salvo com um conjunto de mods e carregado com outro faz a CE **descartar itens com variáveis de
  script** e regravar o mundo (centenas de exceções de `OnStoreLoad` no boot). **Use uma missão separada por stack**
  (cópia da missão vanilla com `storage_1` próprio) e nunca suba um stack novo sobre o `storage_1` de outro.
- A versão do formato do seu mod vai como primeiro campo do bloco de `OnStoreSave` (ver `json-e-config.md`).

## Itens e tipos

- Item novo entra em `types.xml`; o nome tem de existir no config do mod (nome inventado compila e some do spawn).
- Dinheiro físico é contado no inventário, não em saldo de banco. Uma nota que se divide como pilha precisa de
  `varQuantityInit/Min/Max` e `canBeSplit`.
- Mudar `types.xml` só vale depois de um restart e de 1 a 2 ciclos de restock completos; não conclua antes.
- Depois de atualizar o servidor pela Steam, arquivos de missão antigos podem divergir do vanilla novo: compare com a
  missão vanilla atual.

## Limites do servidor

- Com ~33 mods ou mais, o servidor pode crashar no boot com access violation em `CDPCreateServer`, independente do
  conteúdo de qualquer mod. Correção no `serverDZ.cfg`: `steamProtocolMaxDataSize = 4096;`.
- `verifySignatures = 2` rejeita um PBO sem a `.bikey` correspondente em `keys/`. Kick do BattlEye `0x00020005`:
  confira `allowFilePatching = 1;` antes de aprofundar.
