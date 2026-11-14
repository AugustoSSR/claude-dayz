---
name: dayz-command-flow-review
description: 'Traça o fluxo de um comando/toggle de mod DayZ (input do client -> RPC/chat -> handler no servidor -> estado) atrás de bug de timing e de ciclo de vida do player (reconnect, respawn, morte no meio). Use quando o comportamento é intermitente, "às vezes funciona", item cai no chão ou estado dessincroniza, e não há erro de compile.'
license: PolyForm-Noncommercial-1.0.0
---

# DayZ — Review de fluxo de comando

## Quando usar

- "Não tá fluindo" / "funciona às vezes" / "item cai no chão" / "desaparece depois de X" — sintomas de
  **timing**, não de lógica quebrada (a lógica isolada geralmente já foi revisada e está correta — o
  problema é QUANDO ela roda).
- Qualquer feature que reage a reconnect/respawn/morte no meio de uma operação com estado (toggle, vault,
  sessão).
- Antes de aceitar "não sei por que, só falha às vezes" como resposta final — quase sempre é ordem de
  execução, não aleatoriedade real.

## Processo

1. **Mapear a cadeia completa do comando**, hop por hop: input do client (`MissionGameplay.OnUpdate` ou
   o registro de comando de chat do mod) → RPC (se houver) → handler server-side → toda mutação de estado que
   acontece a partir dali (inventário, flags, arquivos).
2. **Para cada hop, perguntar: em que MOMENTO do ciclo de vida do player ele roda?**
   - Comando de chat (`/admin`, etc.) — sempre roda com o player já totalmente carregado/em sessão.
     Praticamente nunca tem problema de timing.
   - `EEInit()` — roda na criação da entidade, tanto em primeiro join quanto em respawn/reconnect. **Não
     garante que o sistema de inventário/slots de roupa já está pronto pra `CreateInInventory` resolver
     posição** — é um ponto MUITO mais cedo no ciclo de vida que qualquer comando de chat.
   - RPC client→server disparado por keybind — roda a qualquer momento depois que o client já processa
     input, geralmente seguro (mid-session).
3. **Se algum hop crítico roda em `EEInit()` (ou outro hook de criação de entidade) e MEXE EM
   INVENTÁRIO/CARGO**, esse é o suspeito primário de qualquer sintoma de "falha intermitente"/"item some"/
   "cai no chão" — o padrão confirmado é que **objetos recém-criados
   não estão prontos pra operação de inventário imediatamente** — mesma categoria de bug, seja o objeto
   recém-criado um vault ou o próprio player reconectando.
4. **Fix padrão**: adiar a operação sensível com `GetGame().GetCallQueue(CALL_CATEGORY_GAMEPLAY).CallLater(
   fn, delayMs, false, params)` — um delay pequeno (segundos, não minutos) já costuma bastar. Reaplicável a qualquer "entidade recém-criada, ainda não pronta" independente de qual
   entidade é.
5. **Adicionar log ANTES e DEPOIS da operação sensível** se a causa não estiver 100% confirmada — barato de
   adicionar, e transforma "não sei por que falha" em prova concreta no próximo teste ao vivo.

## Regras

- Não aceitar "bug intermitente" como diagnóstico final — quase sempre efeito determinístico de ORDEM,
  só parece aleatório porque depende de quão rápido o client/engine processa cada frame.
- Preferir uma correção testável (log + delay) a uma reescrita grande — mudança mínima, a
  filosofia é "menor mudança que resolve".
- Sempre confirmar que o comando funciona no caminho "normal" (mid-session) antes de mexer — se SÓ falha em
  reconnect/respawn, o problema é 100% timing de ciclo de vida, não lógica.

## Ver também

`dayz-duplicate-detector` (duplicação e comentário obsoleto).
