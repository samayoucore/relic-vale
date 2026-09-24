// Check the exact standalone PCK that will be shipped. Format follows Godot's
// PackedSourcePCK::try_open_pack (4.7.2).
import fs from 'node:fs';
import crypto from 'node:crypto';
import path from 'node:path';

const filename = process.argv[2];
if (!filename) throw new Error('Usage: node audit_pack.mjs <RelicVale.pck> [report.json]');
const data = fs.readFileSync(filename);
function need(offset, size) {
  if (!Number.isSafeInteger(offset) || offset < 0 || offset + size > data.length)
    throw new Error(`PCK read outside file at ${offset} + ${size}`);
}
function u32(offset) { need(offset, 4); return data.readUInt32LE(offset); }
function u64(offset) {
  need(offset, 8);
  const n = data.readBigUInt64LE(offset);
  if (n > BigInt(Number.MAX_SAFE_INTEGER)) throw new Error('PCK offset too large');
  return Number(n);
}
if (u32(0) !== 0x43504447) throw new Error('PCK magic missing');
const version = u32(4), major = u32(8), minor = u32(12), flags = u32(20);
if (![2, 3, 4].includes(version) || major !== 4 || minor !== 7) throw new Error('Unexpected PCK/engine version');
if (flags & 1) throw new Error('Encrypted PCK directory cannot be audited');
if (flags & 4) throw new Error('Sparse PCK cannot be distributed standalone');
const fileBase = u64(24);
let cursor = version >= 3 ? u64(32) : 96;
const count = u32(cursor); cursor += 4;
if (count < 100 || count > 100000) throw new Error(`Implausible PCK file count ${count}`);
const seen = new Set();
const files = [];
for (let i = 0; i < count; i++) {
  const length = u32(cursor); cursor += 4;
  if (length < 1 || length > 4096) throw new Error('Invalid PCK path length');
  need(cursor, length);
  const name = data.subarray(cursor, cursor + length).toString('utf8').replace(/\0+$/, '');
  cursor += length;
  const offset = u64(cursor); cursor += 8;
  const size = u64(cursor); cursor += 8;
  need(cursor, 16);
  const expected = data.subarray(cursor, cursor + 16).toString('hex'); cursor += 16;
  const fileFlags = u32(cursor); cursor += 4;
  if (!name || name.startsWith('/') || name.includes('..') || seen.has(name)) throw new Error(`Invalid/duplicate PCK path: ${name}`);
  if (fileFlags !== 0) throw new Error(`Unexpected PCK file flags: ${name}`);
  if (/^(?:tests\/|docs\/)/i.test(name) || /(?:\.blend|\.psd|\.kra)$/i.test(name) || /phase10_active|phase10_launcher/i.test(name))
    throw new Error(`Development material shipped: ${name}`);
  need(fileBase + offset, size);
  const actual = crypto.createHash('md5').update(data.subarray(fileBase + offset, fileBase + offset + size)).digest('hex');
  if (actual !== expected) throw new Error(`PCK digest mismatch: ${name}`);
  seen.add(name);
  files.push({name, size, md5: actual});
}
for (const essential of ['project.binary', 'scenes/Main.tscn.remap']) {
  if (!seen.has(essential)) throw new Error(`Missing essential release file: ${essential}`);
}
const report = {pack: path.resolve(filename), pack_version: version, godot: `${major}.${minor}`, file_count: count, bytes: data.length, sha256: crypto.createHash('sha256').update(data).digest('hex'), files};
if (process.argv[3]) fs.writeFileSync(process.argv[3], JSON.stringify(report, null, 2));
console.log(`PCK_AUDIT ${count} entries, all digests valid, no development files`);
