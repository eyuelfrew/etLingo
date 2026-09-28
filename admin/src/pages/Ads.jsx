import { useCallback, useEffect, useState } from 'react';
import client, { apiError } from '../api/client';
import MediaField from '../components/MediaField';
import {
  PageHeader,
  Card,
  Button,
  Banner,
  Badge,
  Field,
  inputCls,
  tableShellCls,
  thCls,
  tdCls,
  Modal,
  EmptyState,
} from '../components/ui';

const POSITIONS = [
  ['home_top', 'Learn home · top'],
  ['home_mid', 'Learn home · between units'],
  ['culture_top', 'Culture · top'],
  ['after_topics', 'After topic packs'],
  ['profile', 'You / Profile'],
];

const ACTIONS = [
  ['url', 'Open URL'],
  ['screen', 'Open app screen'],
  ['topic', 'Open topic pack'],
  ['culture', 'Open culture unit'],
  ['none', 'No action (info only)'],
];

const SCREENS = [
  ['/topics', 'Topic packs'],
  ['/calendar', 'Ethiopian calendar'],
  ['culture', 'Culture path'],
  ['fidel', 'Fidel trainer'],
];

const empty = {
  title: '',
  body: '',
  image_url: '',
  cta_label: 'Learn more',
  position: 'home_top',
  action_type: 'url',
  action_value: '',
  language_code: '',
  priority: 0,
  is_active: 1,
  starts_at: '',
  ends_at: '',
};

export default function Ads() {
  const [rows, setRows] = useState([]);
  const [error, setError] = useState('');
  const [open, setOpen] = useState(false);
  const [editingId, setEditingId] = useState(null);
  const [form, setForm] = useState(empty);

  const load = useCallback(async () => {
    try {
      setRows((await client.get('/admin/ads')).data || []);
      setError('');
    } catch (e) {
      setError(apiError(e, 'Failed to load ads'));
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  async function save(e) {
    e.preventDefault();
    try {
      const body = {
        ...form,
        priority: Number(form.priority) || 0,
        is_active: form.is_active ? 1 : 0,
        starts_at: form.starts_at || null,
        ends_at: form.ends_at || null,
      };
      if (!body.title || !body.position) {
        setError('Title and position are required.');
        return;
      }
      if (editingId) await client.put(`/admin/ads/${editingId}`, body);
      else await client.post('/admin/ads', body);
      setOpen(false);
      setEditingId(null);
      setForm(empty);
      await load();
    } catch (err) {
      setError(apiError(err, 'Could not save ad'));
    }
  }

  async function remove(row) {
    if (!confirm(`Delete ad "${row.title}"?`)) return;
    try {
      await client.delete(`/admin/ads/${row.id}`);
      await load();
    } catch (err) {
      setError(apiError(err, 'Could not delete ad'));
    }
  }

  async function toggle(row) {
    try {
      await client.put(`/admin/ads/${row.id}`, {
        ...row,
        is_active: row.isActive ? 0 : 1,
        image_url: row.imageUrl,
        cta_label: row.ctaLabel,
        action_type: row.actionType,
        action_value: row.actionValue,
        language_code: row.languageCode,
        starts_at: row.startsAt,
        ends_at: row.endsAt,
      });
      await load();
    } catch (err) {
      setError(apiError(err, 'Could not update ad'));
    }
  }

  return (
    <div>
      <PageHeader
        eyebrow="Promotions"
        title="In-app ads"
        subtitle="Admin-managed promos (not Google Ad). Place them in the app, choose what a tap does, and track clicks."
        actions={
          <Button
            variant="primary"
            onClick={() => {
              setEditingId(null);
              setForm(empty);
              setOpen(true);
            }}
          >
            New ad
          </Button>
        }
      />
      {error && <Banner tone="danger">{error}</Banner>}

      <div className="mt-5 grid gap-3 sm:grid-cols-2 lg:grid-cols-3">
        {POSITIONS.map(([key, label]) => {
          const n = rows.filter((r) => r.position === key).length;
          return (
            <div
              key={key}
              className="rounded-2xl border border-line-soft bg-panel px-4 py-3"
            >
              <p className="text-[13px] font-bold text-ink">{label}</p>
              <p className="mt-1 text-[12px] text-muted">
                {key} · {n} ad{n === 1 ? '' : 's'}
              </p>
            </div>
          );
        })}
      </div>

      <Card className="mt-5" title="All ads">
        {rows.length === 0 ? (
          <EmptyState
            title="No ads yet"
            hint="Create a promo and pick where it shows in the app."
          />
        ) : (
          <div className={tableShellCls}>
            <table className="w-full text-sm">
              <thead>
                <tr>
                  <th className={thCls}>Ad</th>
                  <th className={thCls}>Position</th>
                  <th className={thCls}>Tap action</th>
                  <th className={thCls}>Views</th>
                  <th className={thCls}>Clicks</th>
                  <th className={thCls}>CTR</th>
                  <th className={thCls}>Status</th>
                  <th className={thCls}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {rows.map((r) => {
                  const ctr =
                    r.impressions > 0
                      ? ((r.clicks / r.impressions) * 100).toFixed(1)
                      : '0.0';
                  return (
                    <tr key={r.id}>
                      <td className={tdCls}>
                        <div className="flex items-center gap-2">
                          {r.imageUrl ? (
                            <img
                              src={r.imageUrl}
                              alt=""
                              className="h-10 w-14 rounded-lg object-cover"
                            />
                          ) : (
                            <div className="flex h-10 w-14 items-center justify-center rounded-lg bg-canvas text-[10px] text-muted">
                              ad
                            </div>
                          )}
                          <div>
                            <div className="font-bold">{r.title}</div>
                            <div className="text-[11px] text-muted">
                              {r.body || r.ctaLabel}
                            </div>
                          </div>
                        </div>
                      </td>
                      <td className={tdCls}>
                        <Badge tone="info">
                          {POSITIONS.find((p) => p[0] === r.position)?.[1] ||
                            r.position}
                        </Badge>
                      </td>
                      <td className={tdCls}>
                        <div className="text-[12px] font-semibold">
                          {r.actionType}
                        </div>
                        <div className="max-w-[140px] truncate text-[11px] text-muted">
                          {r.actionValue || '—'}
                        </div>
                      </td>
                      <td className={tdCls}>{r.impressions}</td>
                      <td className={tdCls}>{r.clicks}</td>
                      <td className={tdCls}>{ctr}%</td>
                      <td className={tdCls}>
                        <button type="button" onClick={() => toggle(r)}>
                          {r.isActive ? (
                            <Badge tone="success" dot>
                              Live
                            </Badge>
                          ) : (
                            <Badge tone="neutral">Off</Badge>
                          )}
                        </button>
                      </td>
                      <td className={tdCls}>
                        <button
                          type="button"
                          className="mr-2 text-[12px] font-semibold text-et-blue hover:underline"
                          onClick={() => {
                            setEditingId(r.id);
                            setForm({
                              title: r.title,
                              body: r.body,
                              image_url: r.imageUrl || '',
                              cta_label: r.ctaLabel,
                              position: r.position,
                              action_type: r.actionType,
                              action_value: r.actionValue,
                              language_code: r.languageCode || '',
                              priority: r.priority ?? 0,
                              is_active: r.isActive ? 1 : 0,
                              starts_at: (r.startsAt || '').toString().slice(0, 10),
                              ends_at: (r.endsAt || '').toString().slice(0, 10),
                            });
                            setOpen(true);
                          }}
                        >
                          Edit
                        </button>
                        <button
                          type="button"
                          className="text-[12px] font-semibold text-et-red hover:underline"
                          onClick={() => remove(r)}
                        >
                          Delete
                        </button>
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </Card>

      {open && (
        <Modal
          wide
          onClose={() => setOpen(false)}
          title={editingId ? 'Edit ad' : 'New ad'}
          description="Choose where it appears and what happens on tap."
        >
          <form onSubmit={save} className="grid gap-3 sm:grid-cols-2">
            <Field label="Title">
              <input
                className={inputCls}
                value={form.title}
                onChange={(e) => setForm({ ...form, title: e.target.value })}
                required
              />
            </Field>
            <Field label="CTA label">
              <input
                className={inputCls}
                value={form.cta_label}
                onChange={(e) => setForm({ ...form, cta_label: e.target.value })}
              />
            </Field>
            <div className="sm:col-span-2">
              <Field label="Body">
                <textarea
                  className={inputCls}
                  rows={2}
                  value={form.body}
                  onChange={(e) => setForm({ ...form, body: e.target.value })}
                />
              </Field>
            </div>
            <div className="sm:col-span-2">
              <MediaField
                label="Image (optional)"
                value={form.image_url}
                onChange={(v) => setForm({ ...form, image_url: v })}
              />
            </div>
            <Field label="Position in app">
              <select
                className={inputCls}
                value={form.position}
                onChange={(e) => setForm({ ...form, position: e.target.value })}
              >
                {POSITIONS.map(([k, l]) => (
                  <option key={k} value={k}>
                    {l}
                  </option>
                ))}
              </select>
            </Field>
            <Field label="Language filter" hint="Empty = all courses">
              <input
                className={inputCls}
                placeholder="am / om / ti / so"
                value={form.language_code}
                onChange={(e) =>
                  setForm({ ...form, language_code: e.target.value })
                }
              />
            </Field>
            <Field label="On tap">
              <select
                className={inputCls}
                value={form.action_type}
                onChange={(e) =>
                  setForm({ ...form, action_type: e.target.value })
                }
              >
                {ACTIONS.map(([k, l]) => (
                  <option key={k} value={k}>
                    {l}
                  </option>
                ))}
              </select>
            </Field>
            <Field
              label="Action target"
              hint={
                form.action_type === 'url'
                  ? 'https://…'
                  : form.action_type === 'screen'
                    ? 'route: /topics · /calendar · culture · fidel'
                    : form.action_type === 'topic'
                      ? 'topic slug: animals · food · colors'
                      : form.action_type === 'culture'
                        ? 'culture unit id'
                        : '—'
              }
            >
              <input
                className={inputCls}
                value={form.action_value}
                onChange={(e) =>
                  setForm({ ...form, action_value: e.target.value })
                }
              />
            </Field>
            <Field label="Priority" hint="Higher wins in the same slot">
              <input
                type="number"
                className={inputCls}
                value={form.priority}
                onChange={(e) =>
                  setForm({ ...form, priority: e.target.value })
                }
              />
            </Field>
            <Field label="Start date">
              <input
                type="date"
                className={inputCls}
                value={form.starts_at}
                onChange={(e) =>
                  setForm({ ...form, starts_at: e.target.value })
                }
              />
            </Field>
            <Field label="End date">
              <input
                type="date"
                className={inputCls}
                value={form.ends_at}
                onChange={(e) =>
                  setForm({ ...form, ends_at: e.target.value })
                }
              />
            </Field>
            <label className="flex items-center gap-2 text-sm font-semibold">
              <input
                type="checkbox"
                checked={!!form.is_active}
                onChange={(e) =>
                  setForm({ ...form, is_active: e.target.checked ? 1 : 0 })
                }
              />
              Live
            </label>
            <div className="flex justify-end gap-2 pt-2 sm:col-span-2">
              <Button type="button" variant="ghost" onClick={() => setOpen(false)}>
                Cancel
              </Button>
              <Button type="submit" variant="primary">
                Save ad
              </Button>
            </div>
          </form>
        </Modal>
      )}
    </div>
  );
}
