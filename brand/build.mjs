// Renders the brand SVGs in brand/ to the PNGs the site ships in public/:
//   og-image.jpg          1200x630  link preview (WhatsApp, Telegram, X...); JPEG to
//                                   stay well under WhatsApp's ~300 KB preview limit
//   apple-touch-icon.png   180x180  iOS home screen
//   icon-512.png           512x512  Android / generic
// Lives next to the SVGs it renders. Uses the same fonts as the site (Fontsource woff2, decompressed to temp TTFs,
// since resvg only reads font files). Rubik is the static 700 cut: resvg doesn't
// do variable-font weights.
// Usage: npm run brand   (re-run after editing anything in brand/)

import { mkdtemp, readFile, writeFile } from 'node:fs/promises'
import { tmpdir } from 'node:os'
import { basename, join } from 'node:path'
import { fileURLToPath } from 'node:url'
import { Resvg } from '@resvg/resvg-js'
import sharp from 'sharp'
import wawoff2 from 'wawoff2'

const root = (p) => fileURLToPath(new URL(`../${p}`, import.meta.url)) // repo root
const read = (p) => readFile(root(p))

const fontFiles = [
  'node_modules/@fontsource/bungee/files/bungee-latin-400-normal.woff2',
  'node_modules/@fontsource/monoton/files/monoton-latin-400-normal.woff2',
  'node_modules/@fontsource/rubik/files/rubik-latin-700-normal.woff2',
]
const fontDir = await mkdtemp(join(tmpdir(), 'jom-fonts-'))
const fontPaths = await Promise.all(
  fontFiles.map(async (f) => {
    const out = join(fontDir, basename(f).replace('.woff2', '.ttf'))
    await writeFile(out, Buffer.from(await wawoff2.decompress(await read(f))))
    return out
  }),
)

const markDataUrl = `data:image/svg+xml;base64,${(await read('brand/mark.svg')).toString('base64')}`

// Bulbs along the OG marquee frame (x 18..1182, y 18..612), one every ~46px.
function frameBulbs() {
  const [x0, y0, x1, y1, step] = [18, 18, 1182, 612, 46]
  const w = x1 - x0
  const h = y1 - y0
  const nw = Math.round(w / step)
  const nh = Math.round(h / step)
  const pts = []
  for (let i = 0; i < nw; i++) pts.push([x0 + (i * w) / nw, y0])
  for (let i = 0; i < nh; i++) pts.push([x1, y0 + (i * h) / nh])
  for (let i = 0; i < nw; i++) pts.push([x1 - (i * w) / nw, y1])
  for (let i = 0; i < nh; i++) pts.push([x0, y1 - (i * h) / nh])
  return pts.map(([x, y]) => `<circle cx="${x.toFixed(1)}" cy="${y.toFixed(1)}" r="7"/>`).join('')
}

async function render(svgPath, outPath, width, { jpeg = false } = {}) {
  const svg = (await read(svgPath))
    .toString('utf8')
    .replaceAll('__MARK__', markDataUrl)
    .replace('__BULBS__', frameBulbs())
  const png = new Resvg(svg, {
    fitTo: { mode: 'width', value: width },
    font: { fontFiles: fontPaths, loadSystemFonts: false, defaultFontFamily: 'Rubik Light' },
  })
    .render()
    .asPng()
  const out = jpeg ? await sharp(png).jpeg({ quality: 86, mozjpeg: true }).toBuffer() : png
  await writeFile(root(outPath), out)
  console.log(`  ${outPath}  ${width}px  ${(out.length / 1024).toFixed(0)} KB`)
}

await render('brand/og.svg', 'public/og-image.jpg', 1200, { jpeg: true })
await render('brand/app-icon.svg', 'public/apple-touch-icon.png', 180)
await render('brand/app-icon.svg', 'public/icon-512.png', 512)
