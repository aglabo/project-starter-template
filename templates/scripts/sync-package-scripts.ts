// src: scripts/sync-package-scripts.ts
// @(#) : merge base script templates into a package.json, keeping local-only scripts
//
// Copyright (c) 2025- atsushifx <https://github.com/atsushifx>
//
// This software is released under the MIT License.
// https://opensource.org/licenses/MIT
//
// usage: tsx scripts/sync-package-scripts.ts [target_dir] [--dry-run]
//   target_dir omitted: the directory pnpm was invoked from (INIT_CWD), else the package.json
//   that pnpm is running (npm_package_json), else the current directory.
//   kind is inferred: the repo root uses base-root-scripts.json, anything else base-scripts.json.

// libs
import { readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

type Scripts = Record<string, string>;

const repoRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');

// pnpm forwards extra args as "--" "<arg>"
const args = process.argv.slice(2).filter((a) => a !== '--');
const dryRun = args.includes('--dry-run');
const positional = args.filter((a) => !a.startsWith('-'));

const inferTargetDir = (): string => {
  if (positional[0]) { return path.resolve(positional[0]); }
  if (process.env.INIT_CWD) { return path.resolve(process.env.INIT_CWD); }
  if (process.env.npm_package_json) { return path.dirname(process.env.npm_package_json); }
  return process.cwd();
};
const targetDir = inferTargetDir();
const templateFile = path.resolve(targetDir) === repoRoot ? 'base-root-scripts.json' : 'base-scripts.json';

const readJson = (file: string) => JSON.parse(readFileSync(file, 'utf8'));
const baseScripts: Scripts = readJson(path.join(repoRoot, 'base/configs', templateFile)).scripts;

const targetFile = path.resolve(targetDir, 'package.json');
const pkg = readJson(targetFile);
const current: Scripts = pkg.scripts ?? {};

// base entries win; scripts that exist only in the target stay untouched
const merged: Scripts = { ...current, ...baseScripts };
const changed = Object.keys(baseScripts).filter((k) => current[k] !== baseScripts[k]);

for (const k of changed) {
  console.log(`${current[k] === undefined ? '+' : '~'} ${k}: ${baseScripts[k]}`);
}
if (changed.length === 0) {
  console.log('scripts already in sync');
} else if (!dryRun) {
  writeFileSync(targetFile, JSON.stringify({ ...pkg, scripts: merged }, null, 2) + '\n');
  console.log(`updated ${targetFile}`);
}
