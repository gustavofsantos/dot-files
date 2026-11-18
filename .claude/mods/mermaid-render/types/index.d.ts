export type Diagram =
  | { status: 'rendering' }
  | { status: 'done'; path: string; width: number; height: number }
  | { status: 'error'; error: string }

declare module 'claude-code' {
  interface PluginState {
    'mermaid-render': {
      diagrams: StateFamily<Diagram>
      isShown: StateFamily<boolean>
      viewing: string | null
    }
  }
}
