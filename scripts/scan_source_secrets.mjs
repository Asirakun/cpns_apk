import {execFileSync} from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';
const files = [...new Set(execFileSync('git', ['ls-files','--cached','--others','--exclude-standard','-z'], {encoding:'utf8'}).split('\0').filter(Boolean))];
const patterns = [
  ['private key', /-----BEGIN (?:RSA |EC |OPENSSH |ENCRYPTED )?PRIVATE KEY-----/],
  ['Supabase secret', /sb_secret_[A-Za-z0-9_-]{20,}/],
  ['GitHub token', /(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{40,})/],
  ['AWS access key', /(?:AKIA|ASIA)[A-Z0-9]{16}/],
];
const findings = [];
let checked = 0;
for (const file of files) {
  if (!fs.existsSync(file) || !fs.statSync(file).isFile() || fs.statSync(file).size > 1500000) continue;
  const content = fs.readFileSync(file);
  if (content.includes(0)) continue;
  checked++;
  for (const [index, line] of content.toString('utf8').split(/\r?\n/).entries()) {
    for (const [kind, pattern] of patterns) {
      if (pattern.test(line)) findings.push({file, line:index+1, kind});
    }
    for (const match of line.matchAll(/eyJ[A-Za-z0-9_-]+\.([A-Za-z0-9_-]+)\.[A-Za-z0-9_-]+/g)) {
      try { if (JSON.parse(Buffer.from(match[1], 'base64url')).role === 'service_role') findings.push({file,line:index+1,kind:'service-role JWT'}); } catch {}
    }
  }
}
const ignored = execFileSync('git', ['check-ignore','android/key.properties'], {encoding:'utf8'}).trim() === 'android/key.properties';
if (!ignored) throw new Error('Local signing credentials must be ignored by Git.');
for (const candidate of ['android/example.p12','android/example.pfx','android/example.credentials.json']) {
  if (execFileSync('git', ['check-ignore', candidate], {encoding:'utf8'}).trim() !== candidate) throw new Error('Private signing material must be ignored by Git.');
}
const report = {checkedAt:new Date().toISOString(), scope:'Pattern scan of tracked/unignored text files up to 1.5 MB; not exhaustive secret detection.', checkedFiles:checked, signingConfigIgnored:ignored, findings};
fs.mkdirSync('work', {recursive:true});
fs.writeFileSync(path.join('work','source-secrets.json'), JSON.stringify(report,null,2));
console.log(JSON.stringify(report,null,2));
if (findings.length) process.exitCode = 1;
