import { useCallback, useEffect, useState } from 'react';
import client from '../api/client';
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
  script_preview: '',
  speakers: '',
  region: '',
  color_hex: '#078930',
  dark_hex: '#056B24',
  hello_target: '',
  hello_meaning: '',
  sort_order: 0,
  is_active: 1,
};

export default function Languages() {
  const [rows, setRows] = useState([]);
  const [form, setForm] = useState(empty);
  const [editingId, setEditingId] = useState(null);
  const [open, setOpen] = useState(false);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    try {
      setRows((await client.get('/admin/languages')).data);
      setError('');
    } catch (e) {
      setError(e.response?.data?.error || 'Failed to load. Is MySQL initialized?');
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
      if (editingId) await client.put(`/admin/languages/${editingId}`, form);
      else await client.post('/admin/languages', form);
      setOpen(false);
      setEditingId(null);
      setForm(empty);
      load();
    } catch (err) {
      setError(err.response?.data?.error || 'Save failed');
    }
  };

  const remove = async (id) => {
    if (!confirm('Delete this language and ALL of its units, lessons, questions and phrases?')) return;
    await client.delete(`/admin/languages/${id}`);
    load();
  };

  const edit = (row) => {
    setEditingId(row.id);
    setForm({ ...empty, ...row });
    setOpen(true);
  };

  return (
    <div>
      <PageHeader
        eyebrow="Curriculum"
        title="Languages"
        subtitle="Courses offered in the mobile app. Each language has its own units, lessons, and phrasebook."
        actions={
          <Button
            variant="primary"
            onClick={() => {
              setEditingId(null);
              setForm(empty);
              setOpen(true);
            }}
          >
            Add language
          </Button>
        }
      />

      {error && (
        <div className="mt-5">
          <Banner tone="warning">{error}</Banner>
        </div>
      )}

      <div className="mt-6">
        {loading ? (
          <div className={`${tableShellCls} px-5 py-12 text-center text-sm text-muted`}>Loading…</div>
        ) : rows.length === 0 ? (
          <EmptyState
            icon="🗣"
            title="No languages yet"
            hint="Add Amharic, Afaan Oromo, Tigrinya, or any course you want learners to see."
            action={
              <Button
                variant="primary"
                onClick={() => {
                  setEditingId(null);
                  setForm(empty);
                  setOpen(true);
                }}
              >
                Add first language
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
                  <th className={thCls}>Speakers</th>
                  <th className={thCls}>Greeting</th>
                  <th className={thCls}>Status</th>
                  <th className={`${thCls} text-right`}>Actions</th>
                </tr>
              </thead>
              <tbody>
                {rows.map((r) => (
                  <tr key={r.id} className="border-t border-line-soft transition hover:bg-canvas/60">
                    <td className={tdCls}>
                      <div className="flex items-center gap-3">
                        <span
                          className="h-9 w-9 shrink-0 rounded-xl"
                          style={{ background: `linear-gradient(135deg, ${r.color_hex}, ${r.dark_hex})` }}
                        />
                        <div>
                          <div className="font-ethiopic font-semibold text-ink">{r.native_name || r.name}</div>
                          <div className="text-[12px] text-muted">{r.name}</div>
                        </div>
                      </div>
                    </td>
                    <td className={tdCls}>
                      <code className="rounded-lg bg-canvas px-2 py-1 text-[12px] font-semibold text-muted">
                        {r.code}
                      </code>
                    </td>
                    <td className={`${tdCls} font-medium`}>{r.speakers || '—'}</td>
                    <td className={`${tdCls} font-ethiopic`}>{r.hello_target || '—'}</td>
                    <td className={tdCls}>
                      {r.is_active ? (
                        <Badge tone="success" dot>Live</Badge>
                      ) : (
                        <Badge tone="neutral">Hidden</Badge>
                      )}
                    </td>
                    <td className={`${tdCls} text-right whitespace-nowrap`}>
                      <button
                        onClick={() => edit(r)}
                        className="mr-3 text-[13px] font-semibold text-et-blue hover:underline"
                      >
                        Edit
                      </button>
                      <button
                        onClick={() => remove(r.id)}
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
          title={editingId ? 'Edit language' : 'New language'}
          description="Branding and metadata shown in the learner app language picker."
          onClose={() => setOpen(false)}
          wide
          footer={
            <>
              <Button type="button" variant="secondary" onClick={() => setOpen(false)}>
                Cancel
              </Button>
              <Button type="submit" form="lang-form" variant="primary">
                Save language
              </Button>
            </>
          }
        >
          <form id="lang-form" onSubmit={save} className="grid grid-cols-2 gap-4">
            <Field label="Code *">
              <input
                className={inputCls}
                value={form.code}
                required
                placeholder="am"
                onChange={(e) => setForm({ ...form, code: e.target.value })}
              />
            </Field>
            <Field label="Name *">
              <input
                className={inputCls}
                value={form.name}
                required
                placeholder="Amharic"
                onChange={(e) => setForm({ ...form, name: e.target.value })}
              />
            </Field>
            <Field label="Native name">
              <input
                className={`${inputCls} font-ethiopic`}
                value={form.native_name}
                placeholder="አማርኛ"
                onChange={(e) => setForm({ ...form, native_name: e.target.value })}
              />
            </Field>
            <Field label="Speakers">
              <input
                className={inputCls}
                value={form.speakers}
                placeholder="~32M"
                onChange={(e) => setForm({ ...form, speakers: e.target.value })}
              />
            </Field>
            <Field label="Script preview">
              <input
                className={`${inputCls} font-ethiopic`}
                value={form.script_preview}
                placeholder="ሰላም እንዴት ነህ?"
                onChange={(e) => setForm({ ...form, script_preview: e.target.value })}
              />
            </Field>
            <Field label="Region">
              <input
                className={inputCls}
                value={form.region}
                placeholder="Ethiopia"
                onChange={(e) => setForm({ ...form, region: e.target.value })}
              />
            </Field>
            <Field label="Hello word">
              <input
                className={`${inputCls} font-ethiopic`}
                value={form.hello_target}
                placeholder="ሰላም"
                onChange={(e) => setForm({ ...form, hello_target: e.target.value })}
              />
            </Field>
            <Field label="Hello meaning">
              <input
                className={inputCls}
                value={form.hello_meaning}
                placeholder="Hello / Peace"
                onChange={(e) => setForm({ ...form, hello_meaning: e.target.value })}
              />
            </Field>
            <ColorField
              label="Primary color"
              value={form.color_hex}
              onChange={(v) => setForm({ ...form, color_hex: v })}
            />
            <ColorField
              label="Dark color"
              value={form.dark_hex}
              onChange={(v) => setForm({ ...form, dark_hex: v })}
            />
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
                Visible in the app
              </label>
            </div>
          </form>
        </Modal>
      )}
    </div>
  );
}

function ColorField({ label, value, onChange }) {
  return (
    <div>
      <span className="block text-[13px] font-semibold text-ink">{label}</span>
      <div className="mt-1.5 flex items-center gap-2 rounded-xl border border-line bg-panel px-2 py-1.5">
        <input
          type="color"
          value={value}
          onChange={(e) => onChange(e.target.value)}
          className="h-8 w-10 cursor-pointer rounded-lg border-0 bg-transparent"
        />
        <code className="text-[12px] font-semibold text-muted">{value}</code>
      </div>
    </div>
  );
}
