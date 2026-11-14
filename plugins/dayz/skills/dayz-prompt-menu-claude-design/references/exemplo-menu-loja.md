# Exemplo trabalhado: menu de loja com abas

Exemplo genérico de ideia, medidas, lista de peças (com destino no imageset) e montagem. Nomes e tamanhos são
ilustrativos. O estilo do **bloco 1** vem do `SKILL.md` e é colado antes de cada lote. Detalhes de formato marcados
"não verificado" no `SKILL.md` valem aqui também.

## 1. A ideia

Um menu de loja aberto por uma tecla (input registrado), com **3 abas** (Armas, Suprimentos, Roupas), uma **grade 4x3 de
slots** de itens, um painel de detalhe à direita com área de texto, e dois botões: **Comprar** e **Fechar**. Preços,
nomes e quantidades são texto desenhado pelo código.

## 2. Medidas (resolução de referência 1920x1080)

| Elemento | Tamanho | Observação |
|---|---|---|
| Painel inteiro | 1024x512 | tamanho fixo, centralizado (posição em fração 0,5 do pai) |
| Aba | 128x32 | três botões lado a lado, estados n/h/s |
| Slot | 64x64 | interior de 56x56 liso para o ícone |
| Ícone de item | 56x56 | mesmo estilo, vem do bloco 2 |
| Painel de detalhe | 256x256 | área de texto lisa |
| Botão grande | 160x40 | estados n/h/p/d |

Folha 1 (UI): 1024x512 (cada peça já em potência de 2 onde possível; o painel inteiro é uma imagem solta). Folha 2 (ícones): 512x512 (só potências de 2).

## 3. Lista de peças (depois do bloco 1)

### 3.1 Fundos (imagens soltas, peças grandes)

| Arquivo | Tamanho | Descrição |
|---|---|---|
| loja/fundo_painel.png | 1024x512 | painel de aço escuro com bordas enferrujadas e cantos reforçados; faixa superior lisa para o título; grade 4x3 de nichos à esquerda; coluna de detalhe à direita |
| loja/fundo_detalhe.png | 256x256 | painel de aço com área central lisa para texto |

### 3.2 Abas e botões (vão para a folha 1)

| Arquivo | Tamanho | Estados | Descrição | Destino no imageset |
|---|---|---|---|---|
| loja/aba_armas_{n,h,s}.png | 128x32 | n h s | aba de aço com um símbolo de rifle estilizado à esquerda e área lisa à direita | `aba_armas_n/_h/_s` |
| loja/aba_suprimentos_{n,h,s}.png | 128x32 | n h s | mesma aba com símbolo de lata | `aba_suprimentos_n/_h/_s` |
| loja/aba_roupas_{n,h,s}.png | 128x32 | n h s | mesma aba com símbolo de jaqueta | `aba_roupas_n/_h/_s` |
| loja/botao_{n,h,p,d}.png | 160x40 | n h p d | botão de aço com borda khaki; centro liso para o texto | `botao_n/_h/_p/_d` |

### 3.3 Slots e marcas (folha 1)

| Arquivo | Tamanho | Descrição | Destino |
|---|---|---|---|
| loja/slot.png | 64x64 | moldura quadrada de aço com cantos riscados, **interior 56x56 liso** | `slot` |
| loja/slot_selecionado.png | 64x64 | mesma moldura com borda âmbar | `slot_sel` |
| loja/slot_bloqueado.png | 64x64 | mesma moldura escurecida com cadeado grande | `slot_bloq` |
| loja/raridade_comum.png | 64x64 | borda fina cinza para por cima do ícone | `rar_comum` |
| loja/raridade_rara.png | 64x64 | borda fina azul-aço | `rar_rara` |

### 3.4 Ícones de item (bloco 2; 56x56; folha 2)

| Arquivo | Descrição | Destino |
|---|---|---|
| icones/rifle_velho.png | rifle de ferrolho gasto | `ic_rifle_velho` |
| icones/lata_feijao.png | lata amassada com tampa aberta | `ic_lata_feijao` |
| icones/jaqueta_camo.png | jaqueta de camuflagem desbotada | `ic_jaqueta_camo` |

## 4. Como pedir em lotes

1. Cole o **bloco 1**; peça 3.1 (fundos). Confira 1024x512 e o alfa.
2. Peça 3.2 (abas e botões). Conferir pares de estados (mesma silhueta e tamanho).
3. Peça 3.3 (slots). Atenção ao interior liso.
4. Cole o **bloco 2**; peça 3.4 (ícones).
5. Lote fora do estilo: regere só ele, citando uma peça boa como referência.

## 5. Do PNG ao jogo

1. Os PNG aprovados das seções 3.2 e 3.3 vão para uma pasta; rode
   `python montar-folha.py <pasta> folha_ui.png 1024` (script em `references/`). Ele gera a folha (altura em potência de
   2) e imprime as linhas `ImageSetDefClass`.
2. Converta a folha para **PAA**: `ImageToPAA.exe folha_ui.png folha_ui.paa` (ou `png-para-paa.py` em lote). Faça o mesmo
   com a folha de ícones e com os fundos soltos (já pedidos em potência de 2: 1024x512 e 256x256, para o `ImageToPAA`
   não reamostrar e deformar).
   EDDS, se quiser, é passo manual no TexView2 (referência `imagens-formatos-conversao-caminhos.md`, seção 4).
3. Escreva o `.imageset` com `RefSize 1024 512`, `path "MeuMod/Client/gui/imagesets/loja_ui.paa"` e as entradas impressas;
   registre-o em `CfgMods` → `defs` → `imageSets` → `files[]` no `config.cpp`. O prefixo do `path` é o `$PBOPREFIX$` do mod.
4. No `.layout` (CRLF; edite com Write/Python, não com `sed`): root → `fundo_painel` (ImageWidget) → três botões de aba →
   grade de 12 slots → painel de detalhe → dois botões. Cada widget com nome único; botões e abas com `userID`.
   Texto como `TextWidget` com áreas lisas por baixo.
5. No script: criar o layout com `GetGame().GetWorkspace().CreateWidgets(...)`, buscar os widgets em `Init` com
   `FindAnyWidget`, registrar o tratador com `SetHandler`, e implementar `OnClick` (aba e comprar), `OnMouseEnter`/
   `OnMouseLeave` (troca `_n`/`_h` com `LoadImageFile`) e `OnShow`/`OnHide` com o trio de foco do `menus-e-input.md`.
   Selecionar um slot troca `slot` por `slot_sel`; item sem permissão mostra `slot_bloq`.
6. Teste no client em 1080p e em outra resolução; confira nitidez, cor e alinhamento dos nichos com a grade do código.
