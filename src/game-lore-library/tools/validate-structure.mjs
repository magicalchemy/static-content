#!/usr/bin/env node
import { readdirSync, statSync, renameSync, mkdirSync, rmSync } from 'node:fs';
import { resolve, dirname, basename } from 'node:path';

const ROOT = resolve(dirname(new URL(import.meta.url).pathname), '..');

function parseArgs() {
  const args = process.argv.slice(2);
  let env = 'stage';
  let strict = false;
  let json = false;
  let fix = false;
  let verbose = false;
  let purge = false;
  for (let i = 0; i < args.length; i++) {
    const a = args[i];
    if ((a === '--env' || a === '-e') && args[i + 1]) env = args[++i];
    else if (a === '--strict') strict = true;
    else if (a === '--json') json = true;
    else if (a === '--fix' || a === '-f') fix = true;
    else if (a === '--verbose' || a === '-v') verbose = true;
    else if (a === '--purge') purge = true;
  }
  let envs;
  if (env === 'both') envs = ['stage', 'production'];
  else if (env === 'stage' || env === 'production') envs = [env];
  else {
    console.error("Ошибка: окружение должно быть 'stage', 'production' или 'both'.");
    process.exit(2);
  }
  return { envs, strict, json, fix, verbose, purge };
}

function exists(p) { try { statSync(p); return true; } catch { return false; } }

function isSnake(s) { return /^[a-z0-9_]+$/.test(s); }
function toSnake(s) {
  // simple transliteration-free snake: lower, replace non-alnum with '_', collapse, trim
  let t = s.toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/_+/g, '_').replace(/^_+|_+$/g, '');
  if (!t) t = 'unnamed';
  return t;
}

function isArticleMd(name) { return /^[a-z0-9_]+_(ru|en)\.md$/.test(name); }

function isImageExt(name) { return /\.(png|jpe?g|gif|webp|avif|svg)$/i.test(name); }
function toSnakeFile(name) {
  const i = name.lastIndexOf('.');
  const baseFull = i >= 0 ? name.slice(0, i) : name;
  const ext = i >= 0 ? name.slice(i).toLowerCase() : '';
  // Preserve variant tokens like '.mobile.2x', '.mobile.1x', '.2x', '.1x'
  // Detect at the end of baseFull
  let stem = baseFull;
  let variant = '';
  const m1 = stem.match(/(\.mobile\.(?:1x|2x))$/); // .mobile.2x or .mobile.1x
  if (m1) {
    variant = m1[1];
    stem = stem.slice(0, -variant.length);
  } else {
    const m2 = stem.match(/(\.(?:1x|2x))$/); // .2x or .1x
    if (m2) {
      variant = m2[1];
      stem = stem.slice(0, -variant.length);
    }
  }
  const normalizedStem = toSnake(stem);
  return normalizedStem + variant + ext;
}

function listDirs(dir) { return readdirSync(dir, { withFileTypes: true }).filter(d => d.isDirectory()).map(d => resolve(dir, d.name)); }
function listFiles(dir) { return readdirSync(dir, { withFileTypes: true }).filter(d => d.isFile()).map(d => resolve(dir, d.name)); }

function logv(enabled, ...m) { if (enabled) console.log(...m); }

function validateEnv(envRoot, opts, report) {
  const articlesRoot = resolve(envRoot, 'articles');
  if (!exists(articlesRoot)) {
    report.messages.push({ level: 'warn', msg: `Окружение без статей: ${articlesRoot} — пропуск` });
    return;
  }

  for (const adir of listDirs(articlesRoot)) {
    const dirName = basename(adir);
    let errorsBefore = report.errors;

    // 1) Имя папки статьи — snake_case
    if (!isSnake(dirName)) {
      const suggested = toSnake(dirName);
      if (opts.fix) {
        const target = resolve(articlesRoot, suggested);
        if (!exists(target)) {
          renameSync(adir, target);
          report.messages.push({ level: 'fix', msg: `Переименована папка: ${dirName} -> ${basename(target)}` });
        } else {
          report.messages.push({ level: 'error', msg: `Нельзя переименовать '${dirName}' в '${basename(target)}': уже существует` });
          report.errors++;
        }
      } else {
        report.messages.push({ level: 'error', msg: `Имя папки не snake_case: ${dirName} (предложение: ${suggested})` });
        report.errors++;
      }
    }

    // Обновим путь если переименовали
    const currentAdir = exists(adir) ? adir : resolve(articlesRoot, toSnake(dirName));

    // 2) Наличие images/ (warning, в strict — ошибка)
    const imagesDir = resolve(currentAdir, 'images');
    const imageDir = resolve(currentAdir, 'image');
    // Кандидаты на images/: image, images, img, imgs, pic, pics, assets (если содержат только картинки)
    const candidateNames = ['image', 'images', 'img', 'imgs', 'pic', 'pics', 'assets'];
    const candidateDirs = listDirs(currentAdir)
      .filter(d => candidateNames.includes(basename(d)));

    // При автофиксе: если images/ отсутствует, а есть один из кандидатов — переименуем его в images
    if (opts.fix && !exists(imagesDir)) {
      const preferred = candidateDirs.find(d => basename(d) === 'images')
        || candidateDirs.find(d => basename(d) === 'image')
        || candidateDirs[0];
      if (preferred) {
        try {
          renameSync(preferred, imagesDir);
          report.messages.push({ level: 'fix', msg: `Переименована папка: ${basename(preferred)} -> images (${currentAdir})` });
        } catch {}
      }
    }
    // Дополнительно: если после этого остался 'image' без images, конвертируем
    if (opts.fix && exists(imageDir) && !exists(imagesDir)) {
      try {
        renameSync(imageDir, imagesDir);
        report.messages.push({ level: 'fix', msg: `Переименована папка: image -> images (${currentAdir})` });
      } catch {}
    }
    if (!exists(imagesDir)) {
      const level = opts.strict ? 'error' : 'warn';
      report.messages.push({ level, msg: `Нет папки images/: ${currentAdir}` });
      if (opts.strict) report.errors++;
      if (opts.fix) {
        try { mkdirSync(imagesDir, { recursive: true }); report.messages.push({ level: 'fix', msg: `Создана папка: ${imagesDir}` }); } catch {}
      }
    }

    // 3) Файлы статей — *_ru.md / *_en.md и snake_case
    const files = listFiles(currentAdir).map(p => basename(p));
    const mdFiles = files.filter(n => n.endsWith('.md'));
    if (mdFiles.length === 0) {
      report.messages.push({ level: 'warn', msg: `В папке статьи нет .md файлов: ${currentAdir}` });
    }
    for (const f of mdFiles) {
      if (!isArticleMd(f)) {
        const base = f.replace(/\.md$/, '');
        const guessed = isSnake(base) ? (base + '_ru.md') : (toSnake(base) + '_ru.md');
        if (opts.fix) {
          const src = resolve(currentAdir, f);
          const dst = resolve(currentAdir, guessed);
          if (!exists(dst)) {
            renameSync(src, dst);
            report.messages.push({ level: 'fix', msg: `Переименован файл: ${f} -> ${basename(dst)}` });
          } else {
            report.messages.push({ level: 'error', msg: `Нельзя переименовать '${f}' в '${basename(dst)}': уже существует` });
            report.errors++;
          }
        } else {
          report.messages.push({ level: 'error', msg: `Имя .md файла должно быть lower_snake_case и с суффиксом _ru/_en: ${f} (пример: ${guessed})` });
          report.errors++;
        }
      }
    }

    // 4) Консолидация ассетов: переместить все картинки в images/;
    //    чужие папки, содержащие только картинки, слить; остальные — ошибка или --purge
    const nestedDirs = listDirs(currentAdir);
    for (const nd of nestedDirs) {
      const n = basename(nd);
      if (n === 'images') continue;
      const dirFiles = listFiles(nd).map(p => basename(p));
      const hasSubdirs = listDirs(nd).length > 0;
      const allImages = dirFiles.length > 0 && dirFiles.every(isImageExt) && !hasSubdirs;
      const looksLikeImagesBucket = /^(image|img|imgs|pic|pics|assets)$/i.test(n) || allImages;
      if (looksLikeImagesBucket) {
        if (opts.fix) {
          for (const f of dirFiles) {
            const src = resolve(nd, f);
            const normalized = toSnakeFile(f);
            let dst = resolve(imagesDir, normalized);
            if (exists(dst)) {
              // добавим индекс, чтобы не перезаписать
              const i = normalized.lastIndexOf('.');
              const base = i >= 0 ? normalized.slice(0, i) : normalized;
              const ext = i >= 0 ? normalized.slice(i) : '';
              let k = 1;
              while (exists(dst)) { dst = resolve(imagesDir, `${base}_${k}${ext}`); k++; }
            }
            renameSync(src, dst);
            report.messages.push({ level: 'fix', msg: `Перемещён ассет: ${n}/${f} -> images/${basename(dst)}` });
          }
          // попробовать удалить пустую папку
          try { rmSync(nd, { recursive: true, force: true }); } catch {}
        } else {
          report.messages.push({ level: 'warn', msg: `Найден ассет-каталог '${n}', перенесём содержимое в images/ при --fix` });
        }
      } else {
        if (opts.purge) {
          try { rmSync(nd, { recursive: true, force: true }); report.messages.push({ level: 'fix', msg: `Удалён посторонний каталог: ${n}` }); } catch {}
        } else {
          report.messages.push({ level: 'error', msg: `Посторонний каталог в статье: ${n} (разрешён только images/)` });
          report.errors++;
        }
      }
    }

    // 5) Картинки в корне папки статьи — переместить в images/
    for (const f of files) {
      if (isImageExt(f)) {
        if (opts.fix) {
          const src = resolve(currentAdir, f);
          const normalized = toSnakeFile(f);
          let dst = resolve(imagesDir, normalized);
          if (exists(dst)) {
            const i = normalized.lastIndexOf('.');
            const base = i >= 0 ? normalized.slice(0, i) : normalized;
            const ext = i >= 0 ? normalized.slice(i) : '';
            let k = 1;
            while (exists(dst)) { dst = resolve(imagesDir, `${base}_${k}${ext}`); k++; }
          }
          renameSync(src, dst);
          report.messages.push({ level: 'fix', msg: `Перемещён ассет: ${f} -> images/${basename(dst)}` });
        } else {
          report.messages.push({ level: 'warn', msg: `Картинка в корне статьи: ${f} — будет перемещена в images/ при --fix` });
        }
      }
    }

    // 6) Нормализация имён файлов в images/ (lower_snake_case)
    if (exists(imagesDir)) {
      for (const f of listFiles(imagesDir).map(p => basename(p))) {
        const srcPath = resolve(imagesDir, f);
        let targetName = f;

        // 6.1 Исправление ранее испорченных имён: xxx_2x.png -> xxx.2x.png (и _1x)
        const fixVariant = f.match(/^(.*)_([12]x)(\.[a-z0-9]+)$/i);
        if (fixVariant && !/\.mobile\.([12]x)\.[a-z0-9]+$/i.test(f)) {
          const base = fixVariant[1];
          const vx = fixVariant[2].toLowerCase();
          const ext = fixVariant[3].toLowerCase();
          const candidate = `${base}.${vx}${ext}`;
          if (!exists(resolve(imagesDir, candidate))) {
            targetName = candidate;
          }
        }

        // 6.2 Базовая нормализация стема + сохранение варианта
        const normalized = toSnakeFile(targetName);
        if (normalized !== f) {
          let dst = resolve(imagesDir, normalized);
          if (exists(dst)) {
            const i = normalized.lastIndexOf('.');
            const base = i >= 0 ? normalized.slice(0, i) : normalized;
            const ext = i >= 0 ? normalized.slice(i) : '';
            let k = 1;
            while (exists(dst)) { dst = resolve(imagesDir, `${base}_${k}${ext}`); k++; }
          }
          if (opts.fix) {
            renameSync(srcPath, dst);
            report.messages.push({ level: 'fix', msg: `Переименован ассет: images/${f} -> images/${basename(dst)}` });
          } else {
            report.messages.push({ level: 'warn', msg: `Ненормализованное имя ассета: images/${f} — будет переименовано при --fix` });
          }
        }
      }
    }

    if (opts.verbose && report.errors === errorsBefore) {
      console.log(`[ok] ${currentAdir.replace(envRoot + '/', '')}`);
    }
  }
}

function main() {
  const { envs, strict, json, fix, verbose } = parseArgs();
  const report = { errors: 0, messages: [] };
  for (const e of envs) {
    const envRoot = resolve(ROOT, e);
    if (!exists(envRoot)) {
      report.messages.push({ level: 'warn', msg: `Окружение отсутствует: ${envRoot} — пропуск` });
      continue;
    }
    validateEnv(envRoot, { strict, fix, verbose }, report);
  }
  if (json) {
    console.log(JSON.stringify(report, null, 2));
  } else {
    for (const m of report.messages) {
      const tag = m.level.toUpperCase().padEnd(5, ' ');
      console.log(`${tag} ${m.msg}`);
    }
    console.log(`Итог: ошибок=${report.errors}`);
  }
  process.exit(report.errors > 0 ? 1 : 0);
}

main();
