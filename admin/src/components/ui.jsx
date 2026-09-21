// Shared admin UI primitives — one type scale, one spacing rhythm, one voice.

export function PageHeader({ eyebrow, title, subtitle, actions }) {
  return (
    <div className="flex flex-wrap items-start justify-between gap-4 border-b border-line pb-5">
      <div className="min-w-0">
        {eyebrow && (
          <p className="text-[11px] font-semibold tracking-[0.12em] text-muted uppercase">
            {eyebrow}
          </p>
        )}
        <h1 className="mt-1 text-[24px] font-bold tracking-tight text-ink">
          {title}
        </h1>
        {subtitle && (
          <p className="mt-1.5 max-w-2xl text-sm leading-relaxed text-muted">
            {subtitle}
          </p>
        )}
      </div>
      {actions && <div className="flex flex-wrap items-center gap-2">{actions}</div>}
    </div>
  );
}

export function Card({ title, description, children, className = '', bodyClass = 'px-5 py-4' }) {
  return (
    <section className={`rounded-2xl border border-line-soft bg-panel shadow-[0_1px_0_rgba(26,20,14,0.03)] ${className}`}>
      {(title || description) && (
        <header className="border-b border-line-soft px-5 py-4">
          {title && <h2 className="text-[15px] font-semibold text-ink">{title}</h2>}
          {description && (
            <p className="mt-1 text-[13px] leading-relaxed text-muted">{description}</p>
          )}
        </header>
      )}
      <div className={bodyClass}>{children}</div>
    </section>
  );
}

export function Stat({ label, value, hint, tone = 'neutral' }) {
  const tones = {
    neutral: 'text-ink',
    green: 'text-et-green',
    amber: 'text-et-yellow-dark',
    blue: 'text-et-blue',
    red: 'text-et-red',
  };
  return (
    <div className="rounded-2xl border border-line-soft bg-panel px-4 py-4">
      <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-et-green-soft text-et-green">
        <StatGlyph label={label} />
      </div>
      <p className="mt-3 text-[28px] leading-none font-bold tabular-nums text-ink">
        {value ?? '—'}
      </p>
      <p className="mt-1.5 text-[13px] font-medium text-muted">{label}</p>
      {hint && <p className="mt-0.5 text-[12px] text-muted/80">{hint}</p>}
      {/* tone kept for API compatibility */}
      <span className={`sr-only ${tones[tone]}`}>{tone}</span>
    </div>
  );
}

function StatGlyph({ label }) {
  const map = {
    Languages: 'M4 6h16M4 12h10M4 18h14',
    Units: 'M4 7h6v6H4V7zm10 0h6v6h-6V7zM4 15h6v6H4v-6zm10 0h6v6h-6v-6z',
    Lessons: 'M5 5h9l5 5v9a1 1 0 01-1 1H5a1 1 0 01-1-1V6a1 1 0 011-1z',
    Questions: 'M12 18h.01M9.5 9a2.5 2.5 0 114.3 1.7c-.8.9-1.8 1.3-1.8 2.8',
    Phrases: 'M8 10h8M8 14h5M21 12a9 9 0 11-4-7.5L21 3v9z',
    Learners: 'M16 19v-1a4 4 0 00-4-4H7a4 4 0 00-4 4v1m13-9a4 4 0 11-8 0 4 4 0 018 0z',
  };
  const d = map[label] || map.Languages;
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" className="h-4.5 w-4.5">
      <path d={d} />
    </svg>
  );
}

const BADGE_TONES = {
  neutral: 'bg-canvas text-muted ring-line',
  success: 'bg-et-green-soft text-et-green-dark ring-et-green/20',
  warning: 'bg-et-yellow/15 text-et-yellow-dark ring-et-yellow/30',
  danger: 'bg-et-red/10 text-et-red ring-et-red/20',
  info: 'bg-et-blue/10 text-et-blue ring-et-blue/20',
};

export function Badge({ tone = 'neutral', dot = false, children }) {
  return (
    <span
      className={`inline-flex items-center gap-1.5 rounded-full px-2.5 py-1 text-[12px] font-medium ring-1 ring-inset ${BADGE_TONES[tone] || BADGE_TONES.neutral}`}
    >
      {dot && <span className="h-1.5 w-1.5 rounded-full bg-current opacity-70" />}
      {children}
    </span>
  );
}

export function Button({ variant = 'secondary', className = '', ...props }) {
  const variants = {
    primary:
      'bg-et-green text-white hover:bg-et-green-dark disabled:bg-et-green/40 focus-visible:outline-et-green',
    gold:
      'bg-et-yellow text-ink hover:bg-et-yellow-dark disabled:opacity-50 focus-visible:outline-et-yellow-dark',
    secondary:
      'border border-line bg-panel text-ink hover:bg-canvas disabled:text-muted focus-visible:outline-muted',
    danger:
      'border border-et-red/25 bg-panel text-et-red hover:bg-et-red/5 focus-visible:outline-et-red',
    ghost:
      'text-muted hover:bg-canvas hover:text-ink focus-visible:outline-muted',
  };
  return (
    <button
      {...props}
      className={`inline-flex min-h-10 items-center justify-center gap-2 rounded-xl px-4 text-[13px] font-semibold transition focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 disabled:cursor-not-allowed ${variants[variant]} ${className}`}
    />
  );
}

export function EmptyState({ icon = '◌', title, hint, action }) {
  return (
    <div className="flex flex-col items-center justify-center rounded-2xl border border-dashed border-line bg-panel/60 px-6 py-12 text-center">
      <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-et-green-soft text-et-green">
        <span aria-hidden className="text-xl">{icon}</span>
      </div>
      <p className="mt-3 text-[15px] font-semibold text-ink">{title}</p>
      {hint && <p className="mt-1 max-w-sm text-[13px] leading-relaxed text-muted">{hint}</p>}
      {action && <div className="mt-4">{action}</div>}
    </div>
  );
}

export const inputCls =
  'mt-1.5 block w-full rounded-xl border border-line bg-panel px-3.5 py-2.5 text-[14px] text-ink placeholder:text-muted/70 transition focus:border-et-green focus:ring-2 focus:ring-et-green/15 focus:outline-none';

export const labelCls = 'block text-[13px] font-semibold text-ink';

export const tableShellCls =
  'overflow-hidden rounded-2xl border border-line-soft bg-panel';

export const thCls =
  'px-4 py-3 text-left text-[12px] font-semibold tracking-wide text-muted bg-canvas/70';

export const tdCls = 'px-4 py-3 text-[13px] text-ink align-middle';

export function Field({ label, hint, children }) {
  return (
    <label className="block">
      <span className={labelCls}>{label}</span>
      {children}
      {hint && <span className="mt-1.5 block text-[12px] text-muted">{hint}</span>}
    </label>
  );
}

export function Modal({ title, description, onClose, children, footer, wide = false }) {
  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center overflow-y-auto bg-ink/45 p-4 pt-10 backdrop-blur-[2px]">
      <div
        className={`relative w-full ${wide ? 'max-w-3xl' : 'max-w-lg'} rounded-2xl border border-line-soft bg-panel shadow-2xl`}
        role="dialog"
        aria-modal="true"
      >
        <header className="flex items-start justify-between gap-4 border-b border-line-soft px-6 py-4">
          <div>
            <h2 className="text-[17px] font-bold text-ink">{title}</h2>
            {description && (
              <p className="mt-1 text-[13px] leading-relaxed text-muted">{description}</p>
            )}
          </div>
          <button
            type="button"
            onClick={onClose}
            className="rounded-lg p-1.5 text-muted transition hover:bg-canvas hover:text-ink"
            aria-label="Close"
          >
            <svg viewBox="0 0 24 24" className="h-5 w-5" fill="none" stroke="currentColor" strokeWidth="2">
              <path d="M6 6l12 12M18 6L6 18" />
            </svg>
          </button>
        </header>
        <div className="max-h-[70vh] overflow-y-auto px-6 py-5">{children}</div>
        {footer && (
          <footer className="flex justify-end gap-2 border-t border-line-soft px-6 py-4">
            {footer}
          </footer>
        )}
      </div>
    </div>
  );
}

export function Banner({ tone = 'info', children }) {
  const tones = {
    info: 'border-et-blue/20 bg-et-blue/5 text-et-blue',
    success: 'border-et-green/20 bg-et-green-soft text-et-green-dark',
    warning: 'border-et-yellow/30 bg-et-yellow/10 text-et-yellow-dark',
    danger: 'border-et-red/20 bg-et-red/5 text-et-red',
  };
  return (
    <div className={`rounded-xl border px-4 py-3 text-[13px] font-medium ${tones[tone]}`}>
      {children}
    </div>
  );
}
