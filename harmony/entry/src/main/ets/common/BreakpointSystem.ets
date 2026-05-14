import { mediaquery } from '@kit.ArkUI'

export type BreakpointType = 'xs' | 'sm' | 'md' | 'lg' | 'xl' | 'xxl'

interface BreakpointDefinition {
  name: BreakpointType
  minWidthVp: number
  listener?: mediaquery.MediaQueryListener
}

type BreakpointCallback = (breakpoint: BreakpointType) => void

export class BreakpointSystem {
  private static instance: BreakpointSystem | undefined = undefined

  private readonly breakpoints: BreakpointDefinition[] = [
    { name: 'xs', minWidthVp: 0 },
    { name: 'sm', minWidthVp: 320 },
    { name: 'md', minWidthVp: 600 },
    { name: 'lg', minWidthVp: 840 },
    { name: 'xl', minWidthVp: 1440 }
  ]

  private listeners: Set<BreakpointCallback> = new Set()
  private started: boolean = false
  private currentBreakpoint: BreakpointType = 'sm'

  static getInstance(): BreakpointSystem {
    if (!BreakpointSystem.instance) {
      BreakpointSystem.instance = new BreakpointSystem()
    }
    return BreakpointSystem.instance
  }

  subscribe(callback: BreakpointCallback): () => void {
    this.listeners.add(callback)
    if (!this.started) {
      this.start()
    }
    callback(this.currentBreakpoint)

    return () => {
      this.listeners.delete(callback)
      if (this.listeners.size === 0) {
        this.stop()
      }
    }
  }

  private start(): void {
    if (this.started) {
      return
    }
    this.started = true

    this.breakpoints.forEach((breakpoint: BreakpointDefinition, index: number) => {
      let condition: string
      if (index === this.breakpoints.length - 1) {
        condition = `(${breakpoint.minWidthVp}vp<=width)`
      } else {
        condition = `(${breakpoint.minWidthVp}vp<=width<${this.breakpoints[index + 1].minWidthVp}vp)`
      }

      const listener = mediaquery.matchMediaSync(condition)
      breakpoint.listener = listener

      if (listener.matches) {
        this.updateBreakpoint(breakpoint.name)
      }

      listener.on('change', (result) => {
        if (result.matches) {
          this.updateBreakpoint(breakpoint.name)
        }
      })
    })
  }

  private updateBreakpoint(nextBreakpoint: BreakpointType): void {
    if (this.currentBreakpoint === nextBreakpoint) {
      return
    }

    this.currentBreakpoint = nextBreakpoint
    this.listeners.forEach((callback: BreakpointCallback) => {
      callback(nextBreakpoint)
    })
  }

  private stop(): void {
    this.breakpoints.forEach((breakpoint: BreakpointDefinition) => {
      if (breakpoint.listener) {
        breakpoint.listener.off('change')
      }
      breakpoint.listener = undefined
    })
    this.started = false
  }
}
