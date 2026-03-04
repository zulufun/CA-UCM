/**
 * UCM Logo Component
 * Uses tc.png image from public folder
 */
import { cn } from '../lib/utils'

const sizes = {
  xs: 20,
  sm: 26,
  md: 32,
  lg: 48,
  xl: 64,
}

function LogoIcon({ size = 32, className }) {
  return (
    <img
      src="/tc.png"
      alt="Logo"
      width={size}
      height={size}
      className={cn('object-contain', className)}
    />
  )
}

export function Logo({
  variant = 'horizontal', // 'horizontal' | 'vertical' | 'compact' | 'icon'
  withText = true,
  size = 'md', // 'xs' | 'sm' | 'md' | 'lg' | 'xl'
  className
}) {
  const iconPx = sizes[size] || sizes.md

  if (!withText || variant === 'icon') {
    return (
      <div className={className}>
        <LogoIcon size={iconPx} />
      </div>
    )
  }

  // Vertical variant
  if (variant === 'vertical' || variant === 'stacked') {
    return (
      <div className={cn('flex flex-col items-center', className)} style={{ gap: '12px' }}>
        <LogoIcon size={iconPx} />
        <div className="text-center">
          <div
            className="font-black tracking-tight leading-none logo-text-gradient"
            style={{ fontSize: size === 'lg' ? '32px' : '24px', letterSpacing: '-1px' }}
          >
            UCM
          </div>
          <div
            className="font-semibold uppercase"
            style={{
              fontSize: '9px',
              letterSpacing: '2px',
              color: 'var(--text-tertiary)',
              marginTop: '2px'
            }}
          >
            QUẢN LÝ CHỨNG CHỈ
          </div>
        </div>
      </div>
    )
  }

  // Horizontal / compact with text
  const fontSize = variant === 'compact' ? '18px' : size === 'lg' ? '32px' : '24px'
  return (
    <div className={cn('flex items-center', className)} style={{ gap: variant === 'compact' ? '8px' : '12px' }}>
      <LogoIcon size={iconPx} />
      <div className="flex flex-col">
        <div
          className="font-black tracking-tight leading-none logo-text-gradient"
          style={{ fontSize, letterSpacing: '-1px' }}
        >
          QL-SSL
        </div>
        {variant !== 'compact' && (
          <div
            className="font-semibold uppercase"
            style={{
              fontSize: '9px',
              letterSpacing: '2px',
              color: 'var(--text-tertiary)',
              marginTop: '2px'
            }}
          >
            QUẢN LÝ CHỨNG CHỈ SSL
          </div>
        )}
      </div>
    </div>
  )
}
