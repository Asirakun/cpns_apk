import fs from 'node:fs';
import path from 'node:path';
import {fileURLToPath} from 'node:url';

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');
const packages = [];
let current;
for (const line of fs.readFileSync(path.join(root, 'pubspec.lock'), 'utf8').split(/\r?\n/)) {
  const name = /^  ([a-zA-Z0-9_]+):$/.exec(line);
  if (name) { current = {ecosystem: 'Pub', name: name[1]}; continue; }
  if (!current) continue;
  if (/^    source: hosted$/.test(line)) current.hosted = true;
  const version = /^    version: "([^"]+)"$/.exec(line);
  if (version && current.hosted) packages.push({ecosystem: current.ecosystem, name: current.name, version: version[1]});
}
const npmLock = JSON.parse(fs.readFileSync(path.join(root, 'package-lock.json'), 'utf8'));
for (const [name, info] of Object.entries(npmLock.packages ?? {})) {
  if (name.includes('node_modules/') && info.version) {
    packages.push({ecosystem: 'npm', name: name.split('node_modules/').at(-1), version: info.version});
  }
}
const mavenFile = path.join(root, 'work', 'maven-dependencies.json');
if (!fs.existsSync(mavenFile)) throw new Error('Generate work/maven-dependencies.json before auditing.');
packages.push(...JSON.parse(fs.readFileSync(mavenFile, 'utf8').replace(/^\uFEFF/, '')));
if (packages.filter(p => p.ecosystem === 'Pub').length < 50) throw new Error('Incomplete Pub inventory.');
if (packages.filter(p => p.ecosystem === 'Maven').length < 10) throw new Error('Incomplete Maven inventory.');

async function request(url, body) {
  for (let attempt = 0; attempt < 3; attempt++) {
    try {
      const response = await fetch(url, {
        ...(body ? {method: 'POST', headers: {'content-type': 'application/json'}, body: JSON.stringify(body)} : {}),
        signal: AbortSignal.timeout(30000),
      });
      if (!response.ok) throw new Error(`OSV returned HTTP ${response.status}`);
      return await response.json();
    } catch (error) { if (attempt === 2) throw error; }
  }
}

const findings = [];
for (let offset = 0; offset < packages.length; offset += 100) {
  const batch = packages.slice(offset, offset + 100);
  const queries = batch.map(p => ({package: {name: p.name, ecosystem: p.ecosystem}, version: p.version}));
  const result = await request('https://api.osv.dev/v1/querybatch', {queries});
  if (result.results?.length !== batch.length) throw new Error('Incomplete OSV response.');
  for (let i = 0; i < batch.length; i++) {
    let page = result.results[i];
    const ids = new Set();
    while (true) {
      for (const vuln of page.vulns ?? []) ids.add(vuln.id);
      if (!page.next_page_token) break;
      page = (await request('https://api.osv.dev/v1/querybatch', {
        queries: [{...queries[i], page_token: page.next_page_token}],
      })).results[0];
    }
    if (ids.size) findings.push({...batch[i], ids: [...ids]});
  }
}
const advisories = {};
for (const id of new Set(findings.flatMap(f => f.ids))) {
  advisories[id] = await request(`https://api.osv.dev/v1/vulns/${encodeURIComponent(id)}`);
}
const activeFindings = findings.map(f => ({...f, ids: f.ids.filter(id => !advisories[id].withdrawn)})).filter(f => f.ids.length);
const report = {checkedAt: new Date().toISOString(), source: 'https://api.osv.dev',
  scope: 'Locked Pub/npm packages and resolved Android release runtime Maven components; not a malware or native-engine audit.',
  counts: Object.fromEntries(['Pub', 'npm', 'Maven'].map(e => [e, packages.filter(p => p.ecosystem === e).length])),
  packages, findings: activeFindings, advisories};
fs.mkdirSync(path.join(root, 'work'), {recursive: true});
fs.writeFileSync(path.join(root, 'work', 'dependency-audit.json'), JSON.stringify(report, null, 2));
console.log(JSON.stringify({counts: report.counts, findings: activeFindings}, null, 2));
if (activeFindings.length) process.exitCode = 1;
