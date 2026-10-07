// In-page edge/outline audit. window.__ecAudit() -> {flags:[...]}
window.__ecAudit = function () {
  const T = c => !c || c === 'transparent' || /rgba\([^)]*,\s*0\)$/.test(c);
  const px = s => parseFloat(s) || 0;
  const desc = el => {
    let s = el.tagName.toLowerCase();
    const c = typeof el.className === 'string' ? el.className.trim().split(/\s+/).filter(Boolean).slice(0, 3).join('.') : '';
    if (c) s += '.' + c;
    const t = (el.getAttribute('aria-label') || el.textContent || '').trim().replace(/\s+/g, ' ').slice(0, 30);
    return s + (t ? ` "${t}"` : '');
  };
  const path = el => { const a = []; let e = el; for (let i = 0; e && i < 4 && e !== document.body; i++, e = e.parentElement) a.unshift(desc(e).split(' "')[0]); return a.join(' > '); };
  const effBg = el => { for (let e = el; e; e = e.parentElement) { const b = getComputedStyle(e).backgroundColor; if (!T(b)) return b; } return 'rgb(255,255,255)'; };
  // parse outer box-shadows: hard = spread+offset, soft = +blur
  const shadowExt = s => {
    const ext = { l: 0, r: 0, t: 0, b: 0, hl: 0, hr: 0, ht: 0, hb: 0 };
    if (!s || s === 'none') return null;
    const parts = s.split(/,(?![^()]*\))/);
    let any = false;
    for (const p of parts) {
      if (/inset/.test(p)) continue;
      const nums = p.replace(/[a-z-]+\((?:[^()]|\([^()]*\))*\)|#[0-9a-f]+/gi, '').match(/-?[\d.]+px|\b0\b/g) || [];
      const [x, y, blur, spread] = nums.map(px).concat([0, 0, 0, 0]);
      const col = (p.match(/[a-z-]+\((?:[^()]|\([^()]*\))*\)/i) || [''])[0];
      if (col && (/rgba\([^)]*,\s*0\)$/.test(col) || /\/\s*0\)$/.test(col))) continue;
      any = true;
      const sp = spread || 0, bl = blur || 0;
      ext.hl = Math.max(ext.hl, sp - x); ext.hr = Math.max(ext.hr, sp + x); ext.ht = Math.max(ext.ht, sp - y); ext.hb = Math.max(ext.hb, sp + y);
      ext.l = Math.max(ext.l, sp + bl - x); ext.r = Math.max(ext.r, sp + bl + x); ext.t = Math.max(ext.t, sp + bl - y); ext.b = Math.max(ext.b, sp + bl + y);
    }
    return any ? ext : null;
  };
  const vw = document.documentElement.clientWidth;
  const docW = document.documentElement.scrollWidth;
  const flags = []; let ecN = 0; const mark = e => { if (!e.dataset.ec) e.dataset.ec = 'e' + (++ecN) + '_' + Math.random().toString(36).slice(2, 6); return e.dataset.ec; };
  const all = [...document.body.querySelectorAll('*')].filter(e => !(e instanceof SVGElement) || e.tagName === 'svg');
  const decorated = [];
  for (const el of all) {
    const cs = getComputedStyle(el);
    if (cs.display === 'none' || cs.visibility === 'hidden' || +cs.opacity === 0) continue;
    const r = el.getBoundingClientRect();
    if (r.width < 4 || r.height < 4) continue;
    const bw = Math.max(px(cs.borderTopWidth), px(cs.borderRightWidth), px(cs.borderBottomWidth), px(cs.borderLeftWidth));
    const border = bw > 0 && !T(cs.borderTopColor) && cs.borderTopStyle !== 'none';
    const sh = shadowExt(cs.boxShadow);
    const outline = cs.outlineStyle !== 'none' && px(cs.outlineWidth) > 0 && !T(cs.outlineColor);
    const bg = !T(cs.backgroundColor) && cs.backgroundColor !== (el.parentElement ? effBg(el.parentElement) : '');
    const bgi = cs.backgroundImage !== 'none';
    if (!(border || sh || outline || bg || bgi)) continue;
    decorated.push({ el, cs, r, border, sh, outline, bg, bgi });
  }
  // (a) clipping by ancestors
  for (const d of decorated) {
    const { el, cs, r, sh } = d;
    const oo = d.outline ? px(cs.outlineWidth) + px(cs.outlineOffset) : 0;
    const hard = { l: Math.max(sh ? sh.hl : 0, oo), r: Math.max(sh ? sh.hr : 0, oo), t: Math.max(sh ? sh.ht : 0, oo), b: Math.max(sh ? sh.hb : 0, oo) };
    const soft = sh ? { l: sh.l, r: sh.r, t: sh.t, b: sh.b } : { l: 0, r: 0, t: 0, b: 0 };
    const fixed = cs.position === 'fixed';
    for (let a = el.parentElement; a && a !== document.documentElement; a = a.parentElement) {
      const as = getComputedStyle(a);
      if (as.maskImage && as.maskImage !== 'none' || as.webkitMaskImage && as.webkitMaskImage !== 'none') {
        const ar = a.getBoundingClientRect();
        flags.push({ id: mark(el), kind: 'mask', el: desc(el), anc: desc(a), mask: (as.maskImage || as.webkitMaskImage).slice(0, 120), rect: [r.x, r.y, r.width, r.height].map(Math.round), arect: [ar.x, ar.y, ar.width, ar.height].map(Math.round) });
      }
      if (fixed) { if (as.transform === 'none' && as.filter === 'none' && as.contain === 'none') continue; }
      const ox = as.overflowX, oy = as.overflowY;
      if (ox === 'visible' && oy === 'visible' && !/paint/.test(as.contain)) continue;
      const ar = a.getBoundingClientRect();
      const cl = ar.left + px(as.borderLeftWidth), ct = ar.top + px(as.borderTopWidth);
      const cw = a.clientWidth, ch = a.clientHeight;
      // content-space coords
      const sx = a.scrollLeft, sy = a.scrollTop;
      const limW = (ox === 'auto' || ox === 'scroll') ? Math.max(a.scrollWidth, cw) : cw;
      const limH = (oy === 'auto' || oy === 'scroll') ? Math.max(a.scrollHeight, ch) : ch;
      const offX = (ox === 'auto' || ox === 'scroll') ? sx : 0, offY = (oy === 'auto' || oy === 'scroll') ? sy : 0;
      const L = r.left - cl + offX, R = r.right - cl + offX, Tp = r.top - ct + offY, B = r.bottom - ct + offY;
      // element entirely outside → scrolled away / off-canvas, skip
      if (R < 0 || L > limW || B < 0 || Tp > limH) break;
      const cut = { l: -(L), r: R - limW, t: -(Tp), b: B - limH };
      const cutH = { l: hard.l - L, r: R + hard.r - limW, t: hard.t - Tp, b: B + hard.b - limH };
      const cutS = { l: soft.l - L, r: R + soft.r - limW, t: soft.t - Tp, b: B + soft.b - limH };
      const sides = (o, th) => Object.entries(o).filter(([, v]) => v > th).map(([k, v]) => k + ':' + v.toFixed(1)).join(' ');
      const box = sides(cut, 0.6), ring = sides(cutH, 0.6), blur = sides(cutS, 2);
      if (box || ring || blur) flags.push({ id: mark(el), kind: box ? 'box' : ring ? 'ring' : 'shadow', el: desc(el), path: path(el), anc: desc(a), ov: ox + '/' + oy,
        box, ring, blur, rect: [r.x + scrollX, r.y + scrollY, r.width, r.height].map(Math.round), arect: [ar.x + scrollX, ar.y + scrollY, ar.width, ar.height].map(Math.round), rad: cs.borderTopLeftRadius, shadow: cs.boxShadow.slice(0, 90), border: d.border ? cs.borderTopWidth + ' ' + cs.borderTopColor : '' });
      break; // nearest clipper only (outer ones usually page-level)
    }
    // viewport horizontal
    const vr = r.right + scrollX + hard.r;
    if (!fixed && vr > docW + 0.6 && r.left < vw) flags.push({ id: mark(el), kind: 'viewport', el: desc(el), path: path(el), over: (vr - docW).toFixed(1), rect: [r.x + scrollX, r.y + scrollY, r.width, r.height].map(Math.round) });
    if (r.left + scrollX - hard.l < -0.6 && r.right > 0) flags.push({ id: mark(el), kind: 'viewport', el: desc(el), path: path(el), over: 'left ' + (r.left - hard.l).toFixed(1), rect: [r.x + scrollX, r.y + scrollY, r.width, r.height].map(Math.round) });
  }
  // (b)/(c) inner fills vs rounded parents
  const inside = (x, y, R, rad) => { // is point inside rounded rect R with radii rad [tl,tr,br,bl]
    const corners = [[R.left + rad[0], R.top + rad[0], rad[0], x < R.left + rad[0] && y < R.top + rad[0]], [R.right - rad[1], R.top + rad[1], rad[1], x > R.right - rad[1] && y < R.top + rad[1]], [R.right - rad[2], R.bottom - rad[2], rad[2], x > R.right - rad[2] && y > R.bottom - rad[2]], [R.left + rad[3], R.bottom - rad[3], rad[3], x < R.left + rad[3] && y > R.bottom - rad[3]]];
    if (x < R.left - 0.01 || x > R.right + 0.01 || y < R.top - 0.01 || y > R.bottom + 0.01) return -1;
    for (const [cx, cy, rr, inC] of corners) if (inC && rr > 0) { const dd = Math.hypot(x - cx, y - cy) - rr; if (dd > 0) return -dd; }
    return 1;
  };
  const radii = (cs, r) => { const m = Math.min(r.width, r.height) / 2; return [cs.borderTopLeftRadius, cs.borderTopRightRadius, cs.borderBottomRightRadius, cs.borderBottomLeftRadius].map(v => Math.min(px(v), m)); };
  const seen = new Set();
  for (const P of decorated) {
    const prad = radii(P.cs, P.r); if (Math.max(...prad) < 4) continue;
    if (!(P.border || P.bg || P.sh)) continue;
    const pClips = P.cs.overflow !== 'visible';
    const bwp = px(P.cs.borderTopWidth);
    const PR = { left: P.r.left + bwp, top: P.r.top + bwp, right: P.r.right - bwp, bottom: P.r.bottom - bwp };
    const prIn = prad.map(v => Math.max(0, v - bwp));
    for (const C of decorated) {
      if (C === P || !P.el.contains(C.el)) continue;
      if (!(C.bg || C.border || C.bgi)) continue;
      const crad = radii(C.cs, C.r);
      const r = C.r;
      // sample corner arcs of child
      let worst = 0;
      const cr = [[r.left, r.top, 1, 1, crad[0]], [r.right, r.top, -1, 1, crad[1]], [r.right, r.bottom, -1, -1, crad[2]], [r.left, r.bottom, 1, -1, crad[3]]];
      for (const [x0, y0, sx, sy, rr] of cr) {
        for (let k = 0; k <= 8; k++) {
          const th = (Math.PI / 2) * k / 8;
          const x = x0 + sx * (rr - rr * Math.cos(th)), y = y0 + sy * (rr - rr * Math.sin(th));
          const v = inside(x, y, PR, prIn);
          if (v < 0) worst = Math.min(worst, v);
        }
      }
      if (worst < -0.75) {
        const k = 'poke|' + desc(C.el) + '|' + desc(P.el);
        if (!seen.has(k)) { seen.add(k); flags.push({ id: mark(C.el), kind: pClips ? 'poke-clipped' : 'poke', el: desc(C.el), path: path(C.el), anc: desc(P.el), out: (-worst).toFixed(1), crad: crad.map(Math.round).join('/'), prad: prad.map(Math.round).join('/'), rect: [r.x + scrollX, r.y + scrollY, r.width, r.height].map(Math.round), arect: [P.r.x + scrollX, P.r.y + scrollY, P.r.width, P.r.height].map(Math.round) }); }
        continue;
      }
      // concentric: child near a parent corner
      const ins = [r.left - PR.left, r.top - PR.top, PR.right - r.right, PR.bottom - r.bottom];
      const cornerIns = [[ins[0], ins[1]], [ins[2], ins[1]], [ins[2], ins[3]], [ins[0], ins[3]]];
      for (let i = 0; i < 4; i++) {
        const [dx, dy] = cornerIns[i]; const R0 = prIn[i];
        // (smoke copy) only a nested surface: a child nearly as wide as its parent, sitting inside the parent's corner
        if (R0 < 8 || dx >= R0 || dy >= R0 || dx < 0 || dy < 0 || r.width < (PR.right - PR.left) * 0.8) continue;
        const want = R0 - Math.min(dx, dy); const got = crad[i];
        if (Math.abs(want - got) > Math.max(4, want * 0.35)) {
          const k = 'conc|' + desc(C.el) + '|' + desc(P.el);
          if (!seen.has(k)) { seen.add(k); flags.push({ id: mark(C.el), kind: 'concentric', el: desc(C.el), path: path(C.el), anc: desc(P.el), corner: i, inset: [dx, dy].map(v => +v.toFixed(1)).join(','), want: +want.toFixed(1), got, prad: R0, rect: [r.x + scrollX, r.y + scrollY, r.width, r.height].map(Math.round) }); }
          break;
        }
      }
    }
  }
  // content cut: overflow hidden/clip boxes whose content overflows them
  for (const el of all) {
    const cs = getComputedStyle(el);
    if (!/hidden|clip/.test(cs.overflowX + cs.overflowY) || cs.textOverflow === 'ellipsis' || el === document.body) continue;
    const r = el.getBoundingClientRect(); if (r.width < 20 || r.height < 20) continue;
    const dh = el.scrollHeight - el.clientHeight, dw = el.scrollWidth - el.clientWidth;
    if (dh <= 2 && dw <= 2) continue;
    // any visible text node outside?
    const tw = document.createTreeWalker(el, NodeFilter.SHOW_TEXT); let cutTxt = '';
    while (tw.nextNode()) { const n = tw.currentNode; if (!n.textContent.trim()) continue; const rg = document.createRange(); rg.selectNodeContents(n); for (const q of rg.getClientRects()) { if (q.width < 1) continue; if (q.bottom > r.bottom + 1 || q.right > r.right + 1 || q.top < r.top - 1 || q.left < r.left - 1) { const pe = n.parentElement, ps = getComputedStyle(pe); if (ps.visibility !== 'hidden' && +ps.opacity > 0) cutTxt += n.textContent.trim().slice(0, 30) + ' | '; break; } } if (cutTxt.length > 90) break; }
    if (cutTxt) flags.push({ id: mark(el), kind: 'content-cut', el: desc(el), path: path(el), dh, dw, txt: cutTxt, rect: [r.x + scrollX, r.y + scrollY, r.width, r.height].map(Math.round) });
  }
  for (const d of decorated) {
    if (d.cs.overflowX !== 'visible' || d.cs.overflowY !== 'visible' || !(d.bg || d.sh || d.border)) continue;
    const el = d.el, r = d.r; if (r.width < 40 || r.height < 24) continue;
    const tw = document.createTreeWalker(el, NodeFilter.SHOW_TEXT); let t = '';
    while (tw.nextNode()) { const n = tw.currentNode; if (!n.textContent.trim()) continue; const pe = n.parentElement, ps = getComputedStyle(pe); if (ps.visibility === 'hidden' || +ps.opacity === 0 || ps.position === 'absolute' || ps.position === 'fixed') continue; const rg = document.createRange(); rg.selectNodeContents(n); for (const q of rg.getClientRects()) { if (q.width < 1) continue; if (q.bottom > r.bottom + 2 || q.right > r.right + 2) { t += n.textContent.trim().slice(0, 30) + ' | '; break; } } if (t.length > 90) break; }
    if (t) flags.push({ id: mark(el), kind: 'spill', el: desc(el), path: path(el), txt: t, rect: [r.x + scrollX, r.y + scrollY, r.width, r.height].map(Math.round) });
  }
  // inset outlines (outline-offset < 0) painting over content near the edge
  for (const d of decorated) {
    if (!d.outline) continue; const off = px(d.cs.outlineOffset); if (off >= 0) continue;
    const band = -off + 0.5, r = d.r, el = d.el; let hit = '';
    const near = q => q.width > 0.5 && q.height > 0.5 && (q.left < r.left + band || q.right > r.right - band || q.top < r.top + band || q.bottom > r.bottom - band) && q.right > r.left && q.left < r.right && q.bottom > r.top && q.top < r.bottom;
    const tw = document.createTreeWalker(el, NodeFilter.SHOW_TEXT);
    // (smoke copy) text inside a clipped, visually hidden parent is for screen readers and can't touch the outline
    const hidden = e => { for (let a = e; a && a !== el; a = a.parentElement) { const s = getComputedStyle(a); if (s.clipPath !== 'none' || (s.clip && s.clip !== 'auto') || a.matches('.vh,.visually-hidden,[aria-hidden=true]')) return true; } return false; };
    while (tw.nextNode()) { const n = tw.currentNode; if (!n.textContent.trim() || hidden(n.parentElement)) continue; const rg = document.createRange(); rg.selectNodeContents(n); if ([...rg.getClientRects()].some(near)) { hit += 'text"' + n.textContent.trim().slice(0, 20) + '" '; break; } }
    for (const c of el.querySelectorAll('svg,img,canvas,figure,*')) { if (c === el) continue; const cs2 = getComputedStyle(c); if (!(c.tagName === 'svg' || c.tagName === 'IMG' || !T(cs2.backgroundColor) || cs2.boxShadow !== 'none')) continue; if (cs2.position === 'absolute' && /fill|bar/.test(c.className)) continue; if (near(c.getBoundingClientRect())) { hit += desc(c).split(' "')[0] + ' '; break; } }
    if (hit) flags.push({ id: mark(el), kind: 'outline-over', el: desc(el), path: path(el), w: d.cs.outlineWidth, off: d.cs.outlineOffset, hit, rect: [r.x + scrollX, r.y + scrollY, r.width, r.height].map(Math.round) });
  }
  // shadows computed on screen (drop, text, filter)
  const shadows = [];
  for (const el of all) {
    const cs = getComputedStyle(el); if (cs.display === 'none' || cs.visibility === 'hidden') continue;
    const r = el.getBoundingClientRect(); if (r.width < 1 || r.height < 1) continue;
    const bs = cs.boxShadow, ts = cs.textShadow, fi = cs.filter;
    const parts = bs === 'none' ? [] : bs.split(/,(?![^()]*\))/);
    const drop = parts.filter(q => !/inset/.test(q) && !/\/\s*0\)|,\s*0\)/.test(q.match(/^[^)]*\)/)?.[0] || ''));
    const ins = parts.filter(q => /inset/.test(q));
    if (drop.length || (ts && ts !== 'none') || /drop-shadow/.test(fi)) shadows.push({ el: desc(el), path: path(el), drop: drop.join(',').slice(0, 120), text: ts !== 'none' ? ts.slice(0, 80) : '', filter: /drop-shadow/.test(fi) ? fi.slice(0, 80) : '' });
    else if (ins.length) shadows.push({ el: desc(el), inset: ins.join(',').slice(0, 120) });
  }
  return { flags, shadows, docW, vw, n: decorated.length };
};
