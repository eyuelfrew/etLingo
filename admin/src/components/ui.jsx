// ── Shared admin UI primitives ────────────────────────────────────────────────
// Small, dependency-free building blocks so every screen reads consistently:
// same typography scale, spacing rhythm and status language.

export function PageHeader({ eyebrow, title, subtitle, actions }) {
  return (
    <div className="flex flex-wrap items-start justify-between gap-4 border-b border-slate-200 pb-5">
      <div>
        {eyebrow && (
          <p className="text-[11px] font-bold uppercase tracking-[0.14em] text-slate-400">
            {eyebrow}
          </p>
        )}
        <h1 className="mt-1 text-[22px] font-semibold tracking-tight text-slate-900">
          {title}
        </h1>
        {subtitle && (
          <p className="mt-1 max-w-2xl text-sm leading-relaxed text-slate-500">
            {subtitle}
          </p>
        )}
      </div>
      {actions && <div className="flex items-center gap-2">{actions}</div>}
    </div>
  );
}

export function Card({ title, description, children, className = '' }) {
  return (
    <section
      className={`rounded-xl border border-slate-200 bg-white shadow-[0_1px_2px_rgba(15,23,42,0.04)] ${className}`}
    >
      {(title || description) && (
        <header className="border-b border-slate-100 px-5 py-4">
          <h2 className="text-sm font-semibold text-slate-900">{title}</h2>
          {description && (
            <p className="mt-0.5 text-xs leading-relaxed text-slate-500">{description}</p>
          )}
        </header>
      )}
      <div className="px-5 py-4">{children}</div>
    </section>
  );
}

export function Stat({ label, value, hint, tone = 'slate' }) {
  const tones = {
    slate: 'bg-slate-50 text-slate-900',
    green: 'bg-emerald-50 text-emerald-700',
    amber: 'bg-amber-50 text-amber-700',
    sky: 'bg-sky-50 text-sky-700',
  };
  return (
    <div className="rounded-xl border border-slate-200 bg-white px-4 py-3.5">
      <p className="text-[11px] font-semibold uppercase tracking-wider text-slate-400">
        {label}
      </p>
      <p className={`mt-1.5 inline-flex rounded-md px-2 py-0.5 text-xl font-semibold tabular-nums ${tones[tone]}`}>
        {value}
      </p>
      {hint && <p className="mt-1 text-xs text-slate-400">{hint}</p>}
    </div>
  );
}

const BADGE_TONES = {
  neutral: 'bg-slate-100 text-slate-600 ring-slate-200',
  success: 'bg-emerald-50 text-emerald-700 ring-emerald-200',
  warning: 'bg-amber-50 text-amber-700 ring-amber-200',
  danger: 'bg-red-50 text-red-700 ring-red-200',
  info: 'bg-sky-50 text-sky-700 ring-sky-200',
};

export function Badge({ tone = 'neutral', dot = false, children }) {
  return (
    <span
      className={`inline-flex items-center gap-1.5 rounded-full px-2 py-0.5 text-[11px] font-medium ring-1 ring-inset ${BADGE_TONES[tone]}`}
    >
      {dot && <span className="h-1.5 w-1.5 rounded-full bg-current opacity-70" />}
      {children}
    </span>
  );
}

export function Button({ variant = 'secondary', className = '', ...props }) {
  const variants = {
    primary:
      'bg-slate-900 text-white hover:bg-slate-800 disabled:bg-slate-300 focus-visible:outline-slate-900',
    secondary:
      'border border-slate-300 bg-white text-slate-700 hover:bg-slate-50 disabled:text-slate-400 focus-visible:outline-slate-400',
    danger:
      'border border-red-200 bg-white text-red-600 hover:bg-red-50 focus-visible:outline-red-500',
  };
  return (
    <button
      {...props}
      className={`inline-flex items-center justify-center gap-1.5 rounded-lg px-3.5 py-2 text-[13px] font-medium transition focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 disabled:cursor-not-allowed ${variants[variant]} ${className}`}
    />
  );
}

export function EmptyState({ icon = '◌', title, hint }) {
  return (
    <div className="flex flex-col items-center justify-center rounded-lg border border-dashed border-slate-200 px-6 py-10 text-center">
      <span aria-hidden className="text-2xl text-slate-300">{icon}</span>
      <p className="mt-2 text-sm font-medium text-slate-600">{title}</p>
      {hint && <p className="mt-1 max-w-sm text-xs text-slate-400">{hint}</p>}
    </div>
  );
}

export const inputCls =
  'mt-1.5 block w-full rounded-lg border border-slate-300 bg-white px-3 py-2 text-sm text-slate-900 placeholder:text-slate-400 focus:border-slate-500 focus:ring-2 focus:ring-slate-200 focus:outline-none';

export function Field({ label, hint, children }) {
  return (
    <label className="block">
      <span className="block text-xs font-semibold text-slate-700">{label}</span>
      {children}
      {hint && <span className="mt-1 block text-[11px] text-slate-400">{hint}</span>}
    </label>
  );
}