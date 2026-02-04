import { readdirSync, statSync, utimesSync, unlinkSync } from 'node:fs';
import { resolve, dirname, extname, basename } from 'node:path';
import sharp from 'sharp';

const ROOT = resolve(dirname(new URL(import.meta.url).pathname), '..');
const STAGE_VERSIONS = resolve(ROOT, 'stage', 'versions');

function parseArgs() {
  const args = process.argv.slice(2);
  let quality = 55;   // default AVIF quality
  let effort = 4;     // speed/quality tradeoff
  let force = false;  // overwrite existing targets
  let verbose = false;// detailed logging
  for (let i = 0; i < args.length; i++) {
    const a = args[i];
    if ((a === '--quality' || a === '-q') && args[i + 1]) quality = Number(args[++i]);
    else if ((a === '--effort' || a === '-E') && args[i + 1]) effort = Number(args[++i]);
    else if (a === '--force' || a === '-f') force = true;
    else if (a === '--verbose' || a === '-v') verbose = true;
  }
  return { quality, effort, force, verbose };
}

const IMAGE_INPUT_EXTS = new Set(['.png', '.jpg', '.jpeg']);

function listDirs(dir) {
  return readdirSync(dir, { withFileTypes: true }).filter(d => d.isDirectory()).map(d => resolve(dir, d.name));
}

function exists(p) {
  try { statSync(p); return true; } catch { return false; }
}

async function convertAvif(src, dstPath, opts, resizeTo) {
  const srcStat = statSync(src);
  await sharp(src)
    .resize(resizeTo ?? null) // keep original if resizeTo is undefined
    .avif({ quality: opts.quality, effort: opts.effort })
    .toFile(dstPath);
  utimesSync(dstPath, srcStat.atime, srcStat.mtime);
}

async function processImage(src, dir, opts, counters) {
  const name = basename(src);
  const m = name.match(/^(.*)\.2x\.(png|jpg|jpeg)$/i);
  let meta;
  try {
    meta = await sharp(src).metadata();
  } catch (e) {
    console.error(`Failed to read metadata ${src}: ${e.message}`);
    return;
  }
  const origW = meta.width ?? 0;
  const origH = meta.height ?? 0;

  const targets = [];
  if (m) {
    const base = m[1];
    const w2 = Math.max(1, origW);
    const h2 = Math.max(1, origH);
    const w1 = Math.max(1, Math.floor(w2 * 0.5));
    const h1 = Math.max(1, Math.floor(h2 * 0.5));
    targets.push({ path: resolve(dir, `${base}.2x.avif`), size: { width: w2, height: h2 } });
    targets.push({ path: resolve(dir, `${base}.1x.avif`), size: { width: w1, height: h1 } });
  } else {
    const base = name.replace(/\.[^.]+$/, '');
    targets.push({ path: resolve(dir, `${base}.avif`), size: undefined });
  }

  // force cleanup existing .avif if requested
  if (opts.force) {
    for (const t of targets) {
      if (exists(t.path)) {
        try {
          unlinkSync(t.path);
          if (opts.verbose) console.log(`  cleanup: removed ${basename(t.path)}`);
        } catch (e) {
          console.error(`  cleanup: failed to remove ${t.path}: ${e.message}`);
        }
      }
    }
  }

  for (const t of targets) {
    counters.total++;
    if (exists(t.path) && !opts.force) {
      counters.skipped++;
      if (opts.verbose) console.log(`  ${name} → ${basename(t.path)} [SKIP]`);
      continue;
    }
    try {
      await convertAvif(src, t.path, opts, t.size);
      counters.converted++;
      if (opts.verbose) console.log(`  ${name} → ${basename(t.path)} [CREATE${opts.force ? '/FORCE' : ''}]`);
    } catch (e) {
      console.error(`  Failed to convert ${src} → ${t.path}: ${e.message}`);
    }
  }
}

async function run(opts) {
  if (!exists(STAGE_VERSIONS)) {
    console.log(`Папка отсутствует: ${STAGE_VERSIONS} — пропуск`);
    return;
  }

  const versionDirs = listDirs(STAGE_VERSIONS);
  let counters = { total: 0, converted: 0, skipped: 0 };

  for (const vdir of versionDirs) {
    const entries = readdirSync(vdir, { withFileTypes: true });
    if (opts.verbose) console.log(`[stage] Версия: ${vdir.replace(STAGE_VERSIONS + '/', '')}`);

    for (const e of entries) {
      if (!e.isFile()) continue;
      const src = resolve(vdir, e.name);
      const ext = extname(src).toLowerCase();
      if (!IMAGE_INPUT_EXTS.has(ext)) continue;
      await processImage(src, vdir, opts, counters);
    }
  }

  console.log(`[stage] Всего целей: ${counters.total}, создано: ${counters.converted}, пропущено: ${counters.skipped}`);
}

async function main() {
  const opts = parseArgs();
  await run(opts);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
