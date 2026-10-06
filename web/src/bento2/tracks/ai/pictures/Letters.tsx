// The Next-letter machine (project after 12): type or paste text, train a one-block letter model on its first 90%,
// a pass at a time, and watch two curves: bits per letter on the text it trains on, and on the last 10% it never sees.
// When the second curve turns up, the model is memorizing. Samples at temperatures 0.5, 1 and 1.5 show what it learned.
import { useEffect, useRef, useState } from "react";
import { flag, type SceneProps } from "../../../scenes";
import { fx, path, Read, SaveRow, Scene } from "../../../ui/kit";
import { useB2 } from "../../../ui/useB2";
import { seeded } from "../digits";
import { bitsPerLetter, letterEpoch, letterParams, newLetterModel, sample, splitText, START_TEXT, type LetterModel } from "../letters";
import { Btn, Btns, lin } from "./common";

export const LETTER_ETA = 0.1;
export interface LetterPass { pass: number; train: number; held: number }

const kept = new Map<string, { m: LetterModel; passes: LetterPass[] }>();

/**
 * A letter model for `text`, trained one pass per tick while `run` is on (up to `upto` passes). The model and its
 * passes are kept per text, so the transformer picture and the project share the paragraph's run.
 */
export function useLetterModel(text: string, run: boolean, upto = 60) {
  const make = () => kept.get(text) ?? { m: newLetterModel(text, 11), passes: [] as LetterPass[] };
  const [st, setSt] = useState(make);
  const rng = useRef(seeded(5));
  useEffect(() => { const s = make(); setSt(s); rng.current = seeded(5 + s.passes.length); }, [text]); // eslint-disable-line react-hooks/exhaustive-deps
  useEffect(() => {
    if (!run || text.length < 40) return;
    let stop = false;
    const tick = () => {
      if (stop) return;
      const s = kept.get(text) ?? st;
      if (s.passes.length >= upto) return;
      const { train, held } = splitText(text);
      const t = letterEpoch(s.m, train, LETTER_ETA, rng.current);
      const next = { m: s.m, passes: [...s.passes, { pass: s.passes.length + 1, train: t, held: bitsPerLetter(s.m, held, train) }] };
      kept.set(text, next); setSt(next);
      timer = setTimeout(tick, 16);
    };
    let timer = setTimeout(tick, 16);
    return () => { stop = true; clearTimeout(timer); };
  }, [run, text, upto]); // eslint-disable-line react-hooks/exhaustive-deps
  const reset = () => { kept.delete(text); rng.current = seeded(5); setSt({ m: newLetterModel(text, 11), passes: [] }); };
  return { model: st.m, passes: st.passes, reset };
}

export function LettersScene({ props, place }: SceneProps) {
  const project = flag(props, "project") || place === "project";
  const [draft, setDraft] = useState(START_TEXT);
  const [text, setText] = useState(START_TEXT);
  const [run, setRun] = useState(false);
  const { model, passes, reset } = useLetterModel(text, run);
  const { b2, save, note } = useB2();
  const last = passes.at(-1);
  useEffect(() => { if (passes.length >= 60) setRun(false); }, [passes.length]);
  const best = passes.length ? passes.reduce((a, b) => (b.held < a.held ? b : a)) : null;
  const W = 360, H = 200, sx = lin(0, Math.max(20, passes.length), 40, 340), sy = lin(0, 6, 170, 20);
  const curve = (k: "train" | "held") => path(passes.map(p => [sx(p.pass), sy(Math.min(6, p[k]))]));
  const svg = (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic" role="img" aria-label={last ? `After ${last.pass} passes: ${fx(last.train)} bits per letter on the training text, ${fx(last.held)} on the held-back text.` : "Bits per letter, before training."}>
      <line x1="40" y1="170" x2="340" y2="170" className="b2axis" />
      <line x1="40" y1="170" x2="40" y2="20" className="b2axis" />
      {[0, 2, 4, 6].map(b => <text key={b} x="32" y={sy(b) + 4} textAnchor="end" className="b2t">{b}</text>)}
      <text x="44" y="16" className="b2t">bits per letter</text>
      <text x="340" y="190" textAnchor="end" className="b2t">passes</text>
      {/* a random guess among the letters it knows */}
      <line x1="40" y1={sy(Math.log2(model.vocab.length))} x2="340" y2={sy(Math.log2(model.vocab.length))} className="aidiag" />
      <text x="338" y={sy(Math.log2(model.vocab.length)) - 5} textAnchor="end" className="b2t">guessing among {model.vocab.length} letters</text>
      {passes.length > 1 && <path d={curve("train")} className="b2curve sky" />}
      {passes.length > 1 && <path d={curve("held")} className="b2curve pink" />}
      {best && passes.length > 3 && <circle cx={sx(best.pass)} cy={sy(best.held)} r="5" className="b2dot pink" />}
      {last && <>
        <text x={sx(last.pass) - 4} y={sy(last.train) + 16} textAnchor="end" className="b2t sky">training text</text>
        <text x={sx(last.pass) - 4} y={sy(last.held) - 8} textAnchor="end" className="b2t pink">held back</text>
      </>}
    </svg>
  );
  const samples = passes.length ? [0.5, 1, 1.5].map(T => ({ T, s: sample(model, text.slice(0, 8), 70, T, 3) })) : [];
  const summary = [model.vocab.length, letterParams(model.vocab.length), passes.length];
  const bpl = best ? Math.round(best.held * 100) / 100 : null;
  const saved = bpl != null && b2.shelf.bits_per_letter?.value === bpl;
  const onSave = () => {
    if (!best || bpl == null) return;
    save("letters_model", summary, "ai-letters", { labels: ["letters", "numbers", "passes"], note: `a one-block letter model trained on ${text.length} characters` });
    save("bits_per_letter", bpl, "ai-letters", { unit: "bits", note: `on the held-back 10%, best at pass ${best.pass}; perplexity ${fx(2 ** bpl, 1)}` });
    note({ id: "ai-letters", track: "ai", title: "Next-letter machine", project: "ai-letters", data: { passes: passes.length, bits: bpl, letters: model.vocab.length },
      lines: [`Trained on ${text.length - Math.floor(text.length * 0.1)} characters, ${letterParams(model.vocab.length)} numbers.`, `Held-back text: ${fx(bpl)} bits per letter at pass ${best.pass}, a perplexity of ${fx(2 ** bpl, 1)}.`, ...samples.map(s => `T = ${s.T}: "${s.s}"`)] });
  };
  return (
    <Scene svg={svg}
      controls={<>
        <textarea className="aitext" value={draft} aria-label="Text to learn" onChange={e => setDraft(e.currentTarget.value)} />
        <Btns>
          {draft !== text && <Btn on onClick={() => { setRun(false); setText(draft); }}>Use this text</Btn>}
          <Btn on={!run && draft === text} onClick={() => setRun(r => !r)} disabled={text.length < 40}>{run ? "Pause" : passes.length ? "Keep training" : "Train"}</Btn>
          <Btn onClick={() => { setRun(false); reset(); }}>Start over</Btn>
        </Btns>
        {samples.length > 0 && <div className="aisample">{samples.map(s => <span key={s.T}><small>T = {s.T}</small>{s.s}</span>)}</div>}
      </>}
      readouts={<>
        <Read label="Passes" value={String(passes.length)} />
        <Read label="Training text" value={last ? `${fx(last.train)} bits` : "?"} tone="sky" />
        <Read label="Held back" value={last ? `${fx(last.held)} bits` : "?"} tone="pink" big />
        <Read label="Perplexity" value={last ? fx(2 ** last.held, 1) : "?"} />
      </>}
      foot={project && best ? <SaveRow what={<>Keep its best held-back score, <b>{fx(best.held)} bits per letter</b> (pass {best.pass})</>} saved={saved} onSave={onSave} /> : undefined}
    />
  );
}
