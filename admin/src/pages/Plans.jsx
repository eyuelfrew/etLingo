import { useCallback, useEffect, useState } from 'react';
import client, { apiError } from '../api/client';
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

const empty = {
  sku: '',
  title: '',
  subtitle: '',
  period: 'month',
  price_cents: 0,
  currency: 'ETB',
  features: '',
  badge: '',
  is_active: 1,
  is_highlighted: 0,
  sort_order: 0,
};

const PERIODS = [
  ['month', 'Monthly'],
  ['year', 'Yearly'],
  ['trial', 'Trial / free'],
];

export default function Plans() {
  const [rows, setRows] = useState([]);
  const [error, setError] = useState('');
  const [open, setOpen] = useState(false);
  const [editingId, setEditingId] = useState(null);
  const [form, setForm] = useState(empty);

  const load = useCallback(async () => {
    try {
      setRows((await client.get('/admin/plans')).data || []);
      setError('');
    } catch (e) {
      setError(apiError(e, 'Failed to load plans'));
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
        sku: String(form.sku || '').trim().toLowerCase(),
        title: String(form.title || '').trim(),
        price_cents: Number(form.price_cents) || 0,
        sort_order: Number(form.sort_order) || 0,
        is_active: form.is_active ? 1 : 0,
        is_highlighted: form.is_highlighted ? 1 : 0,
        features: String(form.features || '')
          .split('\n')
          .map((s) => s.trim())
          .filter(Boolean),
      };
      if (!body.sku || !body.title) {
        setError('SKU and title are required.');
        return;
      }
      if (editingId) await client.put(`/admin/plans/${editingId}`, body);
      else await client.post('/admin/plans', body);
      setOpen(false);
      setEditingId(null);
      setForm(empty);
      await load();
    } catch (err) {
      setError(apiError(err, 'Could not save plan'));
    }
  }

  async function remove(row) {
    if (!confirm(`Delete plan "${row.title}"?`)) return;
    try {
      await client.delete(`/admin/plans/${row.id}`);
      await load();
    } catch (err) {
      setError(apiError(err, 'Could not delete plan'));
    }
  }

  return (
    <div>
      <PageHeader
        eyebrow="Billing"
        title="Subscription packages"
        subtitle="Manage monthly / yearly plans shown in the app. Payment gateway can be plugged in later."
        actions={
          <Button
            variant="primary"
            onClick={() => {
              setEditingId(null);
              setForm({ ...empty, sort_order: rows.length });
              setOpen(true);
            }}
          >
            New package
          </Button>
        }
      />
      {error && <Banner tone="danger">{error}</Banner>}

      <Card className="mt-5" title="Plans">
        {rows.length === 0 ? (
          <EmptyState title="No packages" hint="Create Monthly / Yearly / Trial." />
        ) : (
          <div className={tableShellCls}>
            <table className="w-full text-sm">
              <thead>
                <tr>
                  <th className={thCls}>Plan</th>
                  <th className={thCls}>Period</th>
                  <th className={thCls}>Price</th>
                  <th className={thCls}>Features</th>
                  <th className={thCls}>Status</th>
                  <th className={thCls}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {rows.map((r) => (
                  <tr key={r.id}>
                    <td className={tdCls}>
                      <div className="flex items-center gap-2">
                        <div>
                          <div className="font-bold">
                            {r.title}{' '}
                            {r.badge && <Badge tone="info">{r.badge}</Badge>}
                          </div>
                          <div className="text-[11px] text-muted">{r.sku}</div>
                        </div>
                      </div>
                    </td>
                    <td className={tdCls}>{PERIODS.find((p) => p[0] === r.period)?.[1] || r.period}</td>
                    <td className={tdCls}>
                      <span className="font-bold">{r.priceLabel}</span>
                      <span className="text-muted"> {r.periodLabel}</span>
                    </td>
                    <td className={`${tdCls} max-w-xs`}>
                      {(r.features || []).slice(0, 3).join(' · ') || '—'}
                    </td>
                    <td className={tdCls}>
                      {r.isActive ? (
                        <Badge tone="success" dot>
                          Live
                        </Badge>
                      ) : (
                        <Badge tone="neutral">Off</Badge>
                      )}
                    </td>
                    <td className={tdCls}>
                      <button
                        type="button"
                        className="mr-2 text-[12px] font-semibold text-et-blue hover:underline"
                        onClick={() => {
                          setEditingId(r.id);
                          setForm({
                            sku: r.sku,
                            title: r.title,
                            subtitle: r.subtitle,
                            period: r.period,
                            price_cents: r.priceCents,
                            currency: r.currency,
                            features: (r.features || []).join('\n'),
                            badge: r.badge,
                            is_active: r.isActive ? 1 : 0,
                            is_highlighted: r.isHighlighted ? 1 : 0,
                            sort_order: r.sortOrder,
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
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>

      {open && (
        <Modal
          wide
          onClose={() => setOpen(false)}
          title={editingId ? 'Edit package' : 'New package'}
        >
          <form onSubmit={save} className="grid gap-3 sm:grid-cols-2">
            <Field label="SKU" hint="e.g. sub_monthly">
              <input
                className={inputCls}
                value={form.sku}
                onChange={(e) => setForm({ ...form, sku: e.target.value })}
                required
              />
            </Field>
            <Field label="Title">
              <input
                className={inputCls}
                value={form.title}
                onChange={(e) => setForm({ ...form, title: e.target.value })}
                required
              />
            </Field>
            <div className="sm:col-span-2">
              <Field label="Subtitle">
                <input
                  className={inputCls}
                  value={form.subtitle}
                  onChange={(e) => setForm({ ...form, subtitle: e.target.value })}
                />
              </Field>
            </div>
            <Field label="Period">
              <select
                className={inputCls}
                value={form.period}
                onChange={(e) => setForm({ ...form, period: e.target.value })}
              >
                {PERIODS.map(([k, l]) => (
                  <option key={k} value={k}>
                    {l}
                  </option>
                ))}
              </select>
            </Field>
            <Field label="Price (cents)" hint="0 = free until gateway is live">
              <input
                type="number"
                className={inputCls}
                value={form.price_cents}
                onChange={(e) => setForm({ ...form, price_cents: e.target.value })}
              />
            </Field>
            <Field label="Currency">
              <input
                className={inputCls}
                value={form.currency}
                onChange={(e) => setForm({ ...form, currency: e.target.value })}
              />
            </Field>
            <Field label="Badge" hint="e.g. Popular · Best value">
              <input
                className={inputCls}
                value={form.badge}
                onChange={(e) => setForm({ ...form, badge: e.target.value })}
              />
            </Field>
            <div className="sm:col-span-2">
              <Field label="Features (one per line)">
                <textarea
                  className={inputCls}
                  rows={4}
                  value={form.features}
                  onChange={(e) => setForm({ ...form, features: e.target.value })}
                />
              </Field>
            </div>
            <label className="flex items-center gap-2 text-sm font-semibold">
              <input
                type="checkbox"
                checked={!!form.is_active}
                onChange={(e) =>
                  setForm({ ...form, is_active: e.target.checked ? 1 : 0 })
                }
              />
              Active (show in app)
            </label>
            <label className="flex items-center gap-2 text-sm font-semibold">
              <input
                type="checkbox"
                checked={!!form.is_highlighted}
                onChange={(e) =>
                  setForm({ ...form, is_highlighted: e.target.checked ? 1 : 0 })
                }
              />
              Highlight
            </label>
            <div className="flex justify-end gap-2 pt-2 sm:col-span-2">
              <Button type="button" variant="ghost" onClick={() => setOpen(false)}>
                Cancel
              </Button>
              <Button type="submit" variant="primary">
                Save package
              </Button>
            </div>
          </form>
        </Modal>
      )}
    </div>
  );
}
