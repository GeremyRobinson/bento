// A surface in 3D as a hairline wireframe, turned with one finger: Grapher 3D's z = f(x, y), and the gravity well's
// z = −1/r. Points can sit on it, each with an optional ring that pulses (a clock's ticks).
import { useRef, useState, type ReactNode } from "react";
import { path } from "./kit";

export interface SurfacePoint { x: number; y: number; z: number; cls: string; r?: number; label?: string; ring?: number }

export function Surface3D({ f, polar, domain, rmin = 0, zscale = 1, points = [], label, yaw0 = 0.6, pitch0 = 0.55, children, zclip = Infinity }: {
  f?: (x: number, y: number) => number; polar?: (r: number) => number; domain: number; rmin?: number; zscale?: number;
  points?: SurfacePoint[]; label: string; yaw0?: number; pitch0?: number; children?: ReactNode; zclip?: number;
}) {
  const W = 360, H = 260;
  const [yaw, setYaw] = useState(yaw0), [pitch, setPitch] = useState(pitch0);
  const last = useRef<{ x: number; y: number } | null>(null);
  const s = 130 / domain, cx = W / 2, cy = H / 2 - 10;
  const P = (x: number, y: number, z: number): [number, number] => {
    const zz = Math.max(-zclip, Math.min(zclip, z)) * zscale;
    const X = x * Math.cos(yaw) - y * Math.sin(yaw), Y = x * Math.sin(yaw) + y * Math.cos(yaw);
    return [cx + X * s, cy + Y * s * Math.sin(pitch) - zz * s * Math.cos(pitch)];
  };
  const lines: string[] = [];
  const N = 24;
  if (polar) {
    for (let k = 0; k <= 10; k++) {
      const r = rmin + ((domain - rmin) * k) / 10, z = polar(r);
      const pts: [number, number][] = [];
      for (let i = 0; i <= 64; i++) { const a = (2 * Math.PI * i) / 64; pts.push(P(r * Math.cos(a), r * Math.sin(a), z)); }
      lines.push(path(pts));
    }
    for (let i = 0; i < 24; i++) {
      const a = (2 * Math.PI * i) / 24, pts: [number, number][] = [];
      for (let k = 0; k <= 40; k++) { const r = rmin + ((domain - rmin) * k) / 40; pts.push(P(r * Math.cos(a), r * Math.sin(a), polar(r))); }
      lines.push(path(pts));
    }
  } else if (f) {
    for (let i = 0; i <= N; i++) {
      const u = -domain + (2 * domain * i) / N, a: [number, number][] = [], b: [number, number][] = [];
      for (let j = 0; j <= 48; j++) {
        const v = -domain + (2 * domain * j) / 48;
        const z1 = f(u, v), z2 = f(v, u);
        if (Number.isFinite(z1)) a.push(P(u, v, z1));
        if (Number.isFinite(z2)) b.push(P(v, u, z2));
      }
      if (a.length > 1) lines.push(path(a));
      if (b.length > 1) lines.push(path(b));
    }
  }
  const at = points.map(p => P(p.x, p.y, p.z));
  const onDown = (e: React.PointerEvent<SVGSVGElement>) => { (e.target as Element).setPointerCapture?.(e.pointerId); last.current = { x: e.clientX, y: e.clientY }; };
  const onMove = (e: React.PointerEvent<SVGSVGElement>) => {
    if (!last.current) return;
    const dx = e.clientX - last.current.x, dy = e.clientY - last.current.y;
    last.current = { x: e.clientX, y: e.clientY };
    setYaw(y => y + dx * 0.01);
    setPitch(p => Math.max(0.08, Math.min(1.5, p + dy * 0.008)));
  };
  return (
    <svg viewBox={`0 0 ${W} ${H}`} className="b2pic s3" role="img" aria-label={`${label} Drag to turn it.`}
      onPointerDown={onDown} onPointerMove={onMove} onPointerUp={() => (last.current = null)} onPointerCancel={() => (last.current = null)}>
      <g className="b2wire">{lines.map((d, i) => <path key={i} d={d} />)}</g>
      {points.map((p, i) => {
        const [x, y] = at[i]!;
        // a label that would run into another point's label (that one sits to its right, at about its height) reads
        // to the left of its dot instead
        const left = !!p.label && points.some((q, j) => {
          if (j === i || !q.label) return false;
          const [qx, qy] = at[j]!, dx = qx - x;
          return Math.abs(qy - y) < 34 && dx < 170 && (dx > 2 || (Math.abs(dx) <= 2 && j > i));
        });
        return (
          <g key={i}>
            {p.ring != null && <circle cx={x} cy={y} r={(p.r ?? 6) + p.ring * 16} className={`b2ring ${p.cls}`} opacity={1 - p.ring} />}
            <circle cx={x} cy={y} r={p.r ?? 6} className={`b2dot ${p.cls}`} />
            {p.label && <text x={left ? x - 10 : x + 10} y={y - 8} textAnchor={left ? "end" : undefined} className={`b2t ${p.cls}`}>{p.label}</text>}
          </g>
        );
      })}
      {children}
    </svg>
  );
}
