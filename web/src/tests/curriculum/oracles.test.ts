import { describe, expect, it } from "vitest";
import { LESSONS } from "../../curriculum/registry";
import { createRng } from "../../curriculum/generators/rng";

/**
 * Every lesson's final answer, worked out again from the problem's own numbers in plain code, without the lesson's
 * answer model. If a generator and its answers ever drift apart, this catches it. Ported from the Curriculum team's
 * tools/oracles.cjs; each new lesson arrives with its line here.
 */

/* eslint-disable @typescript-eslint/no-explicit-any */
type P = any;
type Oracle = (p: P) => any[];
const gcd = (a: number, b: number) => { a = Math.abs(a); b = Math.abs(b); while (b) [a, b] = [b, a % b]; return a; };
const r2 = (x: number) => Math.round(x * 1000) / 1000;
const simp = (n: number, dd: number): [number, number] => { const g = gcd(n, dd); n /= g; dd /= g; if (dd < 0) { n = -n; dd = -dd; } return [n, dd]; };
const mixed = (n: number, dd: number): (number | null)[] => { [n, dd] = simp(n, dd); const w = Math.floor(n / dd); return w ? [w, n - w * dd, dd] : [null, n, dd]; };

const ORACLES: Record<string, Oracle> = {

 "k-count20":p=>[p.n],"k-tens":p=>[p.rows*10],"k-teens":p=>[10+p.ones],
 "k-add":p=>[p.a+p.b],"k-sub":p=>[p.a-p.b],"k-make10":p=>[10-p.have],
 "k-story":p=>[p.take?p.a-p.b:p.a+p.b],
 "k-write":p=>[String(p.n)],"k-bonds":p=>[p.whole-p.part],"k-solids":p=>[["Cube","Sphere","Cylinder","Cone"][p.shape]],
 "k-sort":p=>{const v=p.ask?Math.min(...p.counts):Math.max(...p.counts);return [[["Buttons","Leaves","Blocks"],["Circles","Squares","Triangles"]][p.by]![(p.counts.indexOf(v)+p.theme)%3]]},
 "g1-tensones":p=>[p.n],"g1-tenmore":p=>[p.more?p.n+10:p.n-10],"g1-ten":p=>[p.a+p.b],"g1-add20":p=>[p.a+p.b],"g1-three":p=>[p.a+p.b+p.c],"g1-tally":p=>{const c=p.counts;return [[c[p.x],c[p.x]-c[p.y],c[0]+c[1]+c[2]][p.ask]]},"g1-picgraph":p=>{const c=p.counts,v=p.few?Math.min(...c):Math.max(...c);return [[c[p.x],[["Apples","Bananas","Grapes"],["Dogs","Cats","Fish"],["Sunny","Rainy","Cloudy"],["Crackers","Popcorn","Pretzels"]][p.theme]![c.indexOf(v)],c[p.x]-c[p.y],c[p.x]+c[p.y]][p.ask]]},"g1-sub20":p=>[p.a-p.b],
 "g1-missing":p=>[p.c-p.a],"g1-addtens":p=>[p.n+p.k*10],"g1-time":p=>[p.hour,p.minute],
 "g2-estimate":p=>[`${p.len} ${p.unit?(p.len===1?"centimeter":"centimeters"):(p.len===1?"inch":"inches")}`,p.len],"g2-coins":p=>p.kind===0?[[1,5,10,25][p.coin]!]:[[1,5,10,25][p.coin]!>[1,5,10,25][p.other]!?"Left":"Right"],"g2-lineplot":p=>{const d:number[]=p.data,c=(v:number)=>d.filter(u=>u===v).length;const m=[...new Set(d)].sort((a,b)=>c(b)-c(a))[0];return [[c(p.v)+1,m,d.filter((u:number)=>u>p.v).length,Math.max(...d)-Math.min(...d)][p.ask]]},"g2-solids":p=>[["Cube","Rectangular prism","Pyramid","Triangular prism"][p.solid],[6,6,5,5][p.solid]],"g2-shares":p=>[["Halves","Thirds","Fourths"][p.parts-2],p.shaded],
 "g2-hundreds":p=>[Math.floor(p.n/100)*100,Math.floor(p.n/10)%10*10,p.n%10],"g2-skip":p=>[p.start+5*p.by],
 "g2-evenodd":p=>[p.n%2?"Odd":"Even"],"g2-regroup":p=>[p.a+p.b],"g2-subregroup":p=>[p.a-p.b],"g2-within1000":p=>[p.sub?p.a-p.b:p.a+p.b],
 "g2-money":p=>[25*p.q+10*p.d+5*p.n+p.p],"g2-time5":p=>[p.h,p.m],"g2-measure":p=>[p.end-p.start],"g2-arrays":p=>[p.rows*p.cols],
 "g3-mass":p=>{const T=[["paper clip",0,1],["grape",0,5],["coin",0,5],["pencil",0,10],["key",0,20],["dog",1,30],["bag of flour",1,2],["watermelon",1,5],["bike",1,15],["backpack",1,5]] as const;if(p.kind===0){const [,kg,v]=T[p.thing]!;return [kg?"Kilograms":"Grams",kg?`${v} kg`:`${v} g`]}if(p.kind===1)return [p.value];return [[p.a+p.b,p.a-p.b,p.a*p.b,p.a/p.b][p.op]]},
 "g3-liters":p=>p.kind===0?[p.value]:[[p.a+p.b,p.a-p.b,p.a*p.b,p.a/p.b][p.op]],
 "g3-graphs":p=>{const c=p.counts;return [[c[p.x],c[p.x]-c[p.y],c[p.x]+c[p.y]][p.ask]]},
 "g3-lineplot":p=>{if(p.kind===0){const [n,d]=simp(p.to===2?1:p.quarters,p.to);return [p.whole,n,d]}const d:number[]=p.data,c=(v:number)=>d.filter(u=>u===v).length;if(p.ask===0)return [c(p.v)];const m=[...new Set(d)].sort((a,b)=>c(b)-c(a))[0]!;const w=Math.floor(m/4),r=m%4,g=gcd(r,4);return [`${r?`${w?`${w} `:""}${r/g}/${4/g}`:String(w)} in`]},
 "g3-quads":p=>[p.also?(p.shape===0?"Yes":"No"):["Square","Rectangle","Rhombus","Parallelogram","Trapezoid","Quadrilateral"][p.shape]],
 "g3-split":p=>[p.a*p.b],"g3-facts":p=>[p.a*p.b],"g3-divfacts":p=>[p.a/p.b],"g3-mult10":p=>[p.a*p.t],
 "g3-round":p=>[Math.round(p.n/p.to)*p.to],"g3-addsub":p=>[p.s>0?p.a+p.b:p.a-p.b],"g3-unitfrac":p=>[p.k,p.b],"g3-fracline":p=>[p.a,p.b],
 "g3-fraccompare":p=>[p.a/p.b<p.c/p.d?"<":p.a/p.b>p.c/p.d?">":"="],"g3-area":p=>[p.l*p.w],
 "g3-elapsed":p=>{const m=p.end-p.start;return [Math.floor(m/60),m%60]},
 "g4-mult2x2":p=>[p.a*p.b],
 "g4-lineplot":p=>{const d:number[]=p.data,c=(v:number)=>d.filter(u=>u===v).length;const m=(v:number)=>{const [n,dd]=simp(v%p.d,p.d);return [Math.floor(v/p.d),n,dd]};if(p.ask===0)return m(Math.max(...d)-Math.min(...d));if(p.ask===1)return m(c(p.v)*p.v);return [d.filter(u=>u>p.v).length]},
 "g4-lines":p=>[p.kind===0?["Line","Ray","Segment"][p.item]:p.kind===1?(p.deg<90?"Acute":p.deg===90?"Right":p.deg<180?"Obtuse":"Straight"):["Parallel","Perpendicular","Intersecting"][p.item]],
 "g4-symmetry":p=>{const L=[4,2,3,1,0,6,0,1,1,5][p.shape]!;return [p.kind===0?(p.line<L?"Yes":"No"):L]},
 "g4-placevalue":p=>[Math.round(p.n/p.place)*p.place],"g4-addsub":p=>[p.sub?p.a-p.b:p.a+p.b],"g4-partial":p=>[p.n*p.m],
 "g4-divide":p=>[p.q,p.r],"g4-equiv":p=>[p.a*p.k],"g4-likefrac":p=>[p.a+p.c,p.d],
 "g4-fraccompare":p=>[p.a/p.b<p.c/p.d?"<":p.a/p.b>p.c/p.d?">":"="],
 "g4-mixed":p=>{const n=p.n1+p.n2;return [p.w1+p.w2+Math.floor(n/p.d),n%p.d]},
 "g4-dec":p=>[r2(p.a/10+p.b/100)],"g4-area":p=>[p.l*p.w,2*(p.l+p.w)],"g4-angles":p=>[(p.st?180:90)-p.a],
 "g5-mult2":p=>[p.firstFactor*p.secondFactor],"g5-divide":p=>[p.n/p.dv],"g5-pow10":p=>[r2(p.x*10**p.k)],
 "g5-adddec":p=>[r2(p.a+p.b)],"g5-multdec":p=>[Math.round(p.A*p.B/10**((p.pa??1)+(p.pb??1))*1e6)/1e6],"g5-divdec":p=>[p.qt],
 add:p=>mixed(p.a*p.d+p.c*p.b,p.b*p.d), sub:p=>mixed(p.a*p.d-p.c*p.b,p.b*p.d),
 mix:p=>p.op==="+"?mixed(p.a*p.d+p.c*p.b,p.b*p.d):mixed(p.a*p.d-p.c*p.b,p.b*p.d),
 "g5-multfrac":p=>mixed(p.a*p.c,p.b*p.d),"g5-improper":p=>[p.w*p.d+p.n,p.d],"g5-fracof":p=>[p.W*p.n/p.d],"g5-unitdiv":p=>[p.W*p.d],
 "g5-volume":p=>[p.l*p.w*p.h],"g5-units":p=>[p.up?p.n/p.u[3]:p.n*p.u[3]],
 "g6-ratio":p=>[p.a*p.k],"g6-rate":p=>[p.u*p.m],"g6-pctof":p=>[p.p*p.W/100],"g6-pctwhole":p=>[p.P*100/p.p],
 "g6-divide":p=>{const m=mixed(p.a*p.d,p.b*p.c);return m[1]===0?[m[0],null,null]:m},"g6-lcm":p=>[p.a*p.b/gcd(p.a,p.b)],"g6-numline":p=>[Math.abs(p.b-p.a)],
 "g6-expo":p=>[p.a**p.n+p.b*p.c],"g6-eval":p=>[p.a*p.x+p.b*p.y],"g6-tri":p=>[p.b*p.h/2],"g6-trap":p=>[(p.a+p.b)*p.h/2],
 "g6-mean":p=>[p.v.reduce((a:number,b:number)=>a+b)/p.v.length],
 "g7-prop":p=>[p.a*p.k],"g7-scale":p=>[p.km*p.g],"g7-discount":p=>[r2(p.off?p.P*(1-p.p/100):p.P*(1+p.p/100))],"g7-pctchange":p=>[p.p],
 "g7-addint":p=>[p.a+p.b],"g7-subint":p=>[p.a-p.b],"g7-mulint":p=>[p.div?p.a:p.a*p.b],"g7-eq":p=>[(p.c-p.b)/p.a],
 "g7-distribute":p=>[p.a+p.c,p.a*p.b],"g7-circum":p=>[r2(2*3.14*p.r)],"g7-circarea":p=>[r2(3.14*p.r*p.r)],"g7-angles":p=>[(p.sup?180:90)-p.a],
 "g8-roots":p=>[p.n],"g8-both":p=>[(p.d-p.b)/(p.a-p.c)],"g8-system":p=>[p.s/(1+p.k),p.k*p.s/(1+p.k)],
 "g8-slope":p=>[(p.y2-p.y1)/(p.x2-p.x1)],"g8-intercept":p=>[p.m,p.y0-p.m*p.x0],"g8-func":p=>[p.a*p.x+p.b],
 "g8-pyth":p=>[Math.hypot(p.a,p.b)],"g8-leg":p=>[Math.sqrt(p.c**2-p.a**2)],"g8-cyl":p=>[r2(3.14*p.r**2*p.h)],"g8-cone":p=>[r2(3.14*p.r**2*p.h/3)],
 "g8-translate":p=>[p.x+p.dx,p.y+p.dy],"g8-tri":p=>[180-p.a-p.b],
 "g9-multistep":p=>[p.c/p.a-p.b],"g9-elim":p=>[(p.sum+p.difference)/2,(p.sum-p.difference)/2],
 "g9-twopoint":p=>{const m=(p.y2-p.y1)/(p.x2-p.x1);return [m,p.y1-m*p.x1]},"g9-negexp":p=>[1,p.a**p.n],"g9-growth":p=>[p.P*p.r**p.t],
 "g9-foil":p=>[p.a+p.b,p.a*p.b],"g9-gcf":p=>[p.m,p.n],"g9-median":p=>{const v=[...p.v].sort((a:number,b:number)=>a-b);return [v[(v.length-1)/2]]},
 "g9-quadform":p=>{const D=p.b*p.b-4*p.c;return [(-p.b+Math.sqrt(D))/2,(-p.b-Math.sqrt(D))/2]},
 "g10-mid":p=>[(p.x1+p.x2)/2,(p.y1+p.y2)/2],"g10-perp":p=>{const [n,dd]=simp(-p.r,p.p);return [n,dd]},"g10-dist":p=>[Math.hypot(p.x2-p.x1,p.y2-p.y1)],
 "g10-polygon":p=>[180*(p.n-2)/p.n],"g10-exterior":p=>[p.a+p.b],"g10-similar":p=>[p.b*p.k],
 "g10-sector":p=>[r2(p.t/360*3.14*p.r**2)],"g10-arc":p=>[r2(p.t/360*2*3.14*p.r)],"g10-surface":p=>[2*(p.l*p.w+p.l*p.h+p.w*p.h)],
 "g10-pyramid":p=>[p.s*p.s*p.h/3],"g11-seq":p=>[p.a1+(p.n-1)*p.d],"g11-geo":p=>[p.a*p.r**(p.n-1)],
 "g11-log":p=>[p.m+p.k],"g11-ratexp":p=>[Math.round(p.base**(p.m/p.n))],"g11-evalpoly":p=>[p.a*p.k**2+p.b*p.k+p.c],
 "g11-compose":p=>[p.a*(p.c*p.k+p.d)+p.b],"g11-radical":p=>[p.b*p.b-p.a],"g11-complex":p=>[p.a*p.c-p.b*p.d,p.a*p.d+p.b*p.c],
 "g11-comb":p=>{let r=1;for(let i=0;i<p.k;i++)r=r*(p.n-i)/(i+1);return [r]},
 "g12-deg":p=>[180*p.n/p.d],"g12-rad":p=>simp(p.t,180),"g12-power":p=>[p.a*p.n,p.n-1],"g12-chain":p=>[p.n*p.a],
 "g12-tangent":p=>[2*p.a*p.k+p.b],"g12-anti":p=>[p.n+1,p.a/(p.n+1)],"g12-defint":p=>[p.a*(p.k**(p.n+1)-(p.j??0)**(p.n+1))/(p.n+1)],
 "g12-series":p=>{const last=p.a+(p.n-1)*p.d;return [p.n*(p.a+last)/2]},"g12-vecmag":p=>[Math.hypot(p.x,p.y)],"g12-dot":p=>[p.a*p.c+p.b*p.d],
 "k-compare":p=>[p.top>p.bottom?"More than":p.top<p.bottom?"Less than":"The same as"],
 "g4-factors":p=>{let c=0;for(let i=1;i<=p.n;i++)if(p.n%i==0)c++;return [c]},
 "g4-deccompare":p=>{const x=p.w+p.a/100,y=p.w+p.b/100;return [x<y?"<":x>y?">":"="]},
 "g5-order":p=>[[p.a+p.b*(p.c-p.d),(p.a+p.b)*p.c-p.d,p.a*p.b-p.c/p.d][p.t]],
 "g5-round":p=>[Math.round(p.N/10**(3-p.p))/10**p.p],"g6-gcf":p=>[p.m,p.n],"g8-sci":p=>[p.c/10,p.e],
 "g9-radical":p=>[p.k,p.m],"g9-factor":p=>[p.p,p.qn],"g10-circle":p=>[p.h,p.k,p.r],"g11-expeq":p=>[p.x],"g11-inverse":p=>[p.x],
 "g11-vertex":p=>[p.h,p.a*p.h*p.h+p.b*p.h+p.c],"g11-synth":p=>p.e?[p.b+p.r,p.e]:[p.b+p.r],"g8-exp":p=>[p.t==0?p.a+p.b:p.t==1?p.a+p.b-p.b:p.exponent],
 "g9-polyadd":p=>p.sub?[p.a-p.d,p.b-p.e,p.c-p.f]:[p.a+p.d,p.b+p.e,p.c+p.f],
 "g10-trig":p=>{const opp=p.a,adj=p.b,h=p.c;const [x,y]=({sin:[opp,h],cos:[adj,h],tan:[opp,adj]} as Record<string,[number,number]>)[p.f]!;return simp(x,y)},
 "g7-prob":p=>simp([p.r,p.b,p.g][p.c],p.r+p.b+p.g),
 "g12-limit":p=>[p.a+p.b],"g12-polyd":p=>[3*p.a+2*p.b+p.c],

 "g1-compare":p=>[p.a<p.b?"< less than":p.a>p.b?"> greater than":"= equal to"],
 "g6-onestep":p=>[p.x],
 "g4-fracwhole":p=>{const m=mixed(p.n*p.W,p.d);return m[1]===0?[m[0],null,null]:m},
 "g9-solvefactor":p=>[p.p,p.r],
 "g4-convert":p=>[p.n*[12,100,60,16][p.k]!+p.m],
 "g3-twostep":p=>[[p.a*p.b-p.c,p.a*p.b+p.c,(p.a-p.c)/p.b][p.kind]],
 "g12-unit":p=>{const v=(p.f==="sin"?Math.sin:Math.cos)(p.t*Math.PI/180);return [Math.round(2*v),2]},
 // picture and choice lessons: the label a child taps, or the count they type
 "k-shapes":p=>[["Circle","Triangle","Square","Rectangle","Hexagon"][p.shape]],
 "k-length":p=>{const T=["pencil","crayon","ribbon","spoon","snake","straw"];return [p.a>p.b?`The ${T[p.top]}`:p.a<p.b?`The ${T[p.bottom]}`:"Same length"]},
 "g1-measure":p=>[Math.abs(p.a-p.b)],"g1-halves":p=>[p.shaded],
 "g2-bargraph":p=>{const v=[p.v0,p.v1,p.v2,p.v3];return [p.kind?v[p.x]+v[p.y]:v[p.x]-v[p.y]]},
 "g3-perim":p=>[[2*(p.a+p.b),4*p.a,p.a+p.b+p.c][p.kind]],"g10-special":p=>[p.s,p.t===45?2:3],
};

const PER_LESSON = 200;
const norm = (xs: unknown[]) => xs.map(x => typeof x === "number" ? r2(x) : x);

describe("every final answer matches the problem's own numbers", () => {
  for (const lesson of LESSONS) {
    const oracle = ORACLES[lesson.id];
    it.skipIf(!oracle)(lesson.id, () => {
      const rng = createRng(29);
      const bad: string[] = [];
      for (let i = 0; i < PER_LESSON; i++) {
        const p = lesson.generate(rng, i % 10), m = lesson.answers(p);
        const got = norm(m.finalParts.flatMap(k => { const s = m.steps[(k + m.steps.length) % m.steps.length]!; return s.slots.map(x => s.choices && x.expected != null ? s.choices[x.expected as number] : x.expected); }));
        const want = norm(oracle!(p));
        if (lesson.id === "g9-quadform") { want.sort(); got.sort(); }
        if (JSON.stringify(want) !== JSON.stringify(got) && bad.length < 3) bad.push(`${JSON.stringify(p).slice(0, 90)} want ${JSON.stringify(want)} got ${JSON.stringify(got)}`);
      }
      expect(bad).toEqual([]);
    });
  }
  it("every lesson has an oracle", () => {
    expect(LESSONS.map(l => l.id).filter(id => !ORACLES[id])).toEqual([]);
  });
});
