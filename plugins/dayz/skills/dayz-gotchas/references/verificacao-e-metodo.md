# Verificação e método

## Antes de usar uma API

- Um erro de compile **não** é prova de que a API existe; a falta de erro também não. Antes de usar qualquer
  chamada de engine (`GetGame().*`, `JsonFileLoader`, métodos de widget, de `EntityAI`, de `PlayerBase`, de
  `ActionBase`, **inclusive métodos de tipos primitivos como `string`**), ache um uso real e confirmado **da mesma
  chamada** nos scripts vanilla ou num mod que roda em produção, e cite `arquivo:linha`.
- Um mod de comunidade "que já existe" não é precedente confiável se nunca foi compilado: vários padrões copiados de um
  mod assim não compilaram. Rederive do vanilla.
- Erro que volta **idêntico** depois de a sintaxe estar correta: a premissa está errada. Compare com um módulo
  irmão que funciona.

## Auditoria estática antes de dizer "pronto"

Rode no módulo inteiro (ajuste os caminhos):

| Procura | Comando |
|---|---|
| Ternário | `grep -nE '\?[^;]*:[^;]*;' --include=*.c -r .` (revise os falsos positivos) |
| `Json(Load\|Save)File` em condição | `grep -nE 'if *\(.*Json(Load\|Save)File' --include=*.c -r .` |
| `.Find(` (array contra map) | `grep -n '\.Find(' --include=*.c -r .` |
| Nomes repetidos de `foreach` | `grep -nE 'foreach *\(' --include=*.c -r .` e compare dentro da mesma função |
| Contadores `for (int i` repetidos | `grep -nE 'for *\(int ' --include=*.c -r .` |
| Reservadas como identificador | `grep -nwE '(map\|ref\|owned\|local)' --include=*.c -r .` e leia o contexto |
| `userid` minúsculo em layout | `grep -n 'userid\b' --include=*.layout -r .` |
| Keyword suspeita de layout | `grep -n 'colums' --include=*.layout -r .` |
| Módulo sem `defs` | `grep -L 'class defs' */config.cpp` |
| Colisão de ID de RPC | ver `rpc-e-rede.md` |
| Chamadores de classe `#ifdef SERVER` | cruze cada classe guardada com seus chamadores |

"Apliquei preventivamente" não conta como auditoria: o grep é o que conta.

## Diagnosticar

- Peça ou leia o artefato (RPT, `script.log` do servidor **e** do client, `crash.log`, log do BattlEye). Cite as linhas.
  O primeiro erro da lista é a raiz; o resto é cascata.
- Compare o horário do log com o do `.pbo`. Log velho não reflete o código atual.
- Para bug visual de `.layout`, rode `git log --oneline -- <arquivo>` e `git show` antes: o mesmo sintoma já foi
  corrigido e revertido às cegas. Duas tentativas cegas falhas no mesmo arquivo: pare, simplifique ou peça um teste no
  client.
- Para "o clique dispara mas nada acontece", coloque um `Print` no `OnClick`, peça o `script.log` do **client** e
  veja o `userID` que chega. Um `userId: 0` repetido em botões diferentes aponta para a propriedade `userid` em
  minúsculo.
- Quando o usuário traz log ou captura de tela, trate o código dele como em sincronia com o deploy; não duvide do
  deploy nem responda "recompile e teste" como primeira ação.
- Quando um relato de subagente diz "zero colisões" ou "API validada", rode o grep você mesmo.

## Escopo

- Spec fechada é escopo comprometido: nada de "v1.1" silencioso nem `TODO`. Se uma parte for inviável, pare só nela e
  diga o que não fechou.
- Servidor compilando não prova UI: diga explicitamente que a tela precisa de teste no client.
- Contradições conhecidas (resolvidas ou em aberto):
  - `AddItem(..., -1)`: um registro dizia que `-1` é "append" e outro que dá `Illegal write`. O terceiro parâmetro é a
    **coluna**; `-1` ali é inválido, use `0`.
  - Ordem de compilação: a documentação diz que os mods compilam na ordem de `requiredAddons` e depois alfabética
    dentro da camada, mas houve `Can't find variable` mesmo com `requiredAddons`. Trate a ordem entre mods dentro da
    mesma camada como **não garantida**.
  - Enumeração de chaves de `map`: em aberto (ver `enforce-tipos-e-colecoes.md`).
