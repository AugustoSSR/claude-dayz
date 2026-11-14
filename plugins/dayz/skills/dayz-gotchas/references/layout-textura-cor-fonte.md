# Textura, cor, gamma e fonte

## Cor de textura sai clareada

O jogo lê a cor de um `.paa` como linear e a codifica em sRGB na saída. Medido: `#121216` aparece como `#4C4C54`,
`#3A0710` como `#82324A`. A cor definida no widget (`color` do layout ou `SetColor`) **não** passa por isso e sai
exata.

- **Chrome plano** (painel, cabeçalho, botão, aba, linha, fundo) = PNG **branco com o alfa da forma**, e a cor vem do
  `color`/`SetColor`.
- **Arte com cor** (emblema, fundo texturizado): linearize o RGB antes de converter para PAA, `(c/255)^2.2`. Tons
  escuros perdem precisão em 8 bits, por isso chrome escuro não deve ir "assado" na textura.
- **O alfa também mistura em linear**: branco a 6% de alfa sobre fundo escuro vira cinza forte; 8% vira mancha;
  degradê escuro em textura vira faixas coloridas (compressão DXT somada à linearização). Para hover e destaque, use
  uma cor sólida misturada em sRGB no código; para fundo escuro, máscara mais cor.
- Imageset: use a textura inteira e recorte no desenho; o contrário deixa o ícone pequeno.
- Escrever DDS com Pillow grava tamanho linear e mipmaps errados e a textura sai preta; recolora nos blocos DXT.

## Fonte

- A fonte do jogo (Metron) é bitmap e **só existe em 12, 14, 16, 22, 28, 48 e 58** (arquivos como
  `gui/fonts/metron-bold16`). Qualquer outro `"exact text size"` estica e borra: use o arquivo do tamanho nativo.
- Ela é **mais larga** que as fontes de mockup comuns. Posições fixas medidas no mockup encostam texto em texto ou
  descentralizam ícone e texto num botão. Posicione pelo texto real em runtime (ver `layout-widgets.md`).
