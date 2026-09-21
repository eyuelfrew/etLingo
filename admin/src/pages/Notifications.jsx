import { useCallback, useEffect, useState } from 'react';
import client from '../api/client';
import { PageHeader, Card, Stat, Badge, Button, EmptyState, Field, inputCls } from '../components/ui';

const emptyForm = { title: '', body: '', type: 'general' };

// Notification categories — must stay in sync with the backend taxonomy in
// notifications.preferences.js. Each maps to a learner preference toggle, so
// opted-out learners won't be pushed for that category (in-app inbox still gets
// the row).
const CATEGORIES = [
  ['general', 'General'],
  ['lesson_reminder', 'Lesson reminder'],
  ['streak_milestone', 'Streak milestone'],
  ['achievement', 'Achievement'],
  ['new_content', 'New content'],
  ['app_update', 'App update'],
  ['tip', 'Tip of the day'],
  ['special_offer', 'Special offer'],
];

function CategorySelect({ value, onChange }) {
  return (
    <select value={value} onChange={onChange} className={inputCls}>
      {CATEGORIES.map(([v, label]) => <option key={v} value={v}>{label}</option>)}
    </select>
  );
}

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

  const pushOn = learners.filter((u) => u.hasPushToken).length;

  return (
    <div className="space-y-6">
      <PageHeader
        eyebrow="Engagement"
        title="Notifications"
        subtitle="Compose one-off messages or scheduled delivery campaigns. Every message reaches the learner's in-app inbox; device notifications respect each learner's category preferences."
      />

      {/* Delivery metrics */}
      <div className="grid grid-cols-2 gap-3 lg:grid-cols-4">
        <Stat label="Messages sent" value={rows.length} hint="All-time broadcasts" />
        <Stat label="Active campaigns" value={campaigns.filter((c) => c.status === 'pending' || c.status === 'running').length} tone="amber" hint="Pending or running" />
        <Stat label="Registered devices" value={pushOn} tone="sky" hint={`of ${learners.length} learners`} />
        <Stat label="Push reach" value={`${learners.length ? Math.round((pushOn / Math.max(1, learners.length)) * 100) : 0}%`} tone="green" hint="Learners with a device token" />
      </div>

      {error && (
        <p className="rounded-lg border border-et-red/20 bg-et-red/5 px-4 py-2.5 text-sm font-medium text-et-red">{error}</p>
      )}
      {notice && (
        <p className="rounded-lg border border-et-green/20 bg-et-green-soft px-4 py-2.5 text-sm font-medium text-et-green-dark">{notice}</p>
      )}

      <div className="grid gap-5 xl:grid-cols-2">
        {/* Compose: instant message */}
        <Card
          title="Instant message"
          description="Delivered to in-app inboxes immediately, with a device notification where permitted."
        >
          <form onSubmit={sendInstant} className="grid gap-3.5">
            <Field label="Title">
              <input required maxLength={160} value={instant.title} onChange={(e) => setInstant({ ...instant, title: e.target.value })} className={inputCls} placeholder="e.g. New Afaan Oromo unit released" />
            </Field>
            <Field label="Category" hint="Learners who opted out of this category won't get a device push.">
              <CategorySelect value={instant.type} onChange={(e) => setInstant({ ...instant, type: e.target.value })} />
            </Field>
            <Field label="Message">
              <textarea rows={3} maxLength={500} value={instant.body} onChange={(e) => setInstant({ ...instant, body: e.target.value })} className={`${inputCls} resize-y`} placeholder="Keep it short and actionable." />
            </Field>

        {/* Audience: everyone or a selected subset */}
            <Field label="Audience">
              <div className="mt-1.5 inline-flex rounded-xl border border-line p-1">
                {[
                  ['everyone', 'All learners'],
                  ['some', 'Selected'],
                ].map(([val, label]) => (
                  <button
                    type="button"
                    key={val}
                    onClick={() => setTargetMode(val)}
                    className={`rounded-lg px-3 py-1.5 text-[12px] font-semibold transition ${
                      targetMode === val ? 'bg-et-green text-white' : 'text-muted hover:text-ink'
                    }`}
                  >
                    {label}
                    {val === 'some' && targetIds.length > 0 && (
                      <span className="ml-1.5 rounded bg-white/20 px-1 tabular-nums">{targetIds.length}</span>
                    )}
                  </button>
                ))}
              </div>
            </Field>

            {targetMode === 'some' && (
              <div>
                <input value={targetQ} onChange={(e) => setTargetQ(e.target.value)} placeholder="Filter by name or email…" className={inputCls} />
                {filteredLearners.length === 0 ? (
                  <p className="mt-2 text-xs text-muted">No learners match this filter.</p>
                ) : (
                  <div className="mt-2 max-h-52 divide-y divide-line-soft overflow-y-auto rounded-lg border border-line-soft">
                    {filteredLearners.map((u) => {
                      const sel = targetIds.includes(u.id);
                      return (
                        <label key={u.id} className={`flex cursor-pointer items-center gap-2.5 px-3 py-2 transition ${sel ? 'bg-canvas/70' : 'hover:bg-canvas/60'}`}>
                          <input type="checkbox" checked={sel} onChange={() => toggleTarget(u.id)} className="h-4 w-4 rounded accent-et-green" />
                          <span className="min-w-0 flex-1 truncate text-[13px] font-medium text-ink">
                            {u.displayName || 'Unnamed learner'}
                          </span>
                          <span className="hidden shrink-0 text-xs text-muted sm:block">{u.email}</span>
                          {u.hasPushToken
                            ? <Badge tone="info">Push on</Badge>
                            : <Badge>Inbox only</Badge>}
                        </label>
                      );
                    })}
                  </div>
                )}
              </div>
            )}

            <div className="flex justify-end pt-1">
              <Button variant="primary" type="submit" disabled={targetMode === 'some' && targetIds.length === 0}>
                {targetMode === 'some' ? `Send to ${targetIds.length} learner${targetIds.length === 1 ? '' : 's'}` : 'Send to all learners'}
              </Button>
            </div>
          </form>
        </Card>

        {/* Compose: scheduled campaign */}
        <Card
          title="Scheduled campaign"
          description="Delivered progressively in batches — recommended for large audiences."
        >
          <form onSubmit={createCampaign} className="grid gap-3.5">
            <Field label="Title">
              <input required maxLength={160} value={campaign.title} onChange={(e) => setCampaign({ ...campaign, title: e.target.value })} className={inputCls} placeholder="e.g. Weekly learning digest" />
            </Field>
            <Field label="Category">
              <CategorySelect value={campaign.type} onChange={(e) => setCampaign({ ...campaign, type: e.target.value })} />
            </Field>
            <Field label="Message">
              <textarea rows={3} maxLength={500} value={campaign.body} onChange={(e) => setCampaign({ ...campaign, body: e.target.value })} className={`${inputCls} resize-y`} />
            </Field>
            <div className="grid gap-3 sm:grid-cols-3">
              <Field label="Audience">
                <select value={campaign.audience} onChange={(e) => setCampaign({ ...campaign, audience: e.target.value })} className={inputCls}>
                  <option value="active">Active only</option>
                  <option value="all">All learners</option>
                </select>
              </Field>
              <Field label="Per batch">
                <input type="number" min={1} max={10000} value={campaign.batchSize} onChange={(e) => setCampaign({ ...campaign, batchSize: Number(e.target.value) })} className={inputCls} />
              </Field>
              <Field label="Every (min)">
                <input type="number" min={1} value={campaign.intervalMinutes} onChange={(e) => setCampaign({ ...campaign, intervalMinutes: Number(e.target.value) })} className={inputCls} />
              </Field>
            </div>
            <div className="flex justify-end pt-1">
              <Button variant="primary" type="submit">Schedule campaign</Button>
            </div>
          </form>
        </Card>
      </div>

      {/* Campaign queue */}
      <Card title="Campaign queue" description="Scheduled deliveries and their progress.">
        {campaigns.length === 0 ? (
          <EmptyState title="No campaigns scheduled" hint="Create one above to deliver a message progressively." />
        ) : (
          <div className="divide-y divide-line-soft">
            {campaigns.map((c) => {
              const active = c.status === 'pending' || c.status === 'running';
              const tone = c.status === 'completed' ? 'success'
                : c.status === 'cancelled' ? 'neutral'
                : 'warning';
              const pct = Math.min(100, (c.totalSent / Math.max(1, c.batchSize)) * 100);
              return (
                <div key={c.id} className="flex items-start justify-between gap-4 py-3.5 first:pt-0 last:pb-0">
                  <div className="min-w-0 flex-1">
                    <div className="flex flex-wrap items-center gap-2">
                      <Badge tone={tone} dot>{c.status}</Badge>
                      <p className="truncate text-[13px] font-medium text-et-green-dark">{c.title}</p>
                    </div>
                    <p className="mt-1 text-xs text-muted">
                      {c.totalSent} delivered · {c.batchSize} per batch · {Math.round(c.intervalSeconds / 60)} min interval · {c.audience === 'active' ? 'active learners' : 'all learners'}
                    </p>
                    {active && (
                      <div className="mt-2 h-1 w-full max-w-sm overflow-hidden rounded-full bg-slate-100">
                        <div className="h-full rounded-full bg-emerald-600 transition-all" style={{ width: `${pct}%` }} />
                      </div>
                    )}
                  </div>
                  <div className="flex shrink-0 items-center gap-2">
                    {active && <Button onClick={() => cancel(c.id)}>Cancel</Button>}
                    <Button variant="danger" onClick={() => removeCampaign(c.id)}>Delete</Button>
                  </div>
                </div>
              );
            })}
          </div>
        )}
      </Card>

      {/* Delivery log */}
      <Card title="Delivery log" description="Messages already dispatched to learners.">
        {rows.length === 0 ? (
          <EmptyState title="Nothing sent yet" hint="Your message history appears here after your first send." />
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-[13px]">
              <thead>
                <tr className="border-b border-line-soft text-[11px] uppercase tracking-wider text-muted">
                  <th className="py-2 pr-4 font-semibold">Status</th>
                  <th className="py-2 pr-4 font-semibold">Title</th>
                  <th className="py-2 pr-4 font-semibold">Message</th>
                  <th className="py-2 text-right font-semibold">Actions</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-line-soft">
                {rows.map((n) => (
                  <tr key={n.id} className="align-top">
                    <td className="py-2.5 pr-4">
                      {n.read ? <Badge>Read</Badge> : <Badge tone="info" dot>New</Badge>}
                    </td>
                    <td className="py-2.5 pr-4 font-medium text-et-green-dark">{n.title}</td>
                    <td className="max-w-sm py-2.5 pr-4 text-muted">{n.body || '—'}</td>
                    <td className="py-2.5 text-right">
                      <Button variant="danger" onClick={() => removeNotif(n.id)}>Delete</Button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>
    </div>
  );
}