"""Junta PNGs de UI numa folha de potência de 2 e imprime as entradas do imageset.

Uso: python montar-folha.py <pasta_com_pngs> <saida.png> [largura_da_folha=512] [margem=2]

Cada PNG vira uma peça com o nome do arquivo (sem extensão). A margem separa as peças para evitar sangramento de
vizinho com filtragem. O formato das entradas segue os .imageset que usamos em mods (ImageSetDefClass dentro de Images).
"""
import sys
from pathlib import Path
from PIL import Image


def proxima_potencia_de_2(n):
    p = 1
    while p < n:
        p *= 2
    return p


def main():
    pasta, saida = Path(sys.argv[1]), Path(sys.argv[2])
    largura = int(sys.argv[3]) if len(sys.argv) > 3 else 512
    margem = int(sys.argv[4]) if len(sys.argv) > 4 else 2
    pecas = []
    for p in sorted(pasta.glob("*.png")):
        im = Image.open(p).convert("RGBA")
        if im.width > largura:
            sys.exit(f"{p.name} ({im.width}px) não cabe na folha de {largura}px")
        pecas.append((p.stem, im))
    pecas.sort(key=lambda x: -x[1].height)  # prateleiras: as mais altas primeiro
    x = y = prateleira = 0
    posicoes = []
    for nome, im in pecas:
        if x + im.width > largura:
            x, y, prateleira = 0, y + prateleira + margem, 0
        posicoes.append((nome, x, y, im))
        x += im.width + margem
        prateleira = max(prateleira, im.height)
    altura = proxima_potencia_de_2(y + prateleira)
    folha = Image.new("RGBA", (largura, altura), (0, 0, 0, 0))
    for nome, px, py, im in posicoes:
        folha.paste(im, (px, py))
    folha.save(saida)
    print(f"# folha {largura}x{altura} -> {saida}  (use RefSize {largura} {altura} no imageset)")
    print(" Images {")
    for nome, px, py, im in sorted(posicoes):
        print(f"  ImageSetDefClass {nome} {{")
        print(f"   Name {chr(34)}{nome}{chr(34)}")
        print(f"   Pos {px} {py}")
        print(f"   Size {im.width} {im.height}")
        print("   Flags 0")
        print("  }")
    print(" }")


main()
