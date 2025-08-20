import { readFileSync, readdirSync, statSync, writeFileSync, existsSync } from 'node:fs';
import { resolve, dirname, relative, extname, basename, join } from 'node:path';

const ROOT = resolve(dirname(new URL(import.meta.url).pathname), '..');

const IMAGE_EXT = new Set(['.png', '.jpg', '.jpeg', '.gif', '.webp', '.avif', '.svg']);

function parseArgs() {
  const args = process.argv.slice(2);
  let env = 'both';
  let fix = false;
  for (let i = 0; i < args.length; i++) {
    const a = args[i];
    if (a === '--fix' || a === '-f') fix = true;
    else if ((a === '--env' || a === '-e') && args[i + 1]) { env = args[++i]; }
  }
  /** @type {('stage'|'production')[]} */
  let envs = ['stage', 'production'];
  if (env === 'stage') envs = ['stage'];
  else if (env === 'production') envs = ['production'];
  else envs = ['stage', 'production'];
  return { envs, fix };
}

function listMarkdownFiles(dir) {
  const out = [];
  (function walk(d) {
    const entries = readdirSync(d, { withFileTypes: true });
    for (const e of entries) {
      const p = resolve(d, e.name);
      if (e.isDirectory()) walk(p);
      else if (e.isFile() && p.endsWith('.md')) out.push(p);
    }
  })(dir);
  return out;
}

function collectAnchors(mdContent) {
  // Matches {#id} with allowed pattern
  const re = /\{#([a-z0-9-]+)\}/g;
  const set = new Set();
  let m;
  while ((m = re.exec(mdContent))) set.add(m[1]);
  return set;
}

function isSnakeCaseMd(name) {
  return /^[a-z0-9_]+(_(ru|en))?\.md$/.test(name);
}

function langSuffix(name) {
  if (/_ru\.md$/.test(name)) return 'ru';
  if (/_en\.md$/.test(name)) return 'en';
  return 'unknown';
}

function validateFile(envRoot, filePath, report, options) {
  const fileDir = dirname(filePath);
  const relFromEnv = relative(envRoot, filePath).replace(/\\/g, '/');
  let content = readFileSync(filePath, 'utf8');
  const ownAnchors = collectAnchors(content);

  // Regex to capture markdown/Image links: ![...](target) and [...](target)
  const linkRe = /(!)?\[[^\]]*\]\(([^)]+)\)/g;
  let m;
  const fileIssues = [];
  let changed = false;

  while ((m = linkRe.exec(content))) {
    const isImage = !!m[1];
    const rawTarget = m[2];
    let target = rawTarget.trim();
    if (!target) continue;

    // Skip http(s)
    if (/^https?:\/\//i.test(target)) continue;

    // Absolute site path
    if (target.startsWith('/')) {
      if (/(\s)/.test(target)) fileIssues.push(`absolute site link contains spaces: ${target}`);
      continue;
    }

    // Split anchor
    let pathOnly = target;
    let anchor = '';
    const hashIdx = target.indexOf('#');
    if (hashIdx !== -1) {
      pathOnly = target.slice(0, hashIdx);
      anchor = target.slice(hashIdx + 1);
    }

    // Pure anchor within same file
    if (!pathOnly && anchor) {
      if (!/^[a-z0-9-]+$/.test(anchor)) {
        // try normalize to kebab-case and lowercase
        const norm = anchor.toLowerCase().replace(/[ _]+/g, '-');
        if (ownAnchors.has(norm) && options.fix) {
          const before = content.slice(0, m.index);
          const after = content.slice(m.index + m[0].length);
          const fixed = m[0].replace(`#${anchor}`, `#${norm}`);
          content = before + fixed + after;
          changed = true;
          continue;
        } else {
          fileIssues.push(`invalid anchor format [a-z0-9-]+: #${anchor}`);
        }
      }
      if (!ownAnchors.has(anchor)) {
        fileIssues.push(`anchor not found in target: ${basename(filePath)}#${anchor}`);
      }
      continue;
    }

    // Resolve relative path
    const absTarget = resolve(fileDir, pathOnly);
    if (!safeExists(absTarget)) {
      // Try auto-fixes before erroring
      let fixedLink = '';
      // 1) If image and bare filename, prefer images/<name>
      if (isImage && !pathOnly.includes('/')) {
        const guess1 = resolve(fileDir, 'images', pathOnly);
        if (existsSync(guess1)) fixedLink = `images/${pathOnly}`;
        const guess2 = resolve(fileDir, 'image', pathOnly);
        if (!fixedLink && existsSync(guess2)) fixedLink = `images/${pathOnly}`;
        // if current dir is .../image, try ../images/
        if (!fixedLink && /(^|\/)image$/.test(fileDir)) {
          const parentImages = resolve(dirname(fileDir), 'images', pathOnly);
          if (existsSync(parentImages)) fixedLink = `../images/${pathOnly}`;
        }
      }
      // 2) Project absolute prefixes -> relative
      if (!fixedLink && (pathOnly.startsWith('src/game-lore-library/') || pathOnly.startsWith('static-content/src/game-lore-library/'))) {
        const candidate = pathOnly.replace(/^static-content\//, '');
        const abs = resolve(ROOT, candidate.replace(/^src\/game-lore-library\//, ''));
        if (existsSync(abs)) {
          fixedLink = relative(fileDir, abs).replace(/\\/g, '/');
        }
      }
      // 3) Missing .md: search by basename across env
      if (!fixedLink && /\.md$/i.test(pathOnly)) {
        const base = basename(pathOnly);
        const envRoot = envRootFromFile(filePath);
        const found = findByBasename(envRoot, base);
        if (found.length === 1) {
          fixedLink = relative(fileDir, found[0]).replace(/\\/g, '/');
        }
      }
      if (fixedLink && options.fix) {
        const before = content.slice(0, m.index);
        const after = content.slice(m.index + m[0].length);
        const fixed = m[0].replace(`(${rawTarget})`, `(${fixedLink}${anchor ? '#' + anchor : ''})`);
        content = before + fixed + after;
        changed = true;
        continue;
      }
      fileIssues.push(`target not found: ${target} (resolved from ${pathOnly})`);
      continue;
    }

    const ext = extname(absTarget).toLowerCase();
    if (ext === '.md') {
      const base = basename(absTarget);
      if (!isSnakeCaseMd(base)) {
        fileIssues.push(`markdown filename not snake_case with optional _ru/_en: ${base} (link: ${target})`);
      }
      const lang = langSuffix(base);
      if (lang === 'unknown') {
        fileIssues.push(`markdown link must point to _ru.md or _en.md: ${base} (link: ${target})`);
      }
      if (anchor) {
        const targetContent = readFileSync(absTarget, 'utf8');
        const targetAnchors = collectAnchors(targetContent);
        if (!/^[a-z0-9-]+$/.test(anchor)) {
          const norm = anchor.toLowerCase().replace(/[ _]+/g, '-');
          if (targetAnchors.has(norm) && options.fix) {
            const before = content.slice(0, m.index);
            const after = content.slice(m.index + m[0].length);
            const fixed = m[0].replace(`#${anchor}`, `#${norm}`);
            content = before + fixed + after;
            changed = true;
          } else {
            fileIssues.push(`invalid anchor format [a-z0-9-]+: #${anchor}`);
          }
        }
        if (!targetAnchors.has(anchor)) {
          fileIssues.push(`anchor not found in target: ${base}#${anchor}`);
        }
      }
    } else if (isImage) {
      const base = basename(absTarget);
      if (/\s/.test(base)) fileIssues.push(`filename contains spaces: ${base} (link: ${target})`);
      const isImageExt = IMAGE_EXT.has(ext);
      if (isImageExt) {
        const tpath = pathOnly.replace(/\\/g, '/');
        if (!/\.2x\.(png|jpg|jpeg|gif|webp|avif|svg)$/i.test(base)) {
          fileIssues.push(`image filename must follow *.2x.<ext> pattern: ${base}`);
        }
        // Must be under images/ directory
        if (!tpath.includes('/')) {
          if (options.fix) {
            const guess = existsSync(resolve(fileDir, 'images', tpath)) ? `images/${tpath}`
              : existsSync(resolve(fileDir, 'image', tpath)) ? `images/${tpath}` : '';
            if (guess) {
              const before = content.slice(0, m.index);
              const after = content.slice(m.index + m[0].length);
              const fixed = m[0].replace(`(${rawTarget})`, `(${guess})`);
              content = before + fixed + after;
              changed = true;
            } else {
              fileIssues.push(`image path must be under images/: ${tpath}`);
            }
          } else {
            fileIssues.push(`image path must be under images/: ${tpath}`);
          }
        } else if (/(^|\/)image\//.test(tpath)) {
          if (options.fix) {
            const fixedPath = tpath.replace(/(^|\/)image\//g, '$1images/');
            const before = content.slice(0, m.index);
            const after = content.slice(m.index + m[0].length);
            const fixed = m[0].replace(`(${rawTarget})`, `(${fixedPath}${anchor ? '#' + anchor : ''})`);
            content = before + fixed + after;
            changed = true;
          } else {
            fileIssues.push(`use 'images/' directory, not 'image/': ${tpath}`);
          }
        } else if (!/(^|\/)images\//.test(tpath)) {
          fileIssues.push(`image path must be under images/: ${tpath}`);
        }
      }
    }
  }

  if (fileIssues.length) {
    report.push({ file: relFromEnv, issues: fileIssues });
  }
  if (changed && options.fix) {
    writeFileSync(filePath, content, 'utf8');
  }
}

function safeExists(p) {
  try {
    statSync(p);
    return true;
  } catch {
    return false;
  }
}

function envRootFromFile(filePath) {
  return filePath.includes('/production/') ? resolve(ROOT, 'production') : resolve(ROOT, 'stage');
}

function findByBasename(root, base) {
  const matches = [];
  (function walk(d) {
    const entries = readdirSync(d, { withFileTypes: true });
    for (const e of entries) {
      const p = resolve(d, e.name);
      if (e.isDirectory()) walk(p);
      else if (e.isFile() && e.name.toLowerCase() === base.toLowerCase()) matches.push(p);
    }
  })(root);
  return matches;
}

function runForEnv(env, options) {
  const envRoot = resolve(ROOT, env);
  const report = [];
  const files = listMarkdownFiles(envRoot);
  for (const f of files) validateFile(envRoot, f, report, options);
  return report;
}

function main() {
  const { envs, fix } = parseArgs();
  let totalErrors = 0;
  let filesWithIssues = 0;
  for (const env of envs) {
    const envReport = runForEnv(env, { fix });
    if (envReport.length) {
      console.error(`\nEnvironment: ${env}`);
      for (const r of envReport) {
        filesWithIssues++;
        console.error(`File: ${r.file}`);
        for (const i of r.issues) {
          totalErrors++;
          console.error(`  - ${i}`);
        }
      }
    }
  }
  if (totalErrors > 0) {
    console.error(`\nSummary: ${totalErrors} issues in ${filesWithIssues} files.`);
    process.exit(fix ? 0 : 1);
  } else {
    console.log('All markdown links look good.');
  }
}

main();
