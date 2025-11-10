#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const readline = require('readline');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

const STAGE_DIR = path.join(__dirname, '../src/game-versions/stage');
const VERSIONS_DIR = path.join(STAGE_DIR, 'versions');
const UPDATES_JSON = path.join(STAGE_DIR, 'updates.json');

function question(query) {
  return new Promise(resolve => rl.question(query, resolve));
}

function validateVersion(version) {
  return /^\d+\.\d+\.\d+$/.test(version);
}

function validateDate(date) {
  return /^\d{4}-\d{2}-\d{2}$/.test(date) && !isNaN(Date.parse(date));
}

function validateType(type) {
  return ['feature', 'fix', 'update'].includes(type);
}

async function main() {
  console.log('🎮 Magic Alchemy - Add New Version\n');

  // Get version number
  let version;
  while (true) {
    version = await question('Enter version (e.g., 0.4.399): ');
    if (validateVersion(version)) {
      const versionDir = path.join(VERSIONS_DIR, version);
      if (fs.existsSync(versionDir)) {
        console.log('❌ Version already exists!');
        continue;
      }
      break;
    }
    console.log('❌ Invalid version format. Use format: X.Y.Z');
  }

  // Get date
  let date;
  while (true) {
    const defaultDate = new Date().toISOString().split('T')[0];
    date = await question(`Enter date (YYYY-MM-DD) [${defaultDate}]: `);
    if (!date) date = defaultDate;
    if (validateDate(date)) break;
    console.log('❌ Invalid date format. Use format: YYYY-MM-DD');
  }

  // Get type
  let type;
  while (true) {
    type = await question('Enter type (feature/fix/update): ');
    if (validateType(type)) break;
    console.log('❌ Invalid type. Choose: feature, fix, or update');
  }

  // Create version directory
  const versionDir = path.join(VERSIONS_DIR, version);
  fs.mkdirSync(versionDir, { recursive: true });
  console.log(`\n✅ Created directory: ${versionDir}`);

  // Create EN markdown file with template
  const enFile = path.join(versionDir, 'en.md');
  const enTemplate = '// Add English description here\n';
  fs.writeFileSync(enFile, enTemplate);
  console.log(`✅ Created file: ${enFile}`);

  // Create RU markdown file with template
  const ruFile = path.join(versionDir, 'ru.md');
  const ruTemplate = '// Добавьте описание здесь\n';
  fs.writeFileSync(ruFile, ruTemplate);
  console.log(`✅ Created file: ${ruFile}`);

  // Update updates.json
  let updates = [];
  if (fs.existsSync(UPDATES_JSON)) {
    updates = JSON.parse(fs.readFileSync(UPDATES_JSON, 'utf8'));
  }

  updates.unshift({
    version,
    date,
    type
  });

  fs.writeFileSync(UPDATES_JSON, JSON.stringify(updates, null, 2) + '\n');
  console.log(`✅ Updated: ${UPDATES_JSON}`);

  console.log('\n🎉 Version added successfully!\n');
  console.log('Summary:');
  console.log(`  Version: ${version}`);
  console.log(`  Date: ${date}`);
  console.log(`  Type: ${type}`);
  console.log(`\nNext steps:`);
  console.log(`  1. Edit ${enFile}`);
  console.log(`  2. Edit ${ruFile}`);

  rl.close();
}

main().catch(error => {
  console.error('❌ Error:', error.message);
  process.exit(1);
});
