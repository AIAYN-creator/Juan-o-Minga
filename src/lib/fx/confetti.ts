// Burst of gold coins and confetti for a correct answer. Call celebrate()
// from anywhere: it draws on a lazily created, click-through canvas overlay.
// Reduced motion: does nothing (the ¡CORRECTO! sign still says it all).

import { motion } from '../motion.svelte'

type Particle = {
  kind: 'coin' | 'paper'
  x: number
  y: number
  vx: number
  vy: number
  size: number
  spin: number
  spinSpeed: number
  angle: number
  color: string
  life: number
}

const PAPER_COLORS = ['#ee1b3a', '#2ff3ff', '#ff2fd6', '#ffd866', '#3dff8e', '#fff7e6']
const GRAVITY = 1400 // px/s²
const DRAG = 0.9 // velocity kept per second, roughly
const LIFETIME = 1.7 // s

let canvas: HTMLCanvasElement | null = null
let ctx: CanvasRenderingContext2D | null = null
let particles: Particle[] = []
let raf = 0
let lastT = 0

function ensureCanvas() {
  if (canvas) return
  canvas = document.createElement('canvas')
  canvas.setAttribute('aria-hidden', 'true')
  Object.assign(canvas.style, {
    position: 'fixed',
    inset: '0',
    width: '100%',
    height: '100%',
    pointerEvents: 'none',
    zIndex: '1000',
  })
  document.body.appendChild(canvas)
  ctx = canvas.getContext('2d')
}

function resize() {
  if (!canvas || !ctx) return
  const dpr = Math.min(window.devicePixelRatio || 1, 2)
  canvas.width = Math.round(window.innerWidth * dpr)
  canvas.height = Math.round(window.innerHeight * dpr)
  ctx.setTransform(dpr, 0, 0, dpr, 0, 0)
}

const rand = (min: number, max: number) => min + Math.random() * (max - min)

function drawCoin(c: CanvasRenderingContext2D, p: Particle) {
  const flip = Math.cos(p.spin) // -1..1: edge-on when 0
  const rx = Math.max(0.15, Math.abs(flip)) * p.size
  const g = c.createLinearGradient(-rx, -p.size, rx, p.size)
  g.addColorStop(0, '#fff1b8')
  g.addColorStop(0.45, flip > 0 ? '#f0b429' : '#cf8f12')
  g.addColorStop(1, '#7a4a06')
  c.fillStyle = g
  c.beginPath()
  c.ellipse(0, 0, rx, p.size, 0, 0, Math.PI * 2)
  c.fill()
  c.strokeStyle = 'rgba(122, 74, 6, 0.9)'
  c.lineWidth = 1.2
  c.stroke()
  // inner ring
  c.strokeStyle = 'rgba(255, 241, 184, 0.7)'
  c.beginPath()
  c.ellipse(0, 0, rx * 0.65, p.size * 0.65, 0, 0, Math.PI * 2)
  c.stroke()
}

function drawPaper(c: CanvasRenderingContext2D, p: Particle) {
  c.rotate(p.angle)
  c.scale(1, Math.cos(p.spin))
  c.fillStyle = p.color
  c.fillRect(-p.size / 2, -p.size / 4, p.size, p.size / 2)
}

function frame(t: number) {
  if (!ctx || !canvas) return
  const dt = lastT ? Math.min(0.05, (t - lastT) / 1000) : 0
  lastT = t
  ctx.clearRect(0, 0, window.innerWidth, window.innerHeight)

  const drag = Math.pow(DRAG, dt)
  particles = particles.filter((p) => (p.life -= dt) > 0 && p.y < window.innerHeight + 40)

  for (const p of particles) {
    p.vx *= drag
    p.vy = p.vy * drag + GRAVITY * dt * (p.kind === 'paper' ? 0.45 : 1)
    p.x += p.vx * dt
    p.y += p.vy * dt
    p.spin += p.spinSpeed * dt
    p.angle += p.spinSpeed * 0.3 * dt

    ctx.save()
    ctx.globalAlpha = Math.min(1, p.life / 0.35)
    ctx.translate(p.x, p.y)
    if (p.kind === 'coin') drawCoin(ctx, p)
    else drawPaper(ctx, p)
    ctx.restore()
  }

  if (particles.length) {
    raf = requestAnimationFrame(frame)
  } else {
    raf = 0
    ctx.clearRect(0, 0, window.innerWidth, window.innerHeight)
  }
}

/** Fire a celebration burst from a point (defaults to upper-middle of the screen). */
export function celebrate(origin?: { x: number; y: number }) {
  if (motion.reduced) return
  ensureCanvas()
  resize()
  const ox = origin?.x ?? window.innerWidth / 2
  const oy = origin?.y ?? window.innerHeight * 0.38
  const count = window.innerWidth < 500 ? 70 : 110

  for (let i = 0; i < count; i++) {
    const coin = i % 5 < 3
    const angle = rand(-Math.PI * 0.92, -Math.PI * 0.08) // upward fan
    const speed = rand(420, 950)
    particles.push({
      kind: coin ? 'coin' : 'paper',
      x: ox + rand(-20, 20),
      y: oy + rand(-10, 10),
      vx: Math.cos(angle) * speed,
      vy: Math.sin(angle) * speed,
      size: coin ? rand(7, 11) : rand(8, 14),
      spin: rand(0, Math.PI * 2),
      spinSpeed: rand(8, 18) * (Math.random() < 0.5 ? -1 : 1),
      angle: rand(0, Math.PI * 2),
      color: PAPER_COLORS[i % PAPER_COLORS.length],
      life: LIFETIME + rand(-0.3, 0.3),
    })
  }

  if (!raf) {
    lastT = 0
    raf = requestAnimationFrame(frame)
  }
}
