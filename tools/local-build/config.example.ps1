# Copie este arquivo para config.local.ps1 e ajuste os caminhos da SUA máquina.
# config.local.ps1 está no .gitignore: nunca o versione.

$Cfg = @{
    # Pasta que contém as pastas dos seus módulos (cada módulo tem um config.cpp na raiz).
    ModsRoot        = 'D:\DayZProjects'

    # Pasta usada como -project= do AddonBuilder (normalmente a mesma ModsRoot ou o drive P:).
    ProjectRoot     = 'D:\DayZProjects'

    # AddonBuilder.exe do pacote "DayZ Tools" (Steam).
    AddonBuilder    = 'C:\Program Files (x86)\Steam\steamapps\common\DayZ Tools\Bin\AddonBuilder\AddonBuilder.exe'

    # Chave de assinatura DE TESTE (gere uma com o DSCreateKey do DayZ Tools). A privada fica FORA de qualquer
    # repositório; a pública (.bikey) é copiada para <ServerDir>\keys.
    SignKey         = 'D:\Chaves\teste_local.biprivatekey'
    PublicKey       = 'D:\Chaves\teste_local.bikey'

    # Onde os PBOs assinados são gravados: <OutDir>\@MeuStackLocal\addons
    OutDir          = "$PSScriptRoot\build"
    OutModName      = '@MeuStackLocal'

    # Servidor dedicado (app 223350) usado SÓ para teste local.
    ServerDir       = 'C:\Program Files (x86)\Steam\steamapps\common\DayZServer'
    ServerConfig    = 'serverDZ.cfg'
    Port            = 2402                 # diferente da porta de produção
    ProfileName     = 'profiles_local'     # profile ISOLADO; nunca o que guarda a config real dos mods
    Mission         = 'dayzOffline.chernarusplus'

    # Mods de terceiros instalados pelo Workshop (IDs da pasta steamapps\workshop\content\221100).
    # Preencha com os que o SEU stack realmente exige (framework, mapa...). Este repositório não lista nenhum.
    WorkshopDir     = 'C:\Program Files (x86)\Steam\steamapps\workshop\content\221100'
    WorkshopMods    = @()                  # por exemplo: @('1559212036')

    # Texto que o seu módulo escreve no RPT quando inicializa (sinal de PASS). Ajuste ao seu log.
    InitPattern     = 'initialized'

    # Segundos de espera antes de ler os logs do boot (10 a 15 costuma bastar para ver erro de compile).
    BootWaitSeconds = 12
}
