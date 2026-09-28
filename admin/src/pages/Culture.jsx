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
  Modal,
  EmptyState,
  tableShellCls,
  thCls,
  tdCls,
} from '../components/ui';

const KINDS = [
  ['text', 'Text'],
  ['fact', 'Fact'],
  ['proverb', 'Proverb'],
  ['steps', 'Steps'],
  ['vocab', 'Words'],
  ['calendar', 'Calendar'],
  ['media', 'Media'],
  ['music', 'Music / lyrics'],
];

const THEMES = [
  'coffee',
  'holiday',
  'food',
  'history',
  'proverb',
  'music',
  'script',
  'calendar',
  'fact',
];

function emptyUnit(langId, sort) {
  return {
    language_id: langId,
    title: '',
    subtitle: '',
    theme: 'fact',
    color_hex: '#6B3F1D',
    dark_hex: '#3E2512',
    icon: 'coffee_rounded',
    sort_order: sort,
    is_active: 1,
  };
}

function emptyCard(unitId, sort) {
  return {
    culture_unit_id: unitId,
    kind: 'text',
    title: '',
    body: '',
    content: {},
    translit: '',
    audio_url: '',
    pdf_url: '',
    vocab: [],
    meta: {},
    xp_reward: 5,
    sort_order: sort,
  };
}

export default function Culture() {
  const [languages, setLanguages] = useState([]);
  const [langId, setLangId] = useState(null);
  const [units, setUnits] = useState([]);
  const [cards, setCards] = useState([]);
  const [error, setError] = useState('');
  const [unitOpen, setUnitOpen] = useState(null);
  const [cardOpen, setCardOpen] = useState(null);
  const [baseLangs, setBaseLangs] = useState([]);

  const load = useCallback(async (id) => {
    try {
      const [langRes, baseRes] = await Promise.all([
        client.get('/admin/languages'),
        client.get('/admin/base-languages').catch(() => ({ data: [] })),
      ]);
      setLanguages(langRes.data);
      setBaseLangs(baseRes.data || []);
      const lid = id ?? langRes.data[0]?.id;
      setLangId(lid);
      if (lid == null) return;
      const u = await client.get(`/admin/culture-units?language_id=${lid}`);
      setUnits(u.data);
      const allCards = [];
      for (const unit of u.data) {
        const c = await client.get(
          `/admin/culture-cards?culture_unit_id=${unit.id}`,
        );
        allCards.push(...c.data.map((x) => ({ ...x, _unit: unit.id })));
      }
      setCards(allCards);
      setError('');
    } catch (e) {
      setError(apiError(e, 'Failed to load culture content'));
    }
  }, []);

  useEffect(() => {
    load();
  }, [load]);

  const cardsOf = (unitId) => cards.filter((c) => c.culture_unit_id === unitId);

  return (
    <div>
      <PageHeader
        eyebrow="Culture Path"
        title="Culture chapters"
        subtitle="Holidays, coffee, proverbs, food — taught beside the language track with the same XP loop."
        actions={
          <>
            <select
              value={langId ?? ''}
              onChange={(e) => load(Number(e.target.value))}
              className={`${inputCls} mt-0 min-w-[180px]`}
            >
              {languages.map((l) => (
                <option key={l.id} value={l.id}>
                  {l.native_name} ({l.name})
                </option>
              ))}
            </select>
            <Button
              variant="primary"
              onClick={() =>
                setUnitOpen(emptyUnit(langId, units.length))
              }
            >
              New chapter
            </Button>
          </>
        }
      />

      {error && (
        <div className="mt-5">
          <Banner tone="warning">{error}</Banner>
        </div>
      )}

      <div className="mt-5 space-y-4">
        {units.length === 0 ? (
          <EmptyState
            icon="☕"
            title="No culture chapters yet"
            hint="Create a chapter (e.g. Coffee ceremony) then add cards."
          />
        ) : (
          units.map((unit) => (
            <Card
              key={unit.id}
              title={`${unit.title}`}
              description={`${unit.theme} · ${cardsOf(unit.id).length} cards`}
              bodyClass="px-5 py-4 space-y-3"
            >
              <div className="flex flex-wrap gap-2">
                <Badge tone="info">{unit.theme}</Badge>
                {unit.is_active ? (
                  <Badge tone="success" dot>Live</Badge>
                ) : (
                  <Badge tone="neutral">Hidden</Badge>
                )}
                <div className="ml-auto flex gap-2">
                  <Button
                    variant="ghost"
                    onClick={() =>
                      setCardOpen(emptyCard(unit.id, cardsOf(unit.id).length))
                    }
                  >
                    + Card
                  </Button>
                  <Button variant="secondary" onClick={() => setUnitOpen(unit)}>
                    Edit
                  </Button>
                  <Button
                    variant="danger"
                    onClick={async () => {
                      if (!confirm('Delete chapter and its cards?')) return;
                      await client.delete(`/admin/culture-units/${unit.id}`);
                      load(langId);
                    }}
                  >
                    Delete
                  </Button>
                </div>
              </div>
              <ul className="space-y-2">
                {cardsOf(unit.id).map((c) => (
                  <li
                    key={c.id}
                    className="flex items-center gap-3 rounded-xl border border-line-soft px-3 py-2"
                  >
                    <Badge tone="neutral">{c.kind}</Badge>
                    <span className="flex-1 truncate text-[13px] font-semibold">
                      {c.title}
                    </span>
                    <Button
                      variant="ghost"
                      onClick={() => setCardOpen(c)}
                    >
                      Edit
                    </Button>
                    <Button
                      variant="ghost"
                      onClick={async () => {
                        if (!confirm('Delete card?')) return;
                        await client.delete(`/admin/culture-cards/${c.id}`);
                        load(langId);
                      }}
                    >
                      Del
                    </Button>
                  </li>
                ))}
                {cardsOf(unit.id).length === 0 && (
                  <li className="text-[13px] text-muted">No cards yet.</li>
                )}
              </ul>
            </Card>
          ))
        )}
      </div>

      {unitOpen && (
        <UnitEditor
          initial={unitOpen}
          onClose={() => setUnitOpen(null)}
          onSaved={() => {
            setUnitOpen(null);
            load(langId);
          }}
        />
      )}
      {cardOpen && (
        <CardEditor
          initial={cardOpen}
          baseLangs={baseLangs}
          onClose={() => setCardOpen(null)}
          onSaved={() => {
            setCardOpen(null);
            load(langId);
          }}
        />
      )}
    </div>
  );
}

function UnitEditor({ initial, onClose, onSaved }) {
  const [form, setForm] = useState(initial);
  const [err, setErr] = useState('');
  const save = async (e) => {
    e.preventDefault();
    try {
      if (initial.id) await client.put(`/admin/culture-units/${initial.id}`, form);
      else await client.post('/admin/culture-units', form);
      onSaved();
    } catch (ex) {
      setErr(apiError(ex, 'Save failed'));
    }
  };
  return (
    <Modal
      title={initial.id ? 'Edit culture chapter' : 'New culture chapter'}
      onClose={onClose}
      footer={
        <>
          <Button variant="secondary" onClick={onClose}>Cancel</Button>
          <Button variant="primary" type="submit" form="cu-form">Save</Button>
        </>
      }
    >
      <form id="cu-form" onSubmit={save} className="grid gap-3">
        {err && <Banner tone="danger">{err}</Banner>}
        <Field label="Title *">
          <input
            className={inputCls}
            required
            value={form.title}
            onChange={(e) => setForm({ ...form, title: e.target.value })}
            placeholder="ቡና · Coffee ceremony"
          />
        </Field>
        <Field label="Subtitle">
          <input
            className={inputCls}
            value={form.subtitle}
            onChange={(e) => setForm({ ...form, subtitle: e.target.value })}
          />
        </Field>
        <Field label="Theme">
          <select
            className={inputCls}
            value={form.theme}
            onChange={(e) => setForm({ ...form, theme: e.target.value })}
          >
            {THEMES.map((t) => (
              <option key={t} value={t}>{t}</option>
            ))}
          </select>
        </Field>
        <div className="grid grid-cols-2 gap-3">
          <Field label="Sort">
            <input
              type="number"
              className={inputCls}
              value={form.sort_order}
              onChange={(e) =>
                setForm({ ...form, sort_order: Number(e.target.value) })
              }
            />
          </Field>
          <label className="flex items-end gap-2 pb-2 text-sm font-semibold">
            <input
              type="checkbox"
              checked={!!form.is_active}
              onChange={(e) =>
                setForm({ ...form, is_active: e.target.checked ? 1 : 0 })
              }
            />
            Live
          </label>
        </div>
      </form>
    </Modal>
  );
}

function CardEditor({ initial, baseLangs, onClose, onSaved }) {
  const langs = baseLangs.length ? baseLangs : [{ code: 'en', name: 'English' }];
  const [form, setForm] = useState(initial);
  const [active, setActive] = useState('en');
  const [err, setErr] = useState('');
  const content = form.content || {};

  const setLangField = (code, field, value) => {
    const next = { ...content };
    next[code] = { ...(next[code] || {}), [field]: value };
    setForm({ ...form, content: next });
  };

  const save = async (e) => {
    e.preventDefault();
    try {
      const payload = {
        ...form,
        culture_unit_id: form.culture_unit_id,
        content: form.content,
      };
      if (initial.id) await client.put(`/admin/culture-cards/${initial.id}`, payload);
      else await client.post('/admin/culture-cards', payload);
      onSaved();
    } catch (ex) {
      setErr(apiError(ex, 'Save failed'));
    }
  };

  return (
    <Modal
      title={initial.id ? 'Edit culture card' : 'New culture card'}
      onClose={onClose}
      wide
      footer={
        <>
          <Button variant="secondary" onClick={onClose}>Cancel</Button>
          <Button variant="primary" type="submit" form="cc-form">Save</Button>
        </>
      }
    >
      <form id="cc-form" onSubmit={save} className="grid gap-3">
        {err && <Banner tone="danger">{err}</Banner>}
        <div className="grid grid-cols-2 gap-3">
          <Field label="Kind">
            <select
              className={inputCls}
              value={form.kind}
              onChange={(e) => setForm({ ...form, kind: e.target.value })}
            >
              {KINDS.map(([v, n]) => (
                <option key={v} value={v}>{n}</option>
              ))}
            </select>
          </Field>
          <Field label="XP">
            <input
              type="number"
              className={inputCls}
              value={form.xp_reward}
              onChange={(e) =>
                setForm({ ...form, xp_reward: Number(e.target.value) })
              }
            />
          </Field>
        </div>
        <Field label="Title (English fallback) *">
          <input
            className={inputCls}
            required
            value={form.title}
            onChange={(e) => setForm({ ...form, title: e.target.value })}
          />
        </Field>
        <Field label="Body (English fallback)">
          <textarea
            className={`${inputCls} h-24 resize-y`}
            value={form.body}
            onChange={(e) => setForm({ ...form, body: e.target.value })}
          />
        </Field>
        <Field label="Translit">
          <input
            className={inputCls}
            value={form.translit}
            onChange={(e) => setForm({ ...form, translit: e.target.value })}
          />
        </Field>
        <div className="flex flex-wrap gap-2">
          {langs.map((l) => (
            <button
              key={l.code}
              type="button"
              onClick={() => setActive(l.code)}
              className={`rounded-full px-3 py-1.5 text-[12px] font-semibold ${
                active === l.code
                  ? 'bg-et-green text-white'
                  : 'bg-canvas text-muted'
              }`}
            >
              {l.native_name || l.name}
            </button>
          ))}
        </div>
        <Field label={`Title / body in ${active}`}>
          <input
            className={inputCls}
            placeholder="Localized title"
            value={content[active]?.title ?? ''}
            onChange={(e) => setLangField(active, 'title', e.target.value)}
          />
          <textarea
            className={`${inputCls} mt-2 h-20 resize-y`}
            placeholder="Localized body"
            value={content[active]?.body ?? ''}
            onChange={(e) => setLangField(active, 'body', e.target.value)}
          />
        </Field>
        <MediaField
          label="Audio"
          value={form.audio_url}
          onChange={(v) => setForm({ ...form, audio_url: v })}
          accept="audio/*"
        />
        <MediaField
          label="PDF"
          value={form.pdf_url}
          onChange={(v) => setForm({ ...form, pdf_url: v })}
          accept="application/pdf"
        />
      </form>
    </Modal>
  );
}
