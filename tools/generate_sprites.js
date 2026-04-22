#!/usr/bin/env node
/**
 * Pixel art sprite generator for Wasteland Survivor.
 * Generates 32x32 pixel art PNGs using pure JavaScript (no dependencies).
 * Output: assets/sprites/
 */

const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const OUT_DIR = path.join(__dirname, '..', 'assets', 'sprites');

// --- Minimal PNG encoder (no deps) ---
function createPNG(width, height, pixels) {
  // pixels: Uint8Array of RGBA data, length = width * height * 4
  const signature = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);

  // IHDR
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(width, 0);
  ihdr.writeUInt32BE(height, 4);
  ihdr[8] = 8;  // bit depth
  ihdr[9] = 6;  // color type: RGBA
  ihdr[10] = 0; // compression
  ihdr[11] = 0; // filter
  ihdr[12] = 0; // interlace
  const ihdrChunk = makeChunk('IHDR', ihdr);

  // IDAT - raw pixel data with filter byte per row
  const raw = Buffer.alloc(height * (1 + width * 4));
  for (let y = 0; y < height; y++) {
    raw[y * (1 + width * 4)] = 0; // no filter
    for (let x = 0; x < width; x++) {
      const srcIdx = (y * width + x) * 4;
      const dstIdx = y * (1 + width * 4) + 1 + x * 4;
      raw[dstIdx] = pixels[srcIdx];
      raw[dstIdx + 1] = pixels[srcIdx + 1];
      raw[dstIdx + 2] = pixels[srcIdx + 2];
      raw[dstIdx + 3] = pixels[srcIdx + 3];
    }
  }
  const compressed = zlib.deflateSync(raw);
  const idatChunk = makeChunk('IDAT', compressed);

  // IEND
  const iendChunk = makeChunk('IEND', Buffer.alloc(0));

  return Buffer.concat([signature, ihdrChunk, idatChunk, iendChunk]);
}

function makeChunk(type, data) {
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length, 0);
  const typeB = Buffer.from(type, 'ascii');
  const crcData = Buffer.concat([typeB, data]);
  const crc = crc32(crcData);
  const crcB = Buffer.alloc(4);
  crcB.writeUInt32BE(crc >>> 0, 0);
  return Buffer.concat([len, typeB, data, crcB]);
}

function crc32(buf) {
  let c = 0xFFFFFFFF;
  for (let i = 0; i < buf.length; i++) {
    c ^= buf[i];
    for (let j = 0; j < 8; j++) {
      c = (c >>> 1) ^ (c & 1 ? 0xEDB88320 : 0);
    }
  }
  return c ^ 0xFFFFFFFF;
}

// --- Pixel art drawing helpers ---
function createCanvas(w, h) {
  return { width: w, height: h, data: new Uint8Array(w * h * 4) };
}

function setPixel(canvas, x, y, r, g, b, a = 255) {
  if (x < 0 || x >= canvas.width || y < 0 || y >= canvas.height) return;
  const i = (y * canvas.width + x) * 4;
  canvas.data[i] = r;
  canvas.data[i + 1] = g;
  canvas.data[i + 2] = b;
  canvas.data[i + 3] = a;
}

function fillRect(canvas, x, y, w, h, r, g, b, a = 255) {
  for (let dy = 0; dy < h; dy++)
    for (let dx = 0; dx < w; dx++)
      setPixel(canvas, x + dx, y + dy, r, g, b, a);
}

function drawFromGrid(canvas, grid, palette, offX = 0, offY = 0) {
  for (let y = 0; y < grid.length; y++) {
    const row = grid[y];
    for (let x = 0; x < row.length; x++) {
      const ch = row[x];
      if (ch === '.' || ch === ' ') continue; // transparent
      const col = palette[ch];
      if (col) setPixel(canvas, offX + x, offY + y, col[0], col[1], col[2], col[3] !== undefined ? col[3] : 255);
    }
  }
}

function savePNG(subdir, name, canvas) {
  const dir = path.join(OUT_DIR, subdir);
  fs.mkdirSync(dir, { recursive: true });
  const png = createPNG(canvas.width, canvas.height, canvas.data);
  const fpath = path.join(dir, name + '.png');
  fs.writeFileSync(fpath, png);
  console.log(`  ✓ ${subdir}/${name}.png (${canvas.width}x${canvas.height})`);
}

// =====================================================================
// PLAYER CHARACTERS (32x32, top-down view)
// =====================================================================

function genSurvivor() {
  const c = createCanvas(32, 32);
  const p = {
    'O': [50, 45, 40],      // outline / dark
    'S': [140, 110, 80],    // skin
    'H': [60, 50, 35],      // hair
    'J': [80, 100, 70],     // jacket (green military)
    'j': [60, 80, 55],      // jacket shadow
    'P': [70, 65, 55],      // pants
    'p': [55, 50, 42],      // pants shadow
    'B': [100, 80, 60],     // boots
    'b': [75, 60, 45],      // boots shadow
    'E': [200, 200, 180],   // eyes
    'G': [120, 120, 110],   // gun / metal
    'g': [90, 90, 82],      // gun shadow
  };
  const grid = [
    '................................',
    '................................',
    '................................',
    '................................',
    '..........OOOOOOOOOO...........',
    '.........OHHHHHHHHHHO..........',
    '........OHHHHHHHHHHHO..........',
    '........OHHHHHHHHHHHHO.........',
    '.......OOSSSSSSSSSSOO..........',
    '.......OSEESSSSSEEESO..........',
    '.......OSSSSSOOSSSSSO..........',
    '.......OSSSSSSSSSSSSO..........',
    '........OSSSSSSSSSO...........',
    '.......OOJJJJJJJJJOO..........',
    '......OJJJJJJJJJJJJJjO........',
    '......OJJJJJJJJJJJJJjO........',
    '.....OJJJJJJJJJJJJJJjjO.......',
    '.....OjJJJJJJJJJJJJJjjO.......',
    '.....OjJJJJJGGGJJJJjjjO.......',
    '.....OjjJJJGGggGJJJjjjO.......',
    '......OjjJJGGggGJJjjjO........',
    '......OOjjJJJJJJJjjjOO........',
    '.......OOPPPPPPPPPOO..........',
    '......OPPPPPPPPPPPPpO.........',
    '......OPPPPPPPPPPPPpO.........',
    '......OpPPPPPPPPPPppO.........',
    '.......OppPPPPPPppO...........',
    '.......OOBBBBBBBOO............',
    '......OBBBBBBBBBBbO...........',
    '......ObBBBBbbBBBbO...........',
    '......OOOOOOOOOOOOOO..........',
    '................................',
  ];
  drawFromGrid(c, grid, p);
  return c;
}

function genScavenger() {
  const c = createCanvas(32, 32);
  const p = {
    'O': [40, 40, 35],
    'S': [150, 120, 90],
    'H': [80, 70, 50],
    'C': [50, 120, 60],     // green coat
    'c': [35, 90, 45],
    'P': [80, 75, 60],
    'B': [70, 60, 50],
    'E': [220, 220, 200],
    'K': [140, 120, 80],    // backpack
    'k': [110, 95, 65],
  };
  const grid = [
    '................................',
    '................................',
    '................................',
    '................................',
    '..........OOOOOOOOOO...........',
    '.........OHHHHHHHHHHO..........',
    '........OHHHHHHHHHHHO..........',
    '........OHHHHHHHHHHHO..........',
    '.......OOSSSSSSSSSSOO..........',
    '.......OSEESSSSSEEESO..........',
    '.......OSSSSSOOSSSSSO..........',
    '.......OSSSSSSSSSSSSO..........',
    '........OSSSSSSSSSO...........',
    '.......OOCCCCCCCCCOKKOO........',
    '......OCCCCCCCCCCCCcKKkO.......',
    '......OCCCCCCCCCCCCcKKkO.......',
    '.....OCCCCCCCCCCCCCccKkO.......',
    '.....OcCCCCCCCCCCCCccKkO.......',
    '.....OcCCCCCCCCCCCcccOOO.......',
    '.....OccCCCCCCCCCcccO..........',
    '......OccCCCCCCCcccO...........',
    '......OOccCCCCCcccOO...........',
    '.......OOPPPPPPPOO............',
    '......OPPPPPPPPPPPpO..........',
    '......OPPPPPPPPPPPpO..........',
    '......OPPPPPPPPPPOO...........',
    '.......OOPPPPPPOO.............',
    '.......OOBBBBBOO..............',
    '......OBBBBBBBBBbO............',
    '......OOOOOOOOOOOOO...........',
    '................................',
    '................................',
  ];
  drawFromGrid(c, grid, p);
  return c;
}

function genDemolisher() {
  const c = createCanvas(32, 32);
  const p = {
    'O': [45, 30, 20],
    'S': [130, 105, 75],
    'H': [40, 35, 30],
    'A': [160, 60, 20],     // armor (orange-red)
    'a': [120, 45, 15],
    'P': [60, 55, 45],
    'B': [80, 60, 40],
    'E': [230, 210, 180],
    'F': [220, 120, 30],    // fire detail
    'M': [100, 100, 95],    // metal
  };
  const grid = [
    '................................',
    '................................',
    '................................',
    '................................',
    '..........OOOOOOOOOO...........',
    '.........OHHHHHHHHHHO..........',
    '........OHHHHHHHHHHHHO.........',
    '........OHHHHHHHHHHHO..........',
    '.......OOSSSSSSSSSSOO..........',
    '.......OSEESSSSSEEESO..........',
    '.......OSSSSSOOSSSSSO..........',
    '.......OSSSSSSSSSSSSO..........',
    '........OSSSSSSSSSO...........',
    '.......OOAAAAAAAAAOOO..........',
    '......OAAAAFFAAFFAAAO..........',
    '......OAAAAFFAAFFAAAaO.........',
    '.....OAAAAAAAAAAAAAAAAaO.......',
    '.....OaAAAAAAAAAAAAAaaO.......',
    '.....OaAAAAMMMMAAAAaaO........',
    '.....OaaAAAMMMMAAaaaO.........',
    '......OaaAAAAAAAAaaaO..........',
    '......OOaaAAAAaaaaaOO..........',
    '.......OOPPPPPPPPOO...........',
    '......OPPPPPPPPPPPpO..........',
    '......OPPPPPPPPPPPpO..........',
    '......OPPPPPPPPPPOO...........',
    '.......OOPPPPPPOO.............',
    '.......OOBBBBBOO..............',
    '......OBBBBBBBBBbO............',
    '......OOOOOOOOOOOOO...........',
    '................................',
    '................................',
  ];
  drawFromGrid(c, grid, p);
  return c;
}

function genMutant() {
  const c = createCanvas(32, 32);
  const p = {
    'O': [40, 20, 30],
    'S': [160, 130, 160],   // pale purple skin
    'H': [90, 40, 60],
    'V': [180, 60, 100],    // veins / mutation
    'v': [140, 45, 75],
    'P': [65, 50, 55],
    'B': [70, 55, 60],
    'E': [255, 80, 80],     // red glowing eyes
    'T': [100, 80, 90],     // torn clothes
    't': [75, 60, 68],
  };
  const grid = [
    '................................',
    '................................',
    '................................',
    '................................',
    '..........OOOOOOOOOO...........',
    '.........OHHHVHHHVHHO..........',
    '........OHHVHHHHVHHHO..........',
    '........OHHHHHHHHHHO...........',
    '.......OOSSSSVSSSSSOO..........',
    '.......OSEESSSSSEESO...........',
    '.......OSSVSSOOSVSSSO..........',
    '.......OSSSSSSSSSSSO...........',
    '........OSSSVSSSSO............',
    '.......OOTTTTTTTTTOOO..........',
    '......OTTTTVTTTVTTTtO.........',
    '......OTTTVTTTTVTTTtO.........',
    '.....OTTTTTTTTTTTTTttO........',
    '.....OtTTTTTTTTTTTTttO........',
    '.....OtTTTVVVVTTTtttO.........',
    '.....OttTTTVVTTTtttO..........',
    '......OttTTTTTTtttO...........',
    '......OOttTTTTtttOO...........',
    '.......OOPPPPPPPOO............',
    '......OPPPPPPPPPPPpO..........',
    '......OPPPPPPPPPPPpO..........',
    '......OPPPPPPPPPPOO...........',
    '.......OOPPPPPPOO.............',
    '.......OOBBBBBOO..............',
    '......OBBBBBBBBBbO............',
    '......OOOOOOOOOOOOO...........',
    '................................',
    '................................',
  ];
  drawFromGrid(c, grid, p);
  return c;
}

// =====================================================================
// ENEMIES (varied sizes)
// =====================================================================

function genWalker() {
  const c = createCanvas(24, 24);
  const p = {
    'O': [40, 15, 15],
    'F': [170, 100, 80],    // decayed flesh
    'f': [130, 75, 60],
    'E': [200, 200, 50],    // yellow eyes
    'R': [120, 40, 40],     // rags
    'r': [90, 30, 30],
    'B': [60, 50, 40],
  };
  const grid = [
    '........................',
    '........................',
    '.......OOOOOOOO.........',
    '......OFFFFFFFFO........',
    '......OFEEFFEFO........',
    '......OFFFFOFFFFO.......',
    '.......OFFFFFFO.........',
    '......OORRRRRROO........',
    '.....ORRRRRRRRRrO.......',
    '.....ORRRRRRRRRrO.......',
    '.....OrRRRRRRRrrO.......',
    '.....OrRRRRRRRrrO.......',
    '......OrrRRRrrO.........',
    '......OOBBBBBOO.........',
    '.....OBBBBBBBBBbO.......',
    '.....OBBBBBBBBBbO.......',
    '.....OBBBBBBBBOO........',
    '......OOBBBOO...........',
    '........................',
    '........................',
    '........................',
    '........................',
    '........................',
    '........................',
  ];
  drawFromGrid(c, grid, p);
  return c;
}

function genMutantDog() {
  const c = createCanvas(24, 18);
  const p = {
    'O': [50, 30, 10],
    'F': [180, 120, 50],    // fur
    'f': [140, 90, 35],
    'E': [255, 60, 60],     // red eyes
    'N': [60, 40, 30],      // nose
    'T': [220, 180, 80],    // teeth
    'L': [120, 90, 40],     // legs
  };
  const grid = [
    '........................',
    '...OO...OOOOOOOO........',
    '..OFFO.OFFFFFFFFO.......',
    '..OFFOOFFEFFFFFFO.......',
    '...OOOFFNFFFFFFFO.......',
    '.....OTFFFFFFFFFO.......',
    '....OFFFFFFFFFFFFfO.....',
    '....OfFFFFFFFFFFffO.....',
    '....OfFFFFFFFFFFffO.....',
    '....OffFFFFFFFfffO......',
    '.....OffFFFFFffO........',
    '.....OOLLOOLLLOO........',
    '....OLLLOOLLLLOO........',
    '....OLLLOOLLLLOO........',
    '....OOOOOOOOOOO.........',
    '........................',
    '........................',
    '........................',
  ];
  drawFromGrid(c, grid, p);
  return c;
}

function genAcidBug() {
  const c = createCanvas(20, 20);
  const p = {
    'O': [20, 50, 10],
    'G': [80, 200, 40],     // green body
    'g': [55, 150, 30],
    'E': [255, 255, 100],   // yellow eyes
    'A': [120, 230, 60],    // acid glow
    'L': [50, 120, 25],     // legs
  };
  const grid = [
    '....................',
    '......OOOOOO........',
    '.....OGGGGGGGO......',
    '....OGGEGGEGGO......',
    '...OLGGGGGGGGLO.....',
    '...OLGAAGAAGGLO.....',
    '..OLGGGGGGGGGGLO....',
    '..OLgGGGGGGGGgLO...',
    '..OLgGGAAAAGGgLO...',
    '...OLgGGAAGGgLO.....',
    '...OLgGGGGGGgLO.....',
    '....OLggGGggLO......',
    '.....OLgGGgLO.......',
    '......OLGGLO........',
    '.......OLLO.........',
    '........OO..........',
    '....................',
    '....................',
    '....................',
    '....................',
  ];
  drawFromGrid(c, grid, p);
  return c;
}

function genIronGiant() {
  const c = createCanvas(40, 40);
  const p = {
    'O': [35, 35, 40],
    'M': [130, 130, 145],   // metal body
    'm': [100, 100, 112],
    'E': [200, 50, 50],     // red eyes
    'R': [160, 80, 40],     // rust
    'r': [120, 60, 30],
    'B': [80, 80, 90],      // dark metal
    'S': [180, 180, 195],   // shiny highlight
  };
  const grid = [
    '........................................',
    '........................................',
    '........................................',
    '...........OOOOOOOOOOOOOOOO.............',
    '..........OMMMMMMMMMMMMMMMMO............',
    '.........OMMMMMSMMMMSMMMMMMMO...........',
    '.........OMMMMMMMMMMMMMMMMMO............',
    '........OOMMMMMMMMMMMMMMMMOOO..........',
    '........OMEEMMMMMMMMMEEMMMO............',
    '........OMMMMMMOOMMMMMMMMO.............',
    '........OMMMMMMMMMMMMMMMO..............',
    '.........OMMMRRMMRRMMMMO...............',
    '........OOBBBBBBBBBBBBBOO..............',
    '.......OBBBMMMMMMMMMBBBBO..............',
    '......OBBMMMMMMMMMMMMMBBO..............',
    '......OBMMMMSMMMMSMMMMMBBO.............',
    '.....OBMMMMMMMMMMMMMMMMMBO.............',
    '.....OBmMMMMMMMMMMMMMMmBBO.............',
    '.....OBmMMMRRRRRRMMMMMmBO..............',
    '.....OBmMMMRRRRRRMMMmBBO...............',
    '......OBmmMMMMMMMmmmBBO................',
    '......OBBmmMMMMmmmBBBO.................',
    '.......OBBBBBBBBBBBBbO.................',
    '......OBBBBBBBBBBBBBBOO................',
    '......OBBBBBBBBBBBBBBbO................',
    '......OBmBBBBBBBBBBmBO.................',
    '.......OBmBBBBBBBBmBO..................',
    '.......OOBBBBBBBBBOO...................',
    '......OBBBBBBBBBBBBBO..................',
    '......OBBBBBBBBBBBBBbO.................',
    '......OmBBBBBmmBBBBmO..................',
    '.......OOOOOOOOOOOOoO..................',
    '........................................',
    '........................................',
    '........................................',
    '........................................',
    '........................................',
    '........................................',
    '........................................',
    '........................................',
  ];
  drawFromGrid(c, grid, p);
  return c;
}

function genExploder() {
  const c = createCanvas(18, 18);
  const p = {
    'O': [60, 20, 0],
    'R': [220, 80, 20],     // red-orange body
    'r': [180, 60, 15],
    'Y': [255, 200, 50],    // yellow glow
    'E': [255, 255, 180],   // bright eyes
    'F': [255, 140, 40],    // fire detail
  };
  const grid = [
    '..................',
    '.....YFFY.........',
    '....YFFFYY........',
    '.....YYYF.........',
    '....OOOOOOOO......',
    '...ORRRRRRRO......',
    '...ORERRRERO......',
    '..ORRRROORRRO.....',
    '..ORRRRRRRRrO.....',
    '..OrRRFFRRRrO.....',
    '..OrRRFFRRrrO.....',
    '...OrrRRRrrO......',
    '...OrrRRRrrO......',
    '....OrrrrO........',
    '.....OOOO.........',
    '..................',
    '..................',
    '..................',
  ];
  drawFromGrid(c, grid, p);
  return c;
}

function genBoss() {
  const c = createCanvas(64, 64);
  const p = {
    'O': [30, 10, 10],
    'D': [100, 30, 30],     // dark crimson body
    'd': [75, 22, 22],
    'R': [150, 50, 40],     // red highlights
    'E': [255, 180, 50],    // glowing orange eyes
    'M': [80, 40, 35],      // mouth
    'A': [120, 55, 45],     // armor plates
    'a': [90, 40, 32],
    'S': [60, 25, 20],      // shadow
    'F': [200, 80, 30],     // fire/lava cracks
    'H': [70, 30, 25],      // horns
  };
  // 64x64 boss - massive ash behemoth
  const grid = [];
  // Build a menacing boss shape
  for (let y = 0; y < 64; y++) {
    let row = '';
    for (let x = 0; x < 64; x++) {
      const cx = x - 32, cy = y - 32;
      const dist = Math.sqrt(cx * cx + cy * cy);

      // Horns on top
      if (y >= 4 && y <= 12 && ((x >= 18 && x <= 22) || (x >= 40 && x <= 44))) {
        row += dist < 3 ? '.' : 'H';
      }
      // Head area
      else if (y >= 10 && y <= 22 && x >= 16 && x <= 46) {
        if (y === 10 || y === 22 || x === 16 || x === 46) row += 'O';
        else if (y >= 15 && y <= 17 && ((x >= 21 && x <= 24) || (x >= 38 && x <= 41))) row += 'E';
        else if (y >= 19 && y <= 20 && x >= 26 && x <= 36) row += 'M';
        else row += 'D';
      }
      // Body
      else if (y >= 22 && y <= 48 && x >= 10 && x <= 52) {
        if (y === 22 || y === 48 || x === 10 || x === 52) row += 'O';
        else if ((x + y) % 12 === 0) row += 'F';
        else if (y >= 24 && y <= 44 && (x <= 14 || x >= 48)) row += 'A';
        else if (dist > 18) row += 'a';
        else row += 'R';
      }
      // Legs
      else if (y >= 48 && y <= 58 && ((x >= 14 && x <= 24) || (x >= 38 && x <= 48))) {
        if (y === 58 || ((x === 14 || x === 24 || x === 38 || x === 48) && y > 48)) row += 'O';
        else row += 'd';
      }
      else {
        row += '.';
      }
    }
    grid.push(row);
  }
  drawFromGrid(c, grid, p);
  return c;
}

// =====================================================================
// XP GEM
// =====================================================================
function genXpGem() {
  const c = createCanvas(12, 12);
  const p = {
    'O': [20, 60, 20],
    'G': [80, 220, 100],
    'g': [50, 180, 70],
    'S': [150, 255, 170],   // shine
  };
  const grid = [
    '............',
    '....OOOO....',
    '...OGGGGO...',
    '..OGGSGGGO..',
    '..OGGGGGGGO.',
    '..OGGGGGgO..',
    '..OGGGGGgO..',
    '..OgGGGggO..',
    '...OgGGgO...',
    '....OggO....',
    '.....OO.....',
    '............',
  ];
  drawFromGrid(c, grid, p);
  return c;
}

// =====================================================================
// BULLET
// =====================================================================
function genBullet() {
  const c = createCanvas(8, 8);
  const p = {
    'O': [80, 70, 40],
    'B': [200, 180, 100],
    'b': [160, 140, 80],
    'S': [240, 220, 150],
  };
  const grid = [
    '..OOOO..',
    '.OSBBO..',
    'OSBBBBO.',
    'OSBBBbO.',
    'OBBBBbO.',
    '.OBBbO..',
    '.ObbO...',
    '..OO....',
  ];
  drawFromGrid(c, grid, p);
  return c;
}


// =====================================================================
// GENERATE ALL
// =====================================================================
console.log('Generating pixel art sprites...\n');

console.log('Players:');
savePNG('player', 'survivor', genSurvivor());
savePNG('player', 'scavenger', genScavenger());
savePNG('player', 'demolisher', genDemolisher());
savePNG('player', 'mutant', genMutant());

console.log('\nEnemies:');
savePNG('enemies', 'walker', genWalker());
savePNG('enemies', 'mutant_dog', genMutantDog());
savePNG('enemies', 'acid_bug', genAcidBug());
savePNG('enemies', 'iron_giant', genIronGiant());
savePNG('enemies', 'exploder', genExploder());
savePNG('enemies', 'boss_ash_behemoth', genBoss());

console.log('\nPickups:');
savePNG('pickups', 'xp_gem', genXpGem());
savePNG('pickups', 'bullet', genBullet());

console.log('\nDone! All sprites generated.');