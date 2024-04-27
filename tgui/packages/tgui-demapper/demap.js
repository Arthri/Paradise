import { readFile, readdir } from 'fs/promises';
import { join } from 'path';
import { createInterface } from 'readline';
import { SourceMapConsumer } from 'source-map';

const publicPath = join(import.meta.dirname, '../../public/');
const publicFilesOrDirs = await readdir(publicPath, { withFileTypes: true });
/** @type{Map<string, SourceMapConsumer>} */
const sourceMaps = new Map();
for await (const entry of publicFilesOrDirs) {
  if (!(entry.isFile() && entry.name.endsWith('.map'))) {
    continue;
  }

  const map = await readFile(join(entry.path, entry.name), 'utf8');
  const mapName = entry.name.replace(/\.map$/g, '');
  console.log(`Loading source map for ${mapName} from ${entry.name}...`);
  sourceMaps.set(mapName, await new SourceMapConsumer(map, null));
}

let stackTrace = '';
const processStackTrace = (/** @type{string} */ stackTrace) => {
  let result = '';
  for (const stackLine of stackTrace.matchAll(
    /\s+at ([\w $]+) \(https?:\/\/[^/]+\/([^:]+):(\d+):(\d+)\)/gm
  )) {
    const [_, identifier, file, line, column] = stackLine;
    const sourceMap = sourceMaps.get(file);
    if (sourceMap === undefined) {
      console.error(`Unmapped file ${file}`);
      result += line;
      continue;
    }
    const original = sourceMap.originalPositionFor({
      line: parseInt(line, 10),
      column: parseInt(column, 10),
    });
    result += `  at ${original.name ?? '<Unknown>'} (${original.source}:${original.line}:${original.column})\n`;
  }
  return result;
};

const rl = createInterface({
  input: process.stdin,
  output: process.stdout,
  terminal: false,
});

rl.on('line', (line) => {
  if (line === '') {
    if (stackTrace === '') {
      console.log('No stack trace entered.');
    } else {
      console.log(processStackTrace(stackTrace));
    }
    stackTrace = '';
  } else {
    stackTrace += line;
    stackTrace += '\n';
  }
});

console.log('Demapper initialized.');
