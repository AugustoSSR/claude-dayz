# Protocolo A2S (consulta de servidor Steam) para servidores DayZ

Notas de implementação do protocolo UDP de consulta da Valve (documentado publicamente em *Server queries* na wiki de
desenvolvimento da Valve), conferidas contra bibliotecas de cliente e contra um cliente próprio em Node que funcionou.
Serve para verificar, de fora do jogo, a identidade de um servidor, sem confiar no que o mod diz de si mesmo.

## Porta e transporte

- UDP puro, sem confirmação nem reenvio: implemente um timeout (1 a 3 s) e reenvie.
- DayZ: a porta de query convencional é a **porta do jogo + 1** (jogo 2302, query 2303). É convenção do DayZ, não regra
  geral do Source. Confirme no `serverDZ.cfg` (`steamQueryPort`).
- Toda requisição e quase toda resposta começa com `FF FF FF FF` ("pacote único"). Uma resposta pode começar com
  `FE FF FF FF` (multipacote, abaixo).
- Strings são terminadas em `00`; inteiros em little-endian.

## A2S_INFO (não exige challenge)

Requisição: `FF FF FF FF 54 "Source Engine Query" 00`.

Resposta (tipo `49`):

| Campo | Tipo | Nota |
|---|---|---|
| Header | 4 bytes | `FF FF FF FF` |
| Tipo | byte | `0x49` |
| Protocolo | byte | |
| Nome | string | o campo que vale conferir |
| Mapa | string | |
| Pasta | string | por exemplo `dayz` |
| Jogo | string | |
| ID | short | AppID |
| Jogadores | byte | |
| Máximo | byte | |
| Bots | byte | |
| Tipo de servidor | byte | `d` dedicado, `l` listen, `p` relay |
| Ambiente | byte | `l` Linux, `w` Windows |
| Visibilidade | byte | 0 público, 1 com senha |
| VAC | byte | 0 ou 1 |
| Versão | string | |
| EDF | byte, opcional | flags dos campos extras |

Campos extras (nesta ordem, independente da posição do bit): `0x80` porta (short); `0x10` SteamID (8 bytes);
`0x40` porta e nome do SourceTV; `0x20` palavras-chave (string); `0x01` GameID (8 bytes, substitui o ID curto).

No DayZ, as palavras-chave carregam estado extra, como a contagem da fila de login (um fragmento do tipo `queue:N`).
Pode-se extrair com uma expressão regular.

Em versões recentes do protocolo, o servidor pode responder à A2S_INFO com um challenge (`41`) antes dos dados;
trate esse caso como abaixo.

## Challenge (A2S_PLAYER e A2S_RULES)

Para mitigar spoofing e amplificação, estas duas consultas exigem um número de 4 bytes emitido pelo servidor.

1. Envie a requisição com challenge `-1` (`FF FF FF FF`).
2. O servidor responde `FF FF FF FF 41 <challenge:4>` (tipo `41`).
3. Reenvie **a mesma requisição** com o challenge recebido no lugar do `-1`.
4. O servidor responde com os dados.

Alguns engines não respondem à requisição dedicada de challenge (`57`). Enviar a consulta direto com `-1` e reagir ao
tipo `41` é a forma mais compatível.

## A2S_PLAYER

Requisição: `FF FF FF FF 55 <challenge:4>`. Resposta (tipo `44`): quantidade (byte), e por jogador: índice (byte, em
prática sempre 0), nome (string), pontuação (long), duração conectado (float, em segundos).

## A2S_RULES

Requisição: `FF FF FF FF 56 <challenge:4>`. Resposta (tipo `45`): quantidade (short), e por regra: nome (string) e
valor (string).

## A2A_PING

Tipo `69`, **obsoleto**: removido de servidores modernos. Para obter latência, meça o tempo de ida e volta de uma
A2S_INFO.

## Respostas multipacote

Cabeçalho `FE FF FF FF`, seguido de:

| Campo | Tipo |
|---|---|
| ID | long (bit alto `0x80000000` ligado = payload comprimido com bzip2) |
| Total | byte |
| Número | byte (a partir de 0) |
| Tamanho | short (só no Source) |
| Tamanho descomprimido e CRC32 | long e long (só no pacote 0 e só se comprimido) |
| Payload | o restante |

Junte os fragmentos pelo número, concatene os payloads e descomprima se o bit estiver ligado. A A2S_INFO sempre cabe
num pacote; o multipacote importa sobretudo para A2S_RULES em servidores com muitas regras.

## Uso para verificação

Consultar a A2S do IP e da porta de query que um mod reporta como seus e comparar nome, mapa e ocupação com o que o
mod afirma é um segundo sinal independente: um mod adulterado pode mentir sobre si, mas não sobre o que o servidor
responde na porta de query. Se for reutilizar um cliente com cache, use um cache **por host** (um cache global de um
único servidor devolve dados do servidor errado).
