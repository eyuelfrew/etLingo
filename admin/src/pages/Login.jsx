import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { Button, Field, inputCls, Banner } from '../components/ui';

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
      setError(err.response?.data?.error || 'Login failed — is the backend running on :5050?');
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="relative flex min-h-screen items-center justify-center overflow-hidden bg-sidebar p-4">
      <div className="pointer-events-none absolute inset-0">
        <div className="absolute -top-24 -left-20 h-80 w-80 rounded-full bg-et-green/20 blur-3xl" />
        <div className="absolute -bottom-24 -right-16 h-80 w-80 rounded-full bg-et-yellow/10 blur-3xl" />
        <svg className="absolute inset-x-0 bottom-0 h-24 w-full opacity-20" viewBox="0 0 680 80" preserveAspectRatio="none">
          <path d="M0 40 L40 20 L80 40 L120 20 L160 40 L200 20 L240 40 L280 20 L320 40 L360 20 L400 40 L440 20 L480 40 L520 20 L560 40 L600 20 L640 40 L680 20"
            fill="none" stroke="#078930" strokeWidth="3" />
        </svg>
      </div>

      <div className="relative z-10 w-full max-w-[400px]">
        <div className="mb-8 text-center">
          <div className="mx-auto mb-4 flex h-14 w-14 items-center justify-center rounded-2xl bg-et-green text-white shadow-lg shadow-et-green/30">
            <span className="font-ethiopic text-2xl font-bold">ኢ</span>
          </div>
          <h1 className="text-[28px] font-bold tracking-tight text-white">
            <span className="font-ethiopic">ኢትLang</span>
            <span className="text-et-yellow"> Admin</span>
          </h1>
          <p className="mt-1.5 text-sm text-sidebar-text">
            Manage courses, learners, and notifications
          </p>
        </div>

        <form
          onSubmit={submit}
          className="space-y-4 rounded-2xl border border-white/10 bg-white/[0.04] p-7 shadow-2xl backdrop-blur-xl"
        >
          <Field label={<span className="text-white">Email</span>}>
            <input
              type="email"
              placeholder="admin@etlang.app"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              className={`${inputCls} mt-1.5 border-white/10 bg-white/5 text-white placeholder:text-white/35 focus:border-et-green focus:bg-white/[0.07]`}
            />
          </Field>
          <Field label={<span className="text-white">Password</span>}>
            <input
              type="password"
              placeholder="••••••••"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              className={`${inputCls} mt-1.5 border-white/10 bg-white/5 text-white placeholder:text-white/35 focus:border-et-green focus:bg-white/[0.07]`}
            />
          </Field>

          {error && (
            <Banner tone="danger">{error}</Banner>
          )}

          <Button
            type="submit"
            variant="primary"
            disabled={busy}
            className="w-full py-3 text-[14px]"
          >
            {busy ? 'Signing in…' : 'Sign in'}
          </Button>

          <p className="text-center text-[12px] text-sidebar-text/60">
            Change the default password before production
          </p>
        </form>

        <p className="mt-6 text-center text-[12px] text-sidebar-text/50">
          etLingo · Learn Ethiopian Languages
        </p>
      </div>
    </div>
  );
}
