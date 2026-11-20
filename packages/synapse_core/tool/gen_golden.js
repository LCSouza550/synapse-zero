#!/usr/bin/env node
/*
 * Gera os vetores de referência (golden) a partir do protótipo HTML original.
 * O protótipo é o "oráculo": o pacote Dart deve produzir resultados idênticos.
 *
 * Uso (a partir da pasta packages/synapse_core):
 *   node tool/gen_golden.js caminho/para/SYNAPSE_ZERO.html test/golden/core_vectors.json
 */
'use strict';
const fs = require('fs');
const path = require('path');

const [htmlPath, outPath] = process.argv.slice(2);
if (!htmlPath || !outPath) {
  console.error('Uso: node tool/gen_golden.js <protótipo.html> <saída.json>');
  process.exit(1);
}

const html = fs.readFileSync(htmlPath, 'utf8');
const start = html.indexOf('const Core = (function () {');
const end = html.indexOf('\n})();', start);
if (start < 0 || end < 0) {
  console.error('Bloco "Core" não encontrado no HTML.');
  process.exit(1);
}
const Core = new Function(html.slice(start, end + 6) + '\nreturn Core;')();

function dumpLevel(level) {
  return {
    n: level.n,
    seed: level.seed,
    fallback: level.fallback,
    optCW: level.optCW,
    optBoth: level.optBoth,
    slack: level.slack,
    budget: level.budget,
    pathTiles: level.pathTiles,
    bonus: level.bonus,
    meta: level.meta,
    nets: level.nets.map(function (n) {
      return { src: n.src, dst: n.dst, inRow: n.inRow, outRow: n.outRow, path: n.path };
    }),
    tiles: level.tiles.map(function (t) {
      return { kind: t.kind, net: t.net, pos: t.pos, mask: t.mask, rot: t.rot, solved: t.solved };
    })
  };
}

function dumpEval(ev) {
  return {
    lit: Array.from(ev.lit),
    netSolved: ev.netSolved,
    fed: ev.fed,
    litCount: ev.litCount,
    solved: ev.solved
  };
}

/* ---- Réplica fiel da lógica de sessão do protótipo (startGame/onTap/undo/resetGame/win) ---- */
function newSession(level) {
  const G = {
    level: level,
    over: false,
    status: 'playing',
    moves: 0,
    clicks: level.budget,
    cap: level.budget,
    claimed: {},
    history: [],
    rots: level.tiles.map(function (t) { return t.rot; }),
    prevSolved: level.nets.map(function () { return false; }),
    result: null
  };
  G.angles = G.rots.map(function (r) { return r * 90; });
  claim(G, Core.evaluate(level, G.rots));
  return G;
}
function claim(G, ev) {
  const got = [];
  G.level.bonus.forEach(function (i) {
    if (!G.claimed[i] && ev.lit[i] >= 0) {
      G.claimed[i] = 1;
      G.clicks += 2;
      G.cap += 2;
      got.push(i);
    }
  });
  return got;
}
function tap(G, i, ccw) {
  if (G.over || G.clicks <= 0) return;
  const dir = ccw ? -1 : 1;
  G.rots[i] = (G.rots[i] + (dir === 1 ? 1 : 3)) % 4;
  G.angles[i] += dir * 90;
  G.clicks--;
  G.moves++;
  const got = claim(G, Core.evaluate(G.level, G.rots));
  G.history.push({ i: i, dir: dir, got: got });
  const ev = Core.evaluate(G.level, G.rots);
  G.prevSolved = ev.netSolved.slice();
  if (ev.solved) {
    G.over = true;
    G.status = 'won';
    const stars = Core.starsFor(G.level, G.moves);
    G.result = { stars: stars, gained: Core.scoreFor(G.level, G.clicks, stars, false) };
  } else if (G.clicks <= 0) {
    G.over = true;
    G.status = 'lost';
  }
}
function undo(G) {
  if (G.over || !G.history.length) return;
  const h = G.history.pop();
  G.rots[h.i] = (G.rots[h.i] + (h.dir === 1 ? 3 : 1)) % 4;
  G.angles[h.i] -= h.dir * 90;
  G.clicks++;
  G.moves--;
  h.got.forEach(function (i) { delete G.claimed[i]; G.clicks -= 2; G.cap -= 2; });
  G.prevSolved = Core.evaluate(G.level, G.rots).netSolved.slice();
}
function reset(G) {
  const L = G.level;
  G.rots = L.tiles.map(function (t) { return t.rot; });
  G.angles = G.rots.map(function (r) { return r * 90; });
  G.moves = 0;
  G.clicks = L.budget;
  G.cap = L.budget;
  G.claimed = {};
  G.history = [];
  G.over = false;
  G.status = 'playing';
  G.result = null;
  G.prevSolved = L.nets.map(function () { return false; });
  claim(G, Core.evaluate(L, G.rots));
}
function snapshot(G) {
  const ev = Core.evaluate(G.level, G.rots);
  return {
    clicks: G.clicks,
    cap: G.cap,
    moves: G.moves,
    status: G.status,
    rots: G.rots.slice(),
    quarterTurns: G.angles.map(function (a) { return a / 90; }),
    claimed: Object.keys(G.claimed).map(Number).sort(function (a, b) { return a - b; }),
    litCount: ev.litCount,
    netSolved: ev.netSolved,
    result: G.result
  };
}

function solutionTaps(level) {
  const taps = [];
  level.tiles.forEach(function (t, i) {
    if (t.kind !== 'path') return;
    let best = 4;
    t.solved.forEach(function (r) { best = Math.min(best, (r - t.rot + 4) % 4); });
    for (let k = 0; k < best; k++) taps.push({ op: 'tap', i: i, ccw: false });
  });
  return taps;
}
function randomOps(level, seed, count) {
  const rnd = Core.mulberry32(seed);
  const ops = [];
  const cells = level.n * level.n;
  for (let k = 0; k < count; k++) {
    const r = rnd();
    if (r < 0.62) ops.push({ op: 'tap', i: Math.floor(rnd() * cells), ccw: false });
    else if (r < 0.82) ops.push({ op: 'tap', i: Math.floor(rnd() * cells), ccw: true });
    else if (r < 0.94) ops.push({ op: 'undo' });
    else ops.push({ op: 'reset' });
  }
  return ops;
}
function runOps(level, ops) {
  const G = newSession(level);
  const steps = [snapshot(G)];
  ops.forEach(function (o) {
    if (o.op === 'tap') tap(G, o.i, o.ccw);
    else if (o.op === 'undo') undo(G);
    else reset(G);
    steps.push(snapshot(G));
  });
  return { initial: steps[0], steps: steps.slice(1) };
}

/* ---- Vetores ---- */
const out = { source: path.basename(htmlPath) };

out.rng = [0, 1, 42, 9000, 123456789, 4294967295].map(function (seed) {
  const r = Core.mulberry32(seed);
  const values = [];
  for (let i = 0; i < 12; i++) values.push(r());
  return { seed: seed, values: values };
});

out.hash = ['', 'abc', '2026-11-19:0', '2026-11-19:1', '2026-11-19:2', '2027-01-01:0'].map(function (s) {
  return { input: s, value: Core.hashString(s) };
});

out.rotMask = [];
[3, 5, 7, 15].forEach(function (m) {
  for (let r = -2; r < 6; r++) out.rotMask.push({ mask: m, rot: r, value: Core.rotMask(m, r) });
});

out.trailSpecs = [];
for (let i = 0; i < 20; i++) out.trailSpecs.push(Core.trailSpec(i));

out.dailySpecs = [];
['2026-11-19', '2026-12-31', '2027-01-01'].forEach(function (day) {
  for (let s = 0; s < 3; s++) out.dailySpecs.push({ day: day, stage: s, spec: Core.dailySpec(day, s) });
});

const cases = [];
for (let i = 0; i < 20; i++) cases.push({ label: 'trail:' + i, ctx: { mode: 'trail', index: i } });
out.dailySpecs.forEach(function (d) {
  cases.push({ label: 'daily:' + d.day + ':' + d.stage, ctx: { mode: 'daily', day: d.day, stage: d.stage } });
});
['facil', 'medio', 'dificil', 'extremo'].forEach(function (diff) {
  [1, 2, 123456, 987654321, 4294967295].forEach(function (seed) {
    cases.push({ label: 'arena:' + diff + ':' + seed, ctx: { mode: 'arena', diff: diff, seed: seed } });
  });
});

out.arenaSpecs = [];
['facil', 'medio', 'dificil', 'extremo'].forEach(function (diff) {
  out.arenaSpecs.push({ diff: diff, seed: 777, spec: Core.specFor({ mode: 'arena', diff: diff, seed: 777 }) });
});

out.levels = cases.map(function (c, idx) {
  const level = Core.generateLevel(Core.specFor(c.ctx));
  const initialRots = level.tiles.map(function (t) { return t.rot; });
  const solvedRots = level.tiles.map(function (t) { return t.solved ? t.solved[0] : t.rot; });
  const scoring = [];
  for (let moves = 0; moves <= level.optCW + level.slack + 2; moves++) {
    const stars = Core.starsFor(level, moves);
    scoring.push({
      moves: moves, stars: stars,
      score: Core.scoreFor(level, level.budget - moves, stars, false),
      assistScore: Core.scoreFor(level, level.budget - moves, stars, true)
    });
  }
  const scenarios = [{ name: 'solucao-otima', ops: solutionTaps(level) }];
  /* esgotar os cliques girando sempre um conduíte-isca: o protótipo decide vitória ou colapso */
  if (idx % 3 === 1) {
    let dummy = level.tiles.findIndex(function (t) { return t.kind !== 'path'; });
    if (dummy < 0) dummy = 0;
    const burn = [];
    for (let k = 0; k < level.budget + 8; k++) burn.push({ op: 'tap', i: dummy, ccw: false });
    scenarios.push({ name: 'esgotar-cliques', ops: burn });
  }
  /* sessões aleatórias (desfazer, reiniciar, giro anti-horário, bônus, derrota) só em parte dos níveis, para manter o arquivo pequeno */
  if (idx % 4 === 0) {
    scenarios.push({ name: 'aleatorio-a', ops: randomOps(level, 5000 + idx, 80) });
    scenarios.push({ name: 'aleatorio-b', ops: randomOps(level, 9000 + idx, 140) });
  }
  return {
    label: c.label,
    ctx: c.ctx,
    level: dumpLevel(level),
    evalInitial: dumpEval(Core.evaluate(level, initialRots)),
    evalSolved: dumpEval(Core.evaluate(level, solvedRots)),
    solvedRots: solvedRots,
    scoring: scoring,
    sessions: scenarios.map(function (s) {
      const r = runOps(level, s.ops);
      return { name: s.name, ops: s.ops, initial: r.initial, steps: r.steps };
    })
  };
});

out.dates = {
  prev: ['2026-03-01', '2026-01-01', '2028-03-01', '2026-11-19', '2026-12-01'].map(function (k) {
    return { key: k, prev: Core.prevDateKey(k) };
  }),
  streakAfter: [
    [0, '', '2026-11-19'], [3, '2026-11-18', '2026-11-19'], [3, '2026-11-19', '2026-11-19'],
    [5, '2026-11-10', '2026-11-19'], [2, '2026-12-31', '2027-01-01']
  ].map(function (a) {
    return { streak: a[0], lastDone: a[1], today: a[2], value: Core.streakAfterCompletion(a[0], a[1], a[2]) };
  }),
  active: [
    [4, '2026-11-19', '2026-11-19'], [4, '2026-11-18', '2026-11-19'], [4, '2026-11-17', '2026-11-19'], [0, '', '2026-11-19']
  ].map(function (a) {
    return { streak: a[0], lastDone: a[1], today: a[2], value: Core.activeStreak(a[0], a[1], a[2]) };
  })
};

fs.mkdirSync(path.dirname(outPath), { recursive: true });
fs.writeFileSync(outPath, JSON.stringify(out));
console.log('OK:', outPath, '(' + Math.round(fs.statSync(outPath).size / 1024) + ' KB,', out.levels.length, 'níveis)');
