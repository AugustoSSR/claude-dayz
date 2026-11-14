# Enforce Script: tipos, referências, coleções e `modded`

## Referências e objetos nativos

- **Nunca `ref` em tipo nativo do engine** (`EntityAI`, `RestContext`, `RestApi`...): o destrutor nativo é privado e o
  compilador tenta chamá-lo (`Method '~Object' is private`, `Method '~RestApi' is private`). Objeto criado por
  `CreateObject` é gerenciado à mão (`Delete()`), não por contagem de referência. `ref` só em classes de script puras.
- `array<string>` e `array<ref string>` são tipos sem relação. `Param1<ref array<ref X>>` leva `ref` no `array` **e** no
  elemento; sem isso o erro é `Invalid statement ')'`.
- `map` não tem `.Delete()` (é `.Remove(chave)`). `array.Find(x)` e `map.Find(chave, out v)` têm assinaturas
  diferentes: não troque um pelo outro.
- `IsInherited(Classe)` exige que a classe exista em tempo de compilação no build real. Se ela pode não existir
  (mod opcional), compare `obj.ClassName()` com literais.

## Coleções e `foreach`

- **`foreach (k, v : Func())` direto sobre o retorno de uma função quebra em runtime**
  (`NULL pointer ... map.Next`) e já derrubou estado de lógica de jogo. Guarde o retorno numa variável local antes.
- **Enumerar as chaves de um `map<string, ref X>`** (`GetKeyArray`, `foreach` e array paralela) devolveu a mesma chave
  várias vezes em três tentativas diferentes. O diagnóstico ficou **inconclusivo**: trate a enumeração como suspeita e
  valide com log em runtime antes de depender dela. `Find(chave, out valor)` por chave exata foi confiável.

## `modded class`

- A `modded class` só funciona na **mesma camada de script** da classe original: `modded class MissionServer`
  não vai em `4_World`, e `modded class DayZPlayerImplement` exige `worldScriptModule` no `config.cpp`. Colocar na
  camada errada dá `Unknown type '...'` e derruba o módulo inteiro.
- **Classe selada do engine** (`DayZInfected`, provavelmente `DayZAnimal`) falha **no boot do servidor**, não no
  build do PBO: compila limpo localmente e o servidor se recusa a subir. Não use `modded` nelas.
- `modded enum` de enum do engine (por exemplo o de IDs de RPC) não é suportado.
- **`override static` só vale para chamada externa qualificada** (`Classe.Metodo()`). Chamada interna sem qualificador
  dentro do método da classe base **não** é virtual e ignora o override; já causou perda de itens em produção quando
  um mod dependia disso. Para mudar comportamento, faça override de método de **instância**. `super` não funciona em
  método estático.
- Patch de classe de config de outro addon: auto-herança `class X: X { ... }`, nunca `class X { ... }` sem pai (que
  recria a classe e perde a herança).

## Chamadas atrasadas

- **`CallLater` quer um método de instância ligado** (`obj.Metodo`), não método estático (invoca malformado e estoura
  no meio da pilha, parecendo bug em outro lugar) e não o par `(obj, "Nome")` (esse é outra função,
  `CallLaterByName`).
- Ao pedir a mesma ação por tecla e por temporizador, guarde o tick de abertura: fechar um menu pela mesma tecla que o
  abriu só é seguro depois de ~0,3 s, senão o mesmo keypress fecha.
