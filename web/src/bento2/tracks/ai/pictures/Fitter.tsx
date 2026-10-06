// The Line fitter (ai.md, "Line fitter"): draggable points, a line y = wx + b with two handles, a real square on each
// miss (its area is the miss squared), the total as a bar, and, when it trains, the loss over time beside it.
// Modes: drag (01's Play), compare (01's Guess: two lines), score (01's Use it: three proposed lines), train (02's
// Use it) and project (the Line fitter project: train, pick η, save w_line, b_line, eta). The points and line are
// shared with the Loss landscape through the tool state "ai-line".
import { useEffect, useRef, useState } from "react";
import { flag, num, str, type SceneProps } from "../../../scenes";
import { fx, path, Read, SaveRow, Scene, Slider, useSvgDrag } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { reduceMotion } from "../../../../app/transition";
import { bestLine, etaLimit, lineStep, lineText, mseOf } from "../maths";
import { Btn, Btns, lin } from "./common";

type Pt = [number, number];
const W = 360, H = 260, X0 = 30, X1 = 248, Y0 = 14, Y1 = 236;
const sx = lin(-0.5, 5, X0, X1), sy = lin(-2, 7, Y1, Y0), ux = lin(X0, X1, -0.5, 5), uy = lin(Y1, Y0, -2, 7);
const PY = (Y1 - Y0) / 9;
const parsePts = (s: string): Pt[] => s.split(";").map(q => q.split(",").map(Number) as Pt).filter(p => p.length === 2 && p.every(Number.isFinite));
const PROPOSED: [string, number, number][] = [["A", 1, 1], ["B", 0.5, 2], ["C", 0.8, 1.2]];
const DEFAULT_PTS = "0,1;1,3;2,2;3,5;4,4";

export function FitterScene({ props, place }: SceneProps) {
  const mode = str<string>(props, "mode", place === "tool" ? "project" : "drag");
  const quiet = flag(props, "quiet"), project = flag(props, "project") || place === "project";
  const { b2, save, note, tool, setToolState } = useB2();
  const shared = tool<{ pts?: Pt[]; w?: number; b?: number } | null>("ai-line", null);
  const fromProps = typeof props.pts === "string";
  const [pts, setPts] = useState<Pt[]>(() => (fromProps ? parsePts(props.pts as string) : shared?.pts ?? parsePts(DEFAULT_PTS)));
  const [w, setW] = useState(() => (fromProps || shared?.w == null ? num(props, "w", 0.5) : shared.w));
  const [b, setB] = useState(() => (fromProps || shared?.b == null ? num(props, "b", 1) : shared.b));
  const [eta, setEta] = useState(num(props, "eta", 0.05));
  const [hist, setHist] = useState<number[]>([]);
  const [run, setRun] = useState(false);
  const [pick, setPick] = useState(0);
  const { ref, drag } = useSvgDrag();
  const trains = mode === "train" || mode === "project";

  // keep the line for the Loss landscape when the picture closes
  const latest = useRef({ pts, w, b });
  latest.current = { pts, w, b };
  useEffect(() => () => { if (mode !== "compare") setToolState("ai-line", latest.current); }, []); // eslint-disable-line react-hooks/exhaustive-deps

  // training: one gradient step on (w, b) every frame while it runs
  useEffect(() => {
    if (!run) return;
    const t = setInterval(() => {
      const L = latest.current;
      const [nw, nb] = lineStep(L.pts, L.w, L.b, eta);
      const bad = !Number.isFinite(nw) || Math.abs(nw) > 1e4;
      setW(bad ? L.w : nw); setB(bad ? L.b : nb);
      setHist(h => [...h, mseOf(L.pts, L.w, L.b)].slice(-80));
      if (bad) setRun(false);
    }, reduceMotion() ? 120 : 60);
    return () => clearInterval(t);
  }, [run, eta]);
  const step = () => { setHist(h => [...h, mseOf(pts, w, b)].slice(-80)); const [nw, nb] = lineStep(pts, w, b, eta); if (Number.isFinite(nw)) { setW(nw); setB(nb); } };

  const lines: { w: number; b: number; cls: string; name?: string }[] = mode === "compare"
    ? [{ w: 2, b: -2, cls: "pink", name: "A" }, { w: 1, b: 0, cls: "mint", name: "B" }]
    : mode === "score" ? [{ w: PROPOSED[pick]![1], b: PROPOSED[pick]![2], cls: "pink", name: PROPOSED[pick]![0] }]
      : [{ w, b, cls: "pink" }];
  const loss = mseOf(pts, lines[0]!.w, lines[0]!.b);
  const end = (L: { w: number; b: number }) => [[-0.5, L.w * -0.5 + L.b], [5, L.w * 5 + L.b]] as Pt[];

  const squares = (L: { w: number; b: number; cls: string }, k: number) => pts.map(([x, y], i) => {
    const r = y - (L.w * x + L.b), s = Math.abs(r) * PY, left = k === 1;
    return <rect key={`${k}-${i}`} x={left ? sx(x) - s : sx(x)} y={Math.min(sy(y), sy(L.w * x + L.b))} width={Math.min(s, 120)} height={s}
      className={`aisq${L.cls === "mint" ? " b" : ""}`} />;
  });
  // the handles: the line's points at x = 0 and x = 4
  const handle = (hx: number) => (
    <g key={hx}>
      <circle cx={sx(hx)} cy={sy(w * hx + b)} r="7" className="b2handle" />
      <circle cx={sx(hx)} cy={sy(w * hx + b)} r="20" className="b2hit" {...drag((_, py) => {
        const yv = Math.max(-2, Math.min(7, uy(py))), other = hx === 0 ? 4 : 0, oy = w * other + b;
        const nw = hx === 0 ? (oy - yv) / 4 : (yv - oy) / 4;
        setW(nw); setB(hx === 0 ? yv : oy);
      })} />
    </g>
  );
  const movable = mode === "drag" || mode === "score" || mode === "project";
  const lossMax = 12, barH = (v: number) => Math.min(1, v / lossMax) * (Y1 - Y0 - 20);
  const lossA = mseOf(pts, 2, -2), lossB = mseOf(pts, 1, 0);

  const svg = (
    <svg ref={ref} viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img"
      aria-label={quiet ? `${pts.length} points and two lines, A and B.` : `${pts.length} points and the line y = ${fx(lines[0]!.w)}x + ${fx(lines[0]!.b)}. Mean squared error ${fx(loss)}.`}>
      {[0, 1, 2, 3, 4].map(x => <line key={x} x1={sx(x)} y1={Y0} x2={sx(x)} y2={Y1} className="b2grid" />)}
      {[0, 2, 4, 6].map(y => <line key={y} x1={X0} y1={sy(y)} x2={X1} y2={sy(y)} className="b2grid" />)}
      <line x1={X0} y1={sy(0)} x2={X1} y2={sy(0)} className="b2axis" />
      <line x1={sx(0)} y1={Y0} x2={sx(0)} y2={Y1} className="b2axis" />
      {!quiet && lines.map((L, k) => squares(L, k))}
      {lines.map((L, k) => <path key={k} d={path(end(L).map(([x, y]) => [sx(x), sy(y)]))} className={`b2curve ${L.cls}`} />)}
      {mode === "compare" && <>
        <text x={sx(4.2)} y={sy(2 * 4.2 - 2) + 16} className="b2t pink">A</text>
        <text x={sx(4.6)} y={sy(4.6) + 18} className="b2t mint">B</text>
      </>}
      {pts.map(([x, y], i) => (
        <g key={i}>
          <circle cx={sx(x)} cy={sy(y)} r="6" className="aidot c0" />
          {movable && <circle cx={sx(x)} cy={sy(y)} r="18" className="b2hit" {...drag((px, py) => setPts(ps => ps.map((p, j) => (j === i ? [Math.round(Math.max(-0.5, Math.min(5, ux(px))) * 10) / 10, Math.round(Math.max(-2, Math.min(7, uy(py))) * 10) / 10] : p))))} />}
        </g>
      ))}
      {(mode === "drag" || mode === "project") && [0, 4].map(handle)}
      {/* the loss: a bar, or two stacked bars for the guess, and the curve over the training steps */}
      <g transform="translate(262,0)">
        {mode === "compare" ? <>
          {!quiet && <>
            <rect x="8" y={Y1 - barH(lossA * 3) * 0.5} width="30" height={barH(lossA * 3) * 0.5} rx="4" className="b2bar pink" />
            <rect x="52" y={Y1 - barH(lossB * 3) * 0.5} width="30" height={barH(lossB * 3) * 0.5} rx="4" className="b2bar mint" />
            <text x="23" y={Y1 - barH(lossA * 3) * 0.5 - 6} textAnchor="middle" className="b2t pink">{fx(lossA * 3, 0)}</text>
            <text x="67" y={Y1 - barH(lossB * 3) * 0.5 - 6} textAnchor="middle" className="b2t mint">{fx(lossB * 3, 0)}</text>
          </>}
          <text x="23" y={Y1 + 16} textAnchor="middle" className="b2t">A</text>
          <text x="67" y={Y1 + 16} textAnchor="middle" className="b2t">B</text>
        </> : <>
          <rect x="4" y={Y1 - barH(loss)} width="20" height={Math.max(1, barH(loss))} rx="4" className="b2bar pink" />
          <text x="14" y={Y1 + 16} textAnchor="middle" className="b2t">loss</text>
          {trains && hist.length > 1 && (() => {
            const m = Math.max(...hist, 0.01), cx = lin(0, Math.max(20, hist.length - 1), 34, 94), cy = lin(0, m, Y1, Y0 + 20);
            return <><path d={path(hist.map((v, i) => [cx(i), cy(v)]))} className="b2curve pink" /><text x="64" y={Y1 + 16} textAnchor="middle" className="b2t">steps</text></>;
          })()}
        </>}
      </g>
    </svg>
  );

  const [bw, bb] = bestLine(pts), limit = etaLimit(pts);
  const savedFit = typeof b2.shelf.w_line?.value === "number" && Math.abs((b2.shelf.w_line.value as number) - w) < 1e-9 && b2.shelf.eta?.value === eta;
  const onSaveFit = () => {
    save("w_line", w, "ai-fitter", { note: "the fitted line's slope" });
    save("b_line", b, "ai-fitter", { note: "the fitted line's intercept" });
    save("eta", eta, "ai-fitter", { note: `learning rate; this data settles below ${fx(limit, 3)}` });
    note({ id: "ai-fitter", track: "ai", title: "Line fitter", project: "ai-fitter", data: { w, b, eta },
      lines: [`${pts.length} points; the line y = ${fx(w)}x + ${fx(b)}, loss ${fx(loss, 3)}.`, `η = ${eta}; on these points it settles for η below ${fx(limit, 3)}.`] });
  };
  const losses = PROPOSED.map(([, pw, pb]) => mseOf(pts, pw, pb)), best = losses.indexOf(Math.min(...losses));
  const savedMse = b2.shelf.mse_line?.value === losses[best];

  return (
    <Scene svg={svg}
      controls={<>
        {mode === "score" && <Btns>{PROPOSED.map(([n], k) => <Btn key={n} on={pick === k} onClick={() => setPick(k)}>Line {n}</Btn>)}</Btns>}
        {trains && <Slider label="Learning rate η" value={eta} min={0.005} max={0.2} step={0.005} onChange={v => { setEta(v); setHist([]); }} format={v => v.toFixed(3)} />}
        {trains && <Btns>
          <Btn on={!run} onClick={() => setRun(r => !r)}>{run ? "Pause" : "Train"}</Btn>
          <Btn onClick={step} disabled={run}>Step</Btn>
          <Btn onClick={() => { setRun(false); setW(-1); setB(0); setHist([]); }}>Reset the line</Btn>
        </Btns>}
      </>}
      readouts={mode === "compare" ? (quiet ? <Read label="Lines" value="A and B" /> : <>
        <Read label="A's squares" value="9 + 0 + 0 = 9" tone="pink" /><Read label="B's squares" value="1 + 1 + 1 = 3" tone="mint" />
      </>) : <>
        {mode === "score" ? PROPOSED.map(([n, pw, pb], k) => <Read key={n} label={`Line ${n}: ${lineText(pw, pb)}`} value={fx(losses[k]!, 3)} tone={k === pick ? "pink" : undefined} />)
          : <><Read label="Line" value={`y = ${fx(w)}x ${b < 0 ? "−" : "+"} ${fx(Math.abs(b))}`} /><Read label="Mean squared error" value={fx(loss, 3)} tone="pink" big /></>}
        {trains && <Read label="Bottom of the bowl" value={`y = ${fx(bw)}x ${bb < 0 ? "−" : "+"} ${fx(Math.abs(bb))}`} />}
        {mode === "project" && <Read label="Settles for η below" value={fx(limit, 3)} />}
      </>}
      foot={mode === "score" && flag(props, "save") ? <SaveRow what={<>Keep the best, <b>mse_line = {fx(losses[best]!, 3)}</b> (line {PROPOSED[best]![0]})</>} saved={savedMse}
        onSave={() => save("mse_line", losses[best]!, "b2-ai-01", { note: `the loss of line ${PROPOSED[best]![0]} on your points` })} />
        : project ? <SaveRow what={<>Keep <b>w_line, b_line</b> and <b>eta = {eta}</b></>} saved={savedFit} onSave={onSaveFit} /> : undefined}
    />
  );
}
