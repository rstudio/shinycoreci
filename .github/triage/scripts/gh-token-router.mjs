#!/usr/bin/env node
import { spawnSync } from 'node:child_process';
import fs from 'node:fs';

const realGh = process.env.TRIAGE_REAL_GH;
if (!realGh) {
  console.error('TRIAGE_REAL_GH is required.');
  process.exit(1);
}

const tokenMap = readTokenMap(process.env.TRIAGE_GH_TOKENS_FILE);
const repos = reposFromArgs(process.argv.slice(2));
const repo = chooseRepo(repos, tokenMap.defaultRepo);
const token = tokenMap.tokens[repo] || process.env.GH_TOKEN;

if (!token) {
  console.error(`No GitHub token is available for ${repo}.`);
  process.exit(1);
}

const result = spawnSync(realGh, process.argv.slice(2), {
  stdio: 'inherit',
  env: { ...process.env, GH_TOKEN: token },
});

if (result.error) {
  console.error(result.error.message);
  process.exit(1);
}
process.exit(result.status ?? 1);

function readTokenMap(filePath) {
  if (!filePath) {
    return { defaultRepo: '', tokens: {} };
  }
  try {
    return JSON.parse(fs.readFileSync(filePath, 'utf8'));
  } catch (error) {
    console.error(`Could not read GitHub token map: ${error.message}`);
    process.exit(1);
  }
}

function reposFromArgs(args) {
  const repos = new Set();

  for (let index = 0; index < args.length; index += 1) {
    const arg = args[index];
    if ((arg === '--repo' || arg === '-R') && args[index + 1]) {
      addRepo(repos, args[index + 1]);
      index += 1;
    } else if (arg.startsWith('--repo=')) {
      addRepo(repos, arg.slice('--repo='.length));
    } else {
      for (const match of arg.matchAll(/(?:^|\s)repo:([A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+)/g)) {
        addRepo(repos, match[1]);
      }
      const apiMatch = arg.match(/(?:^|\/)repos\/([A-Za-z0-9_.-]+)\/([A-Za-z0-9_.-]+)(?:\/|$)/);
      if (apiMatch) {
        addRepo(repos, `${apiMatch[1]}/${apiMatch[2]}`);
      }
    }
  }

  return repos;
}

function addRepo(repos, value) {
  const match = String(value).match(/^([A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+)/);
  if (match) {
    repos.add(match[1]);
  }
}

function chooseRepo(repos, defaultRepo) {
  if (repos.size > 1) {
    console.error(`gh commands must target one repository at a time with the token router. Found: ${Array.from(repos).join(', ')}`);
    process.exit(1);
  }

  return Array.from(repos)[0] || defaultRepo;
}