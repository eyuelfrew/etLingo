import { useCallback, useEffect, useState } from 'react';
import client from '../api/client';
import AudioField from '../components/AudioField';
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
  Card,
  EmptyState,
} from '../components/ui';

export default function Phrases() {
  const [languages, setLanguages] = useState([]);
  const [langId, setLangId] = useState('');
  const [rows, setRows] = useState([]);
  const [error, setError] = useState('');

  const [form, setForm] = useState({
    target: '',
    translit: '',
    meaning: '',
    category: 'Basics',
    audio_url: '',
  });
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
      setForm({ target: '', translit: '', meaning: '', category: 'Basics', audio_url: '' });
      setEditingId(null);
      loadRows();
    } catch (err) {
      setError(err.response?.data?.error || 'Save failed');
    }
  };

  return (
    <div>
      <PageHeader
        eyebrow="Learning content"
        title="Phrasebook"
        subtitle="Words learners see in the app Words tab — with optional pronunciation audio."
        actions={
          languages.length > 0 ? (
            <select
              value={langId}
              onChange={(e) => setLangId(e.target.value)}
              className={`${inputCls} mt-0 min-w-[220px]`}
            >
              {languages.map((l) => (
                <option key={l.id} value={l.id}>
                  {l.native_name} ({l.name})
                </option>
              ))}
            </select>
          ) : null
        }
      />

      {error && (
        <div className="mt-5">
          <Banner tone="warning">{error}</Banner>
        </div>
      )}

      {!error && !languages.length && (
        <div className="mt-6">
          <EmptyState
            icon="💬"
            title="Add a language first"
            hint="Phrasebook rows belong to a language course."
          />
        </div>
      )}

      {!!languages.length && (
        <>
          <div className="mt-6">
            <Card
              title={editingId ? 'Edit phrase' : 'Add phrase'}
              description="Target word, transliteration, meaning, and category."
            >
              <form onSubmit={save}>
                <div className="grid gap-3 md:grid-cols-2 lg:grid-cols-4">
                  <Field label="Word *">
                    <input
                      className={`${inputCls} font-ethiopic`}
                      value={form.target}
                      required
                      placeholder="ሰላም"
                      onChange={(e) => setForm({ ...form, target: e.target.value })}
                    />
                  </Field>
                  <Field label="Transliteration">
                    <input
                      className={inputCls}
                      value={form.translit}
                      placeholder="se·lam"
                      onChange={(e) => setForm({ ...form, translit: e.target.value })}
                    />
                  </Field>
                  <Field label="Meaning *">
                    <input
                      className={inputCls}
                      value={form.meaning}
                      required
                      placeholder="Hello / Peace"
                      onChange={(e) => setForm({ ...form, meaning: e.target.value })}
                    />
                  </Field>
                  <Field label="Category">
                    <input
                      className={inputCls}
                      value={form.category}
                      placeholder="Basics"
                      onChange={(e) => setForm({ ...form, category: e.target.value })}
                    />
                  </Field>
                </div>
                <div className="mt-4 border-t border-line-soft pt-4">
                  <AudioField
                    label="Pronunciation audio"
                    value={form.audio_url}
                    onChange={(v) => setForm({ ...form, audio_url: v })}
                  />
                </div>
                <div className="mt-4 flex gap-2">
                  <Button type="submit" variant="primary">
                    {editingId ? 'Update phrase' : 'Add phrase'}
                  </Button>
                  {editingId && (
                    <Button
                      type="button"
                      variant="secondary"
                      onClick={() => {
                        setEditingId(null);
                        setForm({
                          target: '',
                          translit: '',
                          meaning: '',
                          category: 'Basics',
                          audio_url: '',
                        });
                      }}
                    >
                      Cancel
                    </Button>
                  )}
                </div>
              </form>
            </Card>
          </div>

          <div className="mt-4">
            {rows.length === 0 ? (
              <EmptyState
                icon="📖"
                title="No phrases yet"
                hint="Add the first word for this language."
              />
            ) : (
              <div className={tableShellCls}>
                <table className="w-full">
                  <thead>
                    <tr className="border-b border-line-soft">
                      <th className={thCls}>Word</th>
                      <th className={thCls}>Translit</th>
                      <th className={thCls}>Meaning</th>
                      <th className={thCls}>Category</th>
                      <th className={`${thCls} text-right`}>Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {rows.map((r) => (
                      <tr key={r.id} className="border-t border-line-soft hover:bg-canvas/60">
                        <td className={tdCls}>
                          <span className="font-ethiopic font-semibold">
                            {r.audio_url && (
                              <span className="mr-1.5 text-[12px]" title="Has audio">
                                🔊
                              </span>
                            )}
                            {r.target}
                          </span>
                        </td>
                        <td className={`${tdCls} italic text-muted`}>{r.translit || '—'}</td>
                        <td className={tdCls}>{r.meaning}</td>
                        <td className={tdCls}>
                          <Badge tone="neutral">{r.category}</Badge>
                        </td>
                        <td className={`${tdCls} text-right whitespace-nowrap`}>
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
                            className="mr-3 text-[13px] font-semibold text-et-blue hover:underline"
                          >
                            Edit
                          </button>
                          <button
                            onClick={async () => {
                              if (!confirm('Delete this phrase?')) return;
                              await client.delete(`/admin/phrases/${r.id}`);
                              loadRows();
                            }}
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
        </>
      )}
    </div>
  );
}
