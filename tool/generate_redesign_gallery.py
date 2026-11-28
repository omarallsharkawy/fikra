"""Publish only allow-listed synthetic/reference captures, never device/account images."""
from pathlib import Path
import json
import shutil

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / 'build/validation/redesign'
DEST = ROOT / 'docs/features/html-ui-redesign/visual-evidence'
SCREENS = ['landing', 'signup', 'signup-filled', 'login', 'home', 'note-detail', 'map',
           'ask-empty', 'ask-answered', 'capture', 'capture-filled', 'capture-recording', 'me']
manifest = {}
for group in ['before', 'reference', 'after', 'rtl-before', 'rtl-after']:
    names = []
    for screen in SCREENS:
        for ui in ['ar', 'en']:
            for theme in ['light', 'dark']:
                for content in (['ar', 'en'] if group.startswith('rtl-') else [None]):
                    name = '-'.join(filter(None, [screen, ui, content, theme])) + '.png'
                    source = SOURCE / group / name
                    if source.is_file():
                        target = DEST / group / name
                        target.parent.mkdir(parents=True, exist_ok=True)
                        shutil.copyfile(source, target)
                        names.append(name)
    manifest[group] = names
DEST.mkdir(parents=True, exist_ok=True)
(DEST / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
html = '''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>FIKRAH mobile comparison evidence</title>
<style>body{font:16px system-ui;margin:24px;background:#15151a;color:#eee}h1{font-size:24px}p{max-width:1000px;line-height:1.6;color:#bbb}label{display:inline-flex;flex-direction:column;gap:6px;margin:8px 16px 20px 0}select{font:inherit;padding:8px;border-radius:8px}main{display:flex;align-items:flex-start;gap:16px;flex-wrap:wrap}figure{margin:0;width:398px;max-width:100%}figcaption{height:48px;color:#ddd;line-height:1.4}img{width:100%;height:auto;border:1px solid #555;border-radius:12px}aside{padding:24px;border:1px dashed #777}a{color:#bbaaff}</style>
<h1>FIKRAH mobile: before / HTML / after</h1>
<p>These Flutter screenshots use test-only synthetic repository data; HTML frames contain the prototype samples. No private device/account captures are published. Normal frames are 398×650 at 100% text; the RTL matrix uses 130% text. HTML changes sample content with its UI language and cannot independently show the opposite content-language combination. This gallery supports visual inspection, not a claim of byte-identical browser/native typography or device E2E completion.</p>
<label>Matrix<select id="matrix"><option value="normal">Redesign baseline (100%)</option><option value="rtl">RTL audit (130%)</option></select></label>
<label>Screen<select id="screen"></select></label>
<label>UI language<select id="ui"><option>ar</option><option>en</option></select></label>
<label>Content language (RTL only)<select id="content"><option>ar</option><option>en</option></select></label>
<label>Theme<select id="theme"><option>light</option><option>dark</option></select></label>
<main id="frames"></main>
<script>
const manifest=MANIFEST, screens=SCREENS;
const $=id=>document.getElementById(id);
screens.forEach(s=>$('screen').add(new Option(s,s)));
function render(){const rtl=$('matrix').value==='rtl',s=$('screen').value,u=$('ui').value,c=$('content').value,t=$('theme').value;
$('content').disabled=!rtl; $('frames').replaceChildren();
for(const [group,title] of [[rtl?'rtl-before':'before','Before'],['reference','HTML reference (100%)'],[rtl?'rtl-after':'after','After']]){
const name=[s,u,...(group.startsWith('rtl-')?[c]:[]),t].join('-')+'.png', figure=document.createElement('figure'), caption=document.createElement('figcaption');caption.textContent=title+' · '+s;figure.append(caption);
if(manifest[group].includes(name)){const a=document.createElement('a'),img=document.createElement('img');a.href=group+'/'+name;img.src=a.href;img.alt=title+' '+name;img.loading='lazy';a.append(img);figure.append(a);}else{const aside=document.createElement('aside');aside.textContent='No baseline/reference was captured for this extra state. No image is substituted.';figure.append(aside);} $('frames').append(figure);}}
for(const id of ['matrix','screen','ui','content','theme'])$(id).addEventListener('change',render);render();
</script></html>'''
html = html.replace('MANIFEST', json.dumps(manifest)).replace('SCREENS', json.dumps(SCREENS))
(DEST / 'index.html').write_text(html)
print({group: len(names) for group, names in manifest.items()})
