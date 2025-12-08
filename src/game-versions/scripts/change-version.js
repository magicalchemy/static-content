#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const readline = require('readline');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout
});

const STAGE_DIR = path.join(__dirname, '..', 'stage');
const VERSIONS_DIR = path.join(STAGE_DIR, 'versions');
const UPDATES_JSON = path.join(STAGE_DIR, 'updates.json');

function question(query) {
  return new Promise(resolve => rl.question(query, resolve));
}

function validateVersion(version) {
  return /^\d+\.\d+\.\d+$/.test(version);
}

function readUpdates() {
  if (!fs.existsSync(UPDATES_JSON)) {
    throw new Error('updates.json not found');
  }

  return JSON.parse(fs.readFileSync(UPDATES_JSON, 'utf8'));
}

async function askCurrentVersion(updates) {
  while (true) {
    const currentVersion = await question('Enter current version (e.g., 0.4.402): ');

    if (!validateVersion(currentVersion)) {
      console.log('❌ Invalid version format. Use format: X.Y.Z');
      continue;
    }

    const currentDir = path.join(VERSIONS_DIR, currentVersion);
    if (!fs.existsSync(currentDir)) {
      console.log(`❌ Directory for version ${currentVersion} not found in versions/`);
      continue;
    }

    const hasUpdateEntry = updates.some(update => update.version === currentVersion);
    if (!hasUpdateEntry) {
      console.log(`❌ Version ${currentVersion} not found in updates.json`);
      continue;
    }

    return currentVersion;
  }
}

async function askNewVersion(updates, currentVersion) {
  while (true) {
    const newVersion = await question('Enter new version (e.g., 0.4.406): ');

    if (!validateVersion(newVersion)) {
      console.log('❌ Invalid version format. Use format: X.Y.Z');
      continue;
    }

    if (newVersion === currentVersion) {
      console.log('❌ New version must be different from current version');
      continue;
    }

    const newDir = path.join(VERSIONS_DIR, newVersion);
    if (fs.existsSync(newDir)) {
      console.log(`❌ Directory for version ${newVersion} already exists`);
      continue;
    }

    const updateExists = updates.some(update => update.version === newVersion);
    if (updateExists) {
      console.log(`❌ Version ${newVersion} already exists in updates.json`);
      continue;
    }

    return newVersion;
  }
}

async function main() {
  console.log('🎮 Magic Alchemy - Change Version\n');

  const updates = readUpdates();

  const currentVersion = await askCurrentVersion(updates);
  const newVersion = await askNewVersion(updates, currentVersion);

  const currentDir = path.join(VERSIONS_DIR, currentVersion);
  const newDir = path.join(VERSIONS_DIR, newVersion);

  fs.renameSync(currentDir, newDir);
  console.log(`\n✅ Renamed directory: ${currentDir} -> ${newDir}`);

  const indexToUpdate = updates.findIndex(update => update.version === currentVersion);
  updates[indexToUpdate].version = newVersion;

  fs.writeFileSync(UPDATES_JSON, JSON.stringify(updates, null, 2) + '\n');
  console.log(`✅ Updated version in: ${UPDATES_JSON}`);

  console.log('\n🎉 Version updated successfully!\n');
  console.log('Summary:');
  console.log(`  Previous version: ${currentVersion}`);
  console.log(`  New version: ${newVersion}`);

  rl.close();
}

main().catch(error => {
  console.error('❌ Error:', error.message);
  rl.close();
  process.exit(1);
});
