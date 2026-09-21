import { useState } from 'react';
import AudioField from './AudioField';
import { Button, Field, inputCls, Badge } from './ui';

const KINDS = [
  { value: 'mcq', name: 'Multiple choice', desc: 'Prompt with answer options' },
  { value: 'fill', name: 'Fill the blank', desc: 'Sentence with a ___ to complete' },
  { value: 'match', name: 'Match pairs', desc: 'Pair left tiles with right tiles' },
  { value: 'listen', name: 'Tap what you hear', desc: 'Play audio, learner picks the word' },
];

const DEFAULT_BASE_LANGS = [
  { code: 'en', name: 'English', nativeName: 'English' },
  { code: 'am', name: 'Amharic', nativeName: 'አማርኛ' },
];

const KIND_TONE = {
  mcq: 'info',
  fill: 'warning',
  match: 'neutral',
  listen: 'success',
};

export default function QuestionEditor({
  initial,
  onSave,
  onClose,
  baseLanguages,
  focusBaseLang,
  targetLanguageName,
}) {
  const rawLangs = baseLanguages?.length ? baseLanguages : DEFAULT_BASE_LANGS;
  const langs = [...rawLangs].sort((a, b) => {
    if (a.code === focusBaseLang) return -1;
    if (b.code === focusBaseLang) return 1;
    return 0;
  });
  const labelOf = (l) => l.nativeName || l.native_name || l.name;
  const editing = Boolean(initial?.id);
  const [kind, setKind] = useState(initial?.kind ?? 'mcq');
  const [activeLang, setActiveLang] = useState(focusBaseLang || langs[0]?.code || 'en');
  const [audioUrl, setAudioUrl] = useState(initial?.audio_url ?? '');
  const [options, setOptions] = useState(() => {
    const raw = Array.isArray(initial?.options) ? initial.options : [];
    const labels = raw.map((o) => (typeof o === 'string' ? o : o?.label ?? ''));
    return labels.length ? labels : ['', '', '', ''];
  });
  const [answerIndex, setAnswerIndex] = useState(() => {
    const v = initial?.answer_index;
    return typeof v === 'number' && v >= 0 ? v : 0;
  });
  const [pairs, setPairs] = useState(() => {
    const left = Array.isArray(initial?.match_left) ? initial.match_left : [];
    if (!left.length) return [{ left: '', right: '' }, { left: '', right: '' }];
    const right = Array.isArray(initial?.match_right) ? initial.match_right : [];
    return left.map((l, i) => ({ left: l ?? '', right: right[i] ?? '' }));
  });

  const [content, setContent] = useState(() => {
    const existing = initial?.content;
    const out = {};
    for (const lang of langs) {
      if (existing && typeof existing === 'object') {
        out[lang.code] = {
          prompt: existing[lang.code]?.prompt ?? initial?.prompt ?? '',
          subPrompt: existing[lang.code]?.subPrompt ?? initial?.sub_prompt ?? '',
          hint: existing[lang.code]?.hint ?? initial?.hint ?? '',
        };
      } else {
        out[lang.code] = {
          prompt: initial?.prompt ?? '',
          subPrompt: initial?.sub_prompt ?? '',
          hint: initial?.hint ?? '',
        };
      }
    }
    return out;
  });

  const setLangField = (code, field, value) => {
    setContent((prev) => ({
      ...prev,
      [code]: { ...prev[code], [field]: value },
    }));
  };

  const submit = (e) => {
    e.preventDefault();
    const en = content.en || content[langs[0]?.code] || { prompt: '', subPrompt: '', hint: '' };
    if (!en.prompt || !String(en.prompt).trim()) {
      alert('Please write a prompt (English) before saving.');
      return;
    }
    if (kind === 'listen' && !audioUrl) {
      alert('Listen questions need audio — record or upload a clip first.');
      return;
    }
    const payload = {
      kind,
      prompt: String(en.prompt).trim(),
      sub_prompt: en.subPrompt || '',
      hint: en.hint || '',
      content,
      audio_url: audioUrl,
      options: kind === 'match' ? null : options.filter((o) => o.trim() !== '').map((label) => ({ label })),
      answer_index: kind === 'match' ? -1 : Number(answerIndex),
      match_left: kind === 'match' ? pairs.map((p) => p.left).filter(Boolean) : null,
      match_right: kind === 'match' ? pairs.map((p) => p.right).filter(Boolean) : null,
    };
    if (kind === 'fill' && !(payload.sub_prompt || '').includes('___')) {
      alert('Fill questions need a blank: put ___ in the sub prompt.');
      return;
    }
    if (kind === 'match') {
      const left = payload.match_left || [];
      const right = payload.match_right || [];
      if (left.length < 2 || left.length !== right.length) {
        alert('Match questions need at least 2 pairs, with left and right both filled.');
        return;
      }
    }
    onSave(payload);
  };

  return (
    <form onSubmit={submit} className="space-y-5">
      <div>
        <p className="text-[13px] font-semibold text-ink">Question type</p>
        <div className="mt-2 grid gap-2 sm:grid-cols-2">
          {KINDS.map((k) => (
            <button
              key={k.value}
              type="button"
              disabled={editing}
              onClick={() => setKind(k.value)}
              className={`rounded-xl border px-3.5 py-3 text-left transition ${
                kind === k.value
                  ? 'border-et-green bg-et-green-soft'
                  : 'border-line-soft bg-panel hover:border-et-green/40'
              } ${editing ? 'opacity-60' : ''}`}
            >
              <div className="flex items-center justify-between gap-2">
                <span className="text-[14px] font-semibold text-ink">{k.name}</span>
                <Badge tone={KIND_TONE[k.value] || 'neutral'}>{k.value}</Badge>
              </div>
              <p className="mt-0.5 text-[12px] text-muted">{k.desc}</p>
            </button>
          ))}
        </div>
        {editing && (
          <p className="mt-2 text-[12px] text-muted">Type cannot be changed after create.</p>
        )}
      </div>

      <div>
        <div className="flex flex-wrap items-center gap-2">
          <span className="text-[12px] font-semibold text-muted">Explain in:</span>
          {langs.map((l) => (
            <button
              key={l.code}
              type="button"
              onClick={() => setActiveLang(l.code)}
              className={`rounded-full px-3 py-1.5 text-[12px] font-semibold transition ${
                activeLang === l.code
                  ? 'bg-et-green text-white'
                  : l.code === focusBaseLang
                    ? 'bg-et-green-soft text-et-green-dark ring-1 ring-et-green/30'
                    : 'bg-canvas text-muted hover:text-ink'
              }`}
            >
              {labelOf(l)}
              {l.code === focusBaseLang ? ' · focus' : ''}
            </button>
          ))}
        </div>
        <p className="mt-2 text-[12px] text-muted">
          Writing prompts for <strong>{targetLanguageName || 'target course'}</strong> explained in{' '}
          <strong>{labelOf(langs.find((l) => l.code === activeLang) || langs[0])}</strong>.
          Answer options are usually the {targetLanguageName || 'target'} words learners study.
        </p>
        <div className="mt-3 grid gap-3">
          <Field label={`Prompt * (${activeLang})`}>
            <input
              className={`${inputCls} ${activeLang !== 'en' ? 'font-ethiopic' : ''}`}
              value={content[activeLang]?.prompt ?? ''}
              onChange={(e) => setLangField(activeLang, 'prompt', e.target.value)}
              placeholder={
                activeLang === 'so'
                  ? 'Kee macnihiisu yahay "Hello"?'
                  : activeLang === 'am'
                    ? 'Hello ማለት ምንድን ነው?'
                    : `Which one means Hello — for ${targetLanguageName || 'learners'}?`
              }
            />
          </Field>
          {(kind === 'mcq' || kind === 'fill') && (
            <Field
              label="Sub prompt"
              hint={kind === 'fill' ? 'Must contain ___ for the blank' : 'Optional large text (word under study)'}
            >
              <input
                className={`${inputCls} ${activeLang === 'am' ? 'font-ethiopic' : ''}`}
                value={content[activeLang]?.subPrompt ?? ''}
                onChange={(e) => setLangField(activeLang, 'subPrompt', e.target.value)}
                placeholder={kind === 'fill' ? 'Thank you → ___' : 'ሰላም'}
              />
            </Field>
          )}
          {kind === 'mcq' && (
            <Field label="Hint">
              <input
                className={inputCls}
                value={content[activeLang]?.hint ?? ''}
                onChange={(e) => setLangField(activeLang, 'hint', e.target.value)}
                placeholder="se·lam"
              />
            </Field>
          )}
        </div>
      </div>

      {kind !== 'match' && (
        <div>
          <div className="flex items-center justify-between">
            <p className="text-[13px] font-semibold text-ink">Answer options</p>
            <Button
              type="button"
              variant="ghost"
              onClick={() => setOptions((o) => (o.length >= 6 ? o : [...o, '']))}
              disabled={options.length >= 6}
            >
              + Option
            </Button>
          </div>
          <div className="mt-2 space-y-2">
            {options.map((opt, i) => (
              <div key={i} className="flex items-center gap-2">
                <input
                  type="radio"
                  name="answer"
                  checked={answerIndex === i}
                  onChange={() => setAnswerIndex(i)}
                  className="h-4 w-4 accent-et-green"
                  title="Correct answer"
                />
                <input
                  className={inputCls}
                  value={opt}
                  placeholder={`Option ${i + 1}`}
                  onChange={(e) => {
                    const next = [...options];
                    next[i] = e.target.value;
                    setOptions(next);
                  }}
                />
                {options.length > 2 && (
                  <Button
                    type="button"
                    variant="ghost"
                    onClick={() => {
                      const next = options.filter((_, idx) => idx !== i);
                      setOptions(next);
                      if (answerIndex >= next.length) setAnswerIndex(0);
                    }}
                  >
                    ✕
                  </Button>
                )}
              </div>
            ))}
          </div>
        </div>
      )}

      {kind === 'match' && (
        <div>
          <div className="flex items-center justify-between">
            <p className="text-[13px] font-semibold text-ink">Match pairs</p>
            <Button
              type="button"
              variant="ghost"
              onClick={() => setPairs((p) => [...p, { left: '', right: '' }])}
            >
              + Pair
            </Button>
          </div>
          <div className="mt-2 space-y-2">
            {pairs.map((p, i) => (
              <div key={i} className="grid grid-cols-[1fr_1fr_auto] items-center gap-2">
                <input
                  className={`${inputCls} font-ethiopic`}
                  value={p.left}
                  placeholder="ሰላም"
                  onChange={(e) => {
                    const next = [...pairs];
                    next[i] = { ...next[i], left: e.target.value };
                    setPairs(next);
                  }}
                />
                <input
                  className={inputCls}
                  value={p.right}
                  placeholder="Hello"
                  onChange={(e) => {
                    const next = [...pairs];
                    next[i] = { ...next[i], right: e.target.value };
                    setPairs(next);
                  }}
                />
                {pairs.length > 2 && (
                  <Button
                    type="button"
                    variant="ghost"
                    onClick={() => setPairs(pairs.filter((_, idx) => idx !== i))}
                  >
                    ✕
                  </Button>
                )}
              </div>
            ))}
          </div>
        </div>
      )}

      {(kind === 'listen' || audioUrl) && (
        <AudioField label={kind === 'listen' ? 'Audio (required for listen)' : 'Audio'} value={audioUrl} onChange={setAudioUrl} />
      )}

      <div className="flex justify-end gap-2 border-t border-line-soft pt-4">
        <Button type="button" variant="secondary" onClick={onClose}>
          Cancel
        </Button>
        <Button type="submit" variant="primary">
          {editing ? 'Save question' : 'Add question'}
        </Button>
      </div>
    </form>
  );
}
