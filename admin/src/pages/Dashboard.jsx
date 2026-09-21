import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import client from '../api/client';
import { PageHeader, Stat, Card, Banner } from '../components/ui';

const cards = [
  ['languages', 'Languages'],
  ['units', 'Units'],
  ['lessons', 'Lessons'],
  ['questions', 'Questions'],
  ['phrases', 'Phrases'],
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
        setError(
          e.response?.data?.error?.includes('admins') || e.code === 'ERR_NETWORK'
            ? 'Cannot reach the API/MySQL. Start the backend and run npm run db:init if needed.'
            : 'Failed to load stats.',
        ),
      );
    client
      .get('/admin/app-users')
      .then((r) => setLearners(r.data.length))
      .catch(() => setLearners(0));
  }, []);

  return (
    <div>
      <PageHeader
        eyebrow="Overview"
        title="Dashboard"
        subtitle="Content coverage and audience health across Ethiopian language courses."
        actions={
          <Link
            to="/lessons"
            className="inline-flex min-h-10 items-center justify-center rounded-xl bg-et-green px-4 text-[13px] font-semibold text-white transition hover:bg-et-green-dark"
          >
            Open curriculum
          </Link>
        }
      />

      {error && (
        <div className="mt-6">
          <Banner tone="warning">{error}</Banner>
        </div>
      )}

      <div className="mt-6 grid grid-cols-2 gap-4 sm:grid-cols-3 lg:grid-cols-6">
        {cards.map(([key, label]) => (
          <Stat key={key} label={label} value={stats ? stats[key] : '—'} />
        ))}
        <Link to="/users" className="block transition hover:-translate-y-0.5">
          <Stat label="Learners" value={learners ?? '—'} tone="green" />
        </Link>
      </div>

      <div className="mt-6 grid gap-4 md:grid-cols-2">
        <Card title="Quick actions" description="Common staff workflows">
          <div className="space-y-2">
            <Link
              to="/languages"
              className="flex items-center justify-between rounded-xl border border-line-soft bg-canvas/50 px-4 py-3 text-[14px] font-medium text-ink transition hover:border-et-green/40 hover:bg-et-green-soft"
            >
              Manage courses (Amharic, Oromo…)
              <span aria-hidden className="text-et-green">→</span>
            </Link>
            <Link
              to="/base-languages"
              className="flex items-center justify-between rounded-xl border border-line-soft bg-canvas/50 px-4 py-3 text-[14px] font-medium text-ink transition hover:border-et-green/40 hover:bg-et-green-soft"
            >
              Manage base languages (English, Somali…)
              <span aria-hidden className="text-et-green">→</span>
            </Link>
            <Link
              to="/lessons"
              className="flex items-center justify-between rounded-xl border border-line-soft bg-canvas/50 px-4 py-3 text-[14px] font-medium text-ink transition hover:border-et-green/40 hover:bg-et-green-soft"
            >
              Author units, lessons &amp; questions
              <span aria-hidden className="text-et-green">→</span>
            </Link>
            <Link
              to="/users"
              className="flex items-center justify-between rounded-xl border border-line-soft bg-canvas/50 px-4 py-3 text-[14px] font-medium text-ink transition hover:border-et-green/40 hover:bg-et-green-soft"
            >
              Manage learners
              <span aria-hidden className="text-et-green">→</span>
            </Link>
            <Link
              to="/notifications"
              className="flex items-center justify-between rounded-xl border border-line-soft bg-canvas/50 px-4 py-3 text-[14px] font-medium text-ink transition hover:border-et-yellow/50 hover:bg-et-yellow/10"
            >
              Send a notification
              <span aria-hidden className="text-et-yellow-dark">→</span>
            </Link>
          </div>
        </Card>

        <Card title="About this console" description="What staff can do here">
          <ul className="space-y-3 text-[13.5px] leading-relaxed text-muted">
            <li className="flex gap-2">
              <span className="mt-1.5 h-1.5 w-1.5 shrink-0 rounded-full bg-et-green" />
              Publish languages and course branding for the mobile app.
            </li>
            <li className="flex gap-2">
              <span className="mt-1.5 h-1.5 w-1.5 shrink-0 rounded-full bg-et-yellow" />
              Build teach items and quizzes (mcq, fill, match, listen).
            </li>
            <li className="flex gap-2">
              <span className="mt-1.5 h-1.5 w-1.5 shrink-0 rounded-full bg-et-red" />
              Ban learners, reset progress, and send push campaigns.
            </li>
          </ul>
        </Card>
      </div>
    </div>
  );
}
