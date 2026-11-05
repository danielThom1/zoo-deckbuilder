// Rendu local minimal des fichiers .dc.html (holes, sc-for, sc-if, dc-import, helmet).
(function () {
  class DCLogic { constructor(props) { this.props = props || {}; this.state = {}; } setState(s) { Object.assign(this.state, s); } forceUpdate() {} }
  const cache = {};
  function load(name) {
    if (cache[name]) return cache[name];
    const x = new XMLHttpRequest();
    x.open('GET', name + '.dc.html', false); x.send();
    const doc = new DOMParser().parseFromString(x.responseText, 'text/html');
    return (cache[name] = parse(doc));
  }
  function parse(doc) {
    const xdc = doc.querySelector('x-dc');
    const sc = doc.querySelector('script[data-dc-script]');
    let Comp = null, meta = {};
    if (sc) {
      Comp = new Function('DCLogic', sc.textContent + '\n;return Component;')(DCLogic);
      try { meta = JSON.parse(sc.getAttribute('data-props') || '{}'); } catch (e) {}
    }
    return { xdc, Comp, meta };
  }
  function lookup(path, scope) {
    path = path.trim();
    if (path === 'true') return true; if (path === 'false') return false;
    if (/^-?\d+(\.\d+)?$/.test(path)) return Number(path);
    let v = scope;
    for (const k of path.split('.')) { if (v == null) return ''; v = v[k]; }
    return v == null ? '' : v;
  }
  const HOLE = /\{\{([^}]+)\}\}/g;
  function interp(s, scope) { return s.replace(HOLE, (_, p) => { const v = lookup(p, scope); return typeof v === 'function' ? '' : String(v); }); }
  function whole(s, scope) { const m = s.match(/^\s*\{\{([^}]+)\}\}\s*$/); return m ? lookup(m[1], scope) : interp(s, scope); }
  const helmetDone = new Set();
  function helmet(node) {
    const key = node.innerHTML;
    if (helmetDone.has(key)) return; helmetDone.add(key);
    for (const c of Array.from(node.children)) {
      if (c.tagName === 'LINK' && /fonts\.googleapis/.test(c.getAttribute('href') || '')) continue;
      if (c.tagName === 'LINK' && c.getAttribute('rel') === 'preconnect') continue;
      document.head.appendChild(c.cloneNode(true));
    }
  }
  function renderChildren(src, out, scope) { for (const n of Array.from(src.childNodes)) renderNode(n, out, scope); }
  function renderNode(n, out, scope) {
    if (n.nodeType === 3) { out.appendChild(document.createTextNode(interp(n.textContent, scope))); return; }
    if (n.nodeType !== 1) return;
    const tag = n.tagName.toLowerCase();
    if (tag === 'helmet') { helmet(n); return; }
    if (tag === 'sc-for') {
      const list = whole(n.getAttribute('list') || '', scope) || [];
      const as = n.getAttribute('as') || 'item';
      list.forEach((it, i) => renderChildren(n, out, Object.assign({}, scope, { [as]: it, $index: i })));
      return;
    }
    if (tag === 'sc-if') { if (whole(n.getAttribute('value') || '', scope)) renderChildren(n, out, scope); return; }
    if (tag === 'dc-import') {
      const name = n.getAttribute('name');
      const props = {};
      for (const a of Array.from(n.attributes)) {
        if (a.name === 'name' || a.name.startsWith('hint-')) continue;
        const k = a.name.replace(/-([a-z])/g, (_, c) => c.toUpperCase());
        props[k] = whole(a.value, scope);
      }
      const box = document.createElement('div');
      mount(load(name), box, props);
      while (box.firstChild) out.appendChild(box.firstChild);
      return;
    }
    const el = document.createElementNS(n.namespaceURI, n.localName);
    for (const a of Array.from(n.attributes)) {
      if (/^on[A-Z]/.test(a.name) || /^on[a-z]+$/.test(a.name)) continue;
      el.setAttribute(a.name, interp(a.value, scope));
    }
    renderChildren(n, el, scope);
    out.appendChild(el);
  }
  function mount(def, target, props) {
    const p = Object.assign({}, props);
    const inst = def.Comp ? new def.Comp(p) : { renderVals: () => ({}) };
    const vals = inst.renderVals ? inst.renderVals() : {};
    renderChildren(def.xdc, target, vals);
  }
  document.addEventListener('DOMContentLoaded', () => {
    const l = document.createElement('link'); l.rel = 'stylesheet'; l.href = '/fonts/fonts.css'; document.head.appendChild(l);
    const def = parse(document);
    const host = document.createElement('div');
    def.xdc.parentNode.insertBefore(host, def.xdc);
    def.xdc.style.display = 'none';
    mount(def, host, {});
    def.xdc.remove();
    document.fonts.ready.then(() => { window.__rendu = true; });
  });
})();
