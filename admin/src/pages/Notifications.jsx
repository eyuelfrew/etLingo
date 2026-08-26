import { useCallback, useEffect, useState } from 'react';
import client from '../api/client';

const emptyForm = { title: '', body: '', type: 'general' };

export default function Notifications() {
  const [instant, setInstant] = useState(emptyForm);
  const [campaign, setCampaign] = useState({
    ...emptyForm,
    audience: 'active',
    batchSize: 50,
    intervalMinutes: 60,
  });
  const [rows, setRows] = useState([]);
  const [campaigns, setCampaigns] = useState([]);
  const [error, setError] = useState('');
  const [notice, setNotice] = useState('');

  // Targeted-send picker: "everyone" (broadcast) or a chosen subset of learners.
  const [targetMode, setTargetMode] = useState('everyone'); // 'everyone' | 'some'
  const [learners, setLearners] = useState([]);
  const [targetQ, setTargetQ] = useState('');
  const [targetIds, setTargetIds] = useState([]);

  const load = useCallback(async () => {
    try {
      const [n, c, l] = await Promise.all([
        client.get('/admin/notifications'),
        client.get('/admin/campaigns'),
        client.get('/admin/app-users'),
      ]);
      setRows(n.data);
      setCampaigns(c.data);
      setLearners(l.data);
    } catch (e) {
      setError(e.response?.data?.error || 'Failed to load notifications.');
    }
  }, []);

  useEffect(() => { load(); }, [load]);

  const flash = (msg) => {
    setNotice(msg);
    setError('');
    setTimeout(() => setNotice(''), 2500);
  };

  // ── Instant send: broadcast (everyone) or a chosen subset, immediately ────────
  const sendInstant = async (e) => {
    e.preventDefault();
    try {
      const targeted = targetMode === 'some' && targetIds.length > 0;
      const payload = targeted ? { ...instant, userIds: targetIds } : instant;
      const res = await client.post('/admin/notifications', payload);
      const sent = res.data?.sent ?? 1;
      setInstant(emptyForm);
      setTargetIds([]);
      setTargetQ('');
      setTargetMode('everyone');
      flash(targeted ? `Sent to ${sent} learner(s) ✓` : 'Broadcast sent ✓');
      await load();
    } catch (err) {
      setError(err.response?.data?.error || 'Send failed');
    }
  };

  const toggleTarget = (id) => {
    setTargetIds((prev) =>
      prev.includes(id) ? prev.filter((x) => x !== id) : [...prev, id],
    );
  };

  const filteredLearners = learners.filter(
    (u) =>
      (u.displayName || '').toLowerCase().includes(targetQ.toLowerCase()) ||
      (u.email || '').toLowerCase().includes(targetQ.toLowerCase()),
  );

  // ── Scheduled campaign (batched rounds) ─────────────────────────────────────
  const createCampaign = async (e) => {
    e.preventDefault();
    try {
      await client.post('/admin/campaigns', campaign);
      setCampaign({ ...emptyForm, audience: 'active', batchSize: 50, intervalMinutes: 60 });
      flash('Campaign scheduled — rounds will start delivering now ✓');
      await load();
    } catch (err) {
      setError(err.response?.data?.error || 'Could not schedule campaign');
    }
  };

  const cancel = async (id) => {
    if (!window.confirm('Cancel this campaign? Learners not yet reached will never get it.')) return;
    try {
      await client.post(`/admin/campaigns/${id}/cancel`);
      await load();
    } catch (err) {
      setError(err.response?.data?.error || 'Cancel failed');
    }
  };

  const removeCampaign = async (id) => {
    if (!window.confirm('Delete this campaign and its delivery history?')) return;
    try {
      await client.delete(`/admin/campaigns/${id}`);
      await load();
    } catch (err) {
      setError(err.response?.data?.error || 'Delete failed');
    }
  };

  const removeNotif = async (id) => {
    if (!window.confirm('Delete this notification?')) return;
    try {
      await client.delete(`/admin/notifications/${id}`);
      await load();
    } catch (err) {
      setError(err.response?.data?.error || 'Delete failed');
    }
  };

  return (
    <div>
      <div>
        <h1 className="text-2xl font-black">Notifications</h1>
        <p className="mt-1 text-sm font-medium text-stone-500">
          Broadcast instantly, or schedule a campaign that reaches learners in rounds. To message
          one learner, use the bell icon on their row in Learners.
        </p>
      </div>

      {error && (
        <p className="mt-4 rounded-lg bg-red-50 px-3 py-2 text-sm font-semibold text-red-700">{error}</p>
      )}
      {notice && (
        <p className="mt-4 rounded-lg bg-green-50 px-3 py-2 text-sm font-semibold text-green-800">{notice}</p>
      )}


      {/* -- Instant broadcast ------------------------------------------------ */}
      <form onSubmit={sendInstant} className="mt-6 grid gap-4 rounded-2xl border border-stone-200 bg-white p-6">
        <div className="text-xs font-black uppercase tracking-wider text-stone-400">Instant broadcast</div>
        <div className="grid gap-3 sm:grid-cols-2">
          <Input label="Title *">
            <input required maxLength={160} value={instant.title} onChange={(e) => setInstant({ ...instant, title: e.target.value })} className={inputCls} />
          </Input>
          <Input label="Category">
            <select value={instant.type} onChange={(e) => setInstant({ ...instant, type: e.target.value })} className={inputCls}>
              <option value="general">General</option><option value="feature">Feature</option><option value="alert">Alert</option>
            </select>
          </Input>
        </div>
        <Input label="Message">
          <textarea rows={3} maxLength={500} value={instant.body} onChange={(e) => setInstant({ ...instant, body: e.target.value })} className={`${inputCls} resize-y`} />
        </Input>

        {/* -- Recipients: everyone or a selected subset ---------------------- */}
        <div>
          <span className="mb-1 block text-xs font-black uppercase tracking-wider text-stone-400">Send to</span>
          <div className="flex items-center gap-2">
            {[
              ['everyone', 'Everyone'],
              ['some', 'Specific learners'],
            ].map(([val, label]) => (
              <button
                type="button"
                key={val}
                onClick={() => setTargetMode(val)}
                className={`rounded-full border px-3 py-1.5 text-xs font-bold transition ${
                  targetMode === val
                    ? val === 'everyone'
                      ? 'border-yellow-500 bg-yellow-100 text-yellow-800'
                      : 'border-green-600 bg-green-100 text-green-800'
                    : 'border-stone-200 text-stone-500 hover:bg-stone-50'
                }`}
              >
                {label}
                {val === 'some' && targetIds.length > 0 && (
                  <span className="ml-1">{targetIds.length}</span>
                )}
              </button>
            ))}
          </div>

          {targetMode === 'some' && (
            <div className="mt-3">
              <input
                value={targetQ}
                onChange={(e) => setTargetQ(e.target.value)}
                placeholder="Search name / email…"
                className={`${inputCls} !mt-0`}
              />
              {filteredLearners.length === 0 && (
                <p className="mt-2 text-xs font-medium text-stone-400">No learners match.</p>
              )}
              <div className="mt-2 max-h-56 space-y-1 overflow-y-auto rounded-xl border border-stone-200 p-2">
                {filteredLearners.map((u) => {
                  const sel = targetIds.includes(u.id);
                  return (
                    <label key={u.id} className={`flex cursor-pointer items-center gap-2 rounded-lg px-2 py-1.5 text-sm transition ${sel ? 'bg-green-50' : 'hover:bg-stone-50'}`}>
                      <input
                        type="checkbox"
                        checked={sel}
                        onChange={() => toggleTarget(u.id)}
                        className="h-4 w-4 accent-green-700"
                      />
                      <span className="min-w-0 truncate font-semibold text-stone-700">
                        {u.displayName || '—'}
                      </span>
                      <span className="ml-auto truncate text-xs font-medium text-stone-400">{u.email}</span>
                    </label>
                  );
                })}
              </div>
            </div>
          )}
        </div>

        <button type="submit" disabled={targetMode === 'some' && targetIds.length === 0} className="w-fit rounded-xl bg-yellow-500 px-5 py-2.5 text-sm font-bold text-white shadow transition hover:bg-yellow-600 disabled:cursor-not-allowed disabled:opacity-40">
          {targetMode === 'some'
            ? `Send to ${targetIds.length || 0} learner(s)`
            : 'Send broadcast'}
        </button>
      </form>

      {/* -- Campaign scheduler ------------------------------------------------ */}
      <form onSubmit={createCampaign} className="mt-6 grid gap-4 rounded-2xl border border-stone-200 bg-white p-6">
        <div className="text-xs font-black uppercase tracking-wider text-stone-400">Scheduled campaign</div>
        <div className="grid gap-3 sm:grid-cols-2">
          <Input label="Title *">
            <input required maxLength={160} value={campaign.title} onChange={(e) => setCampaign({ ...campaign, title: e.target.value })} className={inputCls} />
          </Input>
          <Input label="Category">
            <select value={campaign.type} onChange={(e) => setCampaign({ ...campaign, type: e.target.value })} className={inputCls}>
              <option value="general">General</option><option value="feature">Feature</option><option value="alert">Alert</option>
            </select>
          </Input>
        </div>
        <Input label="Message">
          <textarea rows={3} maxLength={500} value={campaign.body} onChange={(e) => setCampaign({ ...campaign, body: e.target.value })} className={`${inputCls} resize-y`} />
        </Input>
        <div className="grid gap-3 sm:grid-cols-3 sm:items-end">
          <Input label="Audience">
            <select value={campaign.audience} onChange={(e) => setCampaign({ ...campaign, audience: e.target.value })} className={inputCls}>
              <option value="active">Active learners</option><option value="all">All learners</option>
            </select>
          </Input>
          <Input label="Batch size">
            <input type="number" min={1} max={10000} value={campaign.batchSize} onChange={(e) => setCampaign({ ...campaign, batchSize: Number(e.target.value) })} className={inputCls} />
          </Input>
          <Input label="Interval (min)">
            <input type="number" min={1} value={campaign.intervalMinutes} onChange={(e) => setCampaign({ ...campaign, intervalMinutes: Number(e.target.value) })} className={inputCls} />
          </Input>
        </div>
        <button type="submit" className="w-fit self-start rounded-xl bg-yellow-500 px-5 py-2.5 text-sm font-bold text-white shadow transition hover:bg-yellow-600">
          Schedule campaign
        </button>
      </form>

      {/* -- Scheduled campaigns ----------------------------------------------- */}
      <h2 className="mt-8 text-lg font-black">Scheduled campaigns</h2>
      <div className="mt-3 space-y-2">
        {campaigns.length === 0 && (
          <p className="rounded-xl bg-white p-6 text-center text-sm font-medium text-stone-400">No campaigns yet.</p>
        )}
        {campaigns.map((c) => {
          const active = c.status === 'pending' || c.status === 'running';
          const tint = c.status === 'completed' ? 'bg-green-100 text-green-800'
            : c.status === 'cancelled' ? 'bg-stone-200 text-stone-600'
            : 'bg-yellow-100 text-yellow-800';
          const pct = Math.min(100, (c.totalSent / Math.max(1, c.batchSize)) * 100);
          return (
            <div key={c.id} className="rounded-xl border border-stone-200 bg-white px-4 py-3">
              <div className="flex items-start justify-between gap-3">
                <div className="min-w-0 flex-1">
                  <div className="flex items-center gap-2">
                    <span className={`rounded-full px-2 py-0.5 text-[11px] font-black uppercase ${tint}`}>{c.status}</span>
                    <span className="truncate text-sm font-bold text-stone-800">{c.title}</span>
                  </div>
                  <div className="mt-1 text-xs font-medium text-stone-500">
                    {c.totalSent} sent · {c.batchSize}/round · every {c.intervalSeconds}s · {c.audience}
                  </div>
                  {c.body && <div className="mt-1 truncate text-xs font-medium text-stone-400">{c.body}</div>}
                  {active && <div className="mt-2 h-1.5 w-full max-w-xs overflow-hidden rounded-full bg-stone-100"><div className="h-full rounded-full bg-green-600 transition-all" style={{ width: `${pct}%` }} /></div>}
                </div>
                <div className="flex items-center gap-1.5">
                  {active && (<button onClick={() => cancel(c.id)} className="rounded-lg border border-yellow-300 px-2.5 py-1 text-xs font-bold text-yellow-800 hover:bg-yellow-50">Cancel</button>)}
                  <button onClick={() => removeCampaign(c.id)} className="rounded-lg border border-red-200 px-2.5 py-1 text-xs font-bold text-red-600 hover:bg-red-50">Delete</button>
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* -- Broadcast history ----------------------------------------------- */}
      <h2 className="mt-8 text-lg font-black">Broadcast history</h2>
      <div className="mt-3 space-y-2">
        {rows.length === 0 && (
          <p className="rounded-xl bg-white p-6 text-center text-sm font-medium text-stone-400">Nothing sent yet.</p>
        )}
        {rows.map((n) => (
          <div key={n.id} className="flex items-center gap-4 rounded-xl border border-stone-200 bg-white px-4 py-3">
            <span className={`rounded-full px-2 py-0.5 text-[11px] font-black uppercase ${n.read ? 'bg-stone-200 text-stone-500' : 'bg-sky-100 text-sky-800'}`}>
              {n.read ? 'read' : 'new'}
            </span>
            <div className="min-w-0 flex-1">
              <div className="truncate text-sm font-bold text-stone-800">{n.title}</div>
              {n.body && <div className="truncate text-xs font-medium text-stone-500">{n.body}</div>}
            </div>
            <button onClick={() => removeNotif(n.id)} className="rounded-lg border border-red-200 px-2.5 py-1 text-xs font-bold text-red-600 hover:bg-red-50">Delete</button>
          </div>
        ))}
      </div>
    </div>
  );
}

const inputCls = 'mt-1 w-full rounded-xl border border-stone-300 px-3 py-2 text-sm font-medium outline-none focus:border-yellow-500';

function Input({ label, children }) {
  return (
    <label className="block">
      <span className="mb-1 block text-xs font-black uppercase tracking-wider text-stone-400">{label}</span>
      {children}
    </label>
  );
}