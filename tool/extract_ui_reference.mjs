// Read the approved local prototype; do not execute its DOM/event handlers.
import fs from 'node:fs';
import vm from 'node:vm';
const html = fs.readFileSync('design/fikrah-ui.html', 'utf8');
const prefix = html.split('<script>')[1].split('const N=')[0];
const context = vm.createContext({});
vm.runInContext(prefix, context);
const dictionary = vm.runInContext('T', context);
const ignored = new Set(['ans', 'tm', 'name', 'tags']); // Prototype-only data.
const placeholders = {greet:['name'], notes:['count'], links:['count','links'], based:['count'], hello:['count']};
for (const language of ['ar','en']) {
  const file = `lib/l10n/app_${language}.arb`;
  const arb = JSON.parse(fs.readFileSync(file, 'utf8'));
  for (const [key,value] of Object.entries(dictionary[language])) {
    if (ignored.has(key)) continue;
    const name = 'rd' + key[0].toUpperCase() + key.slice(1);
    if (Array.isArray(value)) { value.forEach((s,i)=>arb[name+i]=s); continue; }
    arb[name] = typeof value === 'function' ? value(...placeholders[key].map(p=>`{${p}}`)) : value;
    if (placeholders[key]) arb['@'+name] = {placeholders:Object.fromEntries(placeholders[key].map(p=>[p,{type:p==='name'?'String':'int'}]))};
  }
  fs.writeFileSync(file, JSON.stringify(arb,null,2)+'\n');
}
const css = html.split('<style>')[1].split('</style>')[0];
const tokens = [...css.matchAll(/--([a-z]+):([^;}]+)/g)].map(m=>({name:m[1],value:m[2]}));
fs.writeFileSync('docs/features/html-ui-redesign/reference-values.json',JSON.stringify({tokens,css},null,2)+'\n');

// Matching visual-test data is deliberately outside Flutter asset bundles.
const fixtureContext = vm.createContext({});
vm.runInContext(html.split('<script>')[1].split('const POS=')[0], fixtureContext);
const samples = vm.runInContext('({notes:N,edges:E,tags:{ar:T.ar.tags,en:T.en.tags}})',fixtureContext);
fs.mkdirSync('test/support/fixtures',{recursive:true});
fs.writeFileSync('test/support/fixtures/html-reference.json',JSON.stringify(samples,null,2)+'\n');
