import { NavLink, Outlet, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

// Navigation grouped the way staff think about the product, not by table.
const NAV_GROUPS = [
  {
    group: 'Overview',
    items: [{ to: '/', label: 'Dashboard', icon: 'M3 12h4l3-8 4 16 3-8h4' }],
  },
  {
    group: 'Curriculum',
    items: [
      { to: '/languages', label: 'Languages', icon: 'M12 3a9 9 0 100 18 9 9 0 000-18zm0 0c2.5 2.5 3.5 5.5 3.5 9s-1 6.5-3.5 9m0-18c-2.5 2.5-3.5 5.5-3.5 9s1 6.5 3.5 9M3.5 9h17m-17 6h17' },
    ],
  },
  {
    group: 'Learning content',
    items: [
      { to: '/lessons', label: 'Lessons', icon: 'M4 19V6a2 2 0 012-2h9l5 5v10a2 2 0 01-2 2H6a2 2 0 01-2-2z' },
      { to: '/phrases', label: 'Phrasebook', icon: 'M8 10h8M8 14h5M21 12a9 9 0 11-4-7.5L21 3v9z' },
    ],
  },
  {
    group: 'Audience',
    items: [
      { to: '/users', label: 'Learners', icon: 'M16 19v-1a4 4 0 00-4-4H7a4 4 0 00-4 4v1m13-9a4 4 0 11-8 0 4 4 0 018 0zm5 9v-1a4 4 0 00-3-3.87' },
    ],
  },
  {
    group: 'Engagement',
    items: [
      { to: '/notifications', label: 'Notifications', icon: 'M15 17h5l-1.4-1.4A2 2 0 0118 14.2V11a6 6 0 10-12 0v3.2c0 .5-.2 1-.6 1.4L4 17h5m6 0a3 3 0 11-6 0' },
    ],
  },
];

function NavIcon({ path }) {
  return (
    <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.7"
      strokeLinecap="round" strokeLinejoin="round" className="h-[18px] w-[18px] shrink-0">
      <path d={path} />
    </svg>
  );
}

export default function Layout() {
  const { admin, logout } = useAuth();
  const navigate = useNavigate();

  return (
    <div className="flex h-screen bg-slate-50 text-slate-800 antialiased">
      {/* Sidebar */}
      <aside className="flex w-60 shrink-0 flex-col border-r border-slate-800 bg-slate-900">
        <div className="flex items-center gap-2.5 px-5 py-5">
          <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-emerald-600 text-sm font-bold text-white">
            ኢ
          </div>
          <div>
            <p className="text-sm font-semibold leading-tight tracking-tight text-white">EtLingo</p>
            <p className="text-[10px] font-medium uppercase tracking-[0.14em] text-slate-500">
              Admin Console
            </p>
          </div>
        </div>

        <nav className="flex-1 overflow-y-auto px-3 pb-4">
          {NAV_GROUPS.map(({ group, items }) => (
            <div key={group} className="mt-4 first:mt-1">
              <p className="px-3 pb-1.5 text-[10px] font-semibold uppercase tracking-[0.14em] text-slate-600">
                {group}
              </p>
              <div className="space-y-0.5">
                {items.map((item) => (
                  <NavLink
                    key={item.to}
                    to={item.to}
                    end={item.to === '/'}
                    className={({ isActive }) =>
                      `flex items-center gap-2.5 rounded-lg px-3 py-2 text-[13px] font-medium transition ${
                        isActive
                          ? 'bg-slate-800 text-white'
                          : 'text-slate-400 hover:bg-slate-800/60 hover:text-slate-200'
                      }`
                    }
                  >
                    <NavIcon path={item.icon} />
                    {item.label}
                  </NavLink>
                ))}
              </div>
            </div>
          ))}
        </nav>

        {/* Identity */}
        <div className="border-t border-stone-800 p-3">
          <div className="flex items-center gap-2.5 rounded-lg bg-slate-800/60 px-3 py-2.5">
            <div className="flex h-8 w-8 shrink-0 items-center justify-center rounded-full bg-slate-700 text-xs font-semibold uppercase text-slate-200">
              {(admin?.name || '?').slice(0, 1)}
            </div>
            <div className="min-w-0 flex-1">
              <p className="truncate text-xs font-semibold text-white">{admin?.name}</p>
              <p className="truncate text-[11px] text-slate-500">{admin?.email}</p>
            </div>
          </div>
          <button
            onClick={() => { logout(); navigate('/login'); }}
            className="mt-2 w-full rounded-lg px-3 py-2 text-left text-[11px] font-semibold uppercase tracking-wider text-slate-500 transition hover:bg-slate-800 hover:text-red-400"
          >
            Sign out
          </button>
        </div>
      </aside>

      {/* Main column */}
      <div className="flex min-w-0 flex-1 flex-col">
        <header className="flex h-14 shrink-0 items-center justify-between border-b border-slate-200 bg-white px-8">
          <p className="text-[13px] text-slate-400">
            Ethiopian Language Learning Platform
            <span className="mx-2 text-slate-300">/</span>
            <span className="font-medium text-slate-600">Operations</span>
          </p>
          <span className="inline-flex items-center gap-1.5 rounded-full bg-emerald-50 px-2.5 py-1 text-[11px] font-medium text-emerald-700 ring-1 ring-inset ring-emerald-200">
            <span className="relative flex h-1.5 w-1.5">
              <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-emerald-400 opacity-60" />
              <span className="relative inline-flex h-1.5 w-1.5 rounded-full bg-emerald-500" />
            </span>
            System operational
          </span>
        </header>

        <main className="flex-1 overflow-y-auto">
          <div className="mx-auto max-w-6xl px-8 py-7">
            <Outlet />
          </div>
        </main>
      </div>
    </div>
  );
}
