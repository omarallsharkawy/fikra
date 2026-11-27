// Screenshot-only host normalization: remove desktop phone chrome/scrollbars.
// Component CSS, source copy, interactions and mock data remain unmodified.
import fs from 'node:fs';
const source = fs.readFileSync('design/fikrah-ui.html','utf8');
const directory = 'build/validation/redesign-prototype';
fs.mkdirSync(directory,{recursive:true});
fs.writeFileSync(`${directory}/fikrah-ui.html`,source);
const captureCss = '<style id="native-capture-host">#phone{width:398px;height:650px;flex:none;border:0;border-radius:0}#main{scrollbar-width:none}#main::-webkit-scrollbar{display:none}</style>';
fs.writeFileSync(`${directory}/fikrah-mobile-reference.html`,source.replace('</head>',`${captureCss}</head>`));
