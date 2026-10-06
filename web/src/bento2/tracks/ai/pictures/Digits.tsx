// ★★ The Digit reader (ai.md, "Digit reader"), the track's build. An 8 × 8 pad you draw on, shrunk the way the
// bundled digits were; a 64 → h → 10 network trained in the browser with mini-batch gradient descent from a fixed
// seed; confidence bars for the 10 digits; a 10 × 10 confusion grid; and a pixel map (the gradient of the chosen
// digit's score with respect to each pixel). The bundled digits are drawn by a program (see digits.ts), not by people.
// Modes: vector (08's Play), count (08's Guess and Work it), setup (08's Use it), train (09: curves and the grid, with
// the overfitting preset), reader (the build's version 1, and the tool), patches (11's Use it: patch attention).
import { useEffect, useMemo, useRef, useState } from "react";
import { flag, num, str, type SceneProps } from "../../../scenes";
import { fx, path, Read, SaveRow, Scene, Slider, Toggle, useSvgDrag } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { group } from "../../../steps";
import {
  confusion, DEFAULT_PLAN, digitData, forward, newReader, OVERFIT_PLAN, pixelMap, readerParams, TRAIN_N, type Reader, type TrainPlan,
} from "../digits";
import { softmax } from "../maths";
import { NP, PATCH_PLAN, patchError, patchForward, patchRun, type PatchNet } from "../patches";
import { Btn, Btns, lin, Pad, padCounts, sampleDigit, useTrainer } from "./common";

type Stroke = [number, number][];
const NOTE = "These digits are drawn by a program (pen strokes with random tilt, slant, size and wobble), then shrunk the way the UCI handwritten digits were: a 32 × 32 picture counted in 4 × 4 blocks.";

/** the reader's tool state: which run the build uses */
interface ReaderState { h: number; n: number }

function useInput(start = 3) {
  const [strokes, setStrokes] = useState<Stroke[]>([]);
  const [sample, setSample] = useState<number | null>(start);
  const x = useMemo(() => (strokes.length ? padCounts(strokes) : sample != null ? sampleDigit(sample).x : new Float64Array(64)), [strokes, sample]);
  const draw = (s: Stroke[]) => { setSample(null); setStrokes(s); };
  return { strokes, x, draw, sample, next: () => { setStrokes([]); setSample(k => ((k ?? 0) * 7 + 13) % 1797); }, clear: () => { setStrokes([]); setSample(null); } };
}

/** the 10 chances as bars, at (x, y), w wide */
function Bars({ p, x, y, w, h, notSure }: { p: ArrayLike<number>; x: number; y: number; w: number; h: number; notSure?: number | null }) {
  const best = Array.from(p).indexOf(Math.max(...Array.from(p))), bw = w / 10;
  return <g>
    {Array.from(p, (v, k) => <g key={k}>
      <rect x={x + k * bw + 2} y={y + h - v * h} width={bw - 4} height={Math.max(1, v * h)} rx="2" className={`b2bar ${k === best ? "amber" : "sky"}`} opacity={k === best ? 1 : 0.6} />
      <text x={x + k * bw + bw / 2} y={y + h + 15} textAnchor="middle" className={`b2t${k === best ? " amber" : ""}`}>{k}</text>
    </g>)}
    {notSure != null && <line x1={x} y1={y + h - notSure * h} x2={x + w} y2={y + h - notSure * h} className="b2mark" />}
  </g>;
}

/** an 8 × 8 picture of values (a weight row, a pixel map); positive pink, negative sky */
function Tile({ v, x, y, size, signed, on }: { v: ArrayLike<number>; x: number; y: number; size: number; signed?: boolean; on?: number }) {
  const m = Math.max(1e-9, ...Array.from(v, Math.abs)), c = size / 8;
  return <g>
    <rect x={x - 1} y={y - 1} width={size + 2} height={size + 2} rx="2" fill="none" stroke="var(--b2-amber)" strokeOpacity={on ?? 0} strokeWidth="2" />
    {Array.from(v, (a, i) => <rect key={i} x={x + (i % 8) * c} y={y + Math.floor(i / 8) * c} width={c + 0.2} height={c + 0.2}
      fill={signed ? (a > 0 ? "var(--b2-pink)" : "var(--b2-sky)") : "var(--text)"} fillOpacity={signed ? Math.abs(a) / m : a} />)}
  </g>;
}

export function DigitsScene({ props, place }: SceneProps) {
  const mode = str<string>(props, "mode", place === "tool" ? "reader" : "vector");
  if (mode === "count") return <CountView props={props} />;
  if (mode === "train") return <TrainView props={props} />;
  if (mode === "patches") return <PatchView />;
  return <ReaderView mode={mode} project={flag(props, "project") || place === "project"} />;
}

function ReaderView({ mode, project }: { mode: string; project: boolean }) {
  const { b2, save, note, tool, setToolState } = useB2();
  const st = tool<ReaderState>("ai-reader", { h: 16, n: DEFAULT_PLAN.n });
  const [h, setH] = useState(st.h);
  const setup = mode === "setup", vector = mode === "vector";
  const plan: TrainPlan = { ...DEFAULT_PLAN, h, n: st.n };
  const [go, setGo] = useState(!setup);
  const tr = useTrainer(go ? plan : null, { every: 5 });
  const untrained = useMemo(() => newReader(h, plan.seed), [h]); // eslint-disable-line react-hooks/exhaustive-deps
  const net: Reader = setup || !tr.net ? untrained : tr.net;
  const inp = useInput(vector ? 41 : 3);
  const { ref, drag } = useSvgDrag();
  const [view, setView] = useState<"draw" | "grid">("draw");
  const T = typeof b2.shelf.T_digits?.value === "number" ? (b2.shelf.T_digits.value as number) : 1;
  const ns = typeof b2.shelf.not_sure?.value === "number" ? (b2.shelf.not_sure.value as number) : null;
  const f = forward(net, inp.x, T), best = Array.from(f.p).indexOf(Math.max(...Array.from(f.p)));
  const pm = pixelMap(net, inp.x, best);
  const trained = !setup && !tr.busy && !!tr.net;
  const grid = useMemo(() => (trained && view === "grid" ? confusion(net, digitData().test) : null), [trained, view, net]);
  const acc = tr.passes.length ? 1 - tr.passes.at(-1)!.testErr : null;
  const fullAcc = useMemo(() => (trained ? 1 - (() => { const d = digitData().test; let w = 0; for (let i = 0; i < d.y.length; i++) { const p = forward(net, d.x[i]!).p; if (Array.from(p).indexOf(Math.max(...Array.from(p))) !== d.y[i]) w++; } return w / d.y.length; })() : null), [trained, net]);
  const worst = grid ? (() => { let b = [0, 1], bv = -1; grid.forEach((r, i) => r.forEach((v, j) => { if (i !== j && v > bv) { bv = v; b = [i, j]; } })); return { i: b[0]!, j: b[1]!, v: bv }; })() : null;
  const W = 360, H = 260;
  const svg = (
    <svg ref={ref} viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`The digit reader${trained ? "" : " (not trained yet)"}. It reads the picture as ${best}, ${fx(f.p[best]! * 100, 0)}% sure.`}>
      {view === "grid" && grid ? <>
        {grid.map((r, i) => r.map((v, j) => <rect key={`${i}-${j}`} x={60 + j * 22} y={8 + i * 22} width="21" height="21" rx="3"
          fill={i === j ? "var(--text)" : "var(--b2-pink)"} fillOpacity={i === j ? 0.12 + 0.5 * (v / 180) : Math.min(0.9, v / 12)} />))}
        {Array.from({ length: 10 }, (_, k) => <g key={k}>
          <text x="50" y={23 + k * 22} textAnchor="end" className="b2t">{k}</text>
          <text x={71 + k * 22} y="246" textAnchor="middle" className="b2t">{k}</text>
        </g>)}
        <text x="290" y="24" className="b2t">rows: true</text>
        <text x="290" y="44" className="b2t">columns: said</text>
        {worst && <rect x={60 + worst.j * 22} y={8 + worst.i * 22} width="21" height="21" rx="3" fill="none" stroke="var(--b2-amber)" strokeWidth="2" />}
      </> : <>
        <Pad x={8} y={8} size={vector ? 112 : 132} strokes={inp.strokes} setStrokes={inp.draw} counts={inp.x} drag={drag} label="Draw a digit here" />
        {vector ? <>
          {/* the 64 numbers as one long column */}
          {Array.from(inp.x, (v, i) => <rect key={i} x="130" y={8 + i * 3.7} width="14" height="3.4" fill="var(--text)" fillOpacity={0.08 + v * 0.9} />)}
          <text x="137" y="254" textAnchor="middle" className="b2t">64</text>
          {/* the hidden neurons, each as its own 8 × 8 weight picture, lit by how strongly it fires */}
          {Array.from({ length: Math.min(16, net.h) }, (_, j) => {
            const mx = Math.max(1e-9, ...Array.from(f.a));
            return <Tile key={j} v={net.W1.subarray(j * 64, (j + 1) * 64)} x={156 + (j % 4) * 30} y={8 + Math.floor(j / 4) * 30} size={26} signed on={f.a[j]! / mx} />;
          })}
          <text x="214" y="140" textAnchor="middle" className="b2t">16 hidden</text>
          <Bars p={f.p} x={156} y={160} w={196} h={64} />
        </> : <>
          <Bars p={f.p} x={156} y={16} w={196} h={124} notSure={ns} />
          <Tile v={pm} x={8} y={152} size={96} signed />
          <text x="114" y="186" className="b2t">what it looked at:</text>
          <text x="114" y="208" className="b2t pink">pink, more like {best}</text>
          <text x="114" y="230" className="b2t sky">blue, less</text>
        </>}
      </>}
    </svg>
  );
  const shelfR = b2.shelf.digit_reader?.value;
  const summary = [h, readerParams(h), setup ? 0 : plan.n];
  const savedR = Array.isArray(shelfR) && (shelfR as number[]).every((v, i) => v === summary[i]) && (setup || b2.shelf.acc_digits?.value === fullAcc);
  const onSave = () => {
    setToolState("ai-reader", { h, n: plan.n });
    save("digit_reader", summary, setup ? "b2-ai-08" : "ai-reader", { labels: ["hidden", "numbers", "trained on"], note: setup ? "the reader, not trained yet" : "the trained reader; it retrains from its seed in the Digit reader" });
    if (!setup && fullAcc != null) {
      save("acc_digits", fullAcc, "ai-reader", { note: "held-out accuracy on 1,797 held-out digits" });
      note({ id: "ai-reader", track: "ai", title: "Digit reader, version 1", project: "ai-reader", build: false, data: { h, n: plan.n, acc: fullAcc },
        lines: [`A 64 → ${h} → 10 network, ${group(readerParams(h))} numbers, trained on ${group(plan.n)} digits.`, `Held-out accuracy ${fx(fullAcc * 100, 1)}%.${worst ? ` Most confused: a ${worst.i} read as ${worst.j}.` : ""}`] });
    }
  };
  const notSure = ns != null && f.p[best]! < ns;
  return (
    <Scene svg={svg}
      controls={<>
        {setup && <Slider label="Hidden neurons h" value={h} min={4} max={32} step={1} onChange={setH} marks={[{ v: 10, label: "10" }, { v: 16, label: "16" }, { v: 20, label: "20" }, { v: 32, label: "32" }]} />}
        <Btns>
          <Btn onClick={inp.clear}>Clear the pad</Btn>
          <Btn onClick={inp.next}>Show a held-out digit</Btn>
          {!setup && <Toggle label="View" value={view} onChange={setView} options={[{ v: "draw", label: "Draw" }, { v: "grid", label: "10 × 10 grid" }]} />}
          {setup && <Btn on={!go} onClick={() => setGo(true)}>{go ? "Training…" : "Train it"}</Btn>}
        </Btns>
      </>}
      readouts={<>
        <Read label="It reads" value={notSure ? "not sure" : `${best}, ${fx(f.p[best]! * 100, 0)}% sure`} tone="amber" big />
        <Read label="Network" value={mode === "vector" ? `64 → ${h} → 10` : `64 → ${h} → 10, ${group(readerParams(h))} numbers`} />
        {!setup && <Read label={tr.busy ? "Training, pass" : "Held-out accuracy"} value={tr.busy ? `${tr.passes.at(-1)?.epoch ?? 0} of ${plan.epochs}` : fullAcc != null ? `${fx(fullAcc * 100, 1)}%` : acc != null ? `${fx(acc * 100, 1)}%` : "…"} tone="mint" />}
        {worst && <Read label="Most confused" value={`a ${worst.i} read as ${worst.j}, ${worst.v} times`} tone="pink" />}
        {T !== 1 && !setup && <Read label="Temperature" value={`T = ${fx(T)}`} />}
      </>}
      foot={<>
        {(setup || project) && <SaveRow what={setup ? <>Keep the untrained reader as <b>digit_reader</b></> : <>Keep <b>digit_reader</b> and <b>acc_digits</b>{fullAcc != null ? ` = ${fx(fullAcc * 100, 1)}%` : ""}</>}
          saved={savedR} onSave={() => { if (setup || fullAcc != null) onSave(); }} />}
        <p className="ainote">{NOTE}</p>
      </>}
    />
  );
}

function CountView({ props }: { props: SceneProps["props"] }) {
  const quiet = flag(props, "quiet");
  const [s, setS] = useState(num(props, "s", 8));
  const [h, setH] = useState(num(props, "h", 16));
  const W = 360, H = 260, s2 = s * s;
  const counts = [s2 * h, h, h * 10, 10], total = counts.reduce((a, b) => a + b, 0);
  const show = (v: number) => (quiet ? "?" : group(v));
  const hy = (k: number, n: number) => 30 + ((k + 0.5) * 200) / n;
  const nh = Math.min(h, 12);
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`A ${s2} → ${h} → 10 network${quiet ? "" : ` with ${group(total)} numbers to learn`}.`}>
      {Array.from({ length: 16 }, (_, i) => Array.from({ length: nh }, (_, j) => <line key={`${i}-${j}`} x1="40" y1={hy(i, 16)} x2="180" y2={hy(j, nh)} className="b2grid strong" />))}
      {Array.from({ length: nh }, (_, j) => Array.from({ length: 10 }, (_, k) => <line key={`${j}-${k}`} x1="180" y1={hy(j, nh)} x2="300" y2={hy(k, 10)} className="b2grid strong" />))}
      {Array.from({ length: 16 }, (_, i) => <circle key={i} cx="40" cy={hy(i, 16)} r="4" className="b2dot" />)}
      {Array.from({ length: nh }, (_, j) => <circle key={j} cx="180" cy={hy(j, nh)} r="6" className="b2dot sky" />)}
      {Array.from({ length: 10 }, (_, k) => <circle key={k} cx="300" cy={hy(k, 10)} r="6" className="b2dot amber" />)}
      <text x="40" y="20" textAnchor="middle" className="b2t">{s2} in</text>
      <text x="180" y="20" textAnchor="middle" className="b2t sky">{h} hidden</text>
      <text x="300" y="20" textAnchor="middle" className="b2t amber">10 out</text>
      <text x="110" y="250" textAnchor="middle" className="b2t pink">{show(counts[0]!)} + {show(counts[1]!)}</text>
      <text x="240" y="250" textAnchor="middle" className="b2t pink">{show(counts[2]!)} + {show(counts[3]!)}</text>
    </svg>
  );
  return (
    <Scene svg={svg}
      controls={<>
        <Slider label="Picture side s" value={s} min={4} max={28} step={4} onChange={setS} format={v => `${v} × ${v}`} />
        <Slider label="Hidden neurons h" value={h} min={4} max={32} step={2} onChange={setH} />
      </>}
      readouts={<>
        <Read label="Weights, layer 1" value={show(counts[0]!)} />
        <Read label="Biases" value={quiet ? "?" : `${h} + 10`} />
        <Read label="Numbers to learn" value={show(total)} tone="pink" big />
      </>}
    />
  );
}

const SIZES = [100, 200, 300, 500, 1000, 2000, 3000, TRAIN_N];
function TrainView({ props }: { props: SceneProps["props"] }) {
  const preset = str<string>(props, "preset", "") === "overfit", quiet = flag(props, "quiet");
  const [ni, setNi] = useState(preset ? 0 : 6);
  const [h, setH] = useState(preset ? OVERFIT_PLAN.h : 16);
  const plan: TrainPlan = preset ? OVERFIT_PLAN : { ...DEFAULT_PLAN, n: SIZES[ni]!, h, epochs: Math.max(20, Math.round((3000 * 20) / SIZES[ni]!)) };
  const tr = useTrainer(plan, { every: preset ? 5 : Math.max(1, Math.round(plan.epochs / 20)), testLimit: 600 });
  const grid = useMemo(() => (!tr.busy && tr.net ? confusion(tr.net, digitData().test) : null), [tr.busy, tr.net]);
  const W = 360, H = 260, ex = lin(0, plan.epochs, 34, 206), ey = lin(0, 0.6, 236, 14);
  const bmax = Math.max(1.5, ...tr.passes.map(p => p.testBits)), by = lin(0, bmax, 236, 14);
  const last = tr.passes.at(-1);
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`Training on ${plan.n} digits with ${plan.h} hidden neurons: pass ${last?.epoch ?? 0} of ${plan.epochs}.`}>
      <line x1="34" y1="236" x2="206" y2="236" className="b2axis" />
      <line x1="34" y1="236" x2="34" y2="14" className="b2axis" />
      {[0.2, 0.4].map(v => <g key={v}><line x1="34" y1={ey(v)} x2="206" y2={ey(v)} className="b2grid" /><text x="30" y={ey(v) + 4} textAnchor="end" className="b2t">{v * 100}%</text></g>)}
      <path d={path(tr.passes.map(p => [ex(p.epoch), ey(p.trainErr)]))} className="b2curve sky" />
      {!quiet && <path d={path(tr.passes.map(p => [ex(p.epoch), ey(p.testErr)]))} className="b2curve pink" />}
      {!quiet && <path d={path(tr.passes.map(p => [ex(p.epoch), by(p.testBits)]))} className="b2curve amber" strokeDasharray="5 4" />}
      <text x="206" y="252" textAnchor="end" className="b2t">passes</text>
      {grid && Array.from({ length: 10 }, (_, i) => Array.from({ length: 10 }, (_, j) => <rect key={`${i}-${j}`} x={218 + j * 13.6} y={30 + i * 13.6} width="13" height="13" rx="2"
        fill={i === j ? "var(--text)" : "var(--b2-pink)"} fillOpacity={i === j ? 0.1 + 0.5 * (grid[i]![j]! / 180) : Math.min(0.9, grid[i]![j]! / 12)} />))}
      {grid && <text x="286" y="20" textAnchor="middle" className="b2t">confusion grid</text>}
    </svg>
  );
  const worst = grid ? (() => { let b = [0, 1], bv = -1; grid.forEach((r, i) => r.forEach((v, j) => { if (i !== j && v > bv) { bv = v; b = [i, j]; } })); return b; })() : null;
  return (
    <Scene svg={svg}
      controls={preset ? undefined : <>
        <Slider label="Training digits" value={ni} min={0} max={SIZES.length - 1} step={1} onChange={setNi} format={k => group(SIZES[k]!)} />
        <Slider label="Hidden neurons h" value={h} min={4} max={64} step={4} onChange={setH} />
      </>}
      readouts={<>
        <Read label="Training error" value={last ? `${fx(last.trainErr * 100, 1)}%` : "…"} tone="sky" />
        {!quiet && <Read label="Held-out error" value={last ? `${fx(last.testErr * 100, 1)}%` : "…"} tone="pink" />}
        {!quiet && <Read label="Held-out loss, dashed" value={last ? `${fx(last.testBits)} bits` : "…"} tone="amber" />}
        <Read label="Pass" value={`${last?.epoch ?? 0} of ${plan.epochs}`} />
        {worst && <Read label="Most confused" value={`a ${worst[0]} read as ${worst[1]}`} />}
      </>}
    />
  );
}

/** 11's Use it: the patch reader. Tap a patch to see which patches it attends to. */
function PatchView() {
  const { b2, save } = useB2();
  const [net, setNet] = useState<PatchNet | null>(null);
  const [pass, setPass] = useState(0);
  const [err, setErr] = useState<number | null>(null);
  const [at, setAt] = useState(5);
  const [go, setGo] = useState(false);
  const inp = useInput(7);
  const { ref, drag } = useSvgDrag();
  const stop = useRef(false);
  useEffect(() => {
    if (!go) return;
    stop.current = false;
    const run = patchRun(PATCH_PLAN);
    const tick = () => {
      if (stop.current) return;
      const t0 = performance.now();
      let s = run.next();
      while (!s.done && performance.now() - t0 < 20 && !s.value.end) s = run.next();
      if (s.done) return;
      setNet(s.value.net); setPass(s.value.epoch);
      if (s.value.end && s.value.epoch === PATCH_PLAN.epochs) { setErr(patchError(s.value.net, digitData().test)); return; }
      setTimeout(tick, 0);
    };
    setTimeout(tick, 30);
    return () => { stop.current = true; };
  }, [go]);
  const f = net ? patchForward(net, inp.x) : null;
  const best = f ? f.p.indexOf(Math.max(...f.p)) : null;
  const W = 360, H = 260, size = 200, cs = size / 4;
  const svg = (
    <svg ref={ref} viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`A digit cut into 16 patches. Patch ${at + 1} attends most to the patches shaded violet.`}>
      <Pad x={8} y={30} size={size} strokes={inp.strokes} setStrokes={inp.draw} counts={inp.x} drag={drag} label="Draw a digit here" />
      {f && f.A[at]!.map((w, j) => <rect key={j} x={8 + (j % 4) * cs} y={30 + Math.floor(j / 4) * cs} width={cs} height={cs} fill="var(--b2-violet)" fillOpacity={Math.min(0.75, w * 3)} pointerEvents="none" />)}
      {Array.from({ length: NP }, (_, j) => <rect key={`p${j}`} x={8 + (j % 4) * cs} y={30 + Math.floor(j / 4) * cs} width={cs} height={cs} fill="none" className={j === at ? "aibox on" : "aicell"} pointerEvents="none" />)}
      <text x="8" y="20" className="b2t trav">tap a patch below; violet: where it looks</text>
      {f && <Bars p={f.p} x={222} y={40} w={130} h={150} />}
      {Array.from({ length: NP }, (_, j) => <rect key={`t${j}`} x={222 + (j % 8) * 16} y={226 + Math.floor(j / 8) * 16} width="15" height="15" rx="3" className={j === at ? "aibox on trav" : "aibox"} onClick={() => setAt(j)} style={{ cursor: "pointer" }} />)}
    </svg>
  );
  const plain = typeof b2.shelf.acc_digits?.value === "number" ? (b2.shelf.acc_digits.value as number) : null;
  const acc = err != null ? 1 - err : null;
  return (
    <Scene svg={svg}
      controls={<Btns>
        <Btn on={!go} onClick={() => setGo(true)} disabled={go}>{go ? (acc != null ? "Trained" : `Training, pass ${pass} of ${PATCH_PLAN.epochs}`) : "Train the patch reader"}</Btn>
        <Btn onClick={inp.next}>Show a held-out digit</Btn>
        <Btn onClick={inp.clear}>Clear</Btn>
      </Btns>}
      readouts={<>
        <Read label="It reads" value={best != null ? `${best}` : "train it first"} tone="amber" />
        <Read label="Patch reader, held-out accuracy" value={acc != null ? `${fx(acc * 100, 1)}%` : "…"} tone="trav" />
        <Read label="acc_digits, your plain reader" value={plain != null ? `${fx(plain * 100, 1)}%` : "not saved yet"} tone="mint" />
      </>}
      foot={acc != null ? <SaveRow what={<>Keep <b>acc_patches = {fx(acc * 100, 1)}%</b></>} saved={b2.shelf.acc_patches?.value === acc}
        onSave={() => save("acc_patches", acc, "b2-ai-11", { note: `the patch reader, trained on ${group(PATCH_PLAN.n)} digits` })} /> : undefined}
    />
  );
}

/** 09's Work it: a 3-digit confusion grid, rows the true digit and columns what the reader said */
export function ConfusionScene({ props }: SceneProps) {
  const d = str<string>(props, "d", "1,7,9").split(",").map(Number), G = str<string>(props, "g", "48,2,0;6,40,4;0,3,47").split(";").map(r => r.split(",").map(Number));
  const [pick, setPick] = useState<[number, number] | null>(null);
  const W = 360, H = 260, c = 56, x0 = 110, y0 = 50;
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={`A confusion grid for ${d.join(", ")}: ${G.map((r, i) => `true ${d[i]}: ${r.join(", ")}`).join("; ")}.`}>
      <text x={x0 + 1.5 * c} y="24" textAnchor="middle" className="b2t">what the reader said</text>
      <text x="40" y={y0 + 1.5 * c} textAnchor="middle" className="b2t" transform={`rotate(-90 40 ${y0 + 1.5 * c})`}>true digit</text>
      {d.map((v, k) => <g key={k}>
        <text x={x0 + k * c + c / 2} y={y0 - 8} textAnchor="middle" className="b2t">{v}</text>
        <text x={x0 - 10} y={y0 + k * c + c / 2 + 5} textAnchor="end" className="b2t">{v}</text>
      </g>)}
      {G.map((r, i) => r.map((v, j) => <g key={`${i}-${j}`} onClick={() => setPick([i, j])} style={{ cursor: "pointer" }}>
        <rect x={x0 + j * c + 2} y={y0 + i * c + 2} width={c - 4} height={c - 4} rx="6" fill={i === j ? "var(--text)" : "var(--b2-pink)"} fillOpacity={i === j ? 0.12 : Math.min(0.7, v / 10)}
          stroke={pick && pick[0] === i && pick[1] === j ? "var(--b2-amber)" : "none"} strokeWidth="2" />
        <text x={x0 + j * c + c / 2} y={y0 + i * c + c / 2 + 6} textAnchor="middle" className="b2t" style={{ fill: "var(--text)" }}>{v}</text>
      </g>))}
    </svg>
  );
  const tot = G.flat().reduce((a, b) => a + b, 0), tr = G.reduce((s, r, k) => s + r[k]!, 0);
  return <Scene svg={svg} readouts={<>
    <Read label="Images" value={String(tot)} />
    <Read label="Tapped" value={pick ? (pick[0] === pick[1] ? `${G[pick[0]]![pick[1]]} right ${d[pick[0]]}s` : `${G[pick[0]]![pick[1]]}: a ${d[pick[0]]} read as ${d[pick[1]]}`) : "tap a cell"} tone="pink" />
    <Read label="On the diagonal" value={String(tr)} />
  </>} />;
}

export { softmax };
