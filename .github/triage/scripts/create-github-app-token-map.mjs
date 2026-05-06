#!/usr/bin/env node
import crypto from 'node:crypto';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';

const apiVersion = '2022-11-28';
const userAgent = 'shinycoreci-team-issue-triage';
const clientId = requiredEnv('GITHUB_APP_CLIENT_ID');
const privateKey = requiredEnv('GITHUB_APP_PRIVATE_KEY').replace(/\\n/g, '\n');
const ownerRepos = parseOwnerRepos(requiredEnv('TRIAGE_OWNER_REPOS'));
const outputDir = process.env.TRIAGE_TOKEN_OUTPUT_DIR || path.join(os.tmpdir(), 'team-issue-triage');
const outputPath = process.env.GITHUB_OUTPUT;

const readPermissions = {
  actions: 'read',
  contents: 'read',
  issues: 'read',
  pull_requests: 'read',
};
const writePermissions = {
  contents: 'read',
  issues: 'write',
  pull_requests: 'read',
};

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});

async function main() {
  fs.mkdirSync(outputDir, { recursive: true, mode: 0o700 });

  const jwt = createJwt();
  const installations = await resolveInstallations(jwt, ownerRepos);

  const readTokens = await createTokens(jwt, installations, readPermissions);
  const writeTokens = await createTokens(jwt, installations, writePermissions);

  const readTokensFile = writeTokenFile('read-tokens.json', readTokens);
  const writeTokensFile = writeTokenFile('write-tokens.json', writeTokens);

  if (outputPath) {
    fs.appendFileSync(outputPath, `read_tokens_file=${readTokensFile}\n`);
    fs.appendFileSync(outputPath, `write_tokens_file=${writeTokensFile}\n`);
  }

  console.log(`Generated GitHub App token maps for ${ownerRepos.length} repositories across ${installations.size} installations.`);
}

function requiredEnv(name) {
  const value = process.env[name];
  if (!value) {
    throw new Error(`${name} is required.`);
  }
  return value;
}

function parseOwnerRepos(value) {
  const repos = value.split(',').map((repo) => repo.trim()).filter(Boolean);
  if (!repos.length) {
    throw new Error('TRIAGE_OWNER_REPOS must list at least one repository.');
  }

  for (const repo of repos) {
    if (!/^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/.test(repo)) {
      throw new Error(`Repository entry must be owner/repo: ${repo}`);
    }
  }
  return repos;
}

function createJwt() {
  const now = Math.floor(Date.now() / 1000);
  const encodedHeader = base64Url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const encodedPayload = base64Url(JSON.stringify({ iat: now - 60, exp: now + 540, iss: clientId }));
  const signingInput = `${encodedHeader}.${encodedPayload}`;
  const signature = crypto.sign('RSA-SHA256', Buffer.from(signingInput), privateKey);
  return `${signingInput}.${base64Url(signature)}`;
}

function base64Url(value) {
  return Buffer.from(value).toString('base64url');
}

async function resolveInstallations(jwt, repos) {
  const byInstallation = new Map();

  for (const ownerRepo of repos) {
    const [owner, repo] = ownerRepo.split('/', 2);
    const installation = await githubRequest(jwt, 'GET', `/repos/${owner}/${repo}/installation`);
    const key = String(installation.id);
    const existing = byInstallation.get(key) || { installationId: installation.id, repositories: [] };
    existing.repositories.push(ownerRepo);
    byInstallation.set(key, existing);
  }

  return byInstallation;
}

async function createTokens(jwt, installations, permissions) {
  const tokens = {};

  for (const { installationId, repositories } of installations.values()) {
    const repositoryNames = repositories.map((ownerRepo) => ownerRepo.split('/', 2)[1]);
    const response = await githubRequest(jwt, 'POST', `/app/installations/${installationId}/access_tokens`, {
      repositories: repositoryNames,
      permissions,
    });

    console.log(`::add-mask::${response.token}`);
    for (const ownerRepo of repositories) {
      tokens[ownerRepo] = response.token;
    }
  }

  return { defaultRepo: ownerRepos[0], tokens };
}

function writeTokenFile(filename, tokenMap) {
  const filePath = path.join(outputDir, filename);
  fs.writeFileSync(filePath, `${JSON.stringify(tokenMap)}\n`, { mode: 0o600 });
  return filePath;
}

async function githubRequest(jwt, method, route, body) {
  const response = await fetch(`https://api.github.com${route}`, {
    method,
    headers: {
      Accept: 'application/vnd.github+json',
      Authorization: `Bearer ${jwt}`,
      'Content-Type': 'application/json',
      'User-Agent': userAgent,
      'X-GitHub-Api-Version': apiVersion,
    },
    body: body ? JSON.stringify(body) : undefined,
  });

  if (!response.ok) {
    const details = await response.text();
    throw new Error(`GitHub API ${method} ${route} failed with ${response.status}: ${details}`);
  }

  return response.json();
}