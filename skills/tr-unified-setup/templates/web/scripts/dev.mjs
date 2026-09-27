// Runs both components together, the way they run on the target: one origin, the web
// component at the root and the api under /api. Vite's dev server forwards /api to the api
// process (see apps/web/vite.config.ts), so the browser never sees a second origin.

import { spawn } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const repo = path.dirname(path.dirname(fileURLToPath(import.meta.url)));
// uv and npm are found on PATH by name, which on Windows means going through the shell.
const shell = process.platform === 'win32';

const components = [
  {
    name: 'api',
    cwd: path.join(repo, 'apps', 'api'),
    command: 'uv',
    args: ['run', 'uvicorn', 'api.main:app', '--reload', '--host', '127.0.0.1', '--port', '8000'],
  },
  {
    name: 'web',
    cwd: path.join(repo, 'apps', 'web'),
    command: 'npm',
    args: ['run', 'dev'],
  },
];

const running = components.map(({ name, cwd, command, args }) => {
  const child = spawn(command, args, { cwd, shell });
  const say = text => text.split(/\r?\n/).filter(Boolean).forEach(line => console.log(`[${name}] ${line}`));
  child.stdout.on('data', data => say(data.toString()));
  child.stderr.on('data', data => say(data.toString()));
  child.on('exit', code => {
    console.log(`[${name}] exited (${code})`);
    stop();
  });
  return child;
});

let stopping = false;
function stop() {
  if (stopping) return;
  stopping = true;
  running.forEach(child => child.kill());
}

process.on('SIGINT', stop);
process.on('SIGTERM', stop);

console.log('Starting both components. Open http://localhost:5173 and the api answers there under /api.');
