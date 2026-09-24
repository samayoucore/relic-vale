// Inspect PE imports using the Microsoft PE/COFF layout. This catches accidental
// dependencies on builder-only Visual C++ or MinGW runtime DLLs.
import fs from 'node:fs';
import path from 'node:path';

const file = process.argv[2];
if (!file) throw new Error('Usage: node audit_executable.mjs <RelicVale.exe> [report.json]');
const data = fs.readFileSync(file);
const u16 = p => data.readUInt16LE(p);
const u32 = p => data.readUInt32LE(p);
if (data.toString('ascii', 0, 2) !== 'MZ') throw new Error('Missing DOS MZ signature');
const pe = u32(0x3c);
if (data.toString('ascii', pe, pe + 4) !== 'PE\0\0') throw new Error('Missing PE signature');
const coff = pe + 4;
if (u16(coff) !== 0x8664) throw new Error('Release executable is not Windows x64');
const sectionCount = u16(coff + 2);
const optional = coff + 20;
if (u16(optional) !== 0x20b) throw new Error('Release executable is not PE32+');
const sections = [];
for (let i = 0, p = optional + u16(coff + 16); i < sectionCount; i++, p += 40) {
  sections.push({virtualSize: u32(p + 8), virtualAddress: u32(p + 12), rawSize: u32(p + 16), rawAddress: u32(p + 20)});
}
function offset(rva) {
  const s = sections.find(x => rva >= x.virtualAddress && rva < x.virtualAddress + Math.max(x.virtualSize, x.rawSize));
  if (!s) throw new Error(`PE RVA outside sections: ${rva}`);
  const p = s.rawAddress + rva - s.virtualAddress;
  if (p >= data.length) throw new Error('PE import outside file');
  return p;
}
function zstring(p) {
  const end = data.indexOf(0, p);
  if (end < p || end - p > 260) throw new Error('Invalid PE import name');
  return data.toString('ascii', p, end);
}
const directoryRva = u32(optional + 112 + 8);
if (!directoryRva) throw new Error('No PE import directory');
const imports = [];
for (let p = offset(directoryRva), i = 0; i < 300; p += 20, i++) {
  const nameRva = u32(p + 12);
  if (!nameRva) break;
  imports.push(zstring(offset(nameRva)).toUpperCase());
}
if (!imports.length) throw new Error('PE imports could not be read');
const forbidden = imports.filter(x => /^(?:VCRUNTIME|MSVCP|LIBGCC|LIBSTDC\+\+|LIBWINPTHREAD|PYTHON|NODE)/.test(x));
if (forbidden.length) throw new Error(`Unexpected development runtime imports: ${forbidden.join(', ')}`);
const report = {executable: path.resolve(file), architecture:'x86_64', imports};
if (process.argv[3]) fs.writeFileSync(process.argv[3], JSON.stringify(report, null, 2));
console.log(`PE_AUDIT x86_64; imports: ${imports.join(', ')}`);
