# Análise do protótipo (HTML) e plano de migração para Flutter

Fonte: `reference/synapse-zero-prototype.html` (1 arquivo, ~1.660 linhas: CSS, marcação, regras, áudio, UI e splash juntos).

## 1. Mapa: de onde vem cada parte

| Trecho do protótipo | Destino no Flutter | Estado |
|---|---|---|
| `Core` (gerador, avaliador, pontuação, specs, ofensiva) | `packages/synapse_core` | **Portado e coberto por testes** |
| `startGame`, `onTap`, `undo`, `resetGame`, `win`, `lose` | `GameSession` em `synapse_core` | **Portado** |
| Persistência (`localStorage`, chave `synapse-zero-v2`) | `app/lib/services/storage` | A fazer |
| Áudio (Web Audio sintetizado) | `app/lib/services/audio` | A fazer (ver seção 3) |
| Vibração (`navigator.vibrate(12)`) | `app/lib/services/haptics` | A fazer |
| Telas: trilha, diário, arena, jogo, painéis | `app/lib/presentation/screens` | A fazer |
| Tokens de cor e tipografia (`:root`) | `app/lib/presentation/theme` | A fazer |
| Splash (CSS + SVG) | `app/lib/presentation/screens/splash` | A fazer (ver seção 2) |

## 2. Splash: linha do tempo exata (relógio único)

Dimensão do desenho: 320 x 80 (viewBox). Centro do capacitor em (156, 40).

| Instante | Evento |
|---|---|
| 0,20 s a 1,40 s | Feixe A percorre x 18 a 129, velocidade constante; cabeça luminosa acompanha e some no fim |
| 1,40 s a 1,85 s | Capacitor inteiro (anéis, marcas, terminais, condutor) gira de 90° a 0° (curva `cubic-bezier(0.5, 0, 0.2, 1)`); peças "acordam" para `#2b8e9a` |
| 1,85 s | Flash forte (`#eafcff`), halo radial (raio 115) cresce de 0,4 a 1,3 e assenta em 1,0 com opacidade 0,55; brilho do capacitor esmaece e **permanece aceso** |
| 1,85 s a 3,10 s | Feixe B percorre x 183 a 297; o nome surge (opacidade 0 a 1, desfoque 8 px a 0), terminando junto com o feixe |
| 3,10 s | Receptor (x 309) acende: anel, núcleo (escala 0,2 a 1) e onda (escala 1 a 2,6, some em 0,9 s) |
| 4,10 s | Fim automático; desaparece em 0,45 s. Toque encerra antes. Com "reduzir movimento": 0,9 s |

No Flutter, um único `AnimationController` de 4,1 s com `Interval` para cada evento elimina a hesitação (todos os eventos compartilham o mesmo relógio).

Pendências de ajuste já pedidas: halo mais intenso e com propagação maior; feixe liso (não raio); som ativo por padrão.

## 3. Áudio: decisão necessária

O protótipo **sintetiza** todo o som em tempo real com Web Audio (osciladores). O Flutter não tem equivalente nativo. Caminho recomendado: **pré-renderizar** os sons em arquivos (WAV/OGG) e reproduzi-los com um pacote de áudio.

| Som | Descrição de síntese |
|---|---|
| Toque | 520 Hz triangular, 0,07 s |
| Conexão | 392 Hz seno 0,12 s + 587 Hz seno 0,2 s (após 0,09 s) |
| Bônus | 880 Hz + 1320 Hz, seno |
| Vitória | 523, 659, 784 e 1047 Hz, triangular, escalonados |
| Derrota | 330, 247 e 165 Hz, dente de serra |
| Splash | varredura 190 a 540 Hz (0,2 a 1,4 s); 330 + 495 Hz e varredura 240 a 700 Hz em 1,4 s; estalo 1500 Hz + acorde 523/784/1046/1568 Hz e varredura 420 a 1000 Hz em 1,85 s; zumbido 261,6 + 392 Hz até 3,95 s; arpejo 784/1047/1319/1568 Hz + grave 98 Hz em 3,1 s |
| Música ambiente | pad 110, 164,8 e 220 Hz com filtro passa-baixa 700 Hz modulado a 0,07 Hz; notas aleatórias da escala 329,6 a 659,3 Hz a cada 2,2 s |

Os arquivos podem ser gerados a partir dessa tabela. A música deve virar um laço contínuo pré-renderizado.

## 4. Outros pontos para a versão nativa

- **Fontes:** o protótipo baixa Unbounded, IBM Plex Sans e IBM Plex Mono da internet. No app, devem ser **empacotadas como assets** (funciona offline e evita dependência de rede).
- **Vibração de 12 ms:** o Flutter oferece vibrações predefinidas; a duração exata exige um pacote de vibração (confirmar na documentação).
- **Persistência:** esquema atual `{trail[20], tscore[20], extra, arena{}, daily{day, stages[3], scores[3], streak, lastDone, best}, ccw, name, avatar, sfx, music, cb, seenHelp}`.
- **Monetização (PRO):** o protótipo declara que ainda não está definida.
- **Desafio Diário:** usa a data local do aparelho. Consequência: mudar o relógio do celular altera o desafio e a ofensiva. Aceitável no MVP; um servidor de tempo resolveria depois.

## 5. Regras do jogo confirmadas no código

- Pontos: `100 + 40 x células do caminho + 10 x cliques restantes + 100 x estrelas`; modo assistido vale metade.
- Estrelas: 3 se `movimentos <= ótimo`; 2 se `<= ótimo + ceil(folga/2)`; senão 1.
- Orçamento de cliques: `ótimo (horário) + folga`, com folga mínima de 2. Cada bônus ⚡+2 devolve 2 cliques e aumenta o total.
- Trilha: 20 níveis em 4 setores (5x5, 6x6, 7x7 com 2 redes, 8x8 com 2 redes); chefe a cada 5 níveis.
- Desafio Diário: 3 etapas (5x5, 6x6, 7x7 com 2 redes); a ofensiva só avança ao concluir as 3.
- Arena: Fácil 5x5, Médio 6x6, Difícil 7x7 (2 redes), Extremo 8x8 (2 redes).
