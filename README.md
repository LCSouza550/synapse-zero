# SYNAPSE // ZERO

Quebra-cabeça lógico minimalista para celular (Android primeiro).

```
synapse-zero/
├── packages/
│   └── synapse_core/     # regras do jogo em Dart puro (testadas contra o protótipo)
├── app/                  # aplicativo Flutter (a criar)
├── docs/                 # análise do protótipo e decisões técnicas
└── reference/            # protótipo HTML original (referência de comportamento)
```

Regra de dependência: `app/presentation → app/application → synapse_core`.
O `synapse_core` nunca importa nada acima dele.
