// Cheese Tide Rush — hand-in program for make.fun's roblox-brainrot-01 bounty (Node 22, standard library only).
//
// What it does, in order:
//   1. copies the built place (game.rbxl) and the play link (PLAY.json) into the output folder;
//   2. mirrors src/ and screenshots/ there, skipping every file or folder whose name starts with a dot,
//      because the grader rejects an output holding names such as .DS_Store;
//   3. writes dossier.json, the judge's summary, with the kit's untouched buildDossier.
//
// The output folder is /output in the grader's container; set MAKEFUN_OUTPUT_DIR to use another one:
//   mkdir -p out && MAKEFUN_OUTPUT_DIR=out node main.ts

import { copyFileSync, cpSync, existsSync, mkdirSync, writeFileSync } from 'node:fs';
import { basename, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { buildDossier } from './vendor/makefun-roblox.ts';

const projectRoot = fileURLToPath(new URL('.', import.meta.url));
const outputDir = process.env.MAKEFUN_OUTPUT_DIR ?? '/output';

/** True for any path whose last segment is not hidden (does not start with a dot). */
function isVisibleName(path: string): boolean {
  return !basename(path).startsWith('.');
}

/** Copy one file from the project root to the same name in the output folder. */
function shipFile(name: string): void {
  copyFileSync(join(projectRoot, name), join(outputDir, name));
}

/** Copy a whole folder from the project root into the output folder, leaving hidden names behind. */
function shipFolder(name: string): void {
  const source = join(projectRoot, name);
  mkdirSync(join(outputDir, name), { recursive: true });
  if (existsSync(source)) cpSync(source, join(outputDir, name), { recursive: true, filter: isVisibleName });
}

mkdirSync(outputDir, { recursive: true });
shipFile('game.rbxl');
shipFile('PLAY.json');
shipFolder('src');
shipFolder('screenshots');

// The scorer's caps (the kit's gate): text size for the dossier, at most 4 screenshots of 256 KiB each,
// and the place's instance, source and path limits.
const scorerCaps = {
  text_max_bytes: 65536,
  screenshots: { max: 4, max_bytes: 262144 },
  max_instances: 500000,
  scripts_max_source_bytes: 8388608,
  scripts_max_path_chars: 1048576,
};

writeFileSync(join(outputDir, 'dossier.json'), buildDossier(outputDir, scorerCaps));
console.log(`Cheese Tide Rush: wrote ${join(outputDir, 'dossier.json')}`);
