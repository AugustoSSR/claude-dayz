# Pipeline local de build e teste (exemplo)

Dois scripts PowerShell para o ciclo "empacotar, assinar, subir um servidor de teste, ler o log, dar o veredito".
Escrevem só na pasta de saída configurada e na pasta `keys` do servidor de teste. Não tocam produção.

## Pré-requisitos

- Windows, PowerShell 5.1 ou superior.
- **DayZ Tools** (Steam): traz o `AddonBuilder.exe` e o `DSCreateKey.exe`.
- **DayZ Server** (app 223350, Steam), usado só para teste.
- Uma **chave de assinatura de teste** que você gera (`DSCreateKey`). A chave privada (`.biprivatekey`) fica **fora de
  qualquer repositório**. A pública (`.bikey`) vai para a pasta `keys` do servidor.
- Os mods de terceiros de que o seu stack depende, instalados pelo Workshop. O repositório não traz nem lista nenhum.

## Configuração

```powershell
Copy-Item config.example.ps1 config.local.ps1
# edite config.local.ps1: ModsRoot, AddonBuilder, SignKey, PublicKey, ServerDir, WorkshopMods, InitPattern...
```

`config.local.ps1`, `build/`, `logs/` e `*.biprivatekey` estão no `.gitignore`.

## Uso

```powershell
.\build-addon.ps1 -Module MeuModulo        # um módulo (ou -All para todas as pastas com config.cpp)
.\start-server.ps1 -Start -Check           # sobe, espera ~12 s e dá o veredito
.\start-server.ps1 -Check                  # só relê os logs
.\start-server.ps1 -Stop                   # encerra só o servidor de teste (pelo profile)
```

Códigos de saída do `-Check`: `0` PASS, `1` FAIL (com o primeiro erro), `3` sem conclusão (log velho, sem log ou sem
sinal ainda), `2` erro de configuração.

## Decisões embutidas (e por quê)

| Decisão | Motivo |
|---|---|
| `-packonly` | O build completo (binarização) falhou em todos os módulos; o script é compilado pelo engine ao subir o servidor. |
| Sem `-exclude` | Crasha o AddonBuilder (FATAL) e devolve exit code 0. |
| Sucesso = texto `Build Successful` | O exit code é 0 mesmo com crash. |
| Array em `Start-Process -ArgumentList` | Como string, a linha corrompe quando o exe tem espaço no caminho e os `-mod=` somem sem erro. |
| Caminhos 8.3 no `-mod=`, sem aspas | `-mod=` com `;` só carrega o primeiro caminho se algum tiver espaço. |
| Profile e porta de teste próprios | Apontar para o profile real faz os mods recriarem a config do zero e sobrescreverem valores reais. |
| Veredito só com log mais novo que o `.pbo` | Log velho não reflete o código atual. |
| `-Stop` filtra pelo profile | Nunca encerra um servidor que não seja o de teste. |

## Limites conhecidos

- PASS do servidor **não valida UI** (menu, layout, HUD, mapa): isso só compila e roda no client.
- `build-addon.ps1` não apaga o staging do AddonBuilder em `%TEMP%`. Se você moveu, renomeou ou apagou arquivos,
  apague a pasta do módulo (em minúsculas) antes.
- Se o AddonBuilder falhar em "Packing" com exit 1 e sem detalhe, acrescente `-prefix=<NomeDoAddon>` à lista de
  argumentos do script (o `-prefix` automático quebra com espaço ou pasta aninhada no caminho).
- Os padrões de erro do `-Check` (`SCRIPT (E)`, `Can't compile`...) cobrem os casos comuns; ajuste ao seu log.
- Mais contexto e evidência: `plugins/dayz/skills/dayz-gotchas/references/build-addonbuilder-pbo.md` e
  `servidor-local-de-teste.md`.
