const babel = require('@babel/core');
const fs = require('fs');
const pluginAddApiKeyCheck = require('./plugin');

const file = 'node_modules/@bitwarden/cli/build/bw.js';

// Read the original compiled code.
const code = fs.readFileSync(file, 'utf8');

if (code.includes('BITSAILOR_BW_API_KEY')) {
    console.log('The file has already been patched');
    return;
}

// Transform the code using the plugin.
const output = babel.transform(code, {
    plugins: [pluginAddApiKeyCheck],
});

fs.copyFileSync(file, `${file}.backup`)

// Write the patched code to a new file.
fs.writeFileSync(file, output.code);
console.log(`Patched code written to ${file}`);
