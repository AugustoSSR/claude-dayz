# Ambiente: Windows, Git Bash e git compartilhado

Armadilhas de ferramenta que já estragaram arquivo de mod. Valem para quem edita pelo Git Bash (ou por um agente que
usa um shell POSIX no Windows).

## Escrever arquivo

- **Heredoc e strings do Git Bash perdem `\\`** (vira `\`) e sequências como `\t`/`\r\n` dentro de um script Python
  chegam como caractere real (tab, quebra de linha). Para conteúdo com barra invertida (caminho Windows, JSON, regex),
  grave com uma **ferramenta de escrita de arquivo** ou com Python usando `chr(92)`.
- `"${DIR}\\${MOD}"` não expande a variável como se espera: concatene com `/`.
- **`sed -i` e `awk ... > tmp && mv` removem o CRLF** de arquivos que devem ser CRLF (`.layout`, `init.c`, JSON de
  config). Edite com ferramenta de arquivo ou Python. Se usar `sed`, rode `unix2dos` depois e confira contando `\r` de
  verdade (ver `layout-widgets.md`).
- Calcule os bytes **antes** de abrir o arquivo em `'wb'`: abrir já trunca, e se o `encode` falhar depois o arquivo
  fica vazio.
- Antes de criar um arquivo "novo", procure o nome exato. Se a gravação disser "updated" no lugar de "created", você
  sobrescreveu algo: recupere do git. `grep | head` não prova que um arquivo não existe.
- Texto com acento num `.py` pode estar em NFD: normalize para NFC antes de comparar.

## Rodar comandos

- `.bat` pelo Git Bash: `cmd //c "C:\caminho\absoluto\arquivo.bat"`.
- `pboProject`/ferramentas de console podem ficar mudas depois de terminar: confira os artefatos antes de declarar
  travamento.
- Cuidado com `$()`, crase e pipe em comandos remotos montados com aspas duplas: o shell local os expande antes.

## git em repositório compartilhado

- **Nunca `git add -A` nem `git add .`** quando outra sessão (ou pessoa) trabalha no mesmo repositório: já levou
  trabalho alheio para produção. Use `git status --short` e `git add -- <seus caminhos>`.
- Prefira um commit no fim da sessão, com mensagem em lista e push de verdade.
- Um agente que reescreve o arquivo inteiro por conta própria ("só uma correção de estilo") pode desfazer o conserto
  de outro. Nunca dispare dois editores sobre o mesmo arquivo ao mesmo tempo.
