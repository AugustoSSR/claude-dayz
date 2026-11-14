# Servidor local de teste: subir, vigiar, concluir

O pipeline de exemplo do repositório está em `tools/local-build/`.

## Subir

- **Use `Start-Process -FilePath <exe> -ArgumentList @(...)` com um ARRAY** de argumentos, no PowerShell, desanexado.
  Rodar o servidor em background pela ferramenta de shell ou como job do PowerShell **mata o processo quando a
  chamada termina**: parece vivo no primeiro poll e some depois (falso PASS). Passar `-ArgumentList` como **string**
  com aspas embutidas corrompe a linha quando o exe tem espaço no caminho: os `-mod=` somem sem erro, e o servidor
  sobe "normal" sem os seus PBOs. A diferença é string contra array, não contradição.
- Se for chamar um `.bat` pelo Git Bash: `cmd //c "C:\caminho\absoluto\start.bat"`, sem `cd`.
- **`-mod=` com vários caminhos separados por `;` só carrega o primeiro** se algum deles tiver espaço (`Program Files
  (x86)`): use o caminho curto 8.3 (`C:\PROGRA~2\...`) e a lista **sem aspas**.
- Use porta diferente da de produção e um **profile isolado** (`-profiles=profiles_local`). Apontar o teste para o
  profile real faz o mod recriar a própria config do zero no boot e sobrescrever valores reais sem aviso.
- Rode **uma instância de teste por vez**: um segundo servidor "paralelo" disputa a porta de query (27016 por padrão) e
  derruba os dois.

## Vigiar e concluir

- **Olhe o boot em 10 a 15 s** (`.RPT` e `script_*.log`), não espere 30 s ou 2 min antes de abrir o log. Um erro de
  compile real aparece no começo. Só espere mais se não há erro, não há confirmação do módulo e o processo ainda
  consome CPU. Um boot completo de stack grande leva ~25 a 40 s: sinal de "terminou" é um artefato do seu módulo
  (por exemplo o arquivo de config que ele cria), não um timer fixo.
- **Ordem de verdade do veredito**:
  1. O log tem horário **posterior** ao do `.pbo` (compare horários; a ordem de `ls -lat` não basta).
  2. Existe `crash_*.log` novo? Então é FAIL definitivo: leia na hora.
  3. A linha de inicialização do módulo aparece no `.RPT` do boot **atual**?
  O mtime de um arquivo de config **não** serve de sinal de boot novo (ele nem sempre é reescrito).
- **Processo vivo não é sucesso.** Erro de compile na camada `5_Mission` deixa o `DayZServer_x64.exe` vivo e zumbi,
  com a memória subindo e o `.RPT` congelado.
- `.RPT` parado em ~9 linhas + `ErrorMessage_*.mdmp` + `DayZLauncher.exe` aparecendo em segundos = **crash de ambiente
  antes do compile**, não do seu módulo. Reporte bloqueio de ambiente.
- Símbolo de erro que não existe na fonte, no staging nem nas `strings` do `.pbo`: `profiles_local/DataCache` velho.
  Pare o servidor, apague a pasta `DataCache` e relance **uma vez** antes de reportar FAIL.
- "Objeto duplicado no mesmo ponto": veja `central-economy.md` antes de caçar bug.
- **O servidor dedicado não compila UI** (`UIScriptedMenu`, `.layout`, HUD, mapa): "0 erros" não vale para o client.
  O log do client fica em `%LOCALAPPDATA%\DayZ\` (`script_*.log`, `crash_*.log`, `DayZ_x64_*.RPT`), e **não** em
  `Documents\DayZ`.
- Modo "deixar de pé para testar pelo client": PASS = não mate; FAIL = mate. Tire um snapshot dos arquivos do log do
  client e vigie por `crash_*.log` ou `.RPT` novo, com um teto de tempo (depende de humano).

## Concorrência

- **Um agente (ou pessoa) de build por vez**, e ninguém editando os mesmos módulos durante o teste. Colisões já
  resetaram a config e fizeram cada boot sobreviver menos (20 min, depois 40 s, depois 15 s, saída limpa e sem log). Um
  erro **idêntico a um já corrigido** que reaparece costuma ser outro editor que reverteu o arquivo, não o fix que
  falhou: releia o arquivo do disco antes de gastar mais um ciclo.
- Um processo "completed" nem sempre está parado: confira o estado de todos antes de disparar outro.
