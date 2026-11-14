# claude-dayz

Plugin do Claude Code com o que aprendemos fazendo mods e servidor de DayZ: um catálogo verificado de armadilhas do
Enforce Script, diagnóstico de `.layout`, revisão de fluxo de comando e convenções de servidor.

**Estado: privado, em revisão.** Só vira público depois de uma revisão independente.

## O que tem

| Item | Para que serve |
|---|---|
| `skills/dayz-api-corrections` | APIs e padrões que parecem certos e quebram compile ou runtime |
| `skills/dayz-layout-diagnosis` | Método para diagnosticar bug visual em `.layout` sem chutar |
| `skills/dayz-command-flow-review` | Bug intermitente de timing e ciclo de vida do player |
| `skills/dayz-duplicate-detector` | Duplicação e comentário obsoleto entre módulos |
| `shared/dayz-conventions.md` | Estrutura do servidor, types.xml, eventos, gotchas confirmados |
| `docs/restcallback-lifetime.md` | Estudo de caso: callback REST sem referência forte derrubou o servidor |

## Instalação

```
claude plugin marketplace add AugustoSSR/claude-dayz
claude plugin install dayz@claude-dayz --scope user
```

Mantenedor, antes de cada commit: `claude plugin validate .`

## Licença

[PolyForm Noncommercial 1.0.0](LICENSE): uso não comercial. Veja também [NOTICE.md](NOTICE.md).
