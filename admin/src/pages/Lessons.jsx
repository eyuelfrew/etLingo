import { useCallback, useEffect, useState } from 'react';
import client from '../api/client';
import QuestionEditor from '../components/QuestionEditor';

const ICONS = {
  waving_hand_rounded: '👋',
  menu_book_rounded: '📖',
  school_rounded: '🎓',
  sailing_rounded: '⛵',
  coffee_rounded: '☕',
  music_note_rounded: '🎵',
  landscape_rounded: '🏞️',
  flag_rounded: '🚩',
  star_rounded: '⭐',
  chat_bubble_rounded: '💬',
  restaurant_rounded: '🍽️',
  home_rounded: '🏠',
  shopping_bag_rounded: '🛍️',
  directions_bus_rounded: '🚌',
  favorite_rounded: '❤️',
};

const KIND_BADGE = {
  mcq: 'bg-blue-100 text-blue-700',
  fill: 'bg-amber-100 text-amber-700',
  match: 'bg-purple-100 text-purple-700',
  listen: 'bg-teal-100 text-teal-700',
};

const emptyUnit = (sort) => ({
  title: '',
  subtitle: '',
  color_hex: '#078930',
  dark_hex: '#056B24',
  icon: 'waving_hand_rounded',
  sort_order: sort,
});

const emptyLesson = (sort) => ({ title: '', is_boss: false, xp_reward: 10, sort_order: sort });

export default function Lessons() {
  const [languages, setLanguages] = useState([]);
  const [lang, setLang] = useState(null);
  const [units, setUnits] = useState([]);
  const [lessons, setLessons] = useState([]);
  const [questions, setQuestions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [expanded, setExpanded] = useState(null);

  const [unitForm, setUnitForm] = useState(null);
  const [unitEditingId, setUnitEditingId] = useState(null);
  const [lessonCtx, setLessonCtx] = useState(null);
  const [lessonEditingId, setLessonEditingId] = useState(null);
  const [questionCtx, setQuestionCtx] = useState(null);

  useEffect(() => {
    client
      .get('/admin/languages')
      .then(({ data }) => {
        setLanguages(data);
        if (data.length) setLang(data[0]);
        else setLoading(false);
      })
      .catch((e) => {
        setError(e.response?.data?.error || 'Failed to load. Is MySQL initialized?');
        setLoading(false);
      });
  }, []);

  const loadTree = useCallback(async () => {
    if (!lang) return;
    try {
      const [{ data: unitRows }, { data: lessonRows }, { data: questionRows }] = await Promise.all([
        client.get(`/admin/units?language_id=${lang.id}`),
        client.get('/admin/lessons'),
        client.get('/admin/questions'),
      ]);
      const unitIds = new Set(unitRows.map((u) => u.id));
      const myLessons = lessonRows.filter((l) => unitIds.has(l.unit_id));
      const lessonIds = new Set(myLessons.map((l) => l.id));
      setUnits(unitRows);
      setLessons(myLessons);
      setQuestions(questionRows.filter((q) => lessonIds.has(q.lesson_id)));
      setError('');
    } catch {
      setError('Failed to load the course tree.');
    } finally {
      setLoading(false);
    }
  }, [lang]);

  useEffect(() => {
    loadTree();
  }, [loadTree]);

  const questionsOf = (lessonId) => questions.filter((q) => q.lesson_id === lessonId);
  const lessonsOf = (unitId) => lessons.filter((l) => l.unit_id === unitId);

  const saveUnit = async (e) => {
    e.preventDefault();
    try {
      const body = { ...unitForm, language_id: lang.id };
      if (unitEditingId) await client.put(`/admin/units/${unitEditingId}`, body);
      else await client.post('/admin/units', body);
      setUnitForm(null);
      setUnitEditingId(null);
      loadTree();
    } catch (err) {
      setError(err.response?.data?.error || 'Save failed');
    }
  };

  const removeUnit = async (unit) => {
    const n = lessonsOf(unit.id).length;
    if (!confirm(`Delete "${unit.title}"${n ? ` and its ${n} lesson(s) with all their questions` : ''}?`)) return;
    await client.delete(`/admin/units/${unit.id}`);
    if (expanded && !lessonsOf(unit.id).some((l) => l.id === expanded)) setExpanded(null);
    loadTree();
  };

  const saveLesson = async (e) => {
    e.preventDefault();
    try {
      const body = {
        title: lessonCtx.title,
        is_boss: !!lessonCtx.is_boss,
        xp_reward: Number(lessonCtx.xp_reward) || 10,
        sort_order: Number(lessonCtx.sort_order) || 0,
        unit_id: lessonCtx.unitId,
      };
      if (lessonEditingId) await client.put(`/admin/lessons/${lessonEditingId}`, body);
      else await client.post('/admin/lessons', body);
      setLessonCtx(null);
      setLessonEditingId(null);
      loadTree();
    } catch (err) {
      setError(err.response?.data?.error || 'Save failed');
    }
  };

  const removeLesson = async (lesson) => {
    const n = questionsOf(lesson.id).length;
    if (!confirm(`Delete "${lesson.title}"${n ? ` and its ${n} question(s)` : ''}?`)) return;
    await client.delete(`/admin/lessons/${lesson.id}`);
    if (expanded === lesson.id) setExpanded(null);
    loadTree();
  };

  const saveQuestion = async (payload) => {
    const existing = questionCtx.row;
    const body = {
      ...payload,
      lesson_id: questionCtx.lessonId,
      sort_order: existing ? existing.sort_order : questionsOf(questionCtx.lessonId).length,
    };
    if (existing) await client.put(`/admin/questions/${existing.id}`, body);
    else await client.post('/admin/questions', body);
    setQuestionCtx(null);
    loadTree();
  };

  const removeQuestion = async (q) => {
    if (!confirm('Delete this question?')) return;
    await client.delete(`/admin/questions/${q.id}`);
    loadTree();
  };

  return (
    <div>
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-black">Course editor</h1>
          <p className="mt-1 text-sm font-medium text-stone-500">
            Build units, lessons and quiz questions served to the app
          </p>
        </div>
        <div className="flex items-center gap-3">
          <select
            value={lang?.id ?? ''}
            onChange={(e) => {
              setExpanded(null);
              setLang(languages.find((l) => String(l.id) === e.target.value));
            }}
            className="rounded-xl border border-stone-200 bg-white px-4 py-2.5 text-sm font-bold outline-none focus:border-green-600"
          >
            {languages.map((l) => (
              <option key={l.id} value={l.id}>
                {l.native_name} ({l.name})
              </option>
            ))}
          </select>
          {lang && (
            <button
              onClick={() => {
                setUnitEditingId(null);
                setUnitForm(emptyUnit(units.length));
              }}
              className="rounded-xl bg-green-700 px-5 py-2.5 text-sm font-black uppercase tracking-wide text-white shadow hover:bg-green-600"
            >
              + New unit
            </button>
          )}
        </div>
      </div>

      {error && (
        <p className="mt-4 rounded-xl border border-amber-300 bg-amber-50 px-4 py-3 text-sm font-semibold text-amber-800">
          ⚠ {error}
        </p>
      )}

      {loading && <p className="mt-6 text-center text-sm font-semibold text-stone-400">Loading…</p>}

      {!loading && !languages.length && (
        <p className="mt-6 rounded-2xl border border-stone-200 bg-white px-5 py-8 text-center text-sm font-semibold text-stone-400 shadow-sm">
          Add a language first — then build its course here.
        </p>
      )}

      {!loading && lang && (
        <>
          <div className="mt-4 flex gap-2 text-xs font-bold text-stone-500">
            <span className="rounded-full bg-green-100 px-3 py-1 text-green-700">{units.length} units</span>
            <span className="rounded-full bg-blue-100 px-3 py-1 text-blue-700">{lessons.length} lessons</span>
            <span className="rounded-full bg-purple-100 px-3 py-1 text-purple-700">{questions.length} questions</span>
          </div>

          <div className="mt-4 space-y-4">
            {units.map((unit) => {
              const unitLessons = lessonsOf(unit.id);
              return (
                <div key={unit.id} className="overflow-hidden rounded-2xl border border-stone-200 bg-white shadow-sm">
                  <div
                    className="flex flex-wrap items-center justify-between gap-3 px-5 py-4 text-white"
                    style={{ background: `linear-gradient(135deg, ${unit.color_hex}, ${unit.dark_hex})` }}
                  >
                    <div className="flex items-center gap-3">
                      <span className="text-lg">{ICONS[unit.icon] || '📘'}</span>
                      <div>
                        <div className="font-black">{unit.title}</div>
                        <div className="text-xs opacity-80">{unit.subtitle}</div>
                      </div>
                    </div>
                    <div className="flex gap-2 text-xs font-black uppercase tracking-wide">
                      <button
                        onClick={() => {
                          setUnitEditingId(unit.id);
                          setUnitForm({ ...emptyUnit(unit.sort_order), ...unit });
                        }}
                        className="rounded-lg bg-white/20 px-3 py-1.5 hover:bg-white/30"
                      >
                        Edit
                      </button>
                      <button
                        onClick={() => removeUnit(unit)}
                        className="rounded-lg bg-black/20 px-3 py-1.5 hover:bg-black/30"
                      >
                        Delete
                      </button>
                    </div>
                  </div>

                  <ul className="divide-y divide-stone-100">
                    {unitLessons.map((lesson) => {
                      const qs = questionsOf(lesson.id);
                      const open = expanded === lesson.id;
                      return (
                        <li key={lesson.id}>
                          <div className="flex flex-wrap items-center justify-between gap-2 px-5 py-3 text-sm">
                            <div className="flex items-center gap-2">
                              <button
                                onClick={() => setExpanded(open ? null : lesson.id)}
                                className={`flex h-7 w-7 items-center justify-center rounded-full text-xs font-black transition ${
                                  open ? 'bg-green-700 text-white' : 'bg-stone-100 text-stone-500 hover:bg-stone-200'
                                }`}
                                title={open ? 'Hide questions' : 'Show questions'}
                              >
                                {open ? '▾' : '▸'}
                              </button>
                              <span className="font-bold">
                                {lesson.is_boss && '👑 '}
                                {lesson.title}
                              </span>
                              <span className="rounded-full bg-stone-100 px-2.5 py-1 text-xs font-bold text-stone-500">
                                {qs.length} Q · {lesson.xp_reward} XP
                              </span>
                            </div>
                            <div className="whitespace-nowrap">
                              <button
                                onClick={() => {
                                  setQuestionCtx({ lessonId: lesson.id, row: null });
                                  if (!open) setExpanded(lesson.id);
                                }}
                                className="mr-3 font-bold text-green-700 hover:underline"
                              >
                                + Question
                              </button>
                              <button
                                onClick={() => {
                                  setLessonEditingId(lesson.id);
                                  setLessonCtx({
                                    unitId: unit.id,
                                    title: lesson.title,
                                    is_boss: lesson.is_boss,
                                    xp_reward: lesson.xp_reward,
                                    sort_order: lesson.sort_order,
                                  });
                                }}
                                className="mr-2 font-bold text-blue-700 hover:underline"
                              >
                                Edit
                              </button>
                              <button onClick={() => removeLesson(lesson)} className="font-bold text-red-600 hover:underline">
                                Delete
                              </button>
                            </div>
                          </div>

                          {open && (
                            <div className="space-y-2 border-t border-stone-100 bg-stone-50/70 px-5 py-4">
                              {qs.map((q) => (
                                <div
                                  key={q.id}
                                  className="flex items-center justify-between gap-3 rounded-xl border border-stone-200 bg-white px-4 py-2.5"
                                >
                                  <div className="min-w-0">
                                    <span
                                      className={`mr-2 rounded-full px-2 py-0.5 text-[10px] font-black uppercase tracking-wide ${KIND_BADGE[q.kind]}`}
                                    >
                                      {q.kind}
                                    </span>
                                    <span className="truncate text-sm font-semibold">{q.prompt}</span>
                                  </div>
                                  <div className="shrink-0 whitespace-nowrap">
                                    <button
                                      onClick={() => setQuestionCtx({ lessonId: lesson.id, row: q })}
                                      className="mr-2 font-bold text-blue-700 hover:underline"
                                    >
                                      Edit
                                    </button>
                                    <button onClick={() => removeQuestion(q)} className="font-bold text-red-600 hover:underline">
                                      Delete
                                    </button>
                                  </div>
                                </div>
                              ))}
                              {!qs.length && (
                                <p className="py-2 text-center text-xs font-semibold text-stone-400">
                                  No questions yet — add the first one.
                                </p>
                              )}
                              <button
                                onClick={() => setQuestionCtx({ lessonId: lesson.id, row: null })}
                                className="w-full rounded-xl border border-dashed border-stone-300 py-2 text-xs font-bold uppercase tracking-wide text-stone-500 hover:bg-white"
                              >
                                + Add question
                              </button>
                            </div>
                          )}
                        </li>
                      );
                    })}
                    {!unitLessons.length && (
                      <li className="px-5 py-6 text-center text-xs font-semibold text-stone-400">No lessons yet</li>
                    )}
                  </ul>

                  <div className="border-t border-stone-100 px-5 py-3">
                    <button
                      onClick={() => {
                        setLessonEditingId(null);
                        setLessonCtx({ unitId: unit.id, ...emptyLesson(unitLessons.length) });
                      }}
                      className="text-xs font-black uppercase tracking-wide text-green-700 hover:underline"
                    >
                      + Add lesson
                    </button>
                  </div>
                </div>
              );
            })}

            {!units.length && (
              <p className="rounded-2xl border border-stone-200 bg-white px-5 py-8 text-center text-sm font-semibold text-stone-400 shadow-sm">
                No units yet — click “+ New unit” to start building the course.
              </p>
            )}
          </div>
        </>
      )}

      {unitForm && (
        <div className="fixed inset-0 z-40 flex items-center justify-center bg-black/40 p-4">
          <form onSubmit={saveUnit} className="max-h-[85vh] w-full max-w-lg overflow-y-auto rounded-3xl bg-white p-7 shadow-2xl">
            <h2 className="text-xl font-black">{unitEditingId ? 'Edit unit' : 'New unit'}</h2>
            <div className="mt-5 grid grid-cols-2 gap-4">
              <Field label="Title *" value={unitForm.title} onChange={(v) => setUnitForm({ ...unitForm, title: v })} placeholder="Greetings" required />
              <Field label="Subtitle" value={unitForm.subtitle} onChange={(v) => setUnitForm({ ...unitForm, subtitle: v })} placeholder="First words & hellos" />
              <ColorField label="Color" value={unitForm.color_hex} onChange={(v) => setUnitForm({ ...unitForm, color_hex: v })} />
              <ColorField label="Dark color" value={unitForm.dark_hex} onChange={(v) => setUnitForm({ ...unitForm, dark_hex: v })} />
              <Field label="Sort order" type="number" value={unitForm.sort_order} onChange={(v) => setUnitForm({ ...unitForm, sort_order: Number(v) })} />
            </div>
            <div className="mt-4">
              <span className="mb-1.5 block text-xs font-black uppercase tracking-wider text-stone-400">Icon</span>
              <div className="flex flex-wrap gap-1.5">
                {Object.entries(ICONS).map(([name, emoji]) => (
                  <button
                    type="button"
                    key={name}
                    title={name.replaceAll('_', ' ')}
                    onClick={() => setUnitForm({ ...unitForm, icon: name })}
                    className={`h-10 w-10 rounded-xl border text-lg transition ${
                      unitForm.icon === name ? 'border-green-600 bg-green-50' : 'border-stone-200 hover:bg-stone-50'
                    }`}
                  >
                    {emoji}
                  </button>
                ))}
              </div>
            </div>
            <ModalActions onCancel={() => setUnitForm(null)} label="Save unit" />
          </form>
        </div>
      )}

      {lessonCtx && (
        <div className="fixed inset-0 z-40 flex items-center justify-center bg-black/40 p-4">
          <form onSubmit={saveLesson} className="w-full max-w-md rounded-3xl bg-white p-7 shadow-2xl">
            <h2 className="text-xl font-black">{lessonEditingId ? 'Edit lesson' : 'New lesson'}</h2>
            <div className="mt-5 space-y-4">
              <Field label="Title *" value={lessonCtx.title} onChange={(v) => setLessonCtx({ ...lessonCtx, title: v })} placeholder="Say hello" required />
              <div className="grid grid-cols-2 gap-4">
                <Field label="XP reward" type="number" value={lessonCtx.xp_reward} onChange={(v) => setLessonCtx({ ...lessonCtx, xp_reward: v })} />
                <Field label="Sort order" type="number" value={lessonCtx.sort_order} onChange={(v) => setLessonCtx({ ...lessonCtx, sort_order: v })} />
              </div>
              <label className="flex items-center gap-2 text-sm font-semibold">
                <input
                  type="checkbox"
                  checked={!!lessonCtx.is_boss}
                  onChange={(e) => setLessonCtx({ ...lessonCtx, is_boss: e.target.checked })}
                />
                👑 Boss lesson (unit review)
              </label>
            </div>
            <ModalActions onCancel={() => setLessonCtx(null)} label="Save lesson" />
          </form>
        </div>
      )}

      {questionCtx && (
        <QuestionEditor
          initial={questionCtx.row}
          onSave={saveQuestion}
          onClose={() => setQuestionCtx(null)}
        />
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

function ModalActions({ onCancel, label }) {
  return (
    <div className="mt-6 flex gap-3">
      <button type="submit" className="flex-1 rounded-xl bg-green-700 py-3 text-sm font-black uppercase tracking-wide text-white hover:bg-green-600">
        {label}
      </button>
      <button type="button" onClick={onCancel} className="flex-1 rounded-xl border border-stone-300 py-3 text-sm font-black uppercase tracking-wide text-stone-500 hover:bg-stone-50">
        Cancel
      </button>
    </div>
  );
}
