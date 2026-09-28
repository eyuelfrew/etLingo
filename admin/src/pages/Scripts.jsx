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

const emptyScript = {
  code: '',
  name: '',
  native_name: '',
  direction: 'ltr',
  family: '',
  sample: '',
  description: '',
  is_active: 1,
  sort_order: 0,
};

const emptyLetter = {
  glyph: '',
  name: '',
  roman: '',
  sound: '',
  order_name: '',
  form_index: 0,
  notes: '',
  audio_url: '',
  sort_order: 0,
};

const FORM_LABELS = [
  '1st · ä',
  '2nd · u',
  '3rd · i',
  '4th · a',
  '5th · e',
  '6th · ə',
  '7th · o',
  '8th · wa',
];

/**
 * One letter family (e.g. ሀ ሁ ሂ ሃ ሄ ህ ሆ) — expandable, with form reorder.
 * Parent list supports HTML5 drag to reorder whole families.
 */
function FamilyRow({
  familyKey,
  members,
  index,
  onEdit,
  onRemove,
  onPlay,
  onMoveForm,
  onDragStart,
  onDrop,
  onMoveFamily,
  familyCount,
}) {
  const [open, setOpen] = useState(false);
  const [dragOver, setDragOver] = useState(false);
  const sorted = [...members].sort((a, b) => {
    if (a.formIndex !== b.formIndex) return a.formIndex - b.formIndex;
    return (a.sortOrder ?? 0) - (b.sortOrder ?? 0);
  });
  const withAudio = sorted.filter((m) => m.audioUrl).length;

  return (
    <div
      draggable
      onDragStart={(e) => {
        e.dataTransfer.setData('text/family-index', String(index));
        e.dataTransfer.effectAllowed = 'move';
        onDragStart?.(index);
      }}
      onDragOver={(e) => {
        e.preventDefault();
        setDragOver(true);
      }}
      onDragLeave={() => setDragOver(false)}
      onDrop={(e) => {
        e.preventDefault();
        setDragOver(false);
        const from = Number(e.dataTransfer.getData('text/family-index'));
        if (!Number.isNaN(from) && from !== index) onDrop?.(from, index);
      }}
      className={`overflow-hidden rounded-2xl border bg-panel transition ${
        dragOver ? 'border-et-green ring-2 ring-et-green/30' : 'border-line-soft'
      }`}
    >
      <div className="flex items-center">
        <span
          className="cursor-grab px-2 text-muted select-none"
          title="Drag to reorder family"
          aria-hidden
        >
          ⠿
        </span>
        <button
          type="button"
          onClick={() => setOpen(!open)}
          className="flex flex-1 items-center gap-3 px-2 py-3 text-left transition hover:bg-canvas"
        >
          <span className="flex h-12 w-12 items-center justify-center rounded-xl bg-canvas text-2xl font-bold">
            {sorted[0]?.glyph || familyKey}
          </span>
          <span className="min-w-0 flex-1">
            <span className="block text-[14px] font-bold text-ink">
              #{index + 1} {familyKey} family · {sorted.length} forms
            </span>
            <span className="block truncate text-[20px] font-semibold tracking-wide">
              {sorted.map((m) => m.glyph).join(' ')}
            </span>
          </span>
          <Badge tone={withAudio ? 'success' : 'warning'}>
            {withAudio}/{sorted.length} audio
          </Badge>
          <span className="text-muted">{open ? '▾' : '▸'}</span>
        </button>
        <div className="flex flex-col gap-0.5 pr-2">
          <button
            type="button"
            disabled={index <= 0}
            onClick={() => onMoveFamily?.(index, index - 1)}
            className="rounded px-1 text-[11px] text-muted disabled:opacity-30 hover:text-ink"
            title="Move family up"
          >
            ▲
          </button>
          <button
            type="button"
            disabled={index >= familyCount - 1}
            onClick={() => onMoveFamily?.(index, index + 1)}
            className="rounded px-1 text-[11px] text-muted disabled:opacity-30 hover:text-ink"
            title="Move family down"
          >
            ▼
          </button>
        </div>
      </div>
      {open && (
        <div className="border-t border-line-soft px-4 py-3">
          <div className="grid gap-2 sm:grid-cols-2 lg:grid-cols-3">
            {sorted.map((m, fi) => (
              <div
                key={m.id}
                className="flex items-center gap-2 rounded-xl border border-line-soft px-3 py-2"
              >
                <div className="flex flex-col gap-0.5">
                  <button
                    type="button"
                    disabled={fi <= 0}
                    onClick={() =>
                      onMoveForm?.(familyKey, fi, fi - 1)
                    }
                    className="text-[10px] text-muted disabled:opacity-30"
                    title="Move form earlier"
                  >
                    ▲
                  </button>
                  <button
                    type="button"
                    disabled={fi >= sorted.length - 1}
                    onClick={() =>
                      onMoveForm?.(familyKey, fi, fi + 1)
                    }
                    className="text-[10px] text-muted disabled:opacity-30"
                    title="Move form later"
                  >
                    ▼
                  </button>
                </div>
                <span className="text-2xl font-bold">{m.glyph}</span>
                <span className="min-w-0 flex-1">
                  <span className="block text-[12px] font-bold">
                    {FORM_LABELS[m.formIndex] || `form ${m.formIndex}`}
                  </span>
                  <span className="block text-[11px] text-muted">
                    {m.roman} · {m.sound}
                  </span>
                </span>
                <button
                  type="button"
                  disabled={!m.audioUrl}
                  onClick={() => onPlay(m)}
                  className={`rounded-lg px-2 py-1 text-[11px] font-bold ${
                    m.audioUrl
                      ? 'bg-et-green-soft text-et-green hover:underline'
                      : 'text-muted opacity-50'
                  }`}
                >
                  ▶
                </button>
                <button
                  type="button"
                  onClick={() => onEdit(m)}
                  className="text-[11px] font-semibold text-et-blue hover:underline"
                >
                  Edit
                </button>
                <button
                  type="button"
                  onClick={() => onRemove(m)}
                  className="text-[11px] font-semibold text-et-red hover:underline"
                >
                  Del
                </button>
              </div>
            ))}
          </div>
          <p className="mt-3 text-[12px] text-muted">
            Use ▲▼ to fix form order (ä u i a e ə o). Drag the whole row to move
            the family in the alphabet.
          </p>
        </div>
      )}
    </div>
  );
}

/**
 * Language-first script management:
 * pick a course language → create/maintain its writing system(s) → letters.
 */
export default function Scripts() {
  const [params, setParams] = useSearchParams();
  const navigate = useNavigate();

  const [languages, setLanguages] = useState([]);
  const [langId, setLangId] = useState(
    () => Number(params.get('langId')) || null,
  );
  const [bundle, setBundle] = useState(null); // { language, scripts[] }
  const [selectedScriptId, setSelectedScriptId] = useState(null);
  const [letters, setLetters] = useState([]);
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(true);

  const [scriptOpen, setScriptOpen] = useState(false);
  const [editingScriptId, setEditingScriptId] = useState(null);
  const [form, setForm] = useState(emptyScript);

  const [letterOpen, setLetterOpen] = useState(false);
  const [editingLetterId, setEditingLetterId] = useState(null);
  const [letterForm, setLetterForm] = useState(emptyLetter);

  const [importOpen, setImportOpen] = useState(false);
  const [importText, setImportText] = useState('');
  const [bulkGlyphs, setBulkGlyphs] = useState('');

  useEffect(() => {
    (async () => {
      try {
        const { data } = await client.get('/admin/languages');
        const langs = data || [];
        setLanguages(langs);
        if (!langId && langs.length) {
          const fromQuery = Number(params.get('langId'));
          const next = fromQuery || langs[0].id;
          setLangId(next);
          setParams({ langId: String(next) }, { replace: true });
        }
      } catch (e) {
        setError(apiError(e, 'Failed to load languages'));
      } finally {
        setLoading(false);
      }
    })();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const loadBundle = useCallback(async (id) => {
    if (!id) {
      setBundle(null);
      setLetters([]);
      return;
    }
    try {
      const { data } = await client.get(`/admin/languages/${id}/scripts`);
      setBundle(data);
      setError('');
      const scripts = data?.scripts || [];
      setSelectedScriptId((prev) => {
        if (scripts.find((s) => s.id === prev)) return prev;
        const primary = scripts.find((s) => s.isPrimary) || scripts[0];
        return primary ? primary.id : null;
      });
    } catch (e) {
      setError(apiError(e, 'Failed to load scripts for this language'));
    }
  }, []);

  useEffect(() => {
    loadBundle(langId);
  }, [langId, loadBundle]);

  useEffect(() => {
    const script = (bundle?.scripts || []).find((s) => s.id === selectedScriptId);
    setLetters(script?.letters || []);
  }, [bundle, selectedScriptId]);

  const language = bundle?.language;
  const scripts = bundle?.scripts || [];
  const selected = scripts.find((s) => s.id === selectedScriptId);

  function pickLanguage(id) {
    setLangId(id);
    setSelectedScriptId(null);
    setParams({ langId: String(id) }, { replace: true });
  }

  async function saveScript(e) {
    e.preventDefault();
    try {
      const payload = {
        ...form,
        code: String(form.code || '').trim().toLowerCase(),
        name: String(form.name || '').trim(),
        native_name: String(form.native_name || '').trim(),
        sort_order: Number(form.sort_order) || 0,
        is_active: form.is_active ? 1 : 0,
        language_id: langId,
      };
      if (!payload.code || !payload.name) {
        setError('Code and name are required.');
        return;
      }
      if (editingScriptId) {
        await client.put(`/admin/scripts/${editingScriptId}`, payload);
      } else {
        // Language-first create: script belongs to this language + primary.
        await client.post(`/admin/languages/${langId}/scripts`, payload);
      }
      setScriptOpen(false);
      setEditingScriptId(null);
      setForm(emptyScript);
      await loadBundle(langId);
    } catch (err) {
      setError(apiError(err, 'Could not save script'));
    }
  }

  async function removeScript(row) {
    if (!confirm(`Delete script "${row.name}" and all its letters from this language?`)) {
      return;
    }
    try {
      await client.delete(`/admin/scripts/${row.id}`);
      if (selectedScriptId === row.id) setSelectedScriptId(null);
      await loadBundle(langId);
    } catch (err) {
      setError(apiError(err, 'Could not delete script'));
    }
  }

  async function saveLetter(e) {
    e.preventDefault();
    try {
      const body = {
        ...letterForm,
        script_id: selectedScriptId,
        glyph: String(letterForm.glyph || '').trim(),
        audio_url: String(letterForm.audio_url || '').trim(),
        form_index: Number(letterForm.form_index) || 0,
        sort_order: Number(letterForm.sort_order) || 0,
      };
      if (!body.glyph) {
        setError('Glyph is required.');
        return;
      }
      if (editingLetterId) await client.put(`/admin/script-letters/${editingLetterId}`, body);
      else await client.post('/admin/script-letters', body);
      setLetterOpen(false);
      setEditingLetterId(null);
      setLetterForm(emptyLetter);
      await loadBundle(langId);
    } catch (err) {
      setError(apiError(err, 'Could not save letter'));
    }
  }

  async function persistFamilyOrder(groups) {
    // Flatten groups into sequential sort_order (family blocks stay contiguous).
    const items = [];
    let n = 0;
    for (const members of groups) {
      const sorted = [...members].sort((a, b) => {
        if (a.formIndex !== b.formIndex) return a.formIndex - b.formIndex;
        return (a.sortOrder ?? 0) - (b.sortOrder ?? 0);
      });
      for (const m of sorted) {
        items.push({ id: m.id, sortOrder: n, formIndex: m.formIndex });
        n += 1;
      }
    }
    try {
      await client.post('/admin/script-letters/reorder', { items });
      await loadBundle(langId);
    } catch (err) {
      setError(apiError(err, 'Could not save order'));
    }
  }

  function currentGroups() {
    const map = new Map();
    for (const l of letters) {
      const key = l.orderName || l.glyph;
      if (!map.has(key)) map.set(key, []);
      map.get(key).push(l);
    }
    return [...map.entries()].map(([key, members]) => ({
      key,
      members: [...members].sort((a, b) => {
        if (a.formIndex !== b.formIndex) return a.formIndex - b.formIndex;
        return (a.sortOrder ?? 0) - (b.sortOrder ?? 0);
      }),
    }));
  }

  async function moveFamily(from, to) {
    const groups = currentGroups();
    if (from < 0 || to < 0 || from >= groups.length || to >= groups.length) return;
    const next = [...groups];
    const [moved] = next.splice(from, 1);
    next.splice(to, 0, moved);
    await persistFamilyOrder(next.map((g) => g.members));
  }

  async function moveForm(familyKey, fromFi, toFi) {
    const groups = currentGroups();
    const g = groups.find((x) => x.key === familyKey);
    if (!g) return;
    const forms = [...g.members];
    if (fromFi < 0 || toFi < 0 || fromFi >= forms.length || toFi >= forms.length) return;
    const [moved] = forms.splice(fromFi, 1);
    forms.splice(toFi, 0, moved);
    // Keep formIndex in visual order after manual fix
    const reindexed = forms.map((m, i) => ({ ...m, formIndex: i }));
    g.members = reindexed;
    await persistFamilyOrder(groups.map((x) => x.members));
  }

  async function removeLetter(row) {
    if (!confirm(`Remove letter "${row.glyph}"?`)) return;
    try {
      await client.delete(`/admin/script-letters/${row.id}`);
      await loadBundle(langId);
    } catch (err) {
      setError(apiError(err, 'Could not delete letter'));
    }
  }

  async function importLetters(e) {
    e.preventDefault();
    try {
      let payload = { replace: true, letters: [] };
      const t = importText.trim();
      if (t.startsWith('[')) {
        payload.letters = JSON.parse(t);
      } else if (t.includes('|') || t.includes('\t')) {
        payload.letters = t
          .split('\n')
          .map((line) => line.trim())
          .filter(Boolean)
          .map((line, i) => {
            const parts = line.split(/\t|\|/).map((p) => p.trim());
            return {
              glyph: parts[0],
              name: parts[1] || '',
              roman: parts[2] || '',
              sound: parts[3] || parts[2] || '',
              orderName: parts[4] || '',
              formIndex: Number(parts[5] || 0) || 0,
              sortOrder: i,
            };
          });
      } else {
        payload.letters = t.split(/\s+/).filter(Boolean).map((glyph, i) => ({
          glyph,
          name: '',
          roman: '',
          sound: '',
          sortOrder: i,
        }));
      }
      await client.post(`/admin/scripts/${selectedScriptId}/letters/bulk`, payload);
      setImportOpen(false);
      setImportText('');
      await loadBundle(langId);
    } catch (err) {
      setError(apiError(err, 'Import failed'));
    }
  }

  async function expandFromBases(e) {
    e.preventDefault();
    const bases = bulkGlyphs.trim().split(/\s+/).filter(Boolean);
    if (!bases.length || !selectedScriptId) return;
    try {
      await client.post(`/admin/scripts/${selectedScriptId}/letters/bulk`, {
        replace: false,
        letters: bases.map((glyph, i) => ({
          glyph,
          name: '',
          roman: '',
          sound: '',
          orderName: 'base',
          formIndex: 0,
          sortOrder: i,
        })),
      });
      setBulkGlyphs('');
      await loadBundle(langId);
    } catch (err) {
      setError(apiError(err, 'Could not add base glyphs'));
    }
  }

  return (
    <div>
      <PageHeader
        eyebrow="Per language"
        title="Scripts & alphabets"
        subtitle="Create a language first, then its writing system and full alphabet. Learners use these letters in the Fidel trainer and script browser."
        actions={
          <div className="flex flex-wrap gap-2">
            <Button
              variant="ghost"
              onClick={() => navigate('/languages')}
            >
              ← Courses
            </Button>
            <Button
              variant="primary"
              disabled={!langId}
              onClick={() => {
                if (!langId) return;
                setEditingScriptId(null);
                setForm({
                  ...emptyScript,
                  name: '',
                  code: '',
                  native_name: '',
                });
                setScriptOpen(true);
              }}
            >
              New script for this language
            </Button>
          </div>
        }
      />
      {error && <Banner tone="danger">{error}</Banner>}

      {/* Step 1 — language */}
      <Card
        title="1 · Language"
        description="Everything below is scoped to the selected course language."
        className="mt-5"
      >
        {loading ? (
          <p className="text-sm text-muted">Loading languages…</p>
        ) : languages.length === 0 ? (
          <EmptyState
            title="No languages yet"
            hint="Create a course language first (e.g. Amharic)."
            action={
              <Button variant="primary" onClick={() => navigate('/languages')}>
                Go to Courses
              </Button>
            }
          />
        ) : (
          <div className="flex flex-wrap gap-2">
            {languages.map((l) => {
              const on = l.id === langId;
              return (
                <button
                  key={l.id}
                  type="button"
                  onClick={() => pickLanguage(l.id)}
                  className={`rounded-xl border px-4 py-3 text-left transition ${
                    on
                      ? 'border-et-green bg-et-green-soft'
                      : 'border-line-soft bg-panel hover:bg-canvas'
                  }`}
                >
                  <span className="block text-[14px] font-bold text-ink">
                    {l.native_name}
                  </span>
                  <span className="block text-[12px] text-muted">
                    {l.name} · {l.code}
                    {l.script_preview ? ` · ${l.script_preview}` : ''}
                  </span>
                </button>
              );
            })}
          </div>
        )}
      </Card>

      {/* Step 2 — scripts of this language */}
      <div className="mt-5 grid gap-5 lg:grid-cols-[300px_1fr]">
        <Card
          title="2 · Writing system"
          description={language ? `Scripts for ${language.native_name}` : ''}
          bodyClass="p-2"
        >
          {!language ? (
            <EmptyState title="Pick a language" />
          ) : scripts.length === 0 ? (
            <EmptyState
              title="No script yet"
              hint={`Create the alphabet / writing system for ${language.native_name}.`}
              action={
                <Button
                  variant="primary"
                  onClick={() => {
                    setEditingScriptId(null);
                    setForm({
                      ...emptyScript,
                      name: language.native_name || language.name,
                      code: String(language.code || '').slice(0, 4).toLowerCase(),
                      native_name: language.native_name || '',
                    });
                    setScriptOpen(true);
                  }}
                >
                  Create script
                </Button>
              }
            />
          ) : (
            <ul className="divide-y divide-line-soft">
              {scripts.map((s) => (
                <li key={s.id}>
                  <button
                    type="button"
                    onClick={() => setSelectedScriptId(s.id)}
                    className={`flex w-full items-center gap-3 rounded-xl px-3 py-3 text-left transition hover:bg-canvas ${
                      selectedScriptId === s.id ? 'bg-et-green-soft' : ''
                    }`}
                  >
                    <span className="flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-canvas text-lg font-bold">
                      {(s.sample || s.name).slice(0, 2)}
                    </span>
                    <span className="min-w-0 flex-1">
                      <span className="block truncate text-[14px] font-semibold text-ink">
                        {s.name}
                      </span>
                      <span className="block truncate text-[12px] text-muted">
                        {s.letterCount ?? s.letters?.length ?? 0} letters ·{' '}
                        {s.code}
                      </span>
                    </span>
                    {s.isPrimary && <Badge tone="success">primary</Badge>}
                  </button>
                  <div className="flex gap-1 px-3 pb-2">
                    <Button
                      variant="ghost"
                      onClick={() => {
                        setEditingScriptId(s.id);
                        setForm({
                          code: s.code,
                          name: s.name,
                          native_name: s.nativeName || s.native_name || '',
                          direction: s.direction || 'ltr',
                          family: s.family || '',
                          sample: s.sample || '',
                          description: s.description || '',
                          is_active: s.isActive ? 1 : 0,
                          sort_order: s.sortOrder ?? 0,
                        });
                        setScriptOpen(true);
                      }}
                    >
                      Edit
                    </Button>
                    <Button variant="ghost" onClick={() => removeScript(s)}>
                      Delete
                    </Button>
                  </div>
                </li>
              ))}
            </ul>
          )}
        </Card>

        {/* Step 3 — letters */}
        <div className="space-y-5">
          {!selected ? (
            <Card>
              <EmptyState
                title="3 · Alphabet letters"
                hint="Select or create a writing system for this language to manage its letters."
              />
            </Card>
          ) : (
            <Card
              title={`3 · ${selected.name} alphabet`}
              description={`${letters.length} letters · ${selected.direction?.toUpperCase?.() || 'LTR'}${
                selected.sample ? ` · sample ${selected.sample}` : ''
              }`}
            >
              <div className="mb-3 flex flex-wrap gap-2">
                <Button
                  variant="primary"
                  onClick={() => {
                    setEditingLetterId(null);
                    setLetterForm({ ...emptyLetter, sort_order: letters.length });
                    setLetterOpen(true);
                  }}
                >
                  Add letter + audio
                </Button>
                <Button variant="secondary" onClick={() => setImportOpen(true)}>
                  Import / replace
                </Button>
                <span className="ml-auto self-center text-[12px] text-muted">
                  {letters.filter((l) => l.audioUrl).length}/{letters.length} with audio
                </span>
              </div>

              {letters.length === 0 ? (
                <EmptyState
                  title="No letters"
                  hint="Add glyphs or import a full alphabet."
                />
              ) : (
                (() => {
                  // Group into families by orderName (ሀ-row, ለ-row…)
                  // Family order = lowest sortOrder (admin drag order).
                  const groups = new Map();
                  for (const l of letters) {
                    const key = l.orderName || l.glyph;
                    if (!groups.has(key)) groups.set(key, []);
                    groups.get(key).push(l);
                  }
                  const familyRows = [...groups.entries()]
                    .map(([key, members]) => ({
                      key,
                      members,
                      minSort: Math.min(...members.map((m) => m.sortOrder ?? 0)),
                    }))
                    .sort((a, b) => a.minSort - b.minSort)
                    .map(({ key, members }) => [key, members]);
                  return (
                    <div className="space-y-4">
                      <p className="text-[12px] text-muted">
                        {familyRows.length} families ·{' '}
                        {letters.filter((l) => l.audioUrl).length} with audio ·
                        expand a row to edit all vowel orders (1st ä … 7th o).
                      </p>
                      {familyRows.map(([key, members], idx) => (
                        <FamilyRow
                          key={key}
                          familyKey={key}
                          members={members}
                          index={idx}
                          familyCount={familyRows.length}
                          onMoveFamily={moveFamily}
                          onMoveForm={moveForm}
                          onDrop={(from, to) => moveFamily(from, to)}
                          onEdit={(l) => {
                            setEditingLetterId(l.id);
                            setLetterForm({
                              glyph: l.glyph,
                              name: l.name,
                              roman: l.roman,
                              sound: l.sound,
                              order_name: l.orderName,
                              form_index: l.formIndex,
                              notes: l.notes,
                              audio_url: l.audioUrl || '',
                              sort_order: l.sortOrder,
                            });
                            setLetterOpen(true);
                          }}
                          onRemove={removeLetter}
                          onPlay={(l) => {
                            if (!l.audioUrl) return;
                            const a = new Audio(resolveAudioUrl(l.audioUrl));
                            a.play().catch(() => {});
                          }}
                        />
                      ))}
                    </div>
                  );
                })()
              )}

              <form onSubmit={expandFromBases} className="mt-4 flex flex-wrap items-end gap-2">
                <Field label="Quick-add base glyphs" hint="Space-separated · e.g. ሀ ለ ሐ">
                  <input
                    className={inputCls}
                    value={bulkGlyphs}
                    onChange={(e) => setBulkGlyphs(e.target.value)}
                    placeholder="ሀ ለ ሐ መ ሠ ረ"
                  />
                </Field>
                <Button type="submit" variant="secondary">
                  Add bases
                </Button>
              </form>
            </Card>
          )}
        </div>
      </div>

      {scriptOpen && (
        <Modal
          onClose={() => setScriptOpen(false)}
          title={
            editingScriptId
              ? `Edit script · ${language?.native_name || ''}`
              : `New script for ${language?.native_name || 'language'}`
          }
          description={
            editingScriptId
              ? 'Writing system details.'
              : 'This creates the writing system for the selected language and marks it primary.'
          }
        >
          <form onSubmit={saveScript} className="space-y-3">
            <Field label="Code" hint="ethi, latn, arab, osma, …">
              <input
                className={inputCls}
                value={form.code}
                onChange={(e) => setForm({ ...form, code: e.target.value })}
                required
              />
            </Field>
            <Field label="Name">
              <input
                className={inputCls}
                value={form.name}
                onChange={(e) => setForm({ ...form, name: e.target.value })}
                required
              />
            </Field>
            <Field label="Native name">
              <input
                className={inputCls}
                value={form.native_name}
                onChange={(e) => setForm({ ...form, native_name: e.target.value })}
              />
            </Field>
            <Field label="Direction">
              <select
                className={inputCls}
                value={form.direction}
                onChange={(e) => setForm({ ...form, direction: e.target.value })}
              >
                <option value="ltr">Left → right</option>
                <option value="rtl">Right → left</option>
              </select>
            </Field>
            <Field label="Family">
              <input
                className={inputCls}
                value={form.family}
                onChange={(e) => setForm({ ...form, family: e.target.value })}
              />
            </Field>
            <Field label="Sample glyphs">
              <input
                className={inputCls}
                value={form.sample}
                onChange={(e) => setForm({ ...form, sample: e.target.value })}
              />
            </Field>
            <Field label="Description">
              <textarea
                className={inputCls}
                rows={3}
                value={form.description}
                onChange={(e) => setForm({ ...form, description: e.target.value })}
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
              Active
            </label>
            <div className="flex justify-end gap-2 pt-2">
              <Button type="button" variant="ghost" onClick={() => setScriptOpen(false)}>
                Cancel
              </Button>
              <Button type="submit" variant="primary">
                {editingScriptId ? 'Save' : 'Create for language'}
              </Button>
            </div>
          </form>
        </Modal>
      )}

      {letterOpen && (
        <Modal
          onClose={() => setLetterOpen(false)}
          title={editingLetterId ? 'Edit letter' : 'Add letter'}
        >
          <form onSubmit={saveLetter} className="space-y-3">
            <Field label="Glyph">
              <input
                className={`${inputCls} text-xl`}
                value={letterForm.glyph}
                onChange={(e) => setLetterForm({ ...letterForm, glyph: e.target.value })}
                required
              />
            </Field>
            <Field label="Name">
              <input
                className={inputCls}
                value={letterForm.name}
                onChange={(e) => setLetterForm({ ...letterForm, name: e.target.value })}
              />
            </Field>
            <Field label="Romanization">
              <input
                className={inputCls}
                value={letterForm.roman}
                onChange={(e) => setLetterForm({ ...letterForm, roman: e.target.value })}
              />
            </Field>
            <Field label="Sound">
              <input
                className={inputCls}
                value={letterForm.sound}
                onChange={(e) => setLetterForm({ ...letterForm, sound: e.target.value })}
              />
            </Field>
            <Field label="Order name (family)" hint="Family key — e.g. h groups ሀ ሁ ሂ ሃ ሄ ህ ሆ">
              <input
                className={inputCls}
                value={letterForm.order_name}
                onChange={(e) =>
                  setLetterForm({ ...letterForm, order_name: e.target.value })
                }
              />
            </Field>
            <Field
              label="Form index"
              hint="0=ä (ሀ) · 1=u (ሁ) · 2=i (ሂ) · 3=a (ሃ) · 4=e (ሄ) · 5=ə (ህ) · 6=o (ሆ) · 7=wa"
            >
              <input
                type="number"
                min="0"
                max="7"
                className={inputCls}
                value={letterForm.form_index}
                onChange={(e) =>
                  setLetterForm({ ...letterForm, form_index: e.target.value })
                }
              />
            </Field>
            <Field label="Notes">
              <input
                className={inputCls}
                value={letterForm.notes}
                onChange={(e) => setLetterForm({ ...letterForm, notes: e.target.value })}
              />
            </Field>
            <AudioField
              label="Pronunciation audio"
              hint="Record or upload how this letter sounds — helps learners who can’t read the script yet."
              value={letterForm.audio_url}
              onChange={(v) => setLetterForm({ ...letterForm, audio_url: v })}
            />
            <div className="flex justify-end gap-2 pt-2">
              <Button type="button" variant="ghost" onClick={() => setLetterOpen(false)}>
                Cancel
              </Button>
              <Button type="submit" variant="primary">
                Save
              </Button>
            </div>
          </form>
        </Modal>
      )}

      {importOpen && (
        <Modal
          onClose={() => setImportOpen(false)}
          title="Import letters (replaces all)"
        >
          <form onSubmit={importLetters} className="space-y-3">
            <Banner tone="warning">
              Replaces every letter of <strong>{selected?.name}</strong> for{' '}
              <strong>{language?.native_name}</strong>.
            </Banner>
            <Field
              label="Paste letters"
              hint="glyph | name | roman | sound | order — one per line · or space-separated glyphs · or JSON"
            >
              <textarea
                className={inputCls}
                rows={12}
                value={importText}
                onChange={(e) => setImportText(e.target.value)}
                placeholder={'ሀ | ha | hä | ha\nለ | la | lä | la\n…'}
              />
            </Field>
            <div className="flex justify-end gap-2 pt-2">
              <Button type="button" variant="ghost" onClick={() => setImportOpen(false)}>
                Cancel
              </Button>
              <Button type="submit" variant="primary">
                Replace letters
              </Button>
            </div>
          </form>
        </Modal>
      )}
    </div>
  );
}
