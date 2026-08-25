import { useState } from 'react';
import AudioField from './AudioField';

const KINDS = [
  { value: 'mcq', name: 'Multiple choice', desc: 'A prompt with answer options' },
  { value: 'fill', name: 'Fill the blank', desc: 'Sentence with a ___ to complete' },
  { value: 'match', name: 'Match pairs', desc: 'Pair left tiles with right tiles' },
  { value: 'listen', name: 'Tap what you hear', desc: 'Play audio, learner picks the word' },
];

export default function QuestionEditor({ initial, onSave, onClose }) {
  const editing = Boolean(initial?.id);
  const [kind, setKind] = useState(initial?.kind ?? 'mcq');
  const [prompt, setPrompt] = useState(initial?.prompt ?? '');
  const [subPrompt, setSubPrompt] = useState(initial?.sub_prompt ?? '');
  const [hint, setHint] = useState(initial?.hint ?? '');
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
  const [error, setError] = useState('');
  const [saving, setSaving] = useState(false);

  const setOption = (i, v) => setOptions((prev) => prev.map((o, j) => (j === i ? v : o)));
  const addOption = () => setOptions((prev) => [...prev, '']);
  const removeOption = (i) =>
    setOptions((prev) => {
      const next = prev.filter((_, j) => j !== i);
      if (answerIndex >= next.length) setAnswerIndex(next.length - 1);
      else if (answerIndex > i) setAnswerIndex(answerIndex - 1);
      return next;
    });

  const setPair = (i, key, v) =>
    setPairs((prev) => prev.map((p, j) => (j === i ? { ...p, [key]: v } : p)));
  const addPair = () => setPairs((prev) => [...prev, { left: '', right: '' }]);
  const removePair = (i) => setPairs((prev) => prev.filter((_, j) => j !== i));

  const submit = async (e) => {
    e.preventDefault();
    setError('');
    const cleanOptions = options.map((o) => o.trim());
    const cleanPairs = pairs.map((p) => ({ left: p.left.trim(), right: p.right.trim() }));

    if (!prompt.trim()) return setError('Prompt is required.');
    if (kind === 'listen' && !audioUrl.trim()) {
      return setError('Listen questions need audio — record or upload a clip first.');
    }
    if (kind !== 'match') {
      if (cleanOptions.some((o) => !o)) return setError('Every option needs text — remove empty ones.');
      if (cleanOptions.length < 2) return setError('Add at least 2 options.');
      if (kind === 'fill' && !subPrompt.includes('___')) {
        return setError('Fill sentences must contain a ___ blank in the sentence.');
      }
    } else {
      if (cleanPairs.length < 2) return setError('Add at least 2 pairs.');
      if (cleanPairs.some((p) => !p.left || !p.right)) return setError('Every pair needs both sides filled.');
    }

    const usesText = kind === 'mcq' || kind === 'fill';
    const payload = { kind, prompt: prompt.trim(), audio_url: audioUrl.trim() };
    if (kind === 'match') {
      payload.sub_prompt = '';
      payload.hint = '';
      payload.options = null;
      payload.match_left = cleanPairs.map((p) => p.left);
      payload.match_right = cleanPairs.map((p) => p.right);
      payload.answer_index = -1;
    } else {
      payload.sub_prompt = usesText ? subPrompt.trim() : '';
      payload.hint = kind === 'mcq' ? hint.trim() : '';
      payload.match_left = null;
      payload.match_right = null;
      payload.options = cleanOptions;
      payload.answer_index = Math.min(answerIndex, cleanOptions.length - 1);
    }

    setSaving(true);
    try {
      await onSave(payload);
    } catch (err) {
      setError(err.response?.data?.error || 'Save failed.');
      setSaving(false);
    }
  };

  return (
    <div className="fixed inset-0 z-40 flex items-center justify-center bg-black/40 p-4">
      <form
        onSubmit={submit}
        className="max-h-[88vh] w-full max-w-2xl overflow-y-auto rounded-3xl bg-white p-7 shadow-2xl"
      >
        <div className="flex items-center justify-between">
          <h2 className="text-xl font-black">{editing ? 'Edit question' : 'New question'}</h2>
          {editing && (
            <span className={`rounded-full px-3 py-1 text-xs font-black uppercase tracking-wide ${KIND_BADGE[kind]}`}>
              {kind}
            </span>
          )}
        </div>

        {!editing && (
          <div className="mt-4 grid grid-cols-3 gap-2">
            {KINDS.map((k) => (
              <button
                type="button"
                key={k.value}
                onClick={() => setKind(k.value)}
                className={`rounded-xl border px-3 py-2.5 text-left transition ${
                  kind === k.value ? 'border-green-600 bg-green-50' : 'border-stone-200 hover:bg-stone-50'
                }`}
              >
                <div className={`text-sm font-black ${kind === k.value ? 'text-green-700' : 'text-stone-700'}`}>
                  {k.name}
                </div>
                <div className="mt-0.5 text-[11px] leading-tight text-stone-400">{k.desc}</div>
              </button>
            ))}
          </div>
        )}

        <label className="mt-5 block">
          <span className="mb-1 block text-xs font-black uppercase tracking-wider text-stone-400">Prompt *</span>
          <textarea
            rows={2}
            value={prompt}
            onChange={(e) => setPrompt(e.target.value)}
            placeholder="What does ሰላም mean?"
            required
            className="w-full resize-none rounded-xl border border-stone-200 px-3 py-2.5 text-sm outline-none focus:border-green-600"
          />
        </label>

        <AudioField
          label="Pronunciation audio (plays with the prompt)"
          value={audioUrl}
          onChange={setAudioUrl}
        />

        {kind !== 'match' && (
          <>
            {(kind === 'mcq' || kind === 'fill') && (
              <label className="mt-4 block">
                <span className="mb-1 block text-xs font-black uppercase tracking-wider text-stone-400">
                  {kind === 'fill' ? 'Sentence with ___ blank *' : 'Extra line (optional)'}
                </span>
                <input
                  value={subPrompt}
                  onChange={(e) => setSubPrompt(e.target.value)}
                  placeholder={kind === 'fill' ? 'Selam means ___' : 'Shown under the prompt'}
                  className="w-full rounded-xl border border-stone-200 px-3 py-2.5 text-sm outline-none focus:border-green-600"
                />
              </label>
            )}
            {kind === 'mcq' && (
              <label className="mt-4 block">
                <span className="mb-1 block text-xs font-black uppercase tracking-wider text-stone-400">
                  Hint (optional)
                </span>
                <input
                  value={hint}
                  onChange={(e) => setHint(e.target.value)}
                  placeholder="A greeting used any time of day"
                  className="w-full rounded-xl border border-stone-200 px-3 py-2.5 text-sm outline-none focus:border-green-600"
                />
              </label>
            )}

            <div className="mt-5">
              <span className="mb-1.5 block text-xs font-black uppercase tracking-wider text-stone-400">
                {kind === 'listen'
                  ? 'Answer choices — learner taps the word they heard'
                  : 'Options — mark the correct one'}
              </span>
              <div className="space-y-2">
                {options.map((opt, i) => (
                  <div key={i} className="flex items-center gap-2">
                    <input
                      type="radio"
                      name="etlingo-answer"
                      checked={answerIndex === i}
                      onChange={() => setAnswerIndex(i)}
                      className="ml-1 h-4 w-4 shrink-0 accent-green-700"
                      title="Correct answer"
                    />
                    <input
                      value={opt}
                      onChange={(e) => setOption(i, e.target.value)}
                      placeholder={`Option ${i + 1}`}
                      className="flex-1 rounded-xl border border-stone-200 px-3 py-2.5 text-sm outline-none focus:border-green-600"
                    />
                    {options.length > 2 && (
                      <button
                        type="button"
                        onClick={() => removeOption(i)}
                        className="px-1 font-bold text-red-500 hover:text-red-700"
                        title="Remove option"
                      >
                        ✕
                      </button>
                    )}
                  </div>
                ))}
              </div>
              {options.length < 6 && (
                <button
                  type="button"
                  onClick={addOption}
                  className="mt-2 rounded-lg border border-dashed border-stone-300 px-3 py-1.5 text-xs font-bold text-stone-500 hover:bg-stone-50"
                >
                  + Add option
                </button>
              )}
            </div>
          </>
        )}

        {kind === 'match' && (
          <div className="mt-5">
            <span className="mb-1.5 block text-xs font-black uppercase tracking-wider text-stone-400">
              Pairs — row order defines the match
            </span>
            <div className="space-y-2">
              {pairs.map((p, i) => (
                <div key={i} className="flex items-center gap-2">
                  <input
                    value={p.left}
                    onChange={(e) => setPair(i, 'left', e.target.value)}
                    placeholder={`Left ${i + 1} (e.g. ቡና)`}
                    className="flex-1 rounded-xl border border-stone-200 px-3 py-2.5 text-sm outline-none focus:border-green-600"
                  />
                  <span className="text-xs font-black text-stone-300">⇄</span>
                  <input
                    value={p.right}
                    onChange={(e) => setPair(i, 'right', e.target.value)}
                    placeholder={`Right ${i + 1} (e.g. Coffee)`}
                    className="flex-1 rounded-xl border border-stone-200 px-3 py-2.5 text-sm outline-none focus:border-green-600"
                  />
                  {pairs.length > 2 && (
                    <button
                      type="button"
                      onClick={() => removePair(i)}
                      className="px-1 font-bold text-red-500 hover:text-red-700"
                      title="Remove pair"
                    >
                      ✕
                    </button>
                  )}
                </div>
              ))}
            </div>
            <button
              type="button"
              onClick={addPair}
              className="mt-2 rounded-lg border border-dashed border-stone-300 px-3 py-1.5 text-xs font-bold text-stone-500 hover:bg-stone-50"
            >
              + Add pair
            </button>
          </div>
        )}

        {error && (
          <p className="mt-4 rounded-xl border border-red-200 bg-red-50 px-4 py-3 text-sm font-semibold text-red-700">
            ⚠ {error}
          </p>
        )}

        <div className="mt-6 flex gap-3">
          <button
            type="submit"
            disabled={saving}
            className="flex-1 rounded-xl bg-green-700 py-3 text-sm font-black uppercase tracking-wide text-white hover:bg-green-600 disabled:opacity-50"
          >
            {saving ? 'Saving…' : 'Save question'}
          </button>
          <button
            type="button"
            onClick={onClose}
            className="flex-1 rounded-xl border border-stone-300 py-3 text-sm font-black uppercase tracking-wide text-stone-500 hover:bg-stone-50"
          >
            Cancel
          </button>
        </div>
      </form>
    </div>
  );
}

const KIND_BADGE = {
  mcq: 'bg-blue-100 text-blue-700',
  fill: 'bg-amber-100 text-amber-700',
  match: 'bg-purple-100 text-purple-700',
  listen: 'bg-teal-100 text-teal-700',
};
