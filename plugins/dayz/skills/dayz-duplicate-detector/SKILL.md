---
name: dayz-duplicate-detector
description: 'Acha implementações duplicadas do mesmo conceito entre mods/módulos DayZ e comentários obsoletos do tipo "// bug: ainda quebra" já corrigidos em outro lugar. Use quando um bug "já foi corrigido antes", para limpar duplicação ou antes de criar módulo novo. Só lista para revisão humana, nunca apaga.'
license: PolyForm-Noncommercial-1.0.0
---

# DayZ Duplicate & Stale-Comment Detector

## Quando usar

- "Esse bug eu já vi resolvido em outro arquivo/módulo."
- "Será que já existe um sistema de X antes de eu criar um novo?"
- Auditoria periódica pedida explicitamente (não rodar por conta própria em background).

## Processo

1. Delimitar o escopo: um módulo específico, ou comparação entre dois módulos, ou contra uma pasta de referência. Não varrer tudo de uma vez sem necessidade (custo de tokens).
2. `Grep` por assinaturas de classe/método equivalentes (nomes de classe parecidos, mesmo `CfgPatches`, mesma responsabilidade descrita na especificação do módulo).
3. `Grep` por marcadores de comentário suspeitos: `// bug`, `// TODO`, `// fix`, `// workaround`, `// hack`, e checar se o problema descrito já tem correção em outro arquivo (busca do mesmo sintoma).
4. Montar uma lista: `[arquivo:linha] — suspeita — onde parece já estar resolvido — confiança alta/média/baixa`.
5. **Não editar nada.** Devolver a lista para decisão humana: "é intencional ou é duplicata" exige revisão.

## Regras

- Pasta de referência é somente leitura; pode sugerir edição nos módulos próprios, nunca aplicar sozinho.
- Sempre reportar nível de confiança: não afirmar "isso é bug resolvido" sem mostrar onde.
- Escopo definido antes de rodar: nunca varredura total espontânea.
