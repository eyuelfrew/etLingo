import { useCallback, useEffect, useState } from 'react';
import client from '../api/client';
import AudioField from '../components/AudioField';

export default function Phrases() {
  const [languages, setLanguages] = useState([]);
  const [langId, setLangId] = useState('');
  const [rows, setRows] = useState([]);
  const [error, setError] = useState('');

  const [form, setForm] = useState({ target: '', translit: '', meaning: '', category: 'Greetings', audio_url: '' });
  const [editingId, setEditingId] = useState(null);

  const loadLangs = useCallback(async () => {
    try {
      const { data } = await client.get('/admin/languages');
      setLanguages(data);
      if (data.length && !langId) setLangId(String(data[0].id));
    } catch (e) {
      setError(e.response?.data?.error || 'Failed to load languages.');
    }
  }, [langId]);

  const loadRows = useCallback(async () => {
    if (!langId) return;
    try {
      setRows((await client.get(`/admin/phrases?language_id=${langId}`)).data);
    } catch {
      setError('Failed to load phrases.');
    }
  }, [langId]);

  useEffect(() => {
    loadLangs();
  }, [loadLangs]);
  useEffect(() => {
    loadRows();
  }, [loadRows]);

  const save = async (e) => {
    e.preventDefault();
    try {
      if (editingId) await client.put(`/admin/phrases/${editingId}`, form);
      else await client.post('/admin/phrases', { ...form, language_id: Number(langId) });
      setForm({ target: '', translit: '', meaning: '', category: 'Greetings', audio_url: '' });
      setEditingId(null);
      loadRows();
    } catch (err) {
      setError(err.response?.data?.error || 'Save failed');
    }
  };

  return (
    <div>
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-black">Phrasebook</h1>
          <p className="mt-1 text-sm font-medium text-stone-500">
            Words shown in the app's Words tab
          </p>
        </div>
        <select
          value={langId}
          onChange={(e) => setLangId(e.target.value)}
          className="rounded-xl border border-stone-200 bg-white px-4 py-2.5 text-sm font-bold outline-none focus:border-green-600"
        >
          {languages.map((l) => (
            <option key={l.id} value={l.id}>
              {l.native_name} ({l.name})
            </option>
          ))}
        </select>
      </div>

      {error && (
        <p className="mt-4 rounded-xl border border-amber-300 bg-amber-50 px-4 py-3 text-sm font-semibold text-amber-800">
          ⚠ {error}
        </p>
      )}

      {!error && !languages.length && (
        <p className="mt-6 rounded-2xl border border-stone-200 bg-white px-5 py-8 text-center text-sm font-semibold text-stone-400 shadow-sm">
          Add a language first.
        </p>
      )}

      {!!languages.length && (
        <>
          <form onSubmit={save} className="mt-6 rounded-2xl border border-stone-200 bg-white p-5 shadow-sm">
            <div className="grid grid-cols-[repeat(4,minmax(0,1fr))_auto] items-end gap-3">
              <Input label="Word *" value={form.target} onChange={(v) => setForm({ ...form, target: v })} placeholder="ሰላም" required />
              <Input label="Translit" value={form.translit} onChange={(v) => setForm({ ...form, translit: v })} placeholder="se·lam" />
              <Input label="Meaning *" value={form.meaning} onChange={(v) => setForm({ ...form, meaning: v })} placeholder="Hello / Peace" required />
              <Input label="Category" value={form.category} onChange={(v) => setForm({ ...form, category: v })} placeholder="Greetings" />
              <button className="rounded-xl bg-green-700 px-5 py-2.5 text-sm font-black uppercase tracking-wide text-white hover:bg-green-600">
                {editingId ? 'Update' : 'Add'}
              </button>
            </div>
            <div className="mt-4 border-t border-stone-100 pt-4">
              <AudioField
                label="Pronunciation audio"
                value={form.audio_url}
                onChange={(v) => setForm({ ...form, audio_url: v })}
              />
            </div>
          </form>

          <div className="mt-4 overflow-hidden rounded-2xl border border-stone-200 bg-white shadow-sm">
            <table className="w-full text-sm">
              <thead className="bg-stone-50 text-left text-xs font-black uppercase tracking-wider text-stone-400">
                <tr>
                  <th className="px-5 py-3">Word</th>
                  <th className="px-4 py-3">Translit</th>
                  <th className="px-4 py-3">Meaning</th>
                  <th className="px-4 py-3">Category</th>
                  <th className="px-4 py-3" />
                </tr>
              </thead>
              <tbody>
                {rows.map((r) => (
                  <tr key={r.id} className="border-t border-stone-100 hover:bg-stone-50/60">
                    <td className="px-5 py-2.5 font-bold">
                      {r.audio_url && <span className="mr-1 text-xs" title="Has audio">🔊</span>}
                      {r.target}
                    </td>
                    <td className="px-4 py-2.5 italic text-stone-400">{r.translit}</td>
                    <td className="px-4 py-2.5">{r.meaning}</td>
                    <td className="px-4 py-2.5">
                      <span className="rounded-full bg-stone-100 px-2.5 py-1 text-xs font-bold text-stone-500">{r.category}</span>
                    </td>
                    <td className="px-4 py-2.5 text-right whitespace-nowrap">
                      <button
                        onClick={() => {
                          setEditingId(r.id);
                          setForm({
                            target: r.target,
                            translit: r.translit,
                            meaning: r.meaning,
                            category: r.category,
                            audio_url: r.audio_url || '',
                          });
                        }}
                        className="mr-2 font-bold text-blue-700 hover:underline"
                      >
                        Edit
                      </button>
                      <button
                        onClick={async () => {
                          await client.delete(`/admin/phrases/${r.id}`);
                          loadRows();
                        }}
                        className="font-bold text-red-600 hover:underline"
                      >
                        Delete
                      </button>
                    </td>
                  </tr>
                ))}
                {!rows.length && (
                  <tr><td colSpan={5} className="px-5 py-10 text-center text-stone-400">No phrases for this language yet.</td></tr>
                )}
              </tbody>
            </table>
          </div>
        </>
      )}
    </div>
  );
}

function Input({ label, value, onChange, required, placeholder }) {
  return (
    <label className="block">
      <span className="mb-1 block text-xs font-black uppercase tracking-wider text-stone-400">{label}</span>
      <input
        value={value}
        required={required}
        placeholder={placeholder}
        onChange={(e) => onChange(e.target.value)}
        className="w-full rounded-xl border border-stone-200 px-3 py-2.5 text-sm outline-none focus:border-green-600"
      />
    </label>
  );
}
