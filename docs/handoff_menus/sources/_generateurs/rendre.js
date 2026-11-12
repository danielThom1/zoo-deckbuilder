// Rend chaque maquette en PNG 1600 × 900, et sa vérification 1280 × 720 (échelle 0,8 comme canvas_items + expand).
// node rendre.js <dossier_html> <sortie> [fichiers...]
const { chromium } = require('playwright');
const fs = require('fs'), path = require('path');
(async () => {
  const [src, out, ...noms] = process.argv.slice(2);
  const fichiers = noms.length ? noms : fs.readdirSync(src).filter(f => f.endsWith('.html'));
  fs.mkdirSync(path.join(out, '1280'), { recursive: true });
  const b = await chromium.launch();
  for (const f of fichiers) {
    const n = f.replace('.html', '');
    for (const [w, h, z, dest] of [[1600, 900, 1, path.join(out, n + '.png')], [1280, 720, 0.8, path.join(out, '1280', n + '.png')]]) {
      const p = await b.newPage({ viewport: { width: w, height: h } });
      await p.goto('file://' + path.resolve(src, f));
      if (z !== 1) await p.evaluate(z => { document.body.style.zoom = z; }, z);
      await p.evaluate(() => document.fonts.ready);
      await p.waitForTimeout(250);
      if (z === 1) {
        // contrôle : plus petit corps de texte visible et débordements
        const r = await p.evaluate(() => {
          let min = 99, quoi = '';
          for (const el of document.querySelectorAll('body *')) {
            const t = [...el.childNodes].some(c => c.nodeType === 3 && c.textContent.trim());
            if (!t) continue;
            const s = parseFloat(getComputedStyle(el).fontSize);
            if (s < min) { min = s; quoi = el.textContent.trim().slice(0, 30); }
          }
          const e = document.querySelector('.ecran');
          return { min, quoi, deb: e.scrollWidth > 1600 || e.scrollHeight > 900 };
        });
        console.log(n, 'corps min', r.min, JSON.stringify(r.quoi), r.deb ? 'DÉBORDE' : '');
      }
      await p.screenshot({ path: dest });
      await p.close();
    }
  }
  await b.close();
})();
