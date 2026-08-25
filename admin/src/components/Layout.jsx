import { NavLink, Outlet, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

const nav = [
  { to: '/', label: 'Dashboard', icon: '▦' },
  { to: '/languages', label: 'Languages', icon: '🗣' },
  { to: '/lessons', label: 'Lessons', icon: '📚' },
  { to: '/phrases', label: 'Phrasebook', icon: '💬' },
  { to: '/users', label: 'Learners', icon: '👥' },
  { to: '/notifications', label: 'Notifications', icon: '🔔' },
];

export default function Layout() {
  const { admin, logout } = useAuth();
  const navigate = useNavigate();

  return (
    <div className="flex h-screen">
      <aside className="flex w-60 shrink-0 flex-col bg-stone-900 text-stone-300">
        <div className="px-5 py-6">
          <div className="text-xl font-black tracking-tight text-white">
            ኢት<span className="text-yellow-400">Lingo</span>
          </div>
          <div className="mt-0.5 text-[11px] font-medium uppercase tracking-widest text-stone-500">
            Admin Console
          </div>
        </div>
        <nav className="flex-1 space-y-1 px-3">
          {nav.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.to === '/'}
              className={({ isActive }) =>
                `flex items-center gap-3 rounded-xl px-4 py-2.5 text-sm font-semibold transition ${
                  isActive
                    ? 'bg-green-700/90 text-white shadow'
                    : 'hover:bg-stone-800 hover:text-white'
                }`
              }
            >
              <span aria-hidden>{item.icon}</span>
              {item.label}
            </NavLink>
          ))}
        </nav>
        <div className="border-t border-stone-800 p-4">
          <div className="truncate text-sm font-bold text-white">{admin?.name}</div>
          <div className="truncate text-xs text-stone-500">{admin?.email}</div>
          <button
            onClick={() => {
              logout();
              navigate('/login');
            }}
            className="mt-3 w-full rounded-lg border border-stone-700 py-2 text-xs font-bold uppercase tracking-wider text-stone-400 transition hover:border-red-600 hover:text-red-400"
          >
            Sign out
          </button>
        </div>
      </aside>

      <main className="flex-1 overflow-y-auto">
        <div className="mx-auto max-w-5xl px-8 py-8">
          <Outlet />
        </div>
      </main>
    </div>
  );
}
