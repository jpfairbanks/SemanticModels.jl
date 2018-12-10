# Dubstep 

This module uses Cassette.jl to modify programs by overdubbing their executions in a context. 

## TraceCtx

Builds hierarchical runtime value traces by running the program you pass it. You can change the metadata.
You can change out the metadata that you pass in order to collect different information. The default is Any[].

## LPCtx

Replaces all calls to `norm(x,p)` which `norm(x,ctx.metadata[p])` so you can change the norms that a code uses to
compute. 

## Reference


```@autodocs
Modules = [SemanticModels.Dubstep]
```

## Index

```@index
```
