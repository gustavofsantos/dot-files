import { expect, mock, test } from 'claude-code/testing'
import type { On } from 'claude-code'

const SOURCE = 'graph TD\n  A --> B'
const REPLY = `Here it is:\n\n\`\`\`mermaid\n${SOURCE}\n\`\`\`\n\nThat is the flow.`

// A real 800x400 grayscale PNG: the engine checks an Image's bytes.
const PNG =
  'iVBORw0KGgoAAAANSUhEUgAAAyAAAAGQCAAAAABzTlvoAAABTUlEQVR42u3BAQ0AAADCoPdPbQ8HFAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAADPBuPMAAFzsEHCAAAAAElFTkSuQmCC'

const MESSAGE = (text: string) => ({
  plugin: 'mermaid-render',
  surface: 'terminal',
  component: 'AssistantMessage',
  props: { text, isFirstOfReply: true },
  viewport: { columns: 100, rows: 40 },
}) as const

// Stands for the engine: draws a block's text as one Text, and records what
// it was asked to draw.
function engine(on: On, drawn: { text: string; isFirstOfReply: boolean }[]) {
  on('ui.render', { component: 'AssistantMessage' }, async ($, e) => {
    drawn.push({ text: e.props.text, isFirstOfReply: e.props.isFirstOfReply })
    const { Text } = $.ui.resolve(e)

    return <Text>{`engine:${e.props.text}`}</Text>
  })
}

function host(on: On, run: { exitCode: number; stderr: string }) {
  const calls: string[][] = []
  mock.env(on, { HOME: '/home/me' })
  on('fs.exists', () => ({ value: false }))
  on('fs.write', () => ({ value: undefined }))
  on('fs.read', () => ({ value: { base64: PNG } }))
  on('process.run', (_$, e) => {
    calls.push([...e.argv])
    return { value: { ...run, stdout: '', isStdoutTruncated: false, isStderrTruncated: false } }
  })

  return calls
}

test('a reply without mermaid is the engine own drawing', async ($, on) => {
  const drawn: { text: string; isFirstOfReply: boolean }[] = []
  engine(on, drawn)
  const ui = await $.ui.mount(MESSAGE('just text'))
  expect(await ui.find({ type: 'Image' })).toBeUndefined()
  expect(drawn).toEqual([{ text: 'just text', isFirstOfReply: true }])
})

test('a mermaid block renders once and draws as an Image between its text', async ($, on) => {
  const clock = mock.clock(on)
  const drawn: { text: string; isFirstOfReply: boolean }[] = []
  engine(on, drawn)
  const calls = host(on, { exitCode: 0, stderr: '' })

  const ui = await $.ui.mount(MESSAGE(REPLY))
  expect(await ui.find({ text: /rendering mermaid/ })).toBeDefined()
  await clock.settle()

  const image = await ui.find({ type: 'Image' })
  expect(image?.props).toMatchObject({ columns: 50, rows: 13, source: { png: PNG } })
  expect(calls).toHaveLength(1)
  expect(calls[0]?.slice(0, 2)).toEqual(['mmdc', '--quiet'])
  expect(calls[0]).toContain('/home/me/.cache/claude-mermaid/' + calls[0]?.[3]?.split('/').pop())
  expect(drawn.at(-2)).toEqual({ text: 'Here it is:', isFirstOfReply: true })
  expect(drawn.at(-1)).toEqual({ text: '\n\nThat is the flow.', isFirstOfReply: false })

  await ui.press({ key: (await ui.find({ type: 'Button', text: 'source' }))?.key ?? '' })
  expect(await ui.find({ type: 'Image' })).toBeUndefined()
  expect(drawn.at(-2)?.text).toContain('```mermaid')
})

test('an mmdc failure shows its first line and a retry', async ($, on) => {
  const clock = mock.clock(on)
  engine(on, [])
  host(on, { exitCode: 1, stderr: '\nError: Parse error on line 2\n    at parse (x.js)' })

  const ui = await $.ui.mount(MESSAGE(REPLY))
  await clock.settle()
  expect((await ui.find({ type: 'Text', text: /mermaid:/ }))?.text).toContain('Parse error on line 2')
  expect(await ui.find({ type: 'Button', text: 'retry' })).toBeDefined()
})

test('with autoRender off a button renders on demand', { options: { autoRender: false } }, async ($, on) => {
  const clock = mock.clock(on)
  engine(on, [])
  const calls = host(on, { exitCode: 0, stderr: '' })

  const ui = await $.ui.mount(MESSAGE(REPLY))
  await clock.settle()
  expect(calls).toHaveLength(0)
  const button = await ui.find({ type: 'Button', text: 'render diagram' })
  await ui.press({ key: button?.key ?? '' })
  await clock.settle()
  expect(calls).toHaveLength(1)
  expect(await ui.find({ type: 'Image' })).toBeDefined()
})

// Stands for the host on a given system: `uname -s` answers `system`, and
// every argv is recorded.
function hostOn(on: On, system: string) {
  const calls: string[][] = []
  mock.env(on, { HOME: '/home/me' })
  on('fs.exists', () => ({ value: false }))
  on('fs.write', () => ({ value: undefined }))
  on('fs.read', () => ({ value: { base64: PNG } }))
  on('process.run', (_$, e) => {
    calls.push([...e.argv])
    const stdout = e.argv[0] === 'uname' ? `${system}\n` : ''
    return { value: { exitCode: 0, stderr: '', stdout, isStdoutTruncated: false, isStderrTruncated: false } }
  })

  return calls
}

for (const [system, opener] of [['Darwin', 'open'], ['Linux', 'xdg-open']] as const) {
  test(`open runs ${opener} on ${system} when no viewer is set`, async ($, on) => {
    const clock = mock.clock(on)
    engine(on, [])
    const calls = hostOn(on, system)

    const ui = await $.ui.mount(MESSAGE(REPLY))
    await clock.settle()
    await ui.press({ key: (await ui.find({ type: 'Button', text: 'open' }))?.key ?? '' })
    await clock.settle()
    expect(calls.at(-1)?.[0]).toBe(opener)
    expect(calls.at(-1)?.[1]).toMatch(/\/home\/me\/\.cache\/claude-mermaid\/.+\.png$/)
  })
}

test('open runs the configured viewer as is', { options: { viewer: 'feh' } }, async ($, on) => {
  const clock = mock.clock(on)
  engine(on, [])
  const calls = hostOn(on, 'Darwin')

  const ui = await $.ui.mount(MESSAGE(REPLY))
  await clock.settle()
  await ui.press({ key: (await ui.find({ type: 'Button', text: 'open' }))?.key ?? '' })
  await clock.settle()
  expect(calls.some(argv => argv[0] === 'uname')).toBe(false)
  expect(calls.at(-1)?.[0]).toBe('feh')
})
