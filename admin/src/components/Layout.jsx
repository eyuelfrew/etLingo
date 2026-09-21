import { NavLink, Outlet, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

const NAV_GROUPS = [
  {
    group: 'Overview',
    items: [{ to: '/', label: 'Dashboard', icon: 'M3 12h4l3-8 4 16 3-8h4' }],
  },
  {
    group: 'Curriculum',
    items: [
      {
        to: '/languages',
        label: 'Courses',
        icon: 'M12 3a9 9 0 100 18 9 9 0 000-18zm0 0c2.5 2.5 3.5 5.5 3.5 9s-1 6.5-3.5 9m0-18c-2.5 2.5-3.5 5.5-3.5 9s1 6.5 3.5 9M3.5 9h17m-17 6h17',
      },
      {
        to: '/base-languages',
        label: 'Base languages',
        icon: 'M3 12h4m4 0h10M7 12a2 2 0 11-4 0 2 2 0 014 0zm10 0a2 2 0 11-4 0 2 2 0 014 0zM3 7h18M3 17h18',
      },
    ],
  },
  {
    group: 'Learning content',
    items: [
      {
        to: '/lessons',
        label: 'Lessons',
        icon: 'M4 19V6a2 2 0 012-2h9l5 5v10a2 2 0 01-2 2H6a2 2 0 01-2-2z',
      },
      {
        to: '/phrases',
        label: 'Phrasebook',
        icon: 'M8 10h8M8 14h5M21 12a9 9 0 11-4-7.5L21 3v9z',
      },
    ],
  },
  {
    group: 'Audience',
    items: [
      {
        to: '/users',
        label: 'Learners',
        icon: 'M16 19v-1a4 4 0 00-4-4H7a4 4 0 00-4 4v1m13-9a4 4 0 11-8 0 4 4 0 018 0zm5 9v-1a4 4 0 00-3-3.87',
      },
    ],
  },
  {
    group: 'Engagement',
    items: [
      {
        to: '/notifications',
        label: 'Notifications',
        icon: 'M15 17h5l-1.4-1.4A2 2 0 0118 14.2V11a6 6 0 10-12 0v3.2c0 .5-.2 1-.6 1.4L4 17h5m6 0a3 3 0 11-6 0',
      },
    ],
  },
];

function NavIcon({ path }) {
  return (
    <svg
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth="1.7"
      strokeLinecap="round"
      strokeLinejoin="round"
      className="h-[18px] w-[18px] shrink-0"
    >
      <path d={path} />
    </svg>
  );
}

function TibebStrip() {
  return (
    <div className="flex h-1 overflow-hidden rounded-full">
      <span className="flex-1 bg-et-green" />
      <span className="flex-1 bg-et-yellow" />
      <span className="flex-1 bg-et-red" />
    </div>
  );
}

export default function Layout() {
  const { admin, logout } = useAuth();
  const navigate = useNavigate();

  return (
    <div className="flex h-screen bg-canvas text-ink antialiased">
      <aside className="flex w-[248px] shrink-0 flex-col bg-sidebar">
        <div className="px-5 pt-5 pb-4">
          <div className="flex items-center gap-3">
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-et-green text-[18px] font-bold text-white">
              <span className="font-ethiopic">ኢ</span>
            </div>
            <div className="min-w-0">
              <p className="truncate text-[15px] font-bold leading-tight text-white">
                <span className="font-ethiopic">ኢትLang</span> Admin
              </p>
              <p className="text-[11px] font-medium text-sidebar-text/70">
                Ethiopian languages
              </p>
            </div>
          </div>
          <div className="mt-3 px-0.5">
            <TibebStrip />
          </div>
        </div>

        <nav className="flex-1 overflow-y-auto px-3 pb-4">
          {NAV_GROUPS.map(({ group, items }) => (
            <div key={group} className="mt-4 first:mt-0">
              <p className="px-3 pb-1.5 text-[11px] font-semibold tracking-wide text-sidebar-text/45">
                {group}
              </p>
              <div className="space-y-0.5">
                {items.map((item) => (
                  <NavLink
                    key={item.to}
                    to={item.to}
                    end={item.to === '/'}
                    className={({ isActive }) =>
                      `flex items-center gap-2.5 rounded-xl px-3 py-2.5 text-[13.5px] font-medium transition ${
                        isActive
                          ? 'bg-sidebar-active text-white shadow-[inset_0_0_0_1px_rgba(7,137,48,0.35)]'
                          : 'text-sidebar-text hover:bg-white/5 hover:text-white'
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

        <div className="border-t border-white/5 p-3">
          <div className="flex items-center gap-2.5 rounded-xl bg-white/5 px-3 py-2.5">
            <div className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-et-green text-sm font-bold text-white">
              {(admin?.name || '?').slice(0, 1).toUpperCase()}
            </div>
            <div className="min-w-0 flex-1">
              <p className="truncate text-[13px] font-semibold text-white">{admin?.name}</p>
              <p className="truncate text-[11px] text-sidebar-text/60">{admin?.email}</p>
            </div>
          </div>
          <button
            onClick={() => {
              logout();
              navigate('/login');
            }}
            className="mt-2 w-full rounded-xl px-3 py-2.5 text-left text-[13px] font-medium text-sidebar-text/70 transition hover:bg-white/5 hover:text-et-red"
          >
            Sign out
          </button>
        </div>
      </aside>

      <div className="flex min-w-0 flex-1 flex-col">
        <header className="flex h-14 shrink-0 items-center justify-between border-b border-line-soft bg-panel px-8">
          <p className="text-[13px] text-muted">
            Content &amp; learner operations
            <span className="mx-2 text-line">/</span>
            <span className="font-semibold text-ink">etLingo</span>
          </p>
          <span className="inline-flex items-center gap-2 rounded-full bg-et-green-soft px-3 py-1.5 text-[12px] font-semibold text-et-green-dark">
            <span className="relative flex h-1.5 w-1.5">
              <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-et-green opacity-50" />
              <span className="relative inline-flex h-1.5 w-1.5 rounded-full bg-et-green" />
            </span>
            API connected
          </span>
        </header>

        <main className="flex-1 overflow-y-auto">
          <div className="mx-auto max-w-6xl px-8 py-8">
            <Outlet />
          </div>
        </main>
      </div>
    </div>
  );
}
