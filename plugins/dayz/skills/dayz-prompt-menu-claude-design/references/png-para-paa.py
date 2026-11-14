"""Converte PNGs de UI em PAA com o ImageToPAA do DayZ Tools, preservando a estrutura de pastas.

Uso:  python png-para-paa.py <pasta_png> <pasta_paa>
Variavel de ambiente IMAGETOPAA = caminho completo do ImageToPAA.exe
  (em DayZ Tools/Bin/ImageToPAA/ImageToPAA.exe, na pasta de instalacao do DayZ Tools).

Regras (todas confirmadas na pratica):
- ImageToPAA so aceita lados em potencia de 2: o script reamostra para a potencia de 2 mais proxima.
  Reamostrar altera a proporcao da peca: peca de UI deve JA nascer em potencia de 2, ou ser montada numa folha.
- ImageToPAA SEMPRE grava PAA, mesmo que a saida se chame .edds. Para EDDS real, veja o passo manual.
- O sucesso e o arquivo de saida existir (o exit code nao basta); o script confere.
"""
import os
import subprocess
import sys
import tempfile
from pathlib import Path

from PIL import Image


def potencia_proxima(n):
    p = 1
    while p < n:
        p *= 2
    baixo = p // 2
    return baixo if baixo >= 1 and (n - baixo) < (p - n) else p


def main():
    exe = os.environ.get("IMAGETOPAA")
    if not exe or not Path(exe).exists():
        sys.exit("Defina IMAGETOPAA com o caminho do ImageToPAA.exe")
    origem, destino = Path(sys.argv[1]), Path(sys.argv[2])
    ok, falhas = 0, []
    with tempfile.TemporaryDirectory() as tmp:
        for png in sorted(origem.rglob("*.png")):
            im = Image.open(png).convert("RGBA")
            w, h = potencia_proxima(im.width), potencia_proxima(im.height)
            if (w, h) != im.size:
                print(f"AVISO {png.name}: {im.width}x{im.height} reamostrado para {w}x{h}")
                im = im.resize((w, h), Image.LANCZOS)
            tmp_png = Path(tmp) / (png.stem + ".png")
            im.save(tmp_png)
            saida = destino / png.relative_to(origem).with_suffix(".paa")
            saida.parent.mkdir(parents=True, exist_ok=True)
            r = subprocess.run([exe, str(tmp_png), str(saida)], capture_output=True, text=True)
            if saida.exists():
                ok += 1
            else:
                falhas.append((png.name, (r.stdout + r.stderr)[-160:]))
    print(f"OK {ok} | FALHAS {len(falhas)}")
    for nome, log in falhas:
        print("  FALHOU", nome, log)
    sys.exit(1 if falhas else 0)


main()
