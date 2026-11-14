# AddonBuilder, PBO e assinatura

Versão da ferramenta onde isto foi observado: AddonBuilder 1.0.240639 (DayZ Tools). Confira se ainda vale na sua.

- **`-exclude=<lista>` crasha o AddonBuilder** (`FATAL ArgumentNullException` em `TextureHeaderBinazrizeTask`, mesmo
  com `-packonly`) **e devolve exit code 0**. Não use. Efeito colateral aceito: arquivos de projeto do Workbench vão
  junto para o PBO, sem afetar o compile do script.
- **Sucesso é o texto `Build Successful` no output**, nunca o exit code (devolve 0 mesmo crashando). Procure o texto.
- **`-packonly` foi o único modo que funcionou** nesse setup; o build completo (binarização) falhou em todos os
  módulos. Como o script é compilado **pelo engine ao subir o servidor**, um build bom **não prova** que o script
  compila.
- **Staging incremental**: a pasta temporária do AddonBuilder (em `%TEMP%`, uma por módulo, em minúsculas) não apaga
  arquivo removido, movido ou renomeado. Mudou um arquivo de lugar (por exemplo de `3_Game` para `4_World`)? Apague a
  pasta de staging antes de recompilar, ou confira o conteúdo do PBO com `ExtractPbo -P` (Mikero DePboTools).
- **Falha em "Packing" com exit 1 e sem detalhe**, sem `-exclude`: o `-prefix` calculado automaticamente a partir do
  caminho relativo a `-project=` quebra quando o caminho tem espaço ou pasta aninhada duplicada. Passe
  `-prefix="<Addon>"` explícito, ou rode sem `-project=`. Isso também explicou um falso "o engine ignora PBO
  empacotado à mão".
- **PBO empacotado à mão** (FileBank + assinatura) fica registrado no sistema de arquivos, mas **nunca tem os
  scripts compilados**: não serve para addon que tem dependentes. Reporte FAIL em vez de usar como atalho.
- **O `.pbo` de destino fica travado** se o servidor (`DayZServer_x64.exe`) **ou** o client (`DayZ_x64.exe`, conectado
  no mod local) estiver aberto: `Build failed` em "Copying PBO". Confira os dois processos antes de recompilar. Depois
  de fechar o client ele pode ficar "Not Responding" por alguns segundos: recheque. Um rebuild com o client aberto pode
  apagar o `.bisign` e não o `.pbo` travado, e o servidor sobe sem a assinatura.
- **Assinatura**: copie a `.bikey` **pública** para `<servidor>/keys/` de cada mod novo, senão `verifySignatures = 2`
  rejeita o PBO. A chave privada (`.biprivatekey`) **nunca** vai para git, para um documento ou para um repositório.
  Gere uma chave de teste local para builds locais e guarde a privada fora de qualquer repositório.
- `pboProject` em modo batch fica "mudo" depois de terminar: antes de dizer que travou, veja se o `.pbo` e o `.bisign`
  já existem.
- Dependência de build em mod de terceiro: use a instalação do Workshop (`steamapps/workshop/content/221100/<id>`).
  Nunca copie nem compile fonte de terceiros para dentro do seu stack. Sem a instalação, reporte bloqueador.
- Ao fim de cada rodada de edição, liste **só os módulos tocados** para recompilar, e lembre a dependência silenciosa
  (um módulo-base referenciado por vários).
- O client e o servidor devem estar na mesma versão: compare o `buildid` do `appmanifest` do DayZ Server (223350) com o
  do client (221100) quando algo "funcionava ontem".
