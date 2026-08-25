import { useCallback, useEffect, useState } from 'react';
import client from '../api/client';

const emptyForm = { email: '', display_name: '', password: '', xp: 0, hearts: 5, streak: 0, status: 'active' };
const iconBtn = 'flex h-8 w-8 items-center justify-center rounded-lg border text-xs transition disabled:opacity-40';

export default function Users() {
  const [rows, setRows] = useState([]);
  const [q, setQ] = useState('');
  const [status, setStatus] = useState('');
  const [error, setError] = useState('');
  const [busyId, setBusyId] = useState(null);

  const [formOpen, setFormOpen] = useState(false);
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState(emptyForm);
  const [detail, setDetail] = useState(null);
  const [notifyFor, setNotifyFor] = useState(null);
  const [notifyMsg, setNotifyMsg] = useState({ title: '', body: '' });

  const load = useCallback(async () => {
    try {
      const params = new URLSearchParams();
      if (q) params.set('q', q);
      if (status) params.set('status', status);
      const { data } = await client.get(`/admin/app-users?${params}`);
      setRows(data);
    } catch (e) {
      setError(e.response?.data?.error || 'Failed to load users.');
    }
  }, [q, status]);

  useEffect(() => { load(); }, [load]);

  const run = async (id, fn) => {
    setBusyId(id ?? 'new');
    try { await fn(); setError(''); }
    catch (e) { setError(e.response?.data?.error || 'Action failed'); }
    finally { setBusyId(null); }
  };

  const openCreate = () => { setEditing(null); setForm(emptyForm); setFormOpen(true); };

  const openEdit = (u) => {
    setEditing(u);
    setForm({
      email: u.email || '', display_name: u.displayName || '', password: '',
      xp: u.xp ?? 0, hearts: u.hearts ?? 5, streak: u.streak ?? 0,
      status: u.status || 'active',
    });
    setFormOpen(true);
  };

  const saveForm = async (e) => {
    e.preventDefault();
    if (editing) {
      await run(editing.id, async () => {
        await client.put(`/admin/app-users/${editing.id}`, form);
        setFormOpen(false);
        await load();
      });
    } else {
      await run('new', async () => {
        await client.post('/admin/app-users', form);
        setFormOpen(false);
        await load();
      });
    }
  };

  const setStatusFor = (u, next) =>
    run(u.id, async () => {
      await client.put(`/admin/app-users/${u.id}`, { status: next });
      await load();
    });

  const resetProgress = (u) => {
    if (!window.confirm(`Reset ALL progress for ${u.displayName || u.email}? XP and lessons will be wiped.`)) return;
    run(u.id, async () => {
      await client.post(`/admin/app-users/${u.id}/reset-progress`);
      await load();
    });
  };

  const remove = (u) => {
    if (!window.confirm(`Permanently delete ${u.displayName || u.email} and all their data?`)) return;
    run(u.id, async () => {
      await client.delete(`/admin/app-users/${u.id}`);
      await load();
    });
  };

    const viewDetail = async (u) => {
    await run(u.id, async () => {
      const { data } = await client.get(`/admin/app-users/${u.id}`);
      setDetail(data);
    });
  };

  const sendDirect = async (e) => {
    e.preventDefault();
    await run(notifyFor.id, async () => {
      await client.post('/admin/notifications', { ...notifyMsg, userId: notifyFor.id });
      setNotifyFor(null);
      setNotifyMsg({ title: '', body: '' });
    });
  };

  return (
    <div>
      <div className="flex flex-wrap items-end justify-between gap-4">
        <div>
          <h1 className="text-2xl font-black">Learners</h1>
          <p className="mt-1 text-sm font-medium text-stone-500">
            Full control: create, edit, inspect, notify, ban or remove accounts
          </p>
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <input value={q} onChange={(e) => setQ(e.target.value)} placeholder="Search name / email…"
            className="w-52 rounded-xl border border-stone-300 px-3 py-2 text-sm font-medium outline-none focus:border-green-700" />
          <select value={status} onChange={(e) => setStatus(e.target.value)}
            className="rounded-xl border border-stone-300 px-3 py-2 text-sm font-semibold outline-none focus:border-green-700">
            <option value="">All statuses</option>
            <option value="active">Active</option>
            <option value="banned">Banned</option>
          </select>
          <button onClick={openCreate}
            className="rounded-xl bg-green-700 px-4 py-2 text-sm font-bold text-white shadow transition hover:bg-green-800">
            + Add learner
          </button>
        </div>
      </div>

      {error && (
        <p className="mt-4 rounded-lg bg-red-50 px-3 py-2 text-sm font-semibold text-red-700">{error}</p>
      )}

      <div className="mt-6 overflow-x-auto rounded-2xl border border-stone-200 bg-white">
        <table className="w-full min-w-[820px] text-left text-sm">
          <thead className="bg-stone-100 text-[11px] font-black uppercase tracking-wider text-stone-500">
            <tr>
              <th className="px-4 py-3">Learner</th>
              <th className="px-4 py-3">Sign-in</th>
              <th className="px-4 py-3">XP</th>
              <th className="px-4 py-3">Hearts</th>
              <th className="px-4 py-3">Streak</th>
              <th className="px-4 py-3">Lessons</th>
              <th className="px-4 py-3">Status</th>
              <th className="px-4 py-3 text-right">Actions</th>
            </tr>
          </thead>
          <tbody>
            {rows.length === 0 && (
              <tr><td colSpan={8} className="px-4 py-10 text-center font-medium text-stone-400">No learners found.</td></tr>
            )}
            {rows.map((u) => (
              <tr key={u.id} className="border-t border-stone-100 hover:bg-stone-50/60">
                <td className="px-4 py-3">
                  <div className="font-bold text-stone-800">{u.displayName || '—'}</div>
                  <div className="text-xs font-medium text-stone-500">{u.email}</div>
                </td>
                <td className="px-4 py-3 capitalize">{u.provider}</td>
                <td className="px-4 py-3 font-bold">{u.xp}</td>
                <td className="px-4 py-3">{u.hearts}</td>
                <td className="px-4 py-3">{u.streak}</td>
                <td className="px-4 py-3">{u.lessonsDone ?? 0}</td>
                <td className="px-4 py-3">
                  <span className={`rounded-full px-2 py-0.5 text-xs font-bold ${u.status === 'active' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-700'}`}>
                    {u.status}
                  </span>
                </td>
                <td className="px-4 py-3">
                  <div className="flex items-center justify-end gap-1.5">
                    <button title="View details" disabled={busyId === u.id} onClick={() => viewDetail(u)} className={`${iconBtn} border-stone-200 hover:bg-stone-100`}>👁</button>
                    <button title="Edit account" disabled={busyId === u.id} onClick={() => openEdit(u)} className={`${iconBtn} border-blue-200 text-blue-700 hover:bg-blue-50`}>✏️</button>
                    <button title="Send notification" disabled={busyId === u.id} onClick={() => setNotifyFor(u)} className={`${iconBtn} border-amber-300 text-amber-700 hover:bg-amber-50`}>🔔</button>
                    <button title="Reset progress" disabled={busyId === u.id} onClick={() => resetProgress(u)} className={`${iconBtn} border-purple-200 text-purple-700 hover:bg-purple-50`}>♻️</button>
                    {u.status === 'active' ? (
                      <button title="Ban account" disabled={busyId === u.id} onClick={() => setStatusFor(u, 'banned')} className={`${iconBtn} border-yellow-300 text-yellow-800 hover:bg-yellow-50`}>🚫</button>
                    ) : (
                      <button title="Unban account" disabled={busyId === u.id} onClick={() => setStatusFor(u, 'active')} className={`${iconBtn} border-green-300 text-green-800 hover:bg-green-50`}>✅</button>
                    )}
                    <button title="Delete account" disabled={busyId === u.id} onClick={() => remove(u)} className={`${iconBtn} border-red-200 text-red-600 hover:bg-red-50`}>🗑</button>
                  </div>
                </td>
              </tr>
                        ))}
          </tbody>
        </table>
      </div>

      {/* -- Create / Edit modal ---------------------------------------------- */}
      {formOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-stone-900/40 p-4" onClick={() => setFormOpen(false)}>
          <form onSubmit={saveForm} onClick={(e) => e.stopPropagation()} className="w-full max-w-md rounded-2xl bg-white p-6 shadow-2xl">
            <h2 className="font-black">{editing ? `Edit learner #${editing.id}` : 'Add learner'}</h2>
            <div className="mt-4 grid gap-3">
              {!editing && (
                <>
                  <Field label="Email *"><input required type="email" value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} className={inputCls} /></Field>
                  <Field label="Password (optional)"><input type="password" minLength={8} value={form.password} onChange={(e) => setForm({ ...form, password: e.target.value })} placeholder="min 8 chars" className={inputCls} /></Field>
                </>
              )}
              <Field label="Display name"><input value={form.display_name} onChange={(e) => setForm({ ...form, display_name: e.target.value })} className={inputCls} /></Field>
              {editing && (
                <Field label="Email"><input type="email" value={form.email} onChange={(e) => setForm({ ...form, email: e.target.value })} className={inputCls} /></Field>
              )}
              <div className="grid grid-cols-3 gap-3">
                <Field label="XP"><input type="number" min={0} value={form.xp} onChange={(e) => setForm({ ...form, xp: Number(e.target.value) })} className={inputCls} /></Field>
                <Field label="Hearts"><input type="number" min={0} max={5} value={form.hearts} onChange={(e) => setForm({ ...form, hearts: Number(e.target.value) })} className={inputCls} /></Field>
                <Field label="Streak"><input type="number" min={0} value={form.streak} onChange={(e) => setForm({ ...form, streak: Number(e.target.value) })} className={inputCls} /></Field>
              </div>
              {editing && (
                <Field label="Status">
                  <select value={form.status} onChange={(e) => setForm({ ...form, status: e.target.value })} className={inputCls}>
                    <option value="active">Active</option>
                    <option value="banned">Banned</option>
                  </select>
                </Field>
              )}
            </div>
            <div className="mt-5 flex justify-end gap-2">
              <button type="button" onClick={() => setFormOpen(false)} className="rounded-xl border border-stone-300 px-4 py-2 text-sm font-bold text-stone-600 hover:bg-stone-50">Cancel</button>
              <button type="submit" disabled={busyId === editing?.id || busyId === 'new'} className="rounded-xl bg-green-700 px-5 py-2 text-sm font-bold text-white shadow hover:bg-green-800 disabled:opacity-50">
                {editing ? 'Save changes' : 'Create learner'}
              </button>
                        </div>
          </form>
        </div>
      )}

      {/* -- Detail modal ------------------------------------------------------ */}
      {detail && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-stone-900/40 p-4" onClick={() => setDetail(null)}>
          <div onClick={(e) => e.stopPropagation()} className="w-full max-w-md rounded-2xl bg-white p-6 shadow-2xl">
            <div className="flex items-start justify-between gap-4">
              <div>
                <h2 className="font-black">{detail.displayName || 'Learner'}</h2>
                <p className="text-xs font-medium text-stone-500">{detail.email}</p>
              </div>
              <span className={`rounded-full px-2 py-0.5 text-xs font-bold ${detail.status === 'active' ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-700'}`}>{detail.status}</span>
            </div>
            <div className="mt-4 grid grid-cols-3 gap-3 text-center">
              {[['XP', detail.xp], ['Hearts', detail.hearts], ['Streak', detail.streak]].map(([k, v]) => (
                <div key={k} className="rounded-xl bg-stone-100 p-3">
                  <div className="text-lg font-black">{v}</div>
                  <div className="text-[10px] font-bold uppercase tracking-wider text-stone-500">{k}</div>
                </div>
              ))}
            </div>
            <div className="mt-4 text-xs font-bold uppercase tracking-wider text-stone-400">
              Provider: <span className="normal-case tracking-normal text-stone-600">{detail.provider}</span>
              {' · '}Lessons done: <span className="normal-case tracking-normal text-stone-600">{detail.lessonsDone}</span>
            </div>
            {detail.recentLessons?.length > 0 && (
              <div className="mt-3 max-h-40 overflow-y-auto rounded-xl border border-stone-200">
                {detail.recentLessons.map((r, i) => (
                  <div key={i} className="flex justify-between border-b border-stone-100 px-3 py-2 text-xs font-medium text-stone-600 last:border-0">
                    <span>Lesson #{r.lessonId}</span>
                    <span>{r.xpEarned} XP / {r.mistakes} mistakes</span>
                  </div>
                ))}
              </div>
            )}
            <div className="mt-5 flex justify-end">
              <button onClick={() => setDetail(null)} className="rounded-xl border border-stone-300 px-4 py-2 text-sm font-bold text-stone-600 hover:bg-stone-50">Close</button>
                        </div>
          </div>
        </div>
      )}

      {/* -- Direct notification modal ----------------------------------------- */}
      {notifyFor && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-stone-900/40 p-4" onClick={() => setNotifyFor(null)}>
          <form onSubmit={sendDirect} onClick={(e) => e.stopPropagation()} className="w-full max-w-md rounded-2xl bg-white p-6 shadow-2xl">
            <h2 className="font-black">Notify {notifyFor.displayName || notifyFor.email}</h2>
            <p className="mt-1 text-xs font-medium text-stone-500">Delivered only to this learner's in-app inbox.</p>
            <div className="mt-4 grid gap-3">
              <Field label="Title *">
                <input required maxLength={160} value={notifyMsg.title} onChange={(e) => setNotifyMsg({ ...notifyMsg, title: e.target.value })} className={inputCls} />
              </Field>
              <Field label="Message">
                <textarea rows={3} maxLength={500} value={notifyMsg.body} onChange={(e) => setNotifyMsg({ ...notifyMsg, body: e.target.value })} className={`${inputCls} resize-y`} />
              </Field>
            </div>
            <div className="mt-5 flex justify-end gap-2">
              <button type="button" onClick={() => setNotifyFor(null)} className="rounded-xl border border-stone-300 px-4 py-2 text-sm font-bold text-stone-600 hover:bg-stone-50">Cancel</button>
              <button type="submit" disabled={busyId === notifyFor.id} className="rounded-xl bg-amber-500 px-5 py-2 text-sm font-bold text-white shadow hover:bg-amber-600 disabled:opacity-50">Send</button>
            </div>
          </form>
        </div>
      )}
    </div>
  );
}

const inputCls = 'mt-1 w-full rounded-xl border border-stone-300 px-3 py-2 text-sm font-medium outline-none focus:border-green-700';

function Field({ label, children }) {
  return (
    <label className="block text-xs font-black uppercase tracking-wider text-stone-500">
      {label}
      {children}
    </label>
  );
}
      