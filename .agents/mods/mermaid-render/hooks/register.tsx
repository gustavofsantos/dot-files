import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register, RenderChildren } from 'claude-code'

import type { Diagram } from '../types'

// Draws the mermaid code blocks of Claude's replies as images under the
// block, through the terminal's kitty graphics protocol. mmdc renders each
// block once to a PNG in the cache dir, keyed by a hash of its source and
// look, so a resumed session or a reload draws from the cache at once.

const PANE = 'mermaid-view'
const diagrams = { plugin: 'mermaid-render', key: 'diagrams' } as const
const isShown = { plugin: 'mermaid-render', key: 'isShown' } as const
const viewing = atom({ plugin: 'mermaid-render', key: 'viewing' } as const, null)

// mmdc's -s; the PNG is SCALE times the diagram's CSS size.
const SCALE = 2
// A guess at one cell in CSS pixels, to size a diagram near its natural size.
const CELL_WIDTH = 8
const CELL_HEIGHT = 16
// The most an Image may carry inline as bytes; past it the terminal reads the file.
const MAX_INLINE_BASE64 = Math.floor((2 * 1024 * 1024 * 4) / 3)

type Options = {
  autoRender: boolean
  command: string
  puppeteerConfig: string
  theme: string
  background: string
  maxRows: number
}

type Part =
  | { kind: 'text'; text: string }
  | { kind: 'diagram'; source: string; fence: string }

const FENCE = /^[ \t]*(`{3,}|~{3,})[ \t]*mermaid\b[^\n]*\n([\s\S]*?)\n[ \t]*\1[ \t]*$/gm

export function split(text: string): Part[] {
  const parts: Part[] = []
  let at = 0
  for (const match of text.matchAll(FENCE)) {
    const start = match.index ?? 0
    if (start > at) parts.push({ kind: 'text', text: text.slice(at, start) })
    parts.push({ kind: 'diagram', source: match[2] ?? '', fence: match[0] })
    at = start + match[0].length
  }
  if (at < text.length) parts.push({ kind: 'text', text: text.slice(at) })

  return parts
}

export function pngSize(base64: string): { width: number; height: number } | undefined {
  const head = atob(base64.slice(0, 32))
  if (head.length < 24 || head.slice(1, 4) !== 'PNG') return undefined
  const word = (at: number) =>
    ((head.charCodeAt(at) << 24) | (head.charCodeAt(at + 1) << 16) | (head.charCodeAt(at + 2) << 8) | head.charCodeAt(at + 3)) >>> 0

  return { width: word(16), height: word(20) }
}

export function fit(
  width: number,
  height: number,
  maxColumns: number,
  maxRows: number,
): { columns: number; rows: number } {
  const ratio = (height / width) * (CELL_WIDTH / CELL_HEIGHT)
  const natural = Math.ceil(width / SCALE / CELL_WIDTH)
  let columns = Math.max(1, Math.min(maxColumns, natural, 255))
  let rows = Math.max(1, Math.round(columns * ratio))
  if (rows > maxRows) {
    rows = Math.max(1, Math.min(maxRows, 255))
    columns = Math.max(1, Math.min(columns, Math.round(rows / ratio)))
  }

  return { columns, rows }
}

async function hash(text: string): Promise<string> {
  const digest = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(text))

  return [...new Uint8Array(digest)]
    .slice(0, 8)
    .map(byte => byte.toString(16).padStart(2, '0'))
    .join('')
}

function firstLine(text: string): string {
  return (
    text
      .split('\n')
      .map(line => line.trim())
      .find(line => line.length > 0 && !line.startsWith('at ')) ?? 'mmdc failed'
  ).slice(0, 200)
}

// Module memory, rebuilt after a reload: the options, the PNG bytes already
// read, the sources by id (for a retry), what is queued, and the
// one-at-a-time queue (each mmdc starts a headless Chromium).
let options: Options = { autoRender: true, command: 'mmdc', puppeteerConfig: '', theme: 'dark', background: 'transparent', maxRows: 30 }
let maxRows = 30
const pngs = new Map<string, string>()
const sources = new Map<string, string>()
const queued = new Set<string>()
let queue: Promise<void> = Promise.resolve()

async function cacheDir($: EngineInterface): Promise<string> {
  const xdg = await $.env.get('XDG_CACHE_HOME')
  const home = await $.env.get('HOME')

  return `${xdg || `${home}/.cache`}/claude-mermaid`
}

async function show($: EngineInterface, id: string, path: string): Promise<boolean> {
  const { base64 } = await $.fs.read(path, { as: 'bytes' })
  const size = pngSize(base64)
  if (size === undefined) return false
  if (base64.length <= MAX_INLINE_BASE64) pngs.set(id, base64)
  await $.state.set({ ...diagrams, id }, { status: 'done', path, ...size })

  return true
}

async function renderNow($: EngineInterface, id: string, source: string): Promise<void> {
  const dir = await cacheDir($)
  const png = `${dir}/${id}.png`
  try {
    if ((await $.fs.exists(png)) && (await show($, id, png))) return
    const input = `${dir}/${id}.mmd`
    await $.fs.write(input, source)
    const argv = [
      options.command,
      '--quiet',
      '--input', input,
      '--output', png,
      '--theme', options.theme,
      '--backgroundColor', options.background,
      '--scale', String(SCALE),
      ...(options.puppeteerConfig ? ['--puppeteerConfigFile', options.puppeteerConfig] : []),
    ]
    const ran = await $.process.run(argv, { timeoutMs: 60_000 })
    if (ran.exitCode !== 0) {
      await $.state.set({ ...diagrams, id }, { status: 'error', error: firstLine(ran.stderr || ran.stdout) })
      return
    }
    if (!(await show($, id, png))) {
      await $.state.set({ ...diagrams, id }, { status: 'error', error: 'mmdc wrote no PNG' })
    }
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error)
    await $.state.set({ ...diagrams, id }, { status: 'error', error: firstLine(message) })
  }
}

async function render($: EngineInterface, id: string, source: string): Promise<void> {
  if (queued.has(id)) return
  queued.add(id)
  sources.set(id, source)
  await $.state.set({ ...diagrams, id }, { status: 'rendering' })
  const previous = queue
  let release = () => {}
  queue = new Promise(resolve => {
    release = resolve
  })
  try {
    await previous
    await renderNow($, id, source)
  } finally {
    release()
    queued.delete(id)
  }
}

async function expand($: EngineInterface, id: string): Promise<void> {
  await update($, viewing, () => id)
  await $.ui.open({ id: PANE, title: 'Mermaid', focus: true, closeOnEscape: true })
}

export const register: Register = (on, rawOptions) => {
  options = rawOptions as unknown as Options
  maxRows = Math.max(4, Math.min(255, Number(options.maxRows) || 30))

  on('session.start', async ($, e, next) => {
    await $.command.register({
      name: 'mermaid',
      description: 'Show the last expanded mermaid diagram in a pane',
    })

    return next(e)
  })

  on('command.run', { command: 'mermaid' }, async $ => {
    if ((await read($, viewing)) === null) {
      return { text: 'No mermaid diagram expanded yet: press expand under one.' }
    }
    await $.ui.open({ id: PANE, title: 'Mermaid', focus: true, closeOnEscape: true })

    return { text: 'Mermaid pane opened.' }
  })

  on('ui.render', { component: 'AssistantMessage', surface: 'terminal' }, async ($, e, next) => {
    if (e.surface !== 'terminal' || e.props.isSummary) return next(e)
    const parts = split(e.props.text)
    if (!parts.some(part => part.kind === 'diagram')) return next(e)

    const { Box, Text, Button, Image } = $.ui.resolve(e)
    const width = Math.max(10, (e.viewport?.columns ?? 80) - 4)
    const children: RenderChildren[] = []
    let pending = ''

    const flush = async () => {
      const isFirst = children.length === 0
      if (pending.trim() === '' && !(isFirst && e.props.isFirstOfReply)) {
        pending = ''
        return
      }
      const text = pending.trim() === '' ? '_mermaid diagram_' : pending.replace(/\n+$/, '')
      children.push(await next({ ...e, props: { ...e.props, text, isFirstOfReply: isFirst && e.props.isFirstOfReply } }))
      pending = ''
    }

    for (const [index, part] of parts.entries()) {
      if (part.kind === 'text') {
        pending += part.text
        continue
      }
      const id = await hash(`${options.theme}\0${options.background}\0${part.source}`)
      const at = `${index}-${id}`
      const { value: shownValue } = await $.state.get({ ...isShown, id })
      const shown = shownValue ?? options.autoRender
      const { value: diagram } = await $.state.get({ ...diagrams, id })

      if (!shown) {
        pending += part.fence
        await flush()
        children.push(
          <Box paddingLeft={2}>
            <Button
              key={`render-${at}`}
              label={diagram?.status === 'done' ? 'show diagram' : 'render diagram'}
              dimColor
              onPress={async () => {
                await $.state.set({ ...isShown, id }, true)
                if (diagram?.status !== 'done') await render($, id, part.source)
              }}
            />
          </Box>,
        )
        continue
      }

      if (diagram?.status === 'error') {
        pending += part.fence
        await flush()
        children.push(
          <Box paddingLeft={2}>
            <Text color="red">mermaid: {diagram.error} </Text>
            <Button
              key={`retry-${at}`}
              label="retry"
              dimColor
              onPress={() => render($, id, sources.get(id) ?? part.source)}
            />
          </Box>,
        )
        continue
      }

      await flush()
      if (diagram === undefined && !queued.has(id)) {
        $.clock.after(0, () => void render($, id, part.source))
      }

      if (diagram === undefined || diagram.status === 'rendering') {
        children.push(
          <Box paddingLeft={2}>
            <Text dimColor>rendering mermaid diagram…</Text>
          </Box>,
        )
        continue
      }

      const size = fit(diagram.width, diagram.height, width, maxRows)
      const bytes = pngs.get(id)
      children.push(
        <Box flexDirection="column" paddingLeft={2}>
          <Image
            source={bytes ? { png: bytes } : { file: diagram.path, format: 'png' }}
            columns={size.columns}
            rows={size.rows}
            alt="[mermaid diagram]"
          />
          <Box>
            <Button key={`source-${at}`} label="source" dimColor onPress={() => $.state.set({ ...isShown, id }, false)} />
            <Text> </Text>
            <Button key={`expand-${at}`} label="expand" dimColor onPress={() => expand($, id)} />
          </Box>
        </Box>,
      )
    }
    await flush()

    return <Box flexDirection="column">{children}</Box>
  })

  on('ui.render', { component: 'Pane', requestId: PANE }, async ($, e) => {
    const { Box, Text } = $.ui.resolve(e)
    const id = await read($, viewing)
    const diagram = id === null ? undefined : (await $.state.get({ ...diagrams, id })).value
    if (id === null || diagram?.status !== 'done') {
      return <Text dimColor>No diagram to show.</Text>
    }
    if (e.surface !== 'terminal') {
      return <Text dimColor>{diagram.path}</Text>
    }
    const { Image: TerminalImage } = $.ui.resolve(e)
    const rows = Math.max(4, e.props.scroll.bodyRows - 1)
    const size = fit(diagram.width, diagram.height, e.props.bodyColumns, rows)
    const bytes = pngs.get(id)

    return (
      <Box flexDirection="column">
        <TerminalImage
          source={bytes ? { png: bytes } : { file: diagram.path, format: 'png' }}
          columns={size.columns}
          rows={size.rows}
          alt="[mermaid diagram]"
        />
        <Text dimColor>{diagram.path}</Text>
      </Box>
    )
  })
}
