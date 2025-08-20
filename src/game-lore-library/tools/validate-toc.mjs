import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';
import Ajv2020 from 'ajv/dist/2020.js';
import addFormats from 'ajv-formats';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const root = resolve(__dirname, '..');

const schemaPath = resolve(root, 'toc.schema.json');
const stageTocPath = resolve(root, 'stage', 'toc.json');
const prodTocPath = resolve(root, 'production', 'toc.json');

function loadJSON(path) {
  try {
    const raw = readFileSync(path, 'utf8');
    return JSON.parse(raw);
  } catch (e) {
    throw new Error(`Failed to read/parse JSON at ${path}: ${e.message}`);
  }
}

function printErrors(label, errors) {
  console.error(`\n[${label}] Validation errors:`);
  for (const err of errors) {
    const instancePath = err.instancePath || '';
    const loc = instancePath ? instancePath : '(root)';
    const msg = err.message || 'Invalid';
    const params = err.params ? JSON.stringify(err.params) : '';
    console.error(` - ${loc}: ${msg} ${params}`);
  }
}

function validateToc(label, ajv, schema, toc, extraChecks = true) {
  const validate = ajv.compile(schema);
  const ok = validate(toc);
  if (!ok) {
    printErrors(label, validate.errors || []);
    return false;
  }

  if (extraChecks) {
    // Additional structural checks mirroring bash validator nuances
    // - Ensure arrays are non-null (already by schema)
    // - Nothing extra for now; can extend as parity needs.
  }
  return true;
}

function main() {
  const ajv = new Ajv2020({ allErrors: true, allowUnionTypes: true });
  addFormats(ajv);

  const schema = loadJSON(schemaPath);
  let ok = true;

  // parse env flag: -e stage|production|both (default: both)
  const argv = process.argv.slice(2);
  const eIdx = argv.indexOf('-e');
  const env = eIdx !== -1 ? (argv[eIdx + 1] || 'both') : 'both';
  const wantStage = env === 'stage' || env === 'both';
  const wantProd = env === 'production' || env === 'both';

  // stage
  if (wantStage) {
    try {
      const tocStage = loadJSON(stageTocPath);
      ok = validateToc('stage/toc.json', ajv, schema, tocStage) && ok;
    } catch (e) {
      if (e.message.includes('ENOENT')) {
        console.warn(`Skipped stage: ${e.message}`);
      } else {
        console.error(e.message);
        ok = false;
      }
    }
  }

  // production
  if (wantProd) {
    try {
      const tocProd = loadJSON(prodTocPath);
      ok = validateToc('production/toc.json', ajv, schema, tocProd) && ok;
    } catch (e) {
      if (e.message.includes('ENOENT')) {
        console.warn(`Skipped production: ${e.message}`);
      } else {
        console.error(e.message);
        ok = false;
      }
    }
  }

  if (!ok) {
    process.exit(1);
  } else {
    console.log(`toc.json validation is OK${env ? ` (env: ${env})` : ''}.`);
  }
}

main();
