# `MapWidget` e HUD vanilla

## `MapWidget`

- **`MapWidget` desenha por cima dos irmãos.** Um `CanvasWidget` de círculo posto como irmão ficou invisível. O
  overlay (círculo, ícone, marcador) deve nascer como **filho** do `MapWidget`, com `priority` alto (500 a 999 no
  layout). Coordenada de `DrawLine` = `MapToScreen(mundo) - MapWidget.GetScreenPos()`.
- Um modal ou pop-up comum (widget solto na tela) também fica **atrás** do mapa: esconda o `MapWidget` e seus overlays
  enquanto o modal está aberto.
- **`AddUserMark(pos, nome, cor, icone)` desenha um quadrado nativo colorido**: o ícone `.paa` do mod não aparece
  (saiu quadrado cinza ou rosa mesmo com o ícone certo). Use um widget próprio (`ImageWidget` mais `TextWidget`, com
  prioridade alta) como filho do `MapWidget`, reposicionado **todo frame** com `MapToScreen`. Posição proporcional =
  `(tela - posDoMapa) / tamanhoDoMapa`.
- Para tirar o mapa vanilla da tecla M: `override protected void HandleMapToggleByKeyboardShortcut(Man player) {}`
  em `modded MissionGameplay`.
- `SetScreenPos` de widget de aba escondida devolve 0.

## Marcadores 3D em tela

- Marcador sobre jogador ou objeto: projete com `GetScreenPos`/`GetScreenPosRelative` num `CanvasWidget`.
- A posição ao vivo (`GetLivePosition`/lista de jogadores) só é confiável para jogador "streamed in" (perto). Um snapshot
  do servidor com tick de 10 s serve só de fallback e dá "atraso/flick".

## Esconder partes do HUD vanilla

- `modded IngameHud`: esconda a cada `Update()` os widgets `StancePanel`, `WeaponStats`, `WeaponMode`, `Zeroing`,
  `StaminaBar`, `StaminaBackground` e `PresencePanel` (este é o ícone de movimento/ruído).
- Dados da arma na mão vêm do `ItemActionsWidget`:
  `modded class ItemActionsWidget { override protected void Update() { super.Update(); m_Root.Show(false); } }`.
- Leituras equivalentes para um HUD próprio: `player.GetNoisePresenceInAI()` (0 a 4), `StaminaHandler`
  (`GetStamina()`/`GetStaminaMax()`), `HumanMovementState.m_iStanceIdx % 3`, e na arma
  `GetCurrentModeName(muzzle)`, `GetCurrentZeroing(muzzle)`, `IsChamberFull(muzzle)`.
