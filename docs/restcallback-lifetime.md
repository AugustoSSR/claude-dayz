# Caso: RestCallback sem referência forte (34 crashes em produção)

**Impacto**: 34 crashes do DayZServer em 10h, 181GB de core dumps, disco raiz 100%, banco de dados do host travou  
**Causa raiz**: RestCallback criado sem referência forte, coletado pelo GC antes da resposta chegar  
**Status**: corrigido (padrão abaixo)

## O Erro

```c
// ❌ ERRADO — callback criado sem referência forte
ctx.GET(new ValidateCallback(...), path);
// Novo objeto criado, nenhuma variável aponta pra ele
// GC coleta em seguida (quando sente vontade)
// Resposta HTTP chega 10-20min depois
// Engine tenta invocar OnSuccess/OnError em objeto já libertado → corrupção de heap
```

Quando a API estava rápida (segundos), o callback ficava vivo por sorte (GC não tinha rodado). Quando a conexão pendeu por minutos, o GC coletou o callback antes da resposta.

## O Efeito

```
*** %n in writable segments detected *** (glibc heap corruption)
SIGABRT

gcore → core dump de 5.5GB cada
34 crashes × 5.5GB = 181GB
Disco raiz: 100%
Banco do host: PANIC: could not write... No space left on device
Painel de deploy do host: travado
```

## A Solução

```c
// ✅ CORRETO — manter referência forte no mapa estático
protected static ref map<string, ref ValidateCallback> s_CallbacksMap;

void RunValidation() {
    string batchKey = JoinSlugs(slugs_batch);
    
    ValidateCallback callback = new ValidateCallback(batchKey);
    s_CallbacksMap.Set(batchKey, callback);  // Referência forte!
    
    ctx.GET(callback, path);
}
```

```c
// Dentro de ValidateCallback
class ValidateCallback {
    override void OnSuccess(class RestContext ctx, class RestCallback response) {
        // ... processar resposta ...
        
        s_CallbacksMap.Remove(m_BatchKey);  // Liberar referência ao terminar
    }
    
    override void OnError(class RestContext ctx, class RestCallback response) {
        s_CallbacksMap.Remove(m_BatchKey);
    }
    
    override void OnTimeout() {
        s_CallbacksMap.Remove(m_BatchKey);  // ⚠️ CRÍTICO — implementar!
    }
}
```

**Pontos-chave**:
1. Map estático referenciando o callback — impede GC
2. Remoção em **todos** os terminal states: OnSuccess, OnError, OnTimeout
3. OnTimeout **deve** ser implementado — sem isso requisições penduradas vazam memória + slots
4. Não confundir com RestContext/RestApi — **esses** nunca levam `ref` (singleton, destrutor privado)

## Padrão Alternativo (Simples)

Se o callback é reutilizável (um só callback pra todas as requisições), pode ser campo não-mapa:

```c
protected ref ValidateCallback m_Callback;

void RunValidation() {
    if (!m_Callback) {
        m_Callback = new ValidateCallback();
    }
    ctx.GET(m_Callback, path);
}
```

Mas com batching (10 slugs por lote), precisa de mapa pra diferenciar qual lote completou.

## O Que NÃO Fazer

❌ **Não criar RestCallback inline sem referência forte**  
Pode parecer funcionar em teste local (rede rápida) mas quebra em produção (rede lenta).

❌ **Não declarar RestContext/RestApi como `ref`**  
Esses tipos têm destrutor `private`. Compilador tenta gerar chamada de destrutor → compilation error `Method '~RestContext' is private`.

❌ **Não confundir `array<string>` com `array<ref string>`**  
São tipos completamente diferentes sem cast implícito. Precisa de overload explícito.

❌ **Não usar `.Delete()` em `map<K,V>`**  
Método certo é `.Remove(key)`.

❌ **Não assumir que `protected` libera acesso entre irmãs no mesmo arquivo**  
`protected` = classe declarante + subclasses. Outra classe independente no mesmo arquivo **não** tem acesso.

❌ **Não recompilar direto após corrigir 1 erro**  
Compiler para no primeiro erro. Cada um dos 4 erros acima só apareceu DEPOIS de corrigir o anterior.

## Checklist de Segurança

- [ ] Callback criado via `new` armazenado em campo/mapa
- [ ] OnTimeout implementado (não só OnSuccess/OnError)
- [ ] Remoção do mapa em todos os terminal states
- [ ] RestContext/RestApi **não** levam `ref`
- [ ] Revisar arquivo inteiro procurando todos os 4 padrões acima antes de recompilar

## Impacto no Ecossistema

Depois dessa correção, recomendação pra qualquer módulo que usa RestCallback:
- Verificar se segue o padrão de referência forte
- Se tem OnTimeout implementado
- Se tem cleanup em todos os branches
