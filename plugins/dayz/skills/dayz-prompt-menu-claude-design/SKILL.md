---
name: dayz-prompt-menu-claude-design
description: 'Use quando o usuário pedir um menu, tela, HUD ou arte de UI para um mod DayZ: escreve o prompt de arte (estilo fixo, regras técnicas, lista de peças com nome, tamanho, estados e destino no imageset) para colar no Claude Design, e guia a conferência dos PNG, a conversão para textura, o imageset e a montagem do .layout e do script.'
license: PolyForm-Noncommercial-1.0.0
---

# DayZ: do menu ao prompt do Claude Design

Fluxo para criar a **arte** de um menu de mod DayZ sem que cada peça saia num estilo e num tamanho. A ideia vira uma lista
exata de peças, a lista vira um prompt, o usuário cola o prompt no Claude Design (claude.ai) em lotes, os PNG voltam,
são conferidos, viram textura, entram num imageset e o `.layout` os usa. Esta skill cobre o prompt e a conferência; o
código e o diagnóstico visual ficam com `dayz-gotchas` (`menus-e-input`, `layout-widgets`, `layout-textura-cor-fonte`) e
`dayz-layout-diagnosis`.

**Honestidade sobre o engine:** os detalhes de imagem vêm do que fizemos e medimos em mods próprios. O que não foi
conferido está marcado **"não verificado"**: confira num `.imageset` e num layout vanilla extraídos do jogo.

## Quando usar

- "Quero um menu/tela/HUD de X", "faz a arte da aba Y", "gera os ícones da loja".
- Antes de escrever qualquer `.layout` ou script de menu que precise de imagem nova.
- **Não use** para modelos 3D, texturas de item/roupa, nem para o código do menu.

## Regra de ouro

**O estilo é do projeto do usuário, não da skill.** O exemplo abaixo (sobrevivência militar desgastada) é só um modelo. Na
primeira vez, fixe o estilo com o usuário e guarde o **bloco 1** num arquivo do projeto. **Todo prompt seguinte reutiliza
o mesmo bloco 1, palavra por palavra.**

## Passo a passo

1. **Levantar a ideia e as telas.** O que o menu faz, quais abas, quantos slots/linhas, quais botões e estados, que texto
   aparece (o jogo desenha texto com fonte; a arte **não** tem texto), se há ícones de item. Liste as telas.
2. **Medir a partir do layout.** Defina o tamanho do painel, de cada botão, aba e slot **em pixels na resolução de
   referência** (ver "Resolução e escala"). A arte tem o tamanho exato do que o layout posiciona. Prefira painéis de
   tamanho fixo; para painel que muda de tamanho, veja "Esticar painéis".
3. **Escrever o prompt em blocos** (template abaixo): bloco 1 (estilo + regras), bloco 2 (ícones, se houver) e a lista de
   peças em tabelas, **com o destino de cada peça no imageset**. Salve num arquivo do projeto.
4. **Orientar a geração em lotes no Claude Design.** Cole o bloco 1; peça **uma seção por vez** (painéis, botões, slots,
   ícones), sempre "o nome exato do arquivo, PNG com transparência, no tamanho exato". Lote fora do estilo: regere só ele,
   citando uma peça boa do lote anterior.
5. **Conferir os PNG** (checklist abaixo). Rejeite e peça de novo o que falhar.
6. **Montar a folha e converter para textura.** Junte as peças pequenas numa folha de potência de 2 (script em
   `references/montar-folha.py`, que também imprime as entradas do imageset) e converta para o formato de textura do jogo
   para **PAA** com o `ImageToPAA` (`references/png-para-paa.py`); EDDS só à mão (ver "Imagem: formatos, conversão e caminhos").
7. **Registrar o imageset e montar o `.layout`.** As peças são referenciadas por nome no layout; o script do menu cria o
   layout e trata os eventos (ver "Montar o menu").
8. **Testar no client.** O servidor não compila nem mostra UI (`dayz-gotchas`). Teste em pelo menos duas resoluções.

## Imagem: formatos, conversão e caminhos (resumo; detalhe em `references/imagens-formatos-conversao-caminhos.md`)

**Formatos.** O DayZ usa **PAA** e **EDDS**.
- **PAA** é o padrão do projeto: `ImageToPAA.exe` (DayZ Tools) converte PNG/TGA por linha de comando, então dá para
  automatizar (confirmado em todos os nossos mods de UI).
- **EDDS** (DDS próprio da Bohemia, o que o vanilla usa) é o formato que o mantenedor considera o melhor para arte final,
  mas **só se cria à mão**, no TexView2. Use para logo e fundos grandes quando se decidir fazer o passo manual.
- O `ImageToPAA` **sempre grava PAA**, mesmo que a saída se chame `.edds`: nunca dê essa extensão à saída dele.
- A skill recomenda: **PAA por padrão; EDDS só como etapa manual declarada.**

**Conversão automática PNG/TGA → PAA.**
```
ImageToPAA.exe entrada.png saida.paa        (lados em potência de 2; confira que a saída existe)
python references/png-para-paa.py art/png build/paa     (em lote, com IMAGETOPAA definido)
```
O build **`-packonly` não converte nada** (e o build completo falhou no nosso setup): o `.paa` tem de existir pronto
antes de empacotar. Ordem: converter → gerar layouts/imagesets → empacotar → assinar.

**Caminho de volta.** `.paa` → PNG: TexView2 (File → Save As). `.edds` → PNG: `edds2png` (terceiro, baixe você mesmo)
ou TexView2.

**Criação do EDDS é MANUAL** (TexView2 → Save As → EDDS, DXT5 com alfa, mipmaps, salvar dentro da pasta do mod no
caminho citado pelo imageset). Não há script. Passo a passo e ressalvas na referência.

**Folhas e imagesets.** Junte peças pequenas numa folha de potência de 2 (`references/montar-folha.py`, que imprime as
entradas do `.imageset`) com 1 a 2 px de margem. O imageset lista a textura e, por peça, `Name`, `Pos`, `Size`.

**Caminhos que usamos** (cada um com exemplo de layout, imageset e script na referência):

| Padrão | No `.layout` | No script |
|---|---|---|
| Solta, **prefixo completo** do PBO (padrão) | `image0 "MeuMod/Client/gui/data/kit/x.paa"` | `w.LoadImageFile(0, ICONS + "x.paa"); w.SetImage(0);` |
| Imageset `.paa` + `set:` | `image0 "set:meu_menu image:btn_n"` | idem (não verificado em script) |
| Imageset vanilla / `.edds` com GUID | `image0 "set:dayz_gui image:Close"`; `imageTexture "{GUID}..."` | - |
| Solta **relativa** (sem prefixo) | `image0 "gui/data/x.paa"` | **não verificado; evite** |

O imageset **precisa** ser listado em `CfgMods` → `defs` → `imageSets` → `files[]` no `config.cpp`. O prefixo do caminho
tem de ser **igual ao `$PBOPREFIX$`** do módulo que empacota a textura. Quando o prefixo, o `Name`, o registro ou a
extensão estão errados, a imagem **não carrega e a tela fica sem a peça, sem erro de compile**: procure no
`script_*.log` do **client**.

**Potência de 2.** Folhas e peças em lados 16, 32, 64, 128, 256, 512, 1024, 2048. O `ImageToPAA` exige; reamostrar uma
peça fora de proporção a deforma.

## Estados de botão

Duas estratégias; escolha **uma** por menu:

1. **Uma imagem por estado** (`_n` normal, `_h` hover, `_p` pressionado, `_d` desativado, `_s` selecionado), mesma
   silhueta e mesmo tamanho. O script troca a imagem em `OnMouseEnter`/`OnMouseLeave`/`OnClick` (*não verificado*: a
   assinatura exata dos eventos; confira em `ScriptedWidgetEventHandler` nos scripts vanilla). Mais fiel à arte, mais
   peças.
2. **Uma imagem + cor.** Peça a arte em **máscara branca com o alfa da forma** e deixe o código mudar `SetColor` por
   estado. Menos peças, estado exato e sem a distorção de gamma (ver `layout-textura-cor-fonte.md`: cor assada na
   textura sai clareada; a cor do widget, não). Use para chrome plano; arte com cor e textura usa a estratégia 1.

## Texto, fontes, resolução e escala

- **Sem texto na arte.** O jogo desenha o texto com a fonte; a fonte bitmap do jogo só existe em alguns tamanhos nativos
  (`layout-textura-cor-fonte.md`). Reserve **áreas lisas** para o texto.
- **Resolução e escala.** O jogador usa resoluções e escala de UI diferentes. Escolha **uma resolução de referência**
  (por exemplo 1920x1080), meça nela, e use no layout **frações do pai** (`hexactpos 0`) onde o elemento deve acompanhar a
  tela e **pixel exato** (`hexactpos 1`) onde o tamanho deve ser o da arte. Coerência das flags: `layout-widgets.md`. Peça
  a arte no **tamanho da maior resolução que você vai suportar** se o elemento escala com a tela (arte reduzida fica
  nítida; ampliada, borrada). Como a UI reage ao slider de escala do jogo: *não verificado*; teste.
- **Esticar painéis.** Painel de tamanho fixo é o mais seguro. Se o painel precisa mudar de tamanho: (a) monte-o com peças
  separadas (cantos fixos, bordas e miolo esticados como widgets distintos), ou (b) use uma textura que tolere esticar.
  Suporte nativo a 9-slice num `ImageWidget`: *não verificado*; não assuma.

## Montar o menu

- **`.layout`:** montado no Workbench (editor de layout) ou à mão (CRLF!). Hierarquia: root → painel (`ImageWidget` com o
  fundo) → abas, slots, botões. Cada widget interativo tem **nome único** e `userID` (com ID maiúsculo) quando o clique
  precisa distingui-lo. Veja `dayz-layout-diagnosis` e `dayz-gotchas`.
- **Script (Enforce):** uma classe `UIScriptedMenu` (menu em tela cheia) ou `ScriptedWidgetEventHandler` (painel/HUD). Cria
  o layout com `GetGame().GetWorkspace().CreateWidgets("MeuMod/gui/layouts/meu_menu.layout")`, guarda as referências com
  `FindAnyWidget` **uma vez** (em `Init`), registra o tratador com `SetHandler(this)` no root e implementa `OnClick`,
  `OnMouseEnter`, `OnMouseLeave`. Foco, cursor e fechamento: `menus-e-input.md`. Teclas: input registrado.
- Texto e números: `TextWidget.SetText(...)` pelo código, nunca na imagem.

## Template do prompt

O texto vai **em inglês** (geradores de imagem seguem melhor). O estilo é genérico; troque **uma vez** e mantenha.

### Bloco 1: estilo fixo + regras técnicas (cole sempre antes)

```
You are generating a complete UI asset kit for a DayZ mod menu (gritty military survival).
STYLE (all assets must match): worn olive-drab and khaki fabric, scratched dark steel, faded stenciled markings WITHOUT
legible text, rust at the edges, dim desaturated palette, subtle film grain, soft cold overhead light from the top.
PALETTE: steel #1d2024 / #2b3036, olive #3a4030, khaki #8a8466, rust #7a3b1c, warning amber #c98a1b, panel dark #14171a.
TECHNICAL RULES:
- PNG with transparent background (RGBA), EXACT pixel size given for each file, no padding outside the shape.
  Shadows and glows must stay INSIDE the stated size (never extend the canvas).
- NO text, NO letters, NO numbers anywhere (the game draws text on top). Stencil-like marks must be abstract shapes.
- Crisp edges, readable at 100% size, no blur, no photo realism, no watermark.
- Button sets come in states with the SAME size and the SAME silhouette: _n (normal), _h (hover: lighter edge, slight
  glow), _p (pressed: darker, inset 1px), _s (selected: amber edge), _d (disabled: desaturated, dark). Only generate
  the states listed.
- Panel backgrounds are FIXED SIZE (not stretchable) unless an item says "stretchable": then the center must be a plain
  tileable texture and the border must be repeatable.
- Slot frames: a dark recessed square where an inventory icon sits, centered. The frame MUST leave the inner area
  (stated per file) plain and dark.
- Leave PLAIN, uncluttered areas wherever the item says "text area".
- Return every file with the EXACT file name listed.
```

### Bloco 2: ícones de item (cole depois do bloco 1, só se houver ícones)

```
Now generate ITEM ICONS for the same mod in the SAME art style, as inventory icons:
- PNG RGBA, EXACTLY the pixel size stated per file, transparent background.
- One clear object per icon, centered, filling about 80% of the square, strong silhouette.
- Slightly top-down 3/4 view, 1 px dark outline, worn and realistic proportions.
- NO text, letters or numbers.
- Items of the same family must look like a SET (same object; only color or condition changes).
- Return each file with the EXACT file name listed.
```

### Lista de peças

| Arquivo | Tamanho | Estados | Descrição | Destino no imageset |
|---|---|---|---|---|
| `menu/fundo.png` | LxA | - | painel de tamanho fixo; onde ficam os slots e as áreas de texto | imagem solta ou peça `fundo` |
| `menu/aba_<nome>_{n,h,s}.png` | 32x32 | n h s | botão com o símbolo X | `aba_<nome>_n/_h/_s` |
| `menu/slot.png` | 48x48 | - | moldura de slot, interior 40x40 liso | `slot` |

Regras: um nome de arquivo por linha; `{n,h,p,s,d}` = um arquivo por estado; todos os estados com o **mesmo tamanho e a
mesma silhueta**; descreva o que o símbolo **é**, nunca texto; agrupe em lotes (um tipo de peça por vez). Exemplo completo:
`references/exemplo-menu-loja.md`.

## Checklist de conferência (para cada PNG)

- [ ] Nome **exato** do arquivo da lista.
- [ ] Tamanho em pixels **exato** (script abaixo).
- [ ] Fundo **transparente** de verdade (canal alfa).
- [ ] **Nada de texto, letra ou número** na imagem.
- [ ] Estados do mesmo botão com a **mesma silhueta e o mesmo tamanho**.
- [ ] Sombra e brilho **dentro** do tamanho.
- [ ] Moldura de slot com a área central **lisa** no tamanho pedido.
- [ ] Áreas de texto **lisas**, sem ornamento que atrapalhe a leitura.
- [ ] Estilo igual ao do lote anterior.
- [ ] Depois de montar a folha: lados em potência de 2 e peças sem sobreposição.
- [ ] No jogo: nitidez em 1080p e em outra resolução; cor igual à esperada (atenção ao gamma de textura).

```python
import sys, pathlib
from PIL import Image
for p in sorted(pathlib.Path(sys.argv[1]).rglob("*.png")):
    im = Image.open(p)
    print(p.name, im.size, im.mode, "alfa" if im.mode == "RGBA" else "SEM ALFA")
```

## Erros comuns

- **Texto dentro da imagem.** O gerador escreve o nome do botão. O jogo desenha o texto: a arte com letra duplica e não
  traduz. Rejeite.
- **Tamanho diferente entre estados.** O botão "pula" ao passar o mouse.
- **Sombra fora do tamanho.** O canvas cresce e a peça se desloca.
- **Fundo não transparente.** Vira retângulo na tela.
- **Cor assada na textura de chrome.** Sai clareada no jogo; use máscara branca + `SetColor` (`layout-textura-cor-fonte.md`).
- **Gerar tudo de uma vez.** O estilo se perde; um tipo de peça por lote, sempre com o bloco 1.
- **Estilo reescrito a cada prompt.** Use sempre o mesmo bloco 1.
- **Inventar medida.** Arte que não bate com o layout deixa o menu torto; meça antes.
- **Folha sem margem entre peças**, ou fora de potência de 2: vizinho sangrando ou textura distorcida.
- **`hexactpos`/`hexactsize` incoerentes** com a unidade do valor: tudo empilha no canto (`layout-widgets.md`).
- **Esperar que o servidor valide a UI.** Só o client prova.
