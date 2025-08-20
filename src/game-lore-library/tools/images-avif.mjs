import { readdirSync, statSync, utimesSync, mkdirSync, writeFileSync } from 'node:fs';
import { resolve, dirname, extname, basename } from 'node:path';
import sharp from 'sharp';

const ROOT = resolve(dirname(new URL(import.meta.url).pathname), '..');

function parseArgs() {
  const args = process.argv.slice(2);
  let env = 'both';
  let quality = 55; // sensible default
  let effort = 4;   // speed/quality tradeoff
  for (let i = 0; i < args.length; i++) {
    const a = args[i];
    if ((a === '--env' || a === '-e') && args[i + 1]) env = args[++i];
    else if ((a === '--quality' || a === '-q') && args[i + 1]) quality = Number(args[++i]);
    else if ((a === '--effort' || a === '-E') && args[i + 1]) effort = Number(args[++i]);
  }
  const envs = env === 'stage' ? ['stage'] : env === 'production' ? ['production'] : ['stage', 'production'];
  return { envs, quality, effort };
}

const IMAGE_INPUT_EXTS = new Set(['.png', '.jpg', '.jpeg', '.webp']);

function walk(dir, out) {
  const entries = readdirSync(dir, { withFileTypes: true });
  for (const e of entries) {
    const p = resolve(dir, e.name);
    if (e.isDirectory()) walk(p, out);
    else if (e.isFile()) out.push(p);
  }
}

async function convertOne(srcPath, dstPath, opts) {
  const srcStat = statSync(srcPath);
  let dstStat = null;
  try { dstStat = statSync(dstPath); } catch {}
  if (dstStat && dstStat.mtimeMs >= srcStat.mtimeMs) return { skipped: true, reason: 'up-to-date' };

  await sharp(srcPath)
    .avif({ quality: opts.quality, effort: opts.effort })
    .toFile(dstPath);
  // Preserve mtime close to src for stable diffs
  utimesSync(dstPath, srcStat.atime, srcStat.mtime);
  return { skipped: false };
}

async function runForEnv(env, opts) {
  const envRoot = resolve(ROOT, env);
  const files = [];
  walk(envRoot, files);
  let converted = 0;
  let skipped = 0;

  for (const f of files) {
    const ext = extname(f).toLowerCase();
    if (!IMAGE_INPUT_EXTS.has(ext)) continue;
    const dst = f.slice(0, -ext.length) + '.avif';
    try {
      const res = await convertOne(f, dst, opts);
      if (res.skipped) skipped++; else converted++;
    } catch (e) {
      console.error(`Failed to convert ${f}: ${e.message}`);
    }
  }

  console.log(`[${env}] Converted: ${converted}, skipped: ${skipped}`);
}

async function main() {
  const { envs, quality, effort } = parseArgs();
  for (const env of envs) {
    await runForEnv(env, { quality, effort });
  }
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
