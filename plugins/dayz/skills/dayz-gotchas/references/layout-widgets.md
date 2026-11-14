# `.layout` e widgets

Cada item abaixo já gerou um "o menu não funciona" real. Para investigar um bug visual com método, use a skill
`dayz-layout-diagnosis`.

## Propriedades que falham em silêncio

- **`userID`** (com `ID` maiúsculo). `userid` carrega sem erro, o clique até dispara `OnClick`, mas `GetUserID()`
  devolve `0` em todo botão e todo `if (userId == X)` falha. Quando "o clique dispara e nada acontece", o primeiro
  grep é `userid\b`. Prefira `userID` + `override bool OnClick(Widget w, int x, int y, int button)`; um
  `onClick "Metodo();"` inline falhou em silêncio.
- **Keyword errada em widget** (`colums` no lugar de `cols`, por exemplo) derruba o **client** com
  `Access violation ... Illegal write at 0x10` ao criar o menu; o servidor local nunca vê.
- **`hexactpos`/`vexactpos`/`hexactsize`/`vexactsize` têm de bater com o valor**: fração de 0 a 1 do pai exige `0`;
  pixel exige `1`. Fração com `1` é lida como ~0 px e **empilha tudo no canto**. A posição e o tamanho são
  independentes (um widget pode misturar posição relativa com tamanho em pixel). Nunca copie a flag de um widget
  vizinho: pergunte se o valor é fração ou pixel.
- **Nome do widget no código = nome no `.layout`** (e o aninhamento). `FindAnyWidget` devolve `null` sem erro, e o
  menu abre vazio ou sem resposta. Depois de redesenhar um layout, reconcilie o `Init()`. O nome é buscado em toda a
  árvore e pega o primeiro: dois widgets com o mesmo nome (um frame e um texto) escondem o segundo.
- **Hífen no nome do widget** quebra `FindAnyWidget` em silêncio; use camelCase.
- Um `switch` normal em volta de um `ImageWidget` impede `FindAnyWidget` de achar a imagem. Um frame de peça dentro de
  um botão precisa de `ignorepointer 1`, senão rouba o mouse. Filho fora do retângulo do pai não recebe clique.
- Overlay de imagem copiado idêntico de um layout vanilla faz `FindAnyWidget` dos filhos voltar `null`. Para
  restilizar a UI vanilla, repinte em runtime com `modded` do holder correspondente em vez de servir uma cópia do
  layout.
- Busque widgets uma vez, em `Init()`, e guarde a referência. `FindAnyWidget` percorre a árvore: não chame em `Update`.

## Arquivo

- **`.layout` é CRLF.** LF puro (efeito de `sed -i`/`awk` no Git Bash) faz o Workbench travar
  (`access violation`, pilha de `QWindow`). Edite com ferramenta de arquivo ou Python preservando CRLF; se usou
  `sed`, rode `unix2dos` depois. Confira contando `\r` de verdade (`od -An -c f | tr -s ' ' '\n' | grep -c '\\r'`);
  `grep -c $'\r'` dá falso negativo.
- Um `PanelWidgetClass` fino (2 px) com cor opaca de alfa 1 e altura 3 fez o Workbench travar **ao abrir** o arquivo;
  voltar para alfa 0,6 e altura 2 resolveu. As duas mudanças foram feitas juntas, então a causa isolada é
  **desconhecida**. Se precisar de uma linha mais visível, mude uma variável por vez e abra no Workbench a cada passo.

## Estilo e containers

- **`style DayZDefaultPanel`** aplicado a um `GridSpacerWidgetClass` aninhado corrompeu a renderização (texto e linhas
  viram um borrão escuro esticado). Qualquer outra variante do grupo funcionou (`DayZDefaultPanelSides`, `Left`,
  `Right`, `Top`, `Bottom`). A hipótese anterior (mistura de dimensionamento em fração e pixel) estava errada e custou
  várias rodadas: **teste a `style` no seletor do Workbench cedo**.
- `GridSpacerWidget`/`"Size To Content"`/`Update()` em cascata é frágil e não se testa sem o client. Depois de duas
  tentativas cegas no mesmo arquivo, simplifique para posição fixa em fração ou peça teste no client. Antes de mexer,
  rode `git log -- arquivo` e `git show`: o mesmo sintoma já foi "corrigido" e revertido às cegas.
- Layout aprovado é intocável: acrescente função só em espaço vazio, diffe contra a versão aprovada antes de
  regenerar, e confirme em qual **estado** (disputado, vazio, ativo) a referência foi aprovada.
- Observado numa auditoria (não verificado de forma independente): `GridSpacerWidget` com muitos filhos estáticos
  declarados (mais de ~5) pode causar crash nativo sem mensagem; a alternativa que funcionou foi criar os filhos em
  runtime com `CreateWidgets(layout, pai)` dentro de um `ScrollWidget`.

## Listas e texto

- **`TextListboxWidget.AddItem(string text, Class userData, int column, int row = -1)`**: o terceiro argumento é a
  **coluna** (use `0`). `-1` ali dá `Illegal write` no client. `AddItem` só escreve uma coluna: as demais vão por
  `SetItem(row, text, userData, coluna)`.
- A propriedade `colums "Nome1;largura1;Nome2;largura2"` usa **percentuais** que somam 100, não pixels (observado numa
  auditoria; larguras que somavam bem mais de 100 fizeram colunas sumirem).
- Lista com cor igual à do painel de fundo fica "invisível". Defina a cor do texto de forma explícita.
- `EditBoxWidget` e texto: com `"exact text" 1` use também `"exact text size" N`, senão o engine estica a fonte
  bitmap. Veja `layout-textura-cor-fonte.md` para os tamanhos nativos.
- Posicionar pelo texto real: `TextWidget.GetTextSize` + `SetPos` **proporcional ao pai**, e só no eixo x. Evite
  `SetScreenPos`: um widget de aba escondida devolve posição 0 e o texto vai parar no topo da tela.
- Diálogo nativo (`ShowDialog`) não aceita restilização: use um menu próprio e responda em `OnModalResult`.
- Opções de vídeo: o engine devolve texto vazio para qualidade, visibilidade e textura; use os rótulos fixos dos
  arrays vanilla.
