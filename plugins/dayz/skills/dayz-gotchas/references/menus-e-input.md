# Menus (`UIScriptedMenu`) e input

## Ciclo de vida do menu

- `UIScriptedMenu` **não tem `OnInit`**. Os pontos reais são `override Widget Init()` (devolve o root), `OnShow` e
  `OnHide`.
- Padrão de abertura em `OnShow`: `PlayerControlDisable(INPUT_EXCLUDE_INVENTORY)`, `ShowCursor(true)`,
  `ChangeGameFocus(1)`. Espelho em `OnHide`: `ShowCursor(false)`, `ResetGameFocus()`, `PlayerControlEnable(true)` e
  zerar o ponteiro estático da instância (`if (s_Instance == this) s_Instance = null;`).
- `Close()` e `CanClose()`/`CanCloseOnEscape()` são nativos: não sobrescreva (ver `dayz-api-corrections`). O botão de
  fechar só chama `Close()`; a limpeza acontece em `OnHide`.
- Um relato de auditoria diz que `Close()` direto pode não disparar `OnHide` de forma síncrona e deixar o menu num
  estado intermediário com a segunda abertura falhando. **Não foi reproduzido de forma independente.** Se você precisar
  disso, mantenha uma flag explícita de "aberto" além dos hooks, capturando a instância **antes** de esconder.
- Um menu que captura o foco não fecha com ESC pela rota nativa: trate `KC_ESCAPE` em `OnKeyPress`.
- Abrir um menu a partir do `OnClick` de outro menu: `EnterScriptedMenu` direto pode se comportar de forma estranha
  porque o primeiro ainda é o "atual". Foi observado numa auditoria e a saída adotada foi usar
  `ShowScriptedMenu`/uma função estática `Open()`. Trate como hipótese e teste no client.
- Fechar pela mesma tecla que abriu: só depois de ~0,3 s, ou o mesmo keypress fecha o menu.
- `static ref` de menu sobrevive à troca de missão: limpe em `OnMissionFinish`.
- Um elemento de HUD fixo ("overlay") precisa de `priority` acima do mapa e do inventário; com prioridade baixa ele
  some atrás deles. Os valores exatos dependem do que você sobrepõe: meça no client.

## Input: toda tecla é input registrado

- **Toda tecla que o mod usa vira input em `inputs.xml`** (ação `UA...` + `loc` no stringtable + preset), inclusive
  atalho de teste e modificador. Vantagem extra: o input aparece nas opções de controle do jogo e o jogador pode
  remapear.
- Combinação no preset: `<btn name="kLShift"><btn name="kP" /></btn>`. Modificador sozinho: um input com
  `<btn name="kLShift" />` lido por `GetUApi().GetInputByName(nome).LocalValue() > 0`. Ação pontual: `LocalPress()`.
- **Não leia `KeyState` direto.** `KeyState(KeyCode.X)` devolve `0` se nunca apertada, com o **bit 15 ligado enquanto
  apertada** e os **bits 0 a 14 contando os toques**; o contador só zera com `ClearKey`. Um `if (KeyState(...))`
  "gruda" depois do primeiro toque (um atalho de teste passou a valer para sempre e um diálogo invisível engolia
  cliques). Quem insiste em ler a tecla testa `(KeyState(k) & 32768) != 0`. Pior: com um modificador apertado, o jogo
  não dispara a ação registrada só para a tecla.
