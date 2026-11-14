# RestCallback sem referência forte

**Problema**: crash do servidor dedicado por corrupção de heap, intermitente, que só aparecia quando a resposta HTTP
demorava.
**Causa provável**: o `RestCallback` era criado inline, sem nenhuma variável apontando para ele. O Enforce Script gerencia
objetos por **contagem de referência**: sem referência forte, a contagem zera e o objeto é liberado. Se a resposta chega
depois, o engine invoca `OnSuccess`/`OnError` num objeto já liberado. Com a API rápida o problema não aparecia; com a
conexão pendurada por minutos, sim. Esta explicação do mecanismo é **hipótese não verificada**: a evidência é o crash e o
fato de a correção abaixo eliminá-lo.
**Correção**: manter o callback referenciado até o estado terminal.

## Errado

```c
// callback criado sem referência forte
ctx.GET(new ValidateCallback(batchKey), path);
```

Sintoma no log do servidor: `*** %n in writable segments detected ***` (corrupção de heap do glibc) seguido de `SIGABRT`.

## Certo

```c
protected static ref map<string, ref ValidateCallback> s_CallbacksMap;

void RunValidation()
{
    ValidateCallback callback = new ValidateCallback(batchKey);
    s_CallbacksMap.Set(batchKey, callback);   // referência forte
    ctx.GET(callback, path);
}
```

Assinaturas reais de `RestCallback` (conferidas em `3_game/http/restapi.c` dos scripts vanilla):

```c
class ValidateCallback : RestCallback
{
    override void OnSuccess(string data, int dataSize)
    {
        // processar a resposta
        s_CallbacksMap.Remove(m_BatchKey);    // liberar no estado terminal
    }

    override void OnError(int errorCode)
    {
        s_CallbacksMap.Remove(m_BatchKey);
    }

    override void OnTimeout()
    {
        s_CallbacksMap.Remove(m_BatchKey);    // sem isto, requisições penduradas vazam
    }
}
```

`RestCallback` também tem `OnFileCreated(string fileName, int dataSize)`, para downloads em arquivo.

Pontos-chave:
1. O mapa estático mantém o callback vivo.
2. Remova a referência em **todos** os estados terminais (`OnSuccess`, `OnError`, `OnTimeout`).
3. Implemente `OnTimeout`: sem ele, requisições penduradas vazam memória.
4. `RestContext` e `RestApi` **nunca** levam `ref` (destrutor privado: `Method '~RestContext' is private`).

## Alternativa simples

Se um único callback serve para todas as requisições, um campo `protected ref ValidateCallback m_Callback;` basta. Com
lotes de requisições simultâneas, use o mapa para saber qual lote terminou.

## Checklist

- [ ] Todo callback criado com `new` fica guardado num campo ou mapa `ref`.
- [ ] `OnTimeout` implementado, e remoção da referência em todos os estados terminais.
- [ ] `RestContext`/`RestApi` sem `ref`.
- [ ] Erros de compile aparecem um por rodada: revise o arquivo inteiro antes de recompilar.
