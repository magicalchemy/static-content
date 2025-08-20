import { readdirSync, statSync, renameSync, readFileSync, writeFileSync } from 'node:fs';
import { resolve, basename, dirname, extname, join } from 'node:path';

const ROOT = resolve(dirname(new URL(import.meta.url).pathname), '..');
const STAGE = resolve(ROOT, 'stage');
const ARTICLES = resolve(STAGE, 'articles');
const TOC = resolve(STAGE, 'toc.json');

// Transliteration map (RU -> latin) matching bash script
const tr = new Map(Object.entries({
  'А': 'A','а': 'a','Б': 'B','б': 'b','В': 'V','в': 'v','Г': 'G','г': 'g','Д': 'D','д': 'd',
  'Е': 'E','е': 'e','Ё': 'E','ё': 'e','Ж': 'Zh','ж': 'zh','З': 'Z','з': 'z','И': 'I','и': 'i',
  'Й': 'Y','й': 'y','К': 'K','к': 'k','Л': 'L','л': 'l','М': 'M','м': 'm','Н': 'N','н': 'n',
  'О': 'O','о': 'o','П': 'P','п': 'p','Р': 'R','р': 'r','С': 'S','с': 's','Т': 'T','т': 't',
  'У': 'U','у': 'u','Ф': 'F','ф': 'f','Х': 'Kh','х': 'kh','Ц': 'Ts','ц': 'ts','Ч': 'Ch','ч': 'ch',
  'Ш': 'Sh','ш': 'sh','Щ': 'Shch','щ': 'shch','Ъ': '','ъ': '','Ы': 'Y','ы': 'y','Ь': '','ь': '',
  'Э': 'E','э': 'e','Ю': 'Yu','ю': 'yu','Я': 'Ya','я': 'ya'
}));

function transliterate(str) {
  let out = '';
  for (const ch of str) out += tr.get(ch) ?? ch;
  return out;
}

function slugify(raw) {
  const t = transliterate(raw);
  let s = t.toLowerCase();
  s = s.replace(/[^a-z0-9]+/g, '_');
  s = s.replace(/_+/g, '_');
  s = s.replace(/^_+|_+$/g, '');
  return s;
}

function normalizeName(name) {
  if (name.endsWith('_ru.md') || name.endsWith('_en.md')) {
    const base = name.replace(/_(ru|en)\.md$/i, '');
    const lang = name.slice(name.lastIndexOf('_') + 1); // ru.md or en.md
    return `${slugify(base)}_${lang.toLowerCase()}`;
  }
  if (name.includes('.')) {
    const dot = name.lastIndexOf('.');
    const stem = name.slice(0, dot);
    const ext = name.slice(dot + 1).toLowerCase();
    return `${slugify(stem)}.${ext}`;
  }
  return slugify(name);
}

function uniqueTemp(dst) {
  let tmp = `${dst}__tmp__`;
  let i = 2;
  while (exists(tmp)) {
    tmp = `${dst}__tmp__${i++}`;
  }
  return tmp;
}

function exists(p) {
  try { statSync(p); return true; } catch { return false; }
}

function safeRename(src, dst) {
  if (src === dst) return dst;
  const dir = dirname(dst);
  const base = basename(dst);
  let finalDst = dst;
  if (exists(dst)) finalDst = join(dir, `${base}_2`);
  const tmp = uniqueTemp(finalDst);
  renameSync(src, tmp);
  renameSync(tmp, finalDst);
  return finalDst;
}

function normalizeArticles() {
  const mappings = []; // only for .md files: [oldAbs, newAbs]

  // Top-level article directories
  const dirs = readdirSync(ARTICLES, { withFileTypes: true })
    .filter(d => d.isDirectory())
    .map(d => resolve(ARTICLES, d.name));

  for (let dir of dirs) {
    const dname = basename(dir);
    const ndir = normalizeName(dname);
    let dstDir = resolve(ARTICLES, ndir);
    if (dir !== dstDir) {
      dstDir = safeRename(dir, dstDir);
      dir = dstDir;
    }

    // Files inside directory (non-recursive)
    const files = readdirSync(dir, { withFileTypes: true })
      .filter(f => f.isFile())
      .map(f => resolve(dir, f.name));

    for (const f of files) {
      const fname = basename(f);
      const nfname = normalizeName(fname);
      const dstf = resolve(dir, nfname);
      if (f !== dstf) {
        const wasMd = fname.toLowerCase().endsWith('.md');
        const oldAbs = f;
        const newAbs = safeRename(f, dstf);
        if (wasMd) mappings.push([oldAbs, newAbs]);
      }
    }
  }

  return mappings;
}

function updateToc(mappings) {
  if (!exists(TOC)) return;
  let tocRaw = readFileSync(TOC, 'utf8');
  for (const [oldAbs, newAbs] of mappings) {
    // convert to toc-relative by stripping prefix up to stage/
    const oldRel = oldAbs.replace(/^[\s\S]*\/src\/game-lore-library\/stage\//, '');
    const newRel = newAbs.replace(/^[\s\S]*\/src\/game-lore-library\/stage\//, '');
    // escape for regex
    const oldEsc = oldRel.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    tocRaw = tocRaw.replace(new RegExp(oldEsc, 'g'), newRel);
  }
  writeFileSync(TOC, tocRaw, 'utf8');
}

function main() {
  if (!exists(ARTICLES)) {
    console.error(`Not found: ${ARTICLES}`);
    process.exit(1);
  }
  const mappings = normalizeArticles();
  if (mappings.length) {
    updateToc(mappings);
    console.log(`Renamed markdown files: ${mappings.length}`);
  } else {
    console.log('No markdown renames recorded; toc.json left unchanged');
  }
}

main();
