import { useCallback, useEffect, useState } from 'react';
import client from '../api/client';

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
    if (!confirm('Delete this language and ALL its content?')) return;
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
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-black">Languages</h1>
          <p className="mt-1 text-sm font-medium text-stone-500">
            Courses offered in the mobile app
          </p>
        </div>
        <button
          onClick={() => {
            setEditingId(null);
            setForm(empty);
            setOpen(true);
          }}
          className="rounded-xl bg-green-700 px-5 py-2.5 text-sm font-black uppercase tracking-wide text-white shadow hover:bg-green-600"
        >
          + Add language
        </button>
      </div>

      {error && (
        <p className="mt-4 rounded-xl border border-amber-300 bg-amber-50 px-4 py-3 text-sm font-semibold text-amber-800">
          ⚠ {error}
        </p>
      )}

      <div className="mt-6 overflow-hidden rounded-2xl border border-stone-200 bg-white shadow-sm">
        <table className="w-full text-sm">
          <thead className="bg-stone-50 text-left text-xs font-black uppercase tracking-wider text-stone-400">
            <tr>
              <th className="px-5 py-3">Language</th>
              <th className="px-4 py-3">Code</th>
              <th className="px-4 py-3">Speakers</th>
              <th className="px-4 py-3">Greeting</th>
              <th className="px-4 py-3">Active</th>
              <th className="px-4 py-3" />
            </tr>
          </thead>
          <tbody>
            {loading && (
              <tr><td colSpan={6} className="px-5 py-10 text-center text-stone-400">Loading…</td></tr>
            )}
            {!loading && rows.length === 0 && (
              <tr><td colSpan={6} className="px-5 py-10 text-center text-stone-400">No languages yet — add your first one.</td></tr>
            )}
            {rows.map((r) => (
              <tr key={r.id} className="border-t border-stone-100 hover:bg-stone-50/60">
                <td className="px-5 py-3">
                  <div className="flex items-center gap-3">
                    <span
                      className="h-8 w-8 shrink-0 rounded-lg"
                      style={{ background: `linear-gradient(135deg, ${r.color_hex}, ${r.dark_hex})` }}
                    />
                    <div>
                      <div className="font-bold">{r.native_name}</div>
                      <div className="text-xs text-stone-400">{r.name}</div>
                    </div>
                  </div>
                </td>
                <td className="px-4 py-3"><code className="rounded bg-stone-100 px-2 py-0.5">{r.code}</code></td>
                <td className="px-4 py-3 font-semibold">{r.speakers}</td>
                <td className="px-4 py-3">{r.hello_target}</td>
                <td className="px-4 py-3">
                  {r.is_active ? (
                    <span className="rounded-full bg-green-100 px-2.5 py-1 text-xs font-bold text-green-700">Live</span>
                  ) : (
                    <span className="rounded-full bg-stone-200 px-2.5 py-1 text-xs font-bold text-stone-500">Hidden</span>
                  )}
                </td>
                <td className="px-4 py-3 text-right whitespace-nowrap">
                  <button onClick={() => edit(r)} className="mr-2 font-bold text-blue-700 hover:underline">Edit</button>
                  <button onClick={() => remove(r.id)} className="font-bold text-red-600 hover:underline">Delete</button>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {open && (
        <div className="fixed inset-0 z-40 flex items-center justify-center bg-black/40 p-4">
          <form onSubmit={save} className="max-h-[85vh] w-full max-w-lg overflow-y-auto rounded-3xl bg-white p-7 shadow-2xl">
            <h2 className="text-xl font-black">{editingId ? 'Edit language' : 'New language'}</h2>
            <div className="mt-5 grid grid-cols-2 gap-4">
              <Field label="Code *" value={form.code} onChange={(v) => setForm({ ...form, code: v })} placeholder="am" required />
              <Field label="Name *" value={form.name} onChange={(v) => setForm({ ...form, name: v })} placeholder="Amharic" required />
              <Field label="Native name" value={form.native_name} onChange={(v) => setForm({ ...form, native_name: v })} placeholder="አማርኛ" />
              <Field label="Speakers" value={form.speakers} onChange={(v) => setForm({ ...form, speakers: v })} placeholder="57M+" />
              <Field label="Script preview" value={form.script_preview} onChange={(v) => setForm({ ...form, script_preview: v })} placeholder="ሀ ለ ሐ መ" />
              <Field label="Region" value={form.region} onChange={(v) => setForm({ ...form, region: v })} placeholder="Addis Ababa" />
              <Field label="Hello word" value={form.hello_target} onChange={(v) => setForm({ ...form, hello_target: v })} placeholder="ሰላም" />
              <Field label="Hello meaning" value={form.hello_meaning} onChange={(v) => setForm({ ...form, hello_meaning: v })} placeholder="Selam · Hello" />
              <ColorField label="Color" value={form.color_hex} onChange={(v) => setForm({ ...form, color_hex: v })} />
              <ColorField label="Dark color" value={form.dark_hex} onChange={(v) => setForm({ ...form, dark_hex: v })} />
              <Field label="Sort order" type="number" value={form.sort_order} onChange={(v) => setForm({ ...form, sort_order: Number(v) })} />
            </div>
            <label className="mt-4 flex items-center gap-2 text-sm font-semibold">
              <input
                type="checkbox"
                checked={!!form.is_active}
                onChange={(e) => setForm({ ...form, is_active: e.target.checked ? 1 : 0 })}
              />
              Visible in the app
            </label>
            <div className="mt-6 flex gap-3">
              <button type="submit" className="flex-1 rounded-xl bg-green-700 py-3 text-sm font-black uppercase tracking-wide text-white hover:bg-green-600">
                Save
              </button>
              <button type="button" onClick={() => setOpen(false)} className="flex-1 rounded-xl border border-stone-300 py-3 text-sm font-black uppercase tracking-wide text-stone-500 hover:bg-stone-50">
                Cancel
              </button>
            </div>
          </form>
        </div>
      )}
    </div>
  );
}

function Field({ label, value, onChange, type = 'text', required, placeholder }) {
  return (
    <label className="block">
      <span className="mb-1 block text-xs font-black uppercase tracking-wider text-stone-400">{label}</span>
      <input
        type={type}
        value={value ?? ''}
        required={required}
        placeholder={placeholder}
        onChange={(e) => onChange(e.target.value)}
        className="w-full rounded-xl border border-stone-200 px-3 py-2.5 text-sm outline-none focus:border-green-600"
      />
    </label>
  );
}

function ColorField({ label, value, onChange }) {
  return (
    <label className="block">
      <span className="mb-1 block text-xs font-black uppercase tracking-wider text-stone-400">{label}</span>
      <div className="flex items-center gap-2">
        <input
          type="color"
          value={value}
          onChange={(e) => onChange(e.target.value)}
          className="h-10 w-12 cursor-pointer rounded-lg border border-stone-200"
        />
        <code className="text-xs font-bold text-stone-500">{value}</code>
      </div>
    </label>
  );
}
