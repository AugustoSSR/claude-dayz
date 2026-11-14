# Enforce Script: sintaxe, nomes e expressões

Complementa `dayz-api-corrections` (que já cobre ternário, escopo por função, duas declarações do mesmo método e
chamada em várias linhas). Aqui ficam as demais armadilhas de linguagem.

## Declarações e nomes

- **`enum`** fecha com `}` **sem `;`** e o membro se acessa **qualificado** (`MeuEnum.MEMBRO`). `};` somado a acesso
  nu produz `Can't find variable 'MEMBRO'` no mesmo arquivo, e as duas causas aparecem juntas. Se esse erro apontar para
  um membro de enum declarado no próprio arquivo, suspeite do `;` antes de qualquer outra teoria.
- **Palavras e tipos reservados** não servem de nome de variável nem de parâmetro: `map`, `ref`, `owned`, `local`,
  `out`. Erros enganosos: `Variable name 'map' already used as type name`, `Expected name, not a keyword` e
  `Broken expression (missing ';'?)` na linha da declaração (caso `int local`, sem citar a palavra). `map` é o mais
  reincidente.
- **Helper com nome de classe vanilla** (`Icon`, `Text`...) vira chamada de construtor
  (`Cannot convert 'string' to 'LayoutHolder'`). Use prefixo próprio no helper.
- **Método com o nome de um método nativo de `UIScriptedMenu`/`UIMenuPanel`** (`Refresh`, `CanClose`,
  `CanCloseOnEscape`) colide (`Multiple declaration of function`) ou dá aviso de override sem `override`. Use um
  prefixo próprio no nome (`MeuMod_Refresh`).
- **O nome do parâmetro de um override faz parte do contrato.** `Update(float timeslice)`, não `delta`
  (`Can't find variable 'delta'`). Confira o nome exato no vanilla ao sobrescrever qualquer método `proto`/nativo.
- **Construtor leva `void`** (`void MinhaClasse(...)`); sem isso não compila.
- **Variável local com o mesmo nome de um parâmetro** (`x`, `z`) dá `Incompatible parameter 'x'`: renomeie a local.
- **`protected` só vale para a classe e suas subclasses**, nunca para uma classe irmã no mesmo arquivo. Para outra
  classe ler o dado, exponha um acessor (singleton estático) na classe dona.
- **Parâmetro de função é referência fraca**: `param = new array<...>` no corpo não chega ao chamador.
- O escopo é a função inteira, inclusive sob `#ifdef`. Dois `foreach (ref T item : ...)` ou dois `for (int i...)` em
  blocos irmãos derrubam o boot (`Multiple declaration`), e o erro aparece **um por rodada**: depois de corrigir o
  `foreach`, o `for (int i` do mesmo arquivo falha na rodada seguinte. Grepe os dois padrões de uma vez.

## Strings

- **Barra invertida**: a literal `"\\"` não é aceita (`CParser: quoted string not closed`), e o erro costuma apontar
  para **outro arquivo** (o parser continua consumindo código). Para uma barra: `int c = 92; string b = c.AsciiToString();`.
  Nunca termine uma literal em `\` antes da aspa de fechamento. Para montar JSON, não escreva helper
  `Replace("\\", ...)`: garanta que o valor não contém aspas nem barra (ID numérico, UUID, texto fixo).
- **`Replace` e `ToLower`/`ToUpper` mutam a string no lugar** e devolvem `int`/`void`: `a = b.ToLower();` não
  compila (`Incompatible parameter`). Atribua primeiro, mude depois, em duas linhas.
- **`Trim()` devolve uma cópia nova**; `TrimInPlace()` é que muta. Chamar `Trim();` como instrução solta não faz nada.
- **`Split` descarta campo vazio** e desloca os índices. Em protocolo próprio, mande um placeholder (`-`) nos campos
  do meio que podem ser vazios.
- String não se compara com `<`/`>`.

## Expressões e números

- Concatenação longa com vários `float.ToString()` dá `Formula too complex`: monte em partes, com variáveis
  intermediárias.
- `%` direto no `return` falha: calcule numa variável antes.
- `&&` com 3 ou mais termos que repetem o mesmo identificador logo após a checagem de `null` dele
  (`a && a.x && b.y && b.t == a.t`) quebrou o parser (`Expected ')', not 'x'`). Aninhe em `if` separados. A mesma
  forma com `||` funcionou.
- `int` é 32 bits (~2,1 bilhões). Epoch em milissegundos (13 dígitos) estoura: use segundos ou string. Um campo `int`
  onde o JSON trazia `float` derrubou o boot.
- `Math.Round`, `Math.Min`, `Math.Max` devolvem `float`: converta para `int` antes de `ToString()` quando o texto vira
  nome de widget ou percentual. `GetQuantityMax()` é `int`.
- `vector`: `int x = pos[0];` não compila (`Incompatible parameter` e `Index out of range`). Passe por
  `float fx = pos[0]; int x = fx;`.
- `typename t = s.ToType();` na declaração falha: declare `typename t;` e atribua na linha seguinte.
- Função muito grande: `Too many instructions per function`. Código gerado deve ser dividido em funções de poucas
  centenas de linhas (`Fill0..FillN`).
- `GetRestApi()` devolve `null` se ninguém chamou `CreateRestApi()` antes: faça o fallback.
- `DayZGame.m_IsPreviewSpawn` só existe sob `#ifdef DEVELOPER`; não compila no jogo normal.
