# Imagem no DayZ: formatos, conversão e caminhos

Tudo aqui vem do que fizemos e medimos em mods próprios (kit de UI gerado por script, menus, imagesets de ícones). Cada
item diz se foi **confirmado** (visto funcionando no jogo ou no resultado de uma ferramenta) ou **não verificado**. Os
nomes de mod são genéricos (`MeuMod`); os padrões são os reais.

## 1. Formatos: PAA e EDDS

| | **PAA** | **EDDS** |
|---|---|---|
| O que é | Textura própria do DayZ/Arma, comprimida (DXT) | DDS com compressão em blocos própria da Bohemia (formato não documentado), o que o vanilla usa nos imagesets e nas texturas novas |
| Como se cria | **Automático:** `ImageToPAA.exe` (DayZ Tools) converte PNG/TGA por linha de comando; confirmado | **Manual:** pelo TexView2 (DayZ Tools), um arquivo por vez; não há linha de comando equivalente |
| Ler de volta para PNG | TexView2 (abre e salva como PNG/TGA) | `edds2png` (ferramenta de terceiros, ver seção 3) ou TexView2 |
| Automação de pipeline | Sim: dá para gerar centenas de peças por script | Não: cada peça passa por mão |
| Compatibilidade no jogo | Confirmado em produção: layouts `image0` e `LoadImageFile` com `.paa` funcionam | Confirmado: é o formato dos imagesets vanilla; em mod próprio, usado em layouts e imagesets de exemplo |
| Qualidade | Boa; **a cor assada sai clareada pelo gamma** (ver `layout-textura-cor-fonte.md`) | Considerada pelo mantenedor a melhor para arte final. *Não verificado:* comparação medida de qualidade ou de tamanho entre os dois nesta máquina |
| Risco | Reamostrar para potência de 2 deforma peça fora de proporção | Passo manual esquecido: a arte nova não entra no build |

**O que a skill recomenda.**
1. **Padrão do projeto: PAA.** É o único que se gera de forma reproduzível por script, e é o que o nosso pipeline de UI
   (kit gerado, ícones, estados) usa em todos os mods. A arte de menu muda muito; automatizar vale mais.
2. **EDDS para a arte final polida** (logo, fundo de menu grande), **quando o mantenedor decide fazer à mão**, porque
   é o formato preferido por ele e pelo vanilla. É sempre uma etapa manual extra (seção 4), nunca parte do script.
3. **Nunca nomeie a saída do `ImageToPAA` como `.edds`**: o executável **sempre grava PAA**, qualquer que seja a
   extensão pedida. Um PAA com nome `.edds` é um arquivo enganoso (confirmado).

## 2. Conversão automática PNG/TGA → PAA

### 2.1 Pela linha de comando (o que usamos)

```
"<DayZ Tools>\Bin\ImageToPAA\ImageToPAA.exe" entrada.png saida.paa
```

Regras confirmadas:
- **Só aceita lados em potência de 2** (16, 32, 64, 128... até 2048 na prática). Fora disso: reamostre antes.
- **Sempre grava PAA**, ainda que a saída se chame `.edds`.
- O exit code não é confiável; confira se o arquivo de saída existe.
- Entrada RGBA mantém o canal alfa. Para arte com cor (e não máscara branca), linearize antes: `c' = (c/255)^2.2`
  (`layout-textura-cor-fonte.md`).

Script pronto: `references/png-para-paa.py`.

```
set IMAGETOPAA=C:\...\DayZ Tools\Bin\ImageToPAA\ImageToPAA.exe
python png-para-paa.py art\png build\paa
```

Ele percorre a pasta, reamostra para a potência de 2 mais próxima (com aviso: a peça de UI já deveria nascer assim),
chama o `ImageToPAA` e confere que o `.paa` existe. Nos nossos mods, o gerador de UI faz o mesmo com **cache por conteúdo**
(hash do PNG): peça que não mudou não reconverte, e só entram no PBO os `.paa` realmente usados.

### 2.2 Pelo build (AddonBuilder)

- Em **build completo** (com binarização) o AddonBuilder converte as texturas de PNG/TGA para PAA durante o empacotamento
  (há uma tarefa de binarização de cabeçalho de textura no log dele). *Não verificado nesta máquina*, porque **o build
  completo falhou em todos os módulos** no nosso setup.
- Em **`-packonly`** (o único modo que funcionou) o AddonBuilder **só empacota**: não converte nada. O arquivo que está
  na pasta do módulo vai idêntico para o PBO. Por isso **o `.paa` tem de existir pronto antes do build**; um PNG
  referenciado no layout não carrega no jogo (*não verificado o sintoma exato*; é consequência de não haver
  conversão). A ordem é: **converter → gerar layouts/imagesets → empacotar → assinar** (`tools/local-build`).
- O prefixo do PBO sai de `$PBOPREFIX$`; passe `-prefix="<prefixo>"` explícito (ver seção 5.1).

## 3. O caminho de volta: PAA/EDDS → PNG

| De | Para | Ferramenta | Como |
|---|---|---|---|
| `.paa` | PNG/TGA | **TexView2** (DayZ Tools) | abrir o `.paa`; **File → Save As**; escolher PNG ou TGA. Manual, um arquivo por vez |
| `.edds` | PNG | **`edds2png`** (github.com/wrdg/edds2png; release pronto, `.exe`, sem .NET SDK) | `edds2png.exe <arquivo.edds>`; grava o PNG **ao lado da entrada**; vimos uma exceção de `ReadKey` ao final (sem console interativo), mas **o PNG sai correto** (confirmado) |
| `.edds` | PNG | TexView2 | abrir e salvar como PNG |
| PNG | PNG recortado | Pillow | para recortar um ícone de um atlas, leia o `Pos`/`Size` do `.imageset` correspondente |

Notas:
- O `edds2png` é de terceiro e **não vem neste repositório** (licença não registrada; só o link). Baixe você mesmo.
- *Não verificado:* ler `.paa` por Python/Pillow (não há suporte conhecido); use o TexView2.
- Uso típico nosso: pegar o `.edds` de um mod de terceiro **só para estudo**, converter para PNG e reaproveitar o
  **recorte** (nunca redistribuir a arte; ver `NOTICE.md`).
- Ao reaproveitar um ícone de atlas: recorte pelo `Pos`/`Size`, depois cortar a margem transparente pelo alfa e centralizar
  num quadrado. Um imageset que reaproveita a textura reduzida com o `RefSize`/`Pos` antigos deixa o ícone **pequeno** no
  slot (visto no jogo).

## 4. Criação do EDDS: passo a passo MANUAL

**Isto não é automático.** Nenhum script nosso gera `.edds`, e o `ImageToPAA` não serve para isso. Cada `.edds` novo exige
alguém abrindo o TexView2. *Não verificado nesta máquina* (o TexView2 não está instalado aqui): os passos abaixo são a
prática descrita pelo mantenedor e devem ser conferidos na primeira vez.

1. Prepare o PNG: potência de 2, RGBA, a arte já aprovada (cor linearizada se for arte colorida).
2. Abra o PNG no **TexView2** (`DayZ Tools\Bin\TexView2\TexView2.exe`).
3. **File → Save As**, e na lista de tipos escolha **EDDS** (se ele não aparecer na sua versão, a versão do DayZ Tools é
   antiga: atualize).
4. Formato/compressão: **DXT5** para arte com transparência, **DXT1** para arte opaca; **gere os mipmaps** (a UI é
   reduzida em resoluções menores). *Não verificado:* as opções exatas do diálogo.
5. **Salve dentro da pasta do mod**, no caminho que o layout ou o imageset vai citar (por exemplo
   `MeuMod/Client/gui/imagesets/meu_menu.edds`), **não** numa pasta temporária.
6. Atualize o `.imageset` (ou o `.layout`) para o caminho do `.edds`. Opcionalmente o Workbench acrescenta um GUID de
   recurso `{XXXXXXXXXXXXXXXX}` na frente do caminho ao registrar (seção 5.4).
7. Rebuild e teste no client. Um `.edds` esquecido na pasta de trabalho e não empacotado só aparece como imagem vazia.
8. Registre no README do mod que aquele recurso é **manual**: quem regenerar a arte com o script não vai gerar o EDDS.

## 5. Caminhos de imagem: todos os padrões que usamos

Convenção: o **prefixo do PBO** vem do arquivo `$PBOPREFIX$` na raiz do módulo e é o que o jogo usa como raiz do caminho.
Exemplo: `$PBOPREFIX$` com `MeuMod\Client` → o arquivo `gui/data/kit/x.paa` do módulo vira
`MeuMod/Client/gui/data/kit/x.paa`. (Nos layouts usamos `/`; no `$PBOPREFIX$` e em strings do `config.cpp` já vimos `\`.)

### 5.1 Imagem solta com prefixo completo (padrão principal)

Usado em todos os nossos módulos de UI (centenas de widgets). **Confirmado.**

`.layout`:
```
ImageWidgetClass painelFundo {
 position 0 0
 size 1 1
 hexactpos 0
 vexactpos 0
 hexactsize 0
 vexactsize 0
 image0 "MeuMod/Client/gui/data/kit/painel.paa"
 mode blend
 "src alpha" 1
 stretch 1
}
```

Script (guardando a base numa constante):
```c
static const string ICONS = "MeuMod/Client/gui/data/icons/";

void SetarIcone(ImageWidget w, string nome)
{
	w.LoadImageFile(0, ICONS + nome + ".paa");
	w.SetImage(0);
}
```

Estrutura de pastas usada: `gui/layouts/` (layouts), `gui/data/<grupo>/` (texturas: `kit/` máscaras de chrome, `icons/`
ícones, `<Módulo>/` arte do módulo), `gui/imagesets/` (imagesets). Arte de **modelo/item** (config) fica à parte, em
`data/`.

**O que quebra:**
- Prefixo do layout diferente do `$PBOPREFIX$` real (ou `-prefix=` do build diferente do arquivo): a imagem não carrega.
  *Não verificado o comportamento exato* (vimos imagem vazia sem erro de compile). Confira com `ExtractPbo` o prefixo
  gravado no PBO.
- Esquecer `SetImage(0)` depois de `LoadImageFile(0, ...)`: nossos scripts sempre chamam os dois; *não testamos* sem o
  segundo, mas siga o par.
- Extensão trocada (`.png` no layout com `.paa` no PBO): vazio. O caminho citado tem de existir **com a extensão**.
- Pasta com maiúsculas diferentes: no Windows funciona, em outro ambiente pode falhar (*não verificado*); mantenha a
  caixa igual.

### 5.2 Imagem solta relativa (sem o nome do mod)

Encontrada em módulos antigos nossos: `image0 "gui/data/common/buttons/btn_idle_240x56.paa"`.

**Não verificado se carrega** (o caminho não leva o prefixo do PBO; pode depender de onde o layout é carregado). **Regra
da skill: use sempre o prefixo completo (5.1).** Se achar um caminho relativo num mod antigo, trate como suspeito antes de
culpar a arte.

### 5.3 Imageset + `set:` (várias peças numa folha)

Usado para os ícones fantasma de slot de inventário. **Confirmado no jogo.**

`gui/imagesets/meu_menu.imageset` (CRLF):
```
ImageSetClass {
 Name "meu_menu"
 RefSize 512 512
 Textures {
  ImageSetTextureClass {
   mpix 1
   path "MeuMod/Client/gui/imagesets/meu_menu.paa"
  }
 }
 Images {
  ImageSetDefClass btn_n {
   Name "btn_n"
   Pos 0 0
   Size 96 32
   Flags 0
  }
  ImageSetDefClass btn_h {
   Name "btn_h"
   Pos 98 0
   Size 96 32
   Flags 0
  }
 }
 Groups {
 }
}
```
`RefSize` = tamanho da folha em pixels; `Pos` e `Size` em pixels dessa folha. `mpix 1` é o que usamos para textura de
1x; *não verificado:* o significado exato (no imageset vanilla há duas texturas, `mpix 0` e `mpix 1`, a segunda com
sufixo `@2x`, o que sugere variante para escala de UI maior).

Registro no `config.cpp` (**obrigatório**: sem isso `set:` não acha o imageset):
```
class CfgMods {
 class MeuMod_Client {
  class defs {
   class imageSets {
    files[] = { "MeuMod/Client/gui/imagesets/meu_menu.imageset" };
   };
   // gameScriptModule, worldScriptModule, missionScriptModule...
  };
 };
};
```

Uso no `.layout`:
```
image0 "set:meu_menu image:btn_n"
```
No `config.cpp` (campo de ícone de slot):
```
ghostIcon = "set:meu_menu image:btn_n";
```
No script (troca de estado):
```c
w.LoadImageFile(0, "set:meu_menu image:btn_h");   // não verificado em script; confirmado no layout e no config
w.SetImage(0);
```

**O que quebra:**
- Imageset **não listado** em `imageSets files[]`: `set:` não resolve, imagem vazia.
- `Name` do imageset diferente do que o layout cita (`set:<Name>`), ou `image:` com nome que não existe em `Images`.
- `path` do `.paa` com prefixo errado.
- `Pos`/`Size` fora da folha, ou `RefSize` diferente do tamanho real da textura: recorte deslocado ou ícone pequeno.
- Folha sem margem entre peças: vizinho sangra com a filtragem.

### 5.4 Imageset ou layout com `.edds` e GUID `{...}`

Padrão do vanilla e de mods feitos no Workbench: o caminho vem com um GUID de recurso entre chaves.

Imageset vanilla (extraído do jogo, só como referência de formato):
```
Textures {
 ImageSetTextureClass {
  mpix 0
  path "{534691EE0479871C}Gui/imagesets/dayz_gui.edds"
 }
 ImageSetTextureClass {
  mpix 1
  path "{C139E49FD0ECAF9E}Gui/imagesets/dayz_gui@2x.edds"
 }
}
```
Uso do vanilla no layout (funciona em qualquer mod, sem registrar nada): `image0 "set:dayz_gui image:Close"`.

Nos nossos layouts de mod, textura `.edds` com GUID aparece como propriedade `imageTexture`:
```
imageTexture "{B8F3C98074320132}MeuMod/Client/gui/data/Bussola/textures/seta.edds"
```
O GUID identifica o recurso registrado pelo Workbench. *Não verificado:* se o GUID é obrigatório ou se o caminho sozinho
basta; nos nossos `.edds` o Workbench o acrescentou. **Se você escrever o caminho à mão, teste com e sem o GUID.**

### 5.5 Imageset com `.edds` sem GUID e prefixo "de outro módulo"

Achado num imageset nosso: `path "OutroModulo/gui/textures/UI_Icons.edds"` dentro de um pack cujo `$PBOPREFIX$` é outro. É um
**resquício de cópia**: o prefixo citado não é o do PBO que contém a textura. **Não verificado se carrega.** Regra: o início
do `path` tem de ser **igual ao `$PBOPREFIX$` do módulo que empacota a textura**.

### 5.6 Estados por empilhamento de imagens e por cor

- **Estados (normal/hover/pressionado/desativado) como imagens empilhadas** no layout, com `Show()`/`Hide()` pelo script
  (nosso padrão confirmado: preferido a `LoadImageFile` repetido a cada evento).
- **Estados por cor:** uma máscara branca (`kit/_white.paa`, ou a forma do elemento) e `SetColor` por estado. É o padrão
  do nosso kit de UI gerado: o estado muda só a cor, e arquivo separado só quando o estado muda a **forma**
  (caixa marcada, cadeado). Evita o clareamento de gamma e reduz o número de peças.
- Peça decorativa dentro de botão: `ignorepointer 1` (sem isso ela rouba o mouse e nem clique nem hover chegam ao botão).

### 5.7 Caminho vazio e preenchido pelo código

Um `ImageWidget` pode ter `image0 ""` no layout e receber a imagem no script (`LoadImageFile` + `SetImage`), como os
ícones de lista que variam por linha. No Workbench ele aparece **vazio**; isso é normal (`dayz-layout-diagnosis`).

## 6. Tabela-resumo

| Padrão | Layout | Script | Registro | Status |
|---|---|---|---|---|
| 5.1 solta, prefixo completo | `image0 "Pref/gui/data/x.paa"` | `LoadImageFile(0, "Pref/...")` + `SetImage(0)` | nenhum | confirmado |
| 5.2 solta, relativa | `image0 "gui/data/x.paa"` | - | nenhum | não verificado |
| 5.3 imageset `.paa` | `image0 "set:nome image:peca"` | `LoadImageFile(0, "set:...")` (não verificado) | `imageSets files[]` no `config.cpp` | confirmado (layout/config) |
| 5.4 vanilla / `.edds` com GUID | `image0 "set:dayz_gui image:..."` ou `imageTexture "{GUID}..."` | - | vanilla já registrado | confirmado (vanilla); GUID não verificado |
| 5.5 imageset com prefixo de outro módulo | - | - | - | suspeito |
| 5.6 estados por pilha/cor | várias imagens ou `_white` | `Show()`, `SetColor` | - | confirmado |
