import { readdirSync, statSync, utimesSync, mkdirSync, writeFileSync } from 'node:fs';
import { resolve, dirname, extname, basename } from 'node:path';
import sharp from 'sharp';

const ROOT = resolve(dirname(new URL(import.meta.url).pathname), '..');

function parseArgs() {
  const args = process.argv.slice(2);
  let env = 'stage'; // default to stage to match legacy script
  let quality = 55;  // sensible default
  let effort = 4;    // speed/quality tradeoff
  let force = false; // overwrite existing targets
  let verbose = false; // detailed logging
  for (let i = 0; i < args.length; i++) {
    const a = args[i];
    if ((a === '--env' || a === '-e') && args[i + 1]) env = args[++i];
    else if ((a === '--quality' || a === '-q') && args[i + 1]) quality = Number(args[++i]);
    else if ((a === '--effort' || a === '-E') && args[i + 1]) effort = Number(args[++i]);
    else if (a === '--force' || a === '-f') force = true;
    else if (a === '--verbose' || a === '-v') verbose = true;
  }
  let envs;
  if (env === 'both') envs = ['stage', 'production'];
  else if (env === 'stage' || env === 'production') envs = [env];
  else {
    console.error("Ошибка: окружение должно быть 'stage', 'production' или 'both'.");
    process.exit(1);
  }
  return { envs, quality, effort, force, verbose };
}

const IMAGE_INPUT_EXTS = new Set(['.png', '.jpg', '.jpeg']);

// Resolutions and scales to match legacy script behavior
const RESOLUTIONS = [
  { suffix: 'desktop', scale: 1 },   // base
  { suffix: 'mobile',  scale: 0.55 },
];

function listDirs(dir) {
  return readdirSync(dir, { withFileTypes: true }).filter(d => d.isDirectory()).map(d => resolve(dir, d.name));
}

function exists(p) {
  try { statSync(p); return true; } catch { return false; }
}

async function convertOne(srcPath, dstPath, opts) {
  const srcStat = statSync(srcPath);
  let dstStat = null;
  try { dstStat = statSync(dstPath); } catch {}
  if (dstStat) return { skipped: true, reason: 'exists' };

  await sharp(srcPath).avif({ quality: opts.quality, effort: opts.effort }).toFile(dstPath);
  // Preserve mtime close to src for stable diffs
  utimesSync(dstPath, srcStat.atime, srcStat.mtime);
  return { skipped: false };
}

async function runForEnv(env, opts) {
  const envRoot = resolve(ROOT, env);
  const articlesRoot = resolve(envRoot, 'articles');
  if (!exists(articlesRoot)) {
    console.log(`[${env}] Папка отсутствует: ${articlesRoot} — пропуск`);
    return;
  }
  if (opts.verbose) {
    console.log(`[${env}] Старт конвертации: quality=${opts.quality}, effort=${opts.effort}, force=${Boolean(opts.force)}`);
  }
  const articleDirs = listDirs(articlesRoot);

  let total = 0;
  let converted = 0;
  let skipped = 0;

  for (const adir of articleDirs) {
    const imagesDir = resolve(adir, 'images');
    // process only if images dir exists
    try { statSync(imagesDir); } catch { continue; }
    if (opts.verbose) {
      console.log(`  [${env}] Статья: ${adir.replace(envRoot + '/', '')}`);
    }
    const entries = readdirSync(imagesDir, { withFileTypes: true });
    for (const e of entries) {
      if (!e.isFile()) continue;
      const src = resolve(imagesDir, e.name);
      const ext = extname(src).toLowerCase();
      if (!IMAGE_INPUT_EXTS.has(ext)) continue;
      // match *.2x.(png|jpg|jpeg)
      const name = basename(src);
      const m = name.match(/^(.*)\.2x\.(png|jpg|jpeg)$/i);
      if (!m) continue;

      // derive base (without .2x.ext)
      const base = m[1];
      // read original size once
      let meta;
      try {
        meta = await sharp(src).metadata();
      } catch (e) {
        console.error(`Failed to read metadata ${src}: ${e.message}`);
        continue;
      }
      const origW = meta.width ?? 0;
      const origH = meta.height ?? 0;

      for (const r of RESOLUTIONS) {
        // 2x target sizes
        const w2 = Math.max(1, Math.floor(origW * r.scale));
        const h2 = Math.max(1, Math.floor(origH * r.scale));
        // 1x is half of 2x
        const w1 = Math.max(1, Math.floor(w2 * 0.5));
        const h1 = Math.max(1, Math.floor(h2 * 0.5));

        // build targets
        const mobilePart = r.suffix === 'mobile' ? '.mobile' : '';
        const dst2 = resolve(imagesDir, `${base}${mobilePart}.2x.avif`);
        const dst1 = resolve(imagesDir, `${base}${mobilePart}.1x.avif`);

        // count and convert
        total += 2;
        try {
          const existed2 = exists(dst2);
          const existed1 = exists(dst1);
          // 2x
          if (existed2 && !opts.force) {
            if (opts.verbose) console.log(`    ${basename(src)} → ${basename(dst2)} [SKIP]`);
            skipped++;
          } else {
            await sharp(src).resize({ width: w2, height: h2, fit: 'fill' }).avif({ quality: opts.quality, effort: opts.effort }).toFile(dst2);
            const srcStat = statSync(src);
            utimesSync(dst2, srcStat.atime, srcStat.mtime);
            if (opts.verbose) console.log(`    ${basename(src)} → ${basename(dst2)} [${existed2 ? 'FORCE' : 'CREATE'}]`);
            converted++;
          }
          // 1x
          if (existed1 && !opts.force) {
            if (opts.verbose) console.log(`    ${basename(src)} → ${basename(dst1)} [SKIP]`);
            skipped++;
          } else {
            await sharp(src).resize({ width: w1, height: h1, fit: 'fill' }).avif({ quality: opts.quality, effort: opts.effort }).toFile(dst1);
            const srcStat = statSync(src);
            utimesSync(dst1, srcStat.atime, srcStat.mtime);
            if (opts.verbose) console.log(`    ${basename(src)} → ${basename(dst1)} [${existed1 ? 'FORCE' : 'CREATE'}]`);
            converted++;
          }
        } catch (e) {
          console.error(`Failed to convert ${src} (${r.suffix}): ${e.message}`);
        }
      }
    }
  }

  console.log(`[${env}] Всего целей: ${total}, создано: ${converted}, пропущено: ${skipped}`);
}

async function main() {
  const { envs, quality, effort, force, verbose } = parseArgs();
  for (const e of envs) {
    await runForEnv(e, { quality, effort, force, verbose });
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
