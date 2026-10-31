const { spawn } = require('node:child_process');
const action = process.argv[2];
if (!['dev', 'build'].includes(action)) throw new Error('Usa dev o build.');
const child = spawn(process.execPath, [require.resolve('next/dist/bin/next'), action, ...process.argv.slice(3)], {
  stdio: 'inherit', env: { ...process.env, NEXT_PUBLIC_APP_MODE: 'mock' },
});
child.on('error', error => { console.error(error.message); process.exitCode = 1; });
child.on('exit', code => { process.exitCode = code ?? 1; });
