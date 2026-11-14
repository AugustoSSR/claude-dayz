---
name: dayz-layout-diagnosis
description: 'ALWAYS use before diagnosing or fixing a visual bug in a DayZ .layout (misaligned panel, invisible text, wrong size/position, broken border), from a Workbench or in-game screenshot. Covers GridSpacer sizing (exact vs fractional), Size To Content, style corruption gotchas and Workbench-only artifacts.'
license: PolyForm-Noncommercial-1.0.0
---

# Diagnóstico de `.layout` DayZ (GUI/Widgets)

Nasceu de repetidos diagnósticos ERRADOS do mesmo bug visual: cada rodada "corrigia" algo que não era a
causa, porque a leitura do widget tree estava errada. **Regra de ouro: ler a estrutura do arquivo
inteiro (root até folha) ANTES de propor qualquer causa. Nunca reagir só ao screenshot.**

## 1. Antes de tudo: screenshot é do Workbench ou do jogo rodando?

Isso muda completamente o que é "normal" vs "bug":

- **Screenshot do Workbench** (editor de layout, tem painel de propriedades/hierarquia do lado,
  possível grid de fundo cinza claro): é uma renderização ESTÁTICA do `.layout`, sem o código C
  rodando por cima.
  - Widget de texto (`RichTextWidgetClass`) aparecendo VAZIO é **normal** — texto só é setado em
    runtime via `SetText()`. Não é evidência de bug de código.
  - Ícone/imagem aparecendo em branco/vazio é **normal** se o `.c` seta a textura em runtime
    (`LoadImageFile`, `SetImage`) ou se o widget tem `visible 0` por padrão (ativado condicionalmente
    no código).
  - Um contorno fino ao redor de um widget quando ele está selecionado na hierarquia é o **gizmo do
    editor** (indicador de bounds/seleção), não borda renderizada de verdade pela `style`.
  - Uma área vazia/escura que se estende ALÉM do `size` declarado no root do widget pode ser o
    **canvas do Workbench** (área de edição, maior que o widget real) — sempre conferir o `size`
    literal do widget root no arquivo antes de julgar proporção pelo screenshot.
- **Screenshot in-game** (HUD real, jogo rodando): aí sim todo elemento visível é resultado real do
  código + layout juntos. Essa é a única fonte confiável pra confirmar/negar um fix.

**Regra prática**: nunca declarar um bug "corrigido" nem "confirmado" baseado só em screenshot do
Workbench. Pedir/aguardar confirmação in-game antes de fechar o ciclo.

## 2. Ler a árvore inteira antes de julgar posição/tamanho

Sempre ler o `.layout` do arquivo raiz até a folha (via `Read`, arquivo completo, não trecho) antes
de propor causa. Cada nível de `GridSpacerWidgetClass`/`WrapSpacerWidgetClass` redefine como os
filhos são posicionados — julgar um widget isolado sem ver o pai erra a causa quase sempre.

Ao ler, monta mentalmente (ou anota) pra cada nível:
1. `Columns`/`Rows` do grid.
2. Pra cada filho, na ordem declarada: `size X Y`, `hexactsize`/`vexactsize` (0 ou 1).
3. `Padding`/`Margin`.
4. `"Size To Content H"`/`"Size To Content V"` (0 ou 1).

## 3. Sizing model do `GridSpacerWidgetClass`/`WrapSpacerWidgetClass` (exact vs fractional)

Essa é a fonte nº1 de erro de leitura:

- `hexactsize 1` (ou `vexactsize 1`): o valor em `size` correspondente é **pixel exato** (ex:
  `size 24 24` com `hexactsize 1 vexactsize 1` = 24×24 pixels reais, não depende do pai).
- `hexactsize 0` (ou `vexactsize 0`): o valor em `size` correspondente é uma **fração/peso relativo**
  dentro do grid do pai — NÃO é porcentagem de 0-1 necessariamente proporcional de forma intuitiva,
  é peso relativo aos outros irmãos na mesma dimensão. Um filho com `size 1 ...` e `hexactsize 0`
  ocupa "1 parte" da largura disponível — se for o único filho fractional na linha, tende a pegar
  todo o espaço restante depois dos filhos exact-size serem descontados.
- **Não confundir `size 0 0` com "vai desaparecer"**: se for `hexactsize 1 vexactsize 1` (exato),
  `size 0 0` É literalmente zero pixels (correto pra um wrapper de ícone que só ganha tamanho quando
  o código seta uma imagem/ativa visibilidade). Se fosse fractional, `size 0` significaria "peso
  zero" (nunca ocupa espaço, mesmo com conteúdo) — bug real se o elemento devia aparecer.

**Antes de dizer "está espremido à esquerda / não preenche a largura"**: confere se o widget "vazio"
grande é realmente um IRMÃO no mesmo grid (culpado plausível: peso fracional mal distribuído) ou se
é uma camada de canvas fora da árvore do widget (não é bug, é UI do editor — ver seção 1).

## 4. `"Size To Content H"` / `"Size To Content V"`

- `1`: o widget ignora o tamanho recebido do grid pai e se redimensiona pra caber exatamente no
  conteúdo (texto, imagem, filhos). Comum em `RichTextWidgetClass` (`"size to text h/v" 1`) pra
  título/detalhe crescerem com o texto real.
  - **Gotcha já confirmado** (confirmado em campo): se o código só chama `.Update()` (que
    força o widget a recalcular geometria) dentro de um `if` condicional (ex: só quando existe texto
    de detalhe), um widget com `"size to text v" 1` que não passa por esse `Update()` fica preso em
    altura 0 — mesmo com texto setado via `SetText()`. Sempre conferir se `Update()`/equivalente é
    chamado incondicionalmente depois de popular texto num widget com size-to-content ativado.
- `0`: o widget usa o tamanho vindo do grid pai (fixo ou fracional, conforme seção 3) — não se auto-
  ajusta ao conteúdo.

## 5. Gotchas de `style` já confirmados nesta base

- **`style DayZDefaultPanel` (puro) corrompe visualmente quando aplicado a um
  `GridSpacerWidgetClass` usado como container ANINHADO** (não como root direto de um widget
  simples) — produz um borrão/rabisco escuro esticado sobre texto/linhas próximas. Fix confirmado:
  trocar pra `DayZDefaultPanelSides` (ou `...Left`/`...Right`/`...Top`/`...Bottom` — qualquer variante
  do grupo funciona, só a pura corrompe nesse contexto).
- `style Empty`: não desenha nenhuma borda/fundo — se um widget com essa style parece ter borda
  visível no Workbench, é gizmo do editor (seção 1), não a `style` desenhando algo.

## 5b. `userID` é case-sensitive — nunca `userid`

Achado real: a propriedade que `Widget.GetUserID()` lê em
`OnClick(Widget w, ...)` **precisa ser `userID`** (I e D maiúsculos). Escrever `userid` (tudo
minúsculo) **não gera nenhum erro de compile nem de parsing** — o layout carrega normal, o clique
até dispara `OnClick()` — mas `GetUserID()` sempre retorna `0`, fazendo todo `if (userId == X)`
falhar silenciosamente pra TODO botão do menu (não só um).

Sintoma característico: o usuário reporta "nenhum botão funciona, nem o de fechar" — mas um
`Print("OnClick called — userId: " + userId)` de debug já no código mostra `userId: 0` repetido
pra cliques em botões DIFERENTES. Isso é a assinatura desse bug especificamente (clique dispara,
ID sempre 0), diferente de clique não disparar nada (aí sim seria foco/registro de handler).

Antes de suspeitar de `ChangeGameFocus`/foco de input/handler não registrado, `grep -n "userid "` 
(minúsculo) no `.layout` — é mais barato de checar e é o erro mais provável quando `OnClick()` já
comprovadamente dispara.

Pra confirmar se `OnClick()` dispara de verdade: pedir o **script.log do CLIENT** do jogador
(`%LOCALAPPDATA%\DayZ\script_*.log` no Windows — não o do servidor/`profiles_local`) logo depois de
um teste de clique.

## 6. Antes de reportar "corrigido"

1. Build real rodou DEPOIS da última edição do arquivo (confere timestamp do `.c`/`.layout` editado
   vs timestamp do `.pbo` staged/último build — um fix commitado depois do último build não está no
   binário rodando, é a causa mais boba e mais comum de "eu já corrigi mas continua igual").
2. Confirmação veio de screenshot IN-GAME, não do Workbench (seção 1).
3. Se ainda não tiver certeza da causa raiz depois de ler a árvore inteira (seção 2) e checar os
   gotchas conhecidos (seção 5), dizer isso explicitamente em vez de propor um fix chutado
   — "não tenho certeza se X ou Y, preciso que confirme A ou teste B" é aceitável; um fix errado
   apresentado como certeza não é.

## Ver também

- `dayz-api-corrections` (Enforce Script)
- Editar `.layout` via `sed`/`awk` no Bash do Windows remove o CRLF e crasha o Workbench: sempre converter de volta (`unix2dos`) depois.
