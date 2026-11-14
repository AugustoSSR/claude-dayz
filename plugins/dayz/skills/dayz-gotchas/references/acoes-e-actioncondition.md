# Ações, `ActionCondition` e input de ação

## `ActionCondition` roda nos dois lados

`ActionCondition(PlayerBase player, ActionTarget target, ItemBase item)` roda **no client** (decide o que aparece na
lista de interações) **e no servidor dedicado** (valida de novo). Duas falhas silenciosas, sem erro de compilação nem
log:

1. **Estado que só existe no servidor** (singleton criado sob `#ifdef SERVER`, lista carregada no boot) é `null` no
   client. A condição devolve `false`/vazio e a ação nunca aparece, com o servidor 100% saudável.
2. **Estado que só existe no client** (lista recebida por RPC) faz o servidor recusar a ação.

Saídas: (A) popular o estado numa camada que os dois lados leem (`4_World`, não `5_Mission`), ou (B) o servidor envia o
estado ao client por RPC e o client mantém a própria cópia. (B) é melhor quando o dado é privado ou grande. No servidor
dedicado, exija só o alvo na condição e **valide dentro do RPC**.

A sincronização por RPC tem de ocorrer **por jogador, na conexão** (ver `rpc-e-rede.md`): enviar uma vez no boot para
"0 jogadores" deixa a condição falhando para todo mundo que entra depois.

## Registrar e construir ação

- Registre a ação em `modded ActionConstructor`, método `RegisterActions(TTypenameArray actions)`, com
  `actions.Insert(MinhaAcao);`. Não existe `ActionConstructorClient`; a ação registrada no lugar errado nunca aparece.
- `ActionInteractBase` precisa setar `m_CommandUID`, `m_StanceMask` e `m_HUDCursorIcon` no construtor; senão fica sem
  bind de animação (`m_CommandUID = -1`).
- Interação instantânea (abrir um menu): `ActionInstantBase` com `InteractActionInput`, abrindo em `OnStartClient`.
- `GetText()` não recebe o alvo: resolva o nome dentro de `ActionCondition`, que roda todo frame.

## Prioridade de input não é ordem de exibição

Um bug de "minha ação não aparece ao lado da vanilla" foi mal diagnosticado como prioridade de input e "corrigido"
forçando `ContinuousInteractActionInput`. Estava errado:

- A **prioridade** do `ActionInput` decide a ordem em que os baldes de input são processados. O **índice dentro do
  balde** (quem aparece por padrão) vem da ordem de `RegisterActions`.
- `ContinuousInteractActionInput` reage a segurar o botão; `InteractActionInput` reage a clique. Forçar o tipo
  contínuo tira a ação do balde que responde ao clique: ela fica invisível, não "ganha".
- Para competir com uma ação vanilla no mesmo alvo: **herde** o `InteractActionInput` (não sobrescreva
  `GetInputType()`), e insira a sua primeiro em `RegisterActions` se quiser que ela seja a padrão.
- Antes de mexer, leia o `GetInputType()` da ação vanilla concorrente.

## Hooks reais de ação de servidor

- Ações contínuas: `OnStartServer(ActionData)` e `OnFinishProgressServer(ActionData)`. **Não existe**
  `OnFinishServer`.
- Alvo: `EntityAI.Cast(action_data.m_Target.GetObject())`; `m_Object` é privado, só o getter funciona.
- Água: as classes vanilla são `ActionFillBottleBase` (encher, poço e água aberta), `ActionDrinkWellContinuous` e
  `ActionDrinkPondContinuous`. Não existem `ActionFillBottle` nem `ActionDrinkWater`.
- **Nunca apague o item principal de uma ação contínua** (`m_MainItem`) de dentro do fluxo de callback com
  `GetGame().ObjectDelete()`: o jogador congelou no fim da animação. Use `item.DeleteSafe()`.
