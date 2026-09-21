import { useCallback, useEffect, useState } from 'react';
import client, { apiError } from '../api/client';
import {
  PageHeader,
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
  code: '',
  name: '',
  native_name: '',
  is_active: 1,
  sort_order: 0,
};

export default function BaseLanguages() {
  const [rows, setRows] = useState([]);
  const [form, setForm] = useState(empty);
  const [editingId, setEditingId] = useState(null);
  const [open, setOpen] = useState(false);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    try {
      setRows((await client.get('/admin/base-languages')).data);
      setError('');
    } catch (e) {
      setError(apiError(e, 'Failed to load base languages'));
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const save = async (e) => {
    e.preventDefault();
    try {
      const body = {
        ...form,
        code: String(form.code || '').trim().toLowerCase(),
        name: String(form.name || '').trim(),
        native_name: String(form.native_name || '').trim(),
        sort_order: Number(form.sort_order) || 0,
        is_active: form.is_active ? 1 : 0,
      };
      if (!body.code || !body.name || !body.native_name) {
        setError('Code, name, and native name are all required.');
        return;
      }
      if (editingId) await client.put(`/admin/base-languages/${editingId}`, body);
      else await client.post('/admin/base-languages', body);
      setOpen(false);
      setEditingId(null);
      setForm(empty);
      setError('');
      await load();
    } catch (err) {
      setError(apiError(err, 'Could not save base language'));
    }
  };

  const remove = async (row) => {
    if (!confirm(`Remove base language "${row.name}"? Lessons keep old translations; learners just won't see this option.`)) {
      return;
    }
    try {
      await client.delete(`/admin/base-languages/${row.id}`);
      await load();
    } catch (err) {
      setError(apiError(err, 'Could not delete base language'));
    }
  };

  return (
    <div>
      <PageHeader
        eyebrow="Curriculum"
        title="Base languages"
        subtitle="Languages learners already know. Used for prompts, hints, and meanings — e.g. a Somali speaker learning Amharic uses Somali here."
        actions={
          <Button
            variant="primary"
            onClick={() => {
              setEditingId(null);
              setForm(empty);
              setOpen(true);
            }}
          >
            Add base language
          </Button>
        }
      />

      {error && (
        <div className="mt-5">
          <Banner tone="warning">{error}</Banner>
        </div>
      )}

      <div className="mt-5 rounded-2xl border border-et-green/20 bg-et-green-soft px-5 py-4 text-[13px] leading-relaxed text-et-green-dark">
        <strong className="font-semibold">How this works.</strong> Course content (what you learn) is under{' '}
        <em>Languages</em>. Base languages are the <em>instruction</em> side. When you edit a question, each
        active base language gets its own tab for prompt / hint / meaning. The mobile app lists these options
        when a learner picks “the language I already speak.”
      </div>

      <div className="mt-6">
        {loading ? (
          <div className={`${tableShellCls} px-5 py-12 text-center text-sm text-muted`}>Loading…</div>
        ) : rows.length === 0 ? (
          <EmptyState
            icon="🗣"
            title="No base languages yet"
            hint="Add at least English and the languages your learners speak at home."
            action={
              <Button
                variant="primary"
                onClick={() => {
                  setEditingId(null);
                  setForm(empty);
                  setOpen(true);
                }}
              >
                Add first base language
              </Button>
            }
          />
        ) : (
          <div className={tableShellCls}>
            <table className="w-full">
              <thead>
                <tr className="border-b border-line-soft">
                  <th className={thCls}>Language</th>
                  <th className={thCls}>Code</th>
                  <th className={thCls}>Order</th>
                  <th className={thCls}>Status</th>
                  <th className={`${thCls} text-right`}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {rows.map((r) => (
                  <tr key={r.id} className="border-t border-line-soft hover:bg-canvas/60">
                    <td className={tdCls}>
                      <div className="font-ethiopic font-semibold text-ink">{r.native_name}</div>
                      <div className="text-[12px] text-muted">{r.name}</div>
                    </td>
                    <td className={tdCls}>
                      <code className="rounded-lg bg-canvas px-2 py-1 text-[12px] font-semibold text-muted">
                        {r.code}
                      </code>
                    </td>
                    <td className={`${tdCls} tabular-nums`}>{r.sort_order}</td>
                    <td className={tdCls}>
                      {r.is_active ? (
                        <Badge tone="success" dot>Active</Badge>
                      ) : (
                        <Badge tone="neutral">Hidden</Badge>
                      )}
                    </td>
                    <td className={`${tdCls} text-right whitespace-nowrap`}>
                      <button
                        onClick={() => {
                          setEditingId(r.id);
                          setForm({ ...empty, ...r });
                          setOpen(true);
                        }}
                        className="mr-3 text-[13px] font-semibold text-et-blue hover:underline"
                      >
                        Edit
                      </button>
                      <button
                        onClick={() => remove(r)}
                        className="text-[13px] font-semibold text-et-red hover:underline"
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
      </div>

      {open && (
        <Modal
          title={editingId ? 'Edit base language' : 'New base language'}
          description="Shown to learners as “I already speak…” and used for question/teach translations."
          onClose={() => setOpen(false)}
          footer={
            <>
              <Button type="button" variant="secondary" onClick={() => setOpen(false)}>
                Cancel
              </Button>
              <Button type="submit" form="base-lang-form" variant="primary">
                Save language
              </Button>
            </>
          }
        >
          <form id="base-lang-form" onSubmit={save} className="grid gap-4">
            <div className="grid grid-cols-2 gap-4">
              <Field label="Code *">
                <input
                  className={inputCls}
                  value={form.code}
                  required
                  placeholder="so"
                  maxLength={8}
                  onChange={(e) => setForm({ ...form, code: e.target.value })}
                />
              </Field>
              <Field label="Name *">
                <input
                  className={inputCls}
                  value={form.name}
                  required
                  placeholder="Somali"
                  onChange={(e) => setForm({ ...form, name: e.target.value })}
                />
              </Field>
            </div>
            <Field label="Native name *" hint="How speakers write the language name">
              <input
                className={`${inputCls} font-ethiopic`}
                value={form.native_name}
                required
                placeholder="Soomaali"
                onChange={(e) => setForm({ ...form, native_name: e.target.value })}
              />
            </Field>
            <div className="grid grid-cols-2 gap-4">
              <Field label="Sort order">
                <input
                  type="number"
                  className={inputCls}
                  value={form.sort_order}
                  onChange={(e) => setForm({ ...form, sort_order: Number(e.target.value) })}
                />
              </Field>
              <div className="flex items-end pb-2">
                <label className="flex cursor-pointer items-center gap-2.5 text-[14px] font-medium text-ink">
                  <input
                    type="checkbox"
                    checked={!!form.is_active}
                    onChange={(e) => setForm({ ...form, is_active: e.target.checked ? 1 : 0 })}
                    className="h-4 w-4 rounded border-line accent-et-green"
                  />
                  Available to learners
                </label>
              </div>
            </div>
          </form>
        </Modal>
      )}
    </div>
  );
}
