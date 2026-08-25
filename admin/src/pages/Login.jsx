import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

export default function Login() {
  const { login } = useAuth();
  const navigate = useNavigate();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);

  const submit = async (e) => {
    e.preventDefault();
    setError('');
    setBusy(true);
    try {
      await login(email, password);
      navigate('/');
    } catch (err) {
      setError(err.response?.data?.error || 'Login failed — is the backend running?');
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="relative flex min-h-screen items-center justify-center overflow-hidden bg-stone-950 p-4">
      {/* Animated background pattern */}
      <div className="pointer-events-none absolute inset-0">
        {/* Ethiopian cross pattern - top left */}
        <svg className="absolute -top-20 -left-20 h-80 w-80 animate-[spin_60s_linear_infinite] opacity-[0.04]" viewBox="0 0 100 100">
          <rect x="40" y="10" width="20" height="80" rx="4" fill="currentColor" className="text-green-400" />
          <rect x="10" y="40" width="80" height="20" rx="4" fill="currentColor" className="text-green-400" />
          <circle cx="50" cy="50" r="12" fill="none" stroke="currentColor" strokeWidth="3" className="text-yellow-400" />
        </svg>
        {/* Ethiopian cross pattern - bottom right */}
        <svg className="absolute -bottom-16 -right-16 h-72 w-72 animate-[spin_45s_linear_infinite_reverse] opacity-[0.04]" viewBox="0 0 100 100">
          <rect x="40" y="10" width="20" height="80" rx="4" fill="currentColor" className="text-yellow-400" />
          <rect x="10" y="40" width="80" height="20" rx="4" fill="currentColor" className="text-yellow-400" />
          <circle cx="50" cy="50" r="12" fill="none" stroke="currentColor" strokeWidth="3" className="text-green-400" />
        </svg>
        {/* Floating dots */}
        <div className="absolute top-1/4 left-1/4 h-2 w-2 animate-pulse rounded-full bg-green-500/20" />
        <div className="absolute top-1/3 right-1/3 h-1.5 w-1.5 animate-pulse rounded-full bg-yellow-500/20 [animation-delay:1s]" />
        <div className="absolute bottom-1/4 left-1/3 h-1.5 w-1.5 animate-pulse rounded-full bg-green-500/15 [animation-delay:2s]" />
        <div className="absolute bottom-1/3 right-1/4 h-2 w-2 animate-pulse rounded-full bg-yellow-500/15 [animation-delay:0.5s]" />
        {/* Gradient orbs */}
        <div className="absolute top-20 left-20 h-64 w-64 rounded-full bg-green-600/8 blur-3xl" />
        <div className="absolute bottom-20 right-20 h-64 w-64 rounded-full bg-yellow-600/8 blur-3xl" />
      </div>

      {/* Login card */}
      <div className="relative z-10 w-full max-w-sm">
        {/* Logo */}
        <div className="mb-8 text-center">
          <div className="mx-auto mb-5 flex h-20 w-20 items-center justify-center rounded-2xl bg-gradient-to-br from-green-600 to-green-800 shadow-lg shadow-green-900/40 ring-1 ring-white/10">
            <span className="text-3xl">🗣</span>
          </div>
          <h1 className="text-3xl font-black tracking-tight text-white">
            ኢት<span className="bg-gradient-to-r from-green-400 to-yellow-400 bg-clip-text text-transparent">Lingo</span>
          </h1>
          <p className="mt-1.5 text-sm font-medium text-stone-500">
            Admin Console
          </p>
        </div>

        {/* Form card */}
        <form onSubmit={submit} className="space-y-4 rounded-3xl border border-white/[0.06] bg-white/[0.03] p-8 shadow-2xl backdrop-blur-xl">
          <div className="space-y-3">
            <div>
              <label className="mb-1.5 block text-xs font-bold uppercase tracking-wider text-stone-500">Email</label>
              <input
                type="email"
                placeholder="admin@etlang.app"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
                className="w-full rounded-xl border border-white/[0.08] bg-white/[0.05] px-4 py-3 text-sm text-white placeholder-stone-600 outline-none transition focus:border-green-500/50 focus:bg-white/[0.07] focus:ring-2 focus:ring-green-500/10"
              />
            </div>
            <div>
              <label className="mb-1.5 block text-xs font-bold uppercase tracking-wider text-stone-500">Password</label>
              <input
                type="password"
                placeholder="••••••••"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                className="w-full rounded-xl border border-white/[0.08] bg-white/[0.05] px-4 py-3 text-sm text-white placeholder-stone-600 outline-none transition focus:border-green-500/50 focus:bg-white/[0.07] focus:ring-2 focus:ring-green-500/10"
              />
            </div>
          </div>

          {error && (
            <div className="rounded-xl border border-red-500/20 bg-red-500/10 px-4 py-3 text-xs font-semibold text-red-300">
              {error}
            </div>
          )}

          <button
            disabled={busy}
            className="group relative w-full overflow-hidden rounded-xl bg-gradient-to-r from-green-600 to-green-700 py-3.5 text-sm font-black uppercase tracking-wider text-white shadow-lg shadow-green-900/30 transition hover:from-green-500 hover:to-green-600 hover:shadow-green-800/40 disabled:opacity-50"
          >
            <span className="relative z-10">{busy ? 'Signing in…' : 'Sign in'}</span>
            <div className="absolute inset-0 bg-gradient-to-r from-transparent via-white/10 to-transparent -translate-x-full group-hover:translate-x-full transition-transform duration-700" />
          </button>

          <p className="text-center text-[11px] font-medium text-stone-600">
            Default: admin@etlang.app / admin123
          </p>
        </form>

        {/* Footer */}
        <p className="mt-6 text-center text-[11px] font-medium text-stone-700">
          EtLingo — Learn Ethiopian Languages
        </p>
      </div>
    </div>
  );
}
