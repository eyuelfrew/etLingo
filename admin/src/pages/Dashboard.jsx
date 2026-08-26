import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import client from '../api/client';

const cards = [
  ['languages', 'Languages', '🗣', 'bg-green-100 text-green-800'],
  ['units', 'Units', '🧩', 'bg-yellow-100 text-yellow-800'],
  ['lessons', 'Lessons', '📚', 'bg-red-100 text-red-800'],
  ['questions', 'Questions', '❓', 'bg-blue-100 text-blue-800'],
  ['phrases', 'Phrases', '💬', 'bg-purple-100 text-purple-800'],
];

export default function Dashboard() {
  const [stats, setStats] = useState(null);
  const [learners, setLearners] = useState(null);
  const [error, setError] = useState('');

  useEffect(() => {
    client
      .get('/admin/stats')
      .then((r) => setStats(r.data))
      .catch((e) =>
        setError(e.response?.data?.error?.includes('admins') || e.code === 'ERR_NETWORK'
          ? 'Cannot reach the database. Start MySQL and run `npm run db:init` in backend/.'
          : 'Failed to load stats.'),
      );
    client
      .get('/admin/app-users')
      .then((r) => setLearners(r.data.length))
      .catch(() => setLearners(0));
  }, []);

  return (
    <div>
      <h1 className="text-2xl font-black">Dashboard</h1>
      <p className="mt-1 text-sm font-medium text-stone-500">
        Content overview across all Ethiopian languages
      </p>

      {error && (
        <p className="mt-6 rounded-xl border border-amber-300 bg-amber-50 px-5 py-4 text-sm font-semibold text-amber-800">
          ⚠ {error}
        </p>
      )}

      <div className="mt-6 grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-5">
        {cards.map(([key, label, icon, tint]) => (
          <div key={key} className="rounded-2xl border border-stone-200 bg-white p-5 shadow-sm">
            <div className={`mb-3 flex h-10 w-10 items-center justify-center rounded-xl text-lg ${tint}`}>
              {icon}
            </div>
            <div className="text-2xl font-black">{stats ? stats[key] : '—'}</div>
            <div className="text-xs font-bold uppercase tracking-wider text-stone-400">
              {label}
            </div>
          </div>
        ))}
        <Link
          to="/users"
          className="rounded-2xl border border-stone-200 bg-white p-5 shadow-sm transition hover:border-green-600"
        >
          <div className="mb-3 flex h-10 w-10 items-center justify-center rounded-xl bg-orange-100 text-lg">
            👥
          </div>
          <div className="text-2xl font-black">{learners ?? '—'}</div>
          <div className="text-xs font-bold uppercase tracking-wider text-stone-400">Learners</div>
        </Link>
      </div>

      <div className="mt-4 grid gap-3 sm:grid-cols-2">
        <Link
          to="/users"
          className="flex items-center justify-between rounded-xl border border-stone-200 bg-white px-5 py-4 text-sm font-bold text-stone-700 shadow-sm transition hover:border-green-600 hover:text-green-800"
        >
          Manage learners (ban / unban / delete)
          <span aria-hidden>→</span>
        </Link>
        <Link
          to="/notifications"
          className="flex items-center justify-between rounded-xl border border-stone-200 bg-white px-5 py-4 text-sm font-bold text-stone-700 shadow-sm transition hover:border-yellow-500 hover:text-yellow-700"
        >
          Send a notification to learners
          <span aria-hidden>→</span>
        </Link>
      </div>
    </div>
  );
}
