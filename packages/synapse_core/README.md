# synapse_core

Núcleo de regras do **SYNAPSE // ZERO** em Dart puro. Não importa Flutter, áudio nem armazenamento.

## O que contém

| Arquivo | Responsabilidade |
|---|---|
| `rng.dart` | PRNG determinístico (mulberry32) e hash FNV-1a, com aritmética de 32 bits idêntica à do JavaScript |
| `generator.dart` | Reverse-Path Backtracking: gera circuitos com solução garantida |
| `evaluator.dart` | Propagação de energia: quais células acendem e quais redes chegaram à saída |
| `game_session.dart` | Regras da partida: cliques, bônus ⚡+2, desfazer, reiniciar, vitória e colapso |
| `scoring.dart` | Estrelas e pontuação |
| `specs.dart` | Trilha (20 níveis), Desafio Diário (semente por data) e Arena |
| `streak.dart` | Ofensiva diária |

## Como validar

```powershell
dart pub add --dev test lints
dart analyze
dart test
```

Os testes comparam o resultado com o protótipo JavaScript original, célula por célula:
`test/golden/core_vectors.json` foi gerado pelo próprio protótipo (`reference/synapse-zero-prototype.html`).
Para regenerar (requer Node.js):

```powershell
node tool/gen_golden.js ../../reference/synapse-zero-prototype.html test/golden/core_vectors.json
```

## Limitação

O pacote assume inteiros de 64 bits (Dart VM / compilação nativa para Android). Não é suportado em Dart compilado para web.
