import { useCallback, useEffect, useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import client, { apiError } from '../api/client';
import AudioField, { resolveAudioUrl } from '../components/AudioField';
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

const emptyCat = {
  slug: '',
  title: '',
  native_title: '',
  emoji: '',
  color_hex: '#078930',
  description: '',
  is_active: 1,
  sort_order: 0,
};

const emptyWord = {
  target: '',
  translit: '',
  meaning: '',
  audio_url: '',
  image_url: '',
  notes: '',
  sort_order: 0,
};

/** Theme word packs: Animals, Food, Colors… per language. */
export default function Topics() {
  const [params, setParams] = useSearchParams();
  const navigate = useNavigate();
  const [languages, setLanguages] = useState([]);
  const [langId, setLangId] = useState(
    () => Number(params.get('langId')) || null,
  );
  const [cats, setCats] = useState([]);
  const [words, setWords] = useState([]);
  const [selId, setSelId] = useState(null);
  const [error, setError] = useState('');
  const [catOpen, setCatOpen] = useState(false);
  const [wordOpen, setWordOpen] = useState(false);
  const [editingCat, setEditingCat] = useState(null);
  const [editingWord, setEditingWord] = useState(null);
  const [catForm, setCatForm] = useState(emptyCat);
  const [wordForm, setWordForm] = useState(emptyWord);

  const load = useCallback(async () => {
    try {
      const { data } = await client.get('/admin/languages');
      const langs = data || [];
      setLanguages(langs);
      const id = langId || Number(params.get('langId')) || langs[0]?.id || null;
      if (id) {
        setLangId(id);
        if (!params.get('langId')) {
          setParams({ langId: String(id) }, { replace: true });
        }
        const catsRes = await client.get(
          `/admin/topic-categories?language_id=${id}`,
        );
        setCats(catsRes.data || []);
      }
      setError('');
    } catch (e) {
      setError(apiError(e, 'Failed to load topics'));
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [langId]);

  const loadWords = useCallback(async (catId) => {
    if (!catId) {
      setWords([]);
      return;
    }
    try {
      const { data } = await client.get(
        `/admin/topic-words?category_id=${catId}`,
      );
      setWords(data || []);
    } catch (e) {
      setError(apiError(e, 'Failed to load words'));
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  useEffect(() => {
    loadWords(selId);
  }, [selId, loadWords]);

  const selected = cats.find((c) => c.id === selId);

  async function saveCat(e) {
    e.preventDefault();
    try {
      const body = {
        ...catForm,
        language_id: langId,
        slug: String(catForm.slug || '').trim().toLowerCase(),
        title: String(catForm.title || '').trim(),
        sort_order: Number(catForm.sort_order) || 0,
        is_active: catForm.is_active ? 1 : 0,
      };
      if (!body.slug || !body.title) {
        setError('Slug and title are required.');
        return;
      }
      if (editingCat) await client.put(`/admin/topic-categories/${editingCat}`, body);
      else await client.post('/admin/topic-categories', body);
      setCatOpen(false);
      setEditingCat(null);
      setCatForm(emptyCat);
      await load();
    } catch (err) {
      setError(apiError(err, 'Could not save category'));
    }
  }

  async function saveWord(e) {
    e.preventDefault();
    try {
      const body = {
        ...wordForm,
        category_id: selId,
        target: String(wordForm.target || '').trim(),
        sort_order: Number(wordForm.sort_order) || 0,
      };
      if (!body.target) {
        setError('Target word is required.');
        return;
      }
      if (editingWord) await client.put(`/admin/topic-words/${editingWord}`, body);
      else await client.post('/admin/topic-words', body);
      setWordOpen(false);
      setEditingWord(null);
      setWordForm(emptyWord);
      await loadWords(selId);
    } catch (err) {
      setError(apiError(err, 'Could not save word'));
    }
  }

  return (
    <div>
      <PageHeader
        eyebrow="Content learning"
        title="Topic packs"
        subtitle="Pick a theme (Animals, Food…), then teach words in that language with audio and meaning."
        actions={
          <div className="flex gap-2">
            <Button variant="ghost" onClick={() => navigate('/languages')}>
              ← Courses
            </Button>
            <Button
              variant="primary"
              disabled={!langId}
              onClick={() => {
                setEditingCat(null);
                setCatForm({
                  ...emptyCat,
                  sort_order: cats.length,
                });
                setCatOpen(true);
              }}
            >
              New theme
            </Button>
          </div>
        }
      />
      {error && <Banner tone="danger">{error}</Banner>}

      <div className="mt-5 flex flex-wrap gap-2">
        {languages.map((l) => (
          <button
            key={l.id}
            type="button"
            onClick={() => {
              setLangId(l.id);
              setSelId(null);
              setParams({ langId: String(l.id) }, { replace: true });
            }}
            className={`rounded-xl border px-4 py-2 text-[13px] font-semibold ${
              l.id === langId
                ? 'border-et-green bg-et-green-soft'
                : 'border-line-soft hover:bg-canvas'
            }`}
          >
            {l.native_name} ({l.code})
          </button>
        ))}
      </div>

      <div className="mt-5 grid gap-5 lg:grid-cols-[300px_1fr]">
        <Card title="Themes" bodyClass="p-2">
          {cats.length === 0 ? (
            <EmptyState title="No themes yet" hint="Add Animals, Food, Colors…" />
          ) : (
            <ul className="divide-y divide-line-soft">
              {cats.map((c) => (
                <li key={c.id}>
                  <button
                    type="button"
                    onClick={() => setSelId(c.id)}
                    className={`flex w-full items-center gap-3 rounded-xl px-3 py-3 text-left ${
                      selId === c.id ? 'bg-et-green-soft' : 'hover:bg-canvas'
                    }`}
                  >
                    <span className="text-2xl">{c.emoji || '📚'}</span>
                    <span className="min-w-0 flex-1">
                      <span className="block truncate text-[14px] font-bold">
                        {c.title}
                      </span>
                      <span className="block truncate text-[12px] text-muted">
                        {c.nativeTitle || c.slug}
                      </span>
                    </span>
                    {!c.isActive && <Badge tone="warning">off</Badge>}
                  </button>
                  <div className="flex gap-1 px-3 pb-2">
                    <Button
                      variant="ghost"
                      onClick={() => {
                        setEditingCat(c.id);
                        setCatForm({
                          slug: c.slug,
                          title: c.title,
                          native_title: c.nativeTitle || '',
                          emoji: c.emoji || '',
                          color_hex: c.colorHex || '#078930',
                          description: c.description || '',
                          is_active: c.isActive ? 1 : 0,
                          sort_order: c.sortOrder ?? 0,
                        });
                        setCatOpen(true);
                      }}
                    >
                      Edit
                    </Button>
                    <Button
                      variant="ghost"
                      onClick={async () => {
                        if (!confirm(`Delete theme "${c.title}" and its words?`)) return;
                        await client.delete(`/admin/topic-categories/${c.id}`);
                        if (selId === c.id) setSelId(null);
                        await load();
                      }}
                    >
                      Delete
                    </Button>
                  </div>
                </li>
              ))}
            </ul>
          )}
        </Card>

        <Card
          title={selected ? `${selected.emoji || ''} ${selected.title}` : 'Words'}
          description={
            selected
              ? selected.description || selected.nativeTitle
              : 'Select a theme to manage its words.'
          }
        >
          {selected && (
            <div className="mb-3">
              <Button
                variant="primary"
                onClick={() => {
                  setEditingWord(null);
                  setWordForm({ ...emptyWord, sort_order: words.length });
                  setWordOpen(true);
                }}
              >
                Add word + audio
              </Button>
            </div>
          )}
          {!selected ? (
            <EmptyState title="Pick a theme" hint="Animals, Food, Colors…" />
          ) : words.length === 0 ? (
            <EmptyState title="No words" hint="Add the first word for this theme." />
          ) : (
            <div className={tableShellCls}>
              <table className="w-full text-sm">
                <thead>
                  <tr>
                    <th className={thCls}>Target</th>
                    <th className={thCls}>Translit</th>
                    <th className={thCls}>Meaning</th>
                    <th className={thCls}>Audio</th>
                    <th className={thCls}>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {words.map((w) => (
                    <tr key={w.id}>
                      <td className={`${tdCls} text-lg font-bold`}>{w.target}</td>
                      <td className={tdCls}>{w.translit}</td>
                      <td className={tdCls}>{w.meaning}</td>
                      <td className={tdCls}>
                        {w.audioUrl ? (
                          <button
                            type="button"
                            onClick={() => {
                              const a = new Audio(resolveAudioUrl(w.audioUrl));
                              a.play().catch(() => {});
                            }}
                            className="rounded-lg bg-et-green-soft px-2 py-1 text-[12px] font-bold text-et-green"
                          >
                            ▶ play
                          </button>
                        ) : (
                          <Badge tone="warning">no audio</Badge>
                        )}
                      </td>
                      <td className={tdCls}>
                        <button
                          type="button"
                          className="mr-2 text-[12px] font-semibold text-et-blue hover:underline"
                          onClick={() => {
                            setEditingWord(w.id);
                            setWordForm({
                              target: w.target,
                              translit: w.translit,
                              meaning: w.meaning,
                              audio_url: w.audioUrl || '',
                              image_url: w.imageUrl || '',
                              notes: w.notes,
                              sort_order: w.sortOrder,
                            });
                            setWordOpen(true);
                          }}
                        >
                          Edit
                        </button>
                        <button
                          type="button"
                          className="text-[12px] font-semibold text-et-red hover:underline"
                          onClick={async () => {
                            if (!confirm(`Remove "${w.target}"?`)) return;
                            await client.delete(`/admin/topic-words/${w.id}`);
                            await loadWords(selId);
                          }}
                        >
                          Del
                        </button>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </Card>
      </div>

      {catOpen && (
        <Modal
          onClose={() => setCatOpen(false)}
          title={editingCat ? 'Edit theme' : 'New theme'}
        >
          <form onSubmit={saveCat} className="space-y-3">
            <Field label="Slug" hint="animals · food · colors">
              <input
                className={inputCls}
                value={catForm.slug}
                onChange={(e) => setCatForm({ ...catForm, slug: e.target.value })}
                required
              />
            </Field>
            <Field label="Title">
              <input
                className={inputCls}
                value={catForm.title}
                onChange={(e) => setCatForm({ ...catForm, title: e.target.value })}
                required
              />
            </Field>
            <Field label="Native title">
              <input
                className={inputCls}
                value={catForm.native_title}
                onChange={(e) =>
                  setCatForm({ ...catForm, native_title: e.target.value })
                }
              />
            </Field>
            <Field label="Emoji">
              <input
                className={inputCls}
                value={catForm.emoji}
                onChange={(e) => setCatForm({ ...catForm, emoji: e.target.value })}
              />
            </Field>
            <Field label="Description">
              <textarea
                className={inputCls}
                rows={2}
                value={catForm.description}
                onChange={(e) =>
                  setCatForm({ ...catForm, description: e.target.value })
                }
              />
            </Field>
            <label className="flex items-center gap-2 text-sm font-semibold">
              <input
                type="checkbox"
                checked={!!catForm.is_active}
                onChange={(e) =>
                  setCatForm({ ...catForm, is_active: e.target.checked ? 1 : 0 })
                }
              />
              Active
            </label>
            <div className="flex justify-end gap-2 pt-2">
              <Button type="button" variant="ghost" onClick={() => setCatOpen(false)}>
                Cancel
              </Button>
              <Button type="submit" variant="primary">
                Save
              </Button>
            </div>
          </form>
        </Modal>
      )}

      {wordOpen && (
        <Modal
          onClose={() => setWordOpen(false)}
          title={editingWord ? 'Edit word' : 'Add word'}
        >
          <form onSubmit={saveWord} className="space-y-3">
            <Field label="Target (script)">
              <input
                className={`${inputCls} text-xl`}
                value={wordForm.target}
                onChange={(e) => setWordForm({ ...wordForm, target: e.target.value })}
                required
              />
            </Field>
            <Field label="Transliteration">
              <input
                className={inputCls}
                value={wordForm.translit}
                onChange={(e) =>
                  setWordForm({ ...wordForm, translit: e.target.value })
                }
              />
            </Field>
            <Field label="Meaning (English)">
              <input
                className={inputCls}
                value={wordForm.meaning}
                onChange={(e) =>
                  setWordForm({ ...wordForm, meaning: e.target.value })
                }
              />
            </Field>
            <AudioField
              label="Pronunciation audio"
              value={wordForm.audio_url}
              onChange={(v) => setWordForm({ ...wordForm, audio_url: v })}
            />
            <Field label="Image URL (optional)">
              <input
                className={inputCls}
                value={wordForm.image_url}
                onChange={(e) =>
                  setWordForm({ ...wordForm, image_url: e.target.value })
                }
              />
            </Field>
            <div className="flex justify-end gap-2 pt-2">
              <Button type="button" variant="ghost" onClick={() => setWordOpen(false)}>
                Cancel
              </Button>
              <Button type="submit" variant="primary">
                Save
              </Button>
            </div>
          </form>
        </Modal>
      )}
    </div>
  );
}
