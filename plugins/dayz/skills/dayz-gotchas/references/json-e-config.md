# JSON, config de mod e `config.cpp`

## Carregar e salvar JSON

- **`JsonLoadFile` com o alvo `null` falha em silêncio** (sem log) e o código "cria default" sobrescreve o arquivo real
  a cada boot. Instancie o objeto (ou chame o `GetConfig()` que o instancia) **antes** de carregar.
- Arquivo ausente: `FileExist` → `JsonSaveFile` do default → carregar de novo. Sem isso o módulo parece desligado.
- Quando precisar saber se o parse deu certo: `JsonSerializer.ReadFromString(out dados, json, out erro)`, não
  `JsonLoadData` dentro de `if` (a função devolve `void`).
- **JSON que antecede um campo novo devolve `false`/`0`**, não o default compilado (`= true`), e não dá erro nem log.
  Vale para campo escalar, objeto novo e array novo na raiz. Todo campo adicionado ganha o próprio bloco:
  `if (Version < N) { campo = default; migrou = true; }` e a versão sobe depois. Se uma feature "não funciona", abra
  o arquivo real no servidor e veja se o campo existe.
- **`vector` dentro de uma classe que vive em `array<ref X>` crasha o parser nativo** (`Access violation ...
  ReadFromString`). Use três `float` e monte com `Vector(x, y, z)`.
- Config copiada para outra instalação: confira o que é por instalação (chaves, listas de admin, caminhos).

## Persistência de entidade (`OnStoreSave`/`OnStoreLoad`)

- O `version` do `OnStoreLoad` é do engine. A versão do **seu** formato vai como primeiro campo do bloco.
- Abra cada bloco customizado com uma guarda (número mágico). Sem ela, um item de outro mod ou de versão antiga é lido
  desalinhado. Uma leitura curta que devolve `true` com defaults é pior que falhar de forma visível.
- Saldo ou limite: truncar em silêncio no máximo é bug. Use uma variante `TryAdd` que devolve `bool` e registre.

## `config.cpp`

- **Sem `config.cpp` o módulo empacota, o build diz sucesso e nada compila** (e arquivos que o script criaria nunca
  aparecem). Sem `CfgMods`/`defs` o addon não compila os próprios scripts: o bloco `class defs` precisa mapear
  `scripts/3_Game`, `4_World` e `5_Mission` para `gameScriptModule`, `worldScriptModule`, `missionScriptModule`.
  Não há erro nenhum, só silêncio: `grep -L "class defs" */config.cpp` acha os módulos sem o bloco.
- Dependência de outro addon: `requiredAddons` com o nome **exato** do `CfgPatches` dele. `Unknown type` em cascata
  num dependente costuma ser CfgPatches errado, ou terceiro sem `CfgMods` (derap de Workshop) cujos scripts nunca
  foram compilados. Isso é bloqueador para reportar, não motivo para editar o terceiro.
- **Capacidade de cargo de container** (filho de `Container_Base`: baú, caixa, barril): vai em
  `class Cargo { itemsCargoSize[] = {largura, altura}; openable = 0; allowOwnedCargoManipulation = 1; };`.
  `itemsCargoSize` solto na classe é **ignorado** nesse tipo (herda o vanilla). Em roupa e mochila é o contrário:
  solto na classe. Largura máxima 10; nunca inverta `{altura, largura}`. A UI de inventário só rola na vertical:
  prefira grids estreitos e altos (10 colunas por 50 linhas).
- **`hiddenSelections` depende da família do item**: roupa e colete usam `"camo"`; adereço de papel ou caixa
  (`Paper`, `AmmoBox`) usa `"zbytek"`. O config vanilla não diz qual o `.p3d` usa: teste os dois ou abra o modelo.
- Classname inventado (zumbi, animal, item) compila e falha em runtime (spawn vazio). Confirme na vanilla.
- Item novo entra em `types.xml`; um nome que não existe no config compila e some do spawn.
