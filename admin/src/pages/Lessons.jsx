import { useCallback, useEffect, useState } from 'react';
import client, { apiError } from '../api/client';
import QuestionEditor from '../components/QuestionEditor';
import MediaField, { resolveMediaUrl as resolveStorageUrl } from '../components/MediaField';
import AudioField, { resolveAudioUrl } from '../components/AudioField';
import { PageHeader, Badge, Button, Banner } from '../components/ui';

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
  mcq: 'bg-et-blue/10 text-et-blue',
  fill: 'bg-amber-100 text-amber-700',
  match: 'bg-et-green-soft text-et-green-dark',
  listen: 'bg-et-green-soft text-et-green-dark',
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
  const [baseLangs, setBaseLangs] = useState([]);
  const [baseLangCode, setBaseLangCode] = useState(() => localStorage.getItem('etlingo_author_base') || 'so');
  const [units, setUnits] = useState([]);
  const [lessons, setLessons] = useState([]);
  const [questions, setQuestions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [expanded, setExpanded] = useState(null);

  const [unitForm, setUnitForm] = useState(null);
  const [unitEditingId, setUnitEditingId] = useState(null);
  const [unitTeachCtx, setUnitTeachCtx] = useState(null);
  const [lessonCtx, setLessonCtx] = useState(null);
  const [lessonEditingId, setLessonEditingId] = useState(null);
  const [resourceCtx, setResourceCtx] = useState(null);
  const [questionCtx, setQuestionCtx] = useState(null);
  const [teachCtx, setTeachCtx] = useState(null);

  const activeBaseLang = baseLangs.find((b) => b.code === baseLangCode) || baseLangs[0];
  const activeBaseLabel = activeBaseLang
    ? `${activeBaseLang.native_name || activeBaseLang.name} (${activeBaseLang.code})`
    : baseLangCode;

  const setAuthorBase = (code) => {
    setBaseLangCode(code);
    localStorage.setItem('etlingo_author_base', code);
  };

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
    client.get('/admin/base-languages').then(({ data }) => {
      setBaseLangs(data);
      if (data.length && !data.some((b) => b.code === localStorage.getItem('etlingo_author_base'))) {
        // keep stored code if still valid; otherwise fall back
      }
      if (data.length) {
        const stored = localStorage.getItem('etlingo_author_base');
        if (!stored || !data.some((b) => b.code === stored)) {
          const so = data.find((b) => b.code === 'so');
          setAuthorBase(so ? so.code : data[0].code);
        }
      }
    }).catch(() => {});
  }, []);

  // Refresh base-language tabs when returning from that admin page (same tab SPA keeps state).
  useEffect(() => {
    const onFocus = () => {
      client.get('/admin/base-languages').then(({ data }) => setBaseLangs(data)).catch(() => {});
    };
    window.addEventListener('focus', onFocus);
    return () => window.removeEventListener('focus', onFocus);
  }, []);

  const loadTree = useCallback(async () => {
    if (!lang) return;
    try {
      const [{ data: unitRows }, { data: lessonRows }, { data: questionRows }] = await Promise.all([
        client.get(`/admin/units?language_id=${Number(lang.id)}`),
        client.get('/admin/lessons'),
        client.get('/admin/questions'),
      ]);
      const unitIds = new Set(unitRows.map((u) => Number(u.id)));
      const myLessons = lessonRows.filter((l) => unitIds.has(Number(l.unit_id)));
      const lessonIds = new Set(myLessons.map((l) => Number(l.id)));
      setUnits(unitRows);
      setLessons(myLessons);
      setQuestions(questionRows.filter((q) => lessonIds.has(Number(q.lesson_id))));
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

  const questionsOf = (lessonId) => {
    const id = Number(lessonId);
    return questions.filter((q) => Number(q.lesson_id) === id);
  };
  const lessonsOf = (unitId) => {
    const id = Number(unitId);
    return lessons.filter((l) => Number(l.unit_id) === id);
  };
  const teachItemsOf = (lesson) => {
    try {
      if (Array.isArray(lesson.teach_content)) return lesson.teach_content;
      if (typeof lesson.teach_content === 'string' && lesson.teach_content) return JSON.parse(lesson.teach_content);
    } catch { /* ignore */ }
    return [];
  };
  const unitTeachItemsOf = (unit) => {
    try {
      if (Array.isArray(unit.teach_content)) return unit.teach_content;
      if (typeof unit.teach_content === 'string' && unit.teach_content) return JSON.parse(unit.teach_content);
    } catch { /* ignore */ }
    return [];
  };

  const resourcesOf = (lesson) => {
    try {
      if (Array.isArray(lesson.resources)) return lesson.resources;
      if (typeof lesson.resources === 'string' && lesson.resources) return JSON.parse(lesson.resources);
    } catch { /* ignore */ }
    return [];
  };

  const saveLessonResources = async (lessonId, resources) => {
    try {
      await client.put(`/admin/lessons/${lessonId}`, { resources });
      setResourceCtx(null);
      setError('');
      await loadTree();
    } catch (err) {
      setError(apiError(err, 'Could not save lesson files'));
    }
  };

  /** Does this row already have instruction-language text for the selected base? */
  const hasBase = (contentLike, code) => {
    if (!contentLike || !code) return false;
    if (Array.isArray(contentLike)) {
      return contentLike.some((item) => {
        const m = item?.meanings;
        return !!(m && typeof m === 'object' && String(m[code] || '').trim());
      });
    }
    if (typeof contentLike === 'string') {
      try {
        return hasBase(JSON.parse(contentLike), code);
      } catch {
        return false;
      }
    }
    if (typeof contentLike === 'object') {
      const node = contentLike[code];
      if (node && typeof node === 'object') {
        return !!(
          String(node.prompt || '').trim() ||
          String(node.subPrompt || node.sub_prompt || '').trim() ||
          String(node.hint || '').trim() ||
          String(node.meaning || '').trim()
        );
      }
      // teach item-style
      if (contentLike.meanings && typeof contentLike.meanings === 'object') {
        return !!String(contentLike.meanings[code] || '').trim();
      }
      if (typeof contentLike.prompt === 'string') {
        return code === 'en' && !!contentLike.prompt.trim();
      }
    }
    return false;
  };

  const BaseStatus = ({ ok }) => (
    <span
      className={`ml-1.5 rounded-full px-1.5 py-0.5 text-[10px] font-bold ${
        ok ? 'bg-et-green-soft text-et-green-dark' : 'bg-et-yellow/20 text-et-yellow-dark'
      }`}
      title={ok ? `Has ${baseLangCode} text` : `Missing ${baseLangCode} — open editor`}
    >
      {baseLangCode} {ok ? '✓' : '…'}
    </span>
  );

  const saveUnitTeachContent = async (unitId, items) => {
    try {
      await client.put(`/admin/units/${unitId}`, { teach_content: items });
      setUnitTeachCtx(null);
      setError('');
      await loadTree();
    } catch (err) {
      setError(apiError(err, 'Could not save unit vocabulary'));
    }
  };

  const saveUnit = async (e) => {
    e.preventDefault();
    try {
      const body = {
        ...unitForm,
        language_id: Number(lang.id),
        sort_order: Number(unitForm.sort_order) || 0,
      };
      if (unitEditingId) await client.put(`/admin/units/${unitEditingId}`, body);
      else await client.post('/admin/units', body);
      setUnitForm(null);
      setUnitEditingId(null);
      setError('');
      await loadTree();
    } catch (err) {
      setError(apiError(err, 'Could not save unit'));
    }
  };

  const removeUnit = async (unit) => {
    const n = lessonsOf(unit.id).length;
    if (!confirm(`Delete "${unit.title}"${n ? ` and its ${n} lesson(s) with all their questions` : ''}?`)) return;
    try {
      await client.delete(`/admin/units/${unit.id}`);
      if (expanded && !lessonsOf(unit.id).some((l) => l.id === expanded)) setExpanded(null);
      setError('');
      await loadTree();
    } catch (err) {
      setError(apiError(err, 'Could not delete unit'));
    }
  };

  const saveLesson = async (e) => {
    e.preventDefault();
    try {
      const body = {
        title: String(lessonCtx.title || '').trim(),
        is_boss: !!lessonCtx.is_boss,
        xp_reward: Number(lessonCtx.xp_reward) || 10,
        sort_order: Number(lessonCtx.sort_order) || 0,
        unit_id: Number(lessonCtx.unitId),
      };
      if (!body.title) {
        setError('Lesson title is required.');
        return;
      }
      if (lessonEditingId) await client.put(`/admin/lessons/${lessonEditingId}`, body);
      else await client.post('/admin/lessons', body);
      setLessonCtx(null);
      setLessonEditingId(null);
      setError('');
      await loadTree();
    } catch (err) {
      setError(apiError(err, 'Could not save lesson'));
    }
  };

  const removeLesson = async (lesson) => {
    const n = questionsOf(lesson.id).length;
    if (!confirm(`Delete "${lesson.title}"${n ? ` and its ${n} question(s)` : ''}?`)) return;
    try {
      await client.delete(`/admin/lessons/${lesson.id}`);
      if (expanded === lesson.id) setExpanded(null);
      setError('');
      await loadTree();
    } catch (err) {
      setError(apiError(err, 'Could not delete lesson'));
    }
  };

  const saveQuestion = async (payload) => {
    try {
      const existing = questionCtx.row;
      const lessonId = Number(questionCtx.lessonId);
      const body = {
        ...payload,
        lesson_id: lessonId,
        sort_order: existing
          ? existing.sort_order
          : questionsOf(lessonId).length,
      };
      if (!body.prompt || !String(body.prompt).trim()) {
        setError('Prompt is required — write what the learner should answer.');
        return;
      }
      if (payload.kind === 'listen' && !payload.audio_url) {
        setError('Listen questions need an audio file — record or upload one first.');
        return;
      }
      if (payload.kind !== 'match') {
        const opts = body.options || [];
        if (opts.length < 2) {
          setError('Add at least two answer options.');
          return;
        }
      }
      if (existing) await client.put(`/admin/questions/${existing.id}`, body);
      else await client.post('/admin/questions', body);
      setQuestionCtx(null);
      setError('');
      if (!expanded) setExpanded(lessonId);
      await loadTree();
    } catch (err) {
      setError(apiError(err, 'Could not save question — check the browser console and backend logs.'));
    }
  };

  const removeQuestion = async (q) => {
    if (!confirm('Delete this question?')) return;
    try {
      await client.delete(`/admin/questions/${q.id}`);
      setError('');
      await loadTree();
    } catch (err) {
      setError(apiError(err, 'Could not delete question'));
    }
  };

  const saveTeachContent = async (lessonId, items) => {
    try {
      await client.put(`/admin/lessons/${lessonId}`, { teach_content: items });
      setTeachCtx(null);
      setError('');
      await loadTree();
    } catch (err) {
      setError(apiError(err, 'Could not save teach content'));
    }
  };

  return (
    <div>
      <PageHeader
        eyebrow="Learning content"
        title="Course editor"
        subtitle="Pick the language to teach, then the language used to explain it. Write vocabulary and questions for that pair."
      />

      <div className="mt-5 rounded-2xl border border-line-soft bg-panel p-5 shadow-[0_1px_0_rgba(26,20,14,0.03)]">
        <div className="grid gap-4 md:grid-cols-[1fr_auto_1fr_auto] md:items-end">
          <div>
            <p className="text-[12px] font-semibold text-muted">1 · Teach language (course)</p>
            <select
              value={lang?.id ?? ''}
              onChange={(e) => {
                setExpanded(null);
                setLang(languages.find((l) => String(l.id) === e.target.value));
              }}
              className="mt-1.5 w-full rounded-xl border border-line bg-panel px-3.5 py-2.5 text-[14px] font-semibold text-ink outline-none focus:border-et-green"
            >
              {languages.map((l) => (
                <option key={l.id} value={l.id}>
                  {l.native_name} ({l.name})
                </option>
              ))}
            </select>
          </div>

          <div className="hidden pb-3 text-center text-[18px] font-bold text-et-green md:block">×</div>

          <div>
            <p className="text-[12px] font-semibold text-muted">2 · Explain in (base language)</p>
            <select
              value={baseLangCode}
              onChange={(e) => setAuthorBase(e.target.value)}
              className="mt-1.5 w-full rounded-xl border border-line bg-panel px-3.5 py-2.5 text-[14px] font-semibold text-ink outline-none focus:border-et-green"
            >
              {baseLangs.map((b) => (
                <option key={b.code} value={b.code}>
                  {b.native_name || b.name} ({b.code})
                </option>
              ))}
            </select>
          </div>

          <div className="flex items-center gap-2">
            {lang && (
              <Button
                variant="primary"
                onClick={() => {
                  setUnitEditingId(null);
                  setUnitForm(emptyUnit(units.length));
                }}
              >
                New unit
              </Button>
            )}
          </div>
        </div>

        <div className="mt-4 flex flex-wrap items-center gap-2 border-t border-line-soft pt-4 text-[13px] text-muted">
          <span className="font-semibold text-ink">
            Authoring: {lang?.native_name || lang?.name || '—'}
          </span>
          <span>taught using</span>
          <Badge tone="success">{activeBaseLabel}</Badge>
          <span className="text-muted/80">
            Editors open on this base language. Badges show rows still missing {baseLangCode} text.
          </span>
        </div>
      </div>

      {error && (
        <div className="mt-5">
          <Banner tone="warning">{error}</Banner>
        </div>
      )}

      {loading && <p className="mt-6 text-center text-[13px] font-medium text-muted">Loading…</p>}

      {!loading && !languages.length && (
        <p className="mt-6 rounded-2xl border border-line bg-white px-5 py-8 text-center text-sm font-semibold text-muted shadow-sm">
          Add a course language first (Curriculum → Courses), then come back here.
        </p>
      )}

      {!loading && lang && (
        <>
          <div className="mt-4 flex flex-wrap gap-2 text-[12px] font-semibold text-muted">
            <span className="rounded-full bg-et-green-soft px-3 py-1 text-et-green-dark">{units.length} units</span>
            <span className="rounded-full bg-et-blue/10 px-3 py-1 text-et-blue">{lessons.length} lessons</span>
            <span className="rounded-full bg-et-green-soft px-3 py-1 text-et-green-dark">{questions.length} questions</span>
            <span className="rounded-full bg-et-yellow/20 px-3 py-1 text-et-yellow-dark">
              explain: {baseLangCode}
            </span>
          </div>

          <div className="mt-4 rounded-2xl border border-et-green/25 bg-et-green-soft/50 px-4 py-3 text-[12px] leading-relaxed text-et-green-dark">
            <strong>Authoring flow:</strong> 1) teach language → 2) explain in ({activeBaseLabel}) →
            open <strong>📖 Vocabulary</strong> on a unit → write meanings in {activeBaseLabel} →
            add lesson questions. Switch base language to author another instruction language
            (e.g. Somali, then English).
          </div>

          <div className="mt-4 space-y-4">
            {units.map((unit) => {
              const unitLessons = lessonsOf(unit.id);
              return (
                <div key={unit.id} className="overflow-hidden rounded-2xl border border-line bg-white shadow-sm">
                  <div
                    className="flex flex-wrap items-center justify-between gap-3 px-5 py-4 text-white"
                    style={{ background: `linear-gradient(135deg, ${unit.color_hex}, ${unit.dark_hex})` }}
                  >
                    <div className="flex items-center gap-3">
                      <span className="text-lg">{ICONS[unit.icon] || '📘'}</span>
                      <div>
                        <div className="font-semibold">{unit.title}</div>
                        <div className="text-xs opacity-80">{unit.subtitle}</div>
                      </div>
                    </div>
                    <div className="flex flex-wrap items-center gap-2 text-[12px] font-semibold">
                      <button
                        onClick={() => setUnitTeachCtx({ unitId: unit.id, unit })}
                        className="rounded-lg bg-white/95 px-3 py-1.5 text-et-green-dark hover:bg-white"
                      >
                        📖 Vocabulary ({unitTeachItemsOf(unit).length})
                        <BaseStatus ok={hasBase(unitTeachItemsOf(unit), baseLangCode)} />
                      </button>
                      <button
                        onClick={() => {
                          setUnitEditingId(unit.id);
                          setUnitForm({ ...emptyUnit(unit.sort_order), ...unit });
                        }}
                        className="rounded-lg bg-white/20 px-3 py-1.5 hover:bg-white/30 text-white"
                      >
                        Edit
                      </button>
                      <button
                        onClick={() => removeUnit(unit)}
                        className="rounded-lg bg-black/20 px-3 py-1.5 hover:bg-black/30 text-white"
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
                                className={`flex h-7 w-7 items-center justify-center rounded-full text-xs font-semibold transition ${
                                  open ? 'bg-et-green text-white' : 'bg-canvas text-muted hover:bg-line'
                                }`}
                                title={open ? 'Hide questions' : 'Show questions'}
                              >
                                {open ? '▾' : '▸'}
                              </button>
                              <span className="font-bold">
                                {lesson.is_boss && '👑 '}
                                {lesson.title}
                              </span>
                              <span className="rounded-full bg-canvas px-2.5 py-1 text-xs font-bold text-muted">
                                {teachItemsOf(lesson).length} T · {qs.length} Q · {lesson.xp_reward} XP
                              </span>
                            </div>
                            <div className="whitespace-nowrap">
                              <button
                                onClick={() => setTeachCtx({ lessonId: lesson.id, lesson })}
                                className="mr-3 font-semibold text-et-yellow-dark hover:underline"
                                title="Lesson-only extra words (chapter vocab is on the unit)"
                              >
                                Extra teach
                              </button>
                              <button
                                onClick={() =>
                                  setResourceCtx({
                                    lessonId: lesson.id,
                                    lesson,
                                    initial: resourcesOf(lesson),
                                  })
                                }
                                className="mr-3 font-semibold text-et-blue hover:underline"
                              >
                                Files ({resourcesOf(lesson).length})
                              </button>
                              <button
                                onClick={() => {
                                  setQuestionCtx({ lessonId: lesson.id, row: null });
                                  if (!open) setExpanded(lesson.id);
                                }}
                                className="mr-3 font-bold text-et-green-dark hover:underline"
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
                                className="mr-2 font-bold text-et-blue hover:underline"
                              >
                                Edit
                              </button>
                              <button onClick={() => removeLesson(lesson)} className="font-bold text-et-red hover:underline">
                                Delete
                              </button>
                            </div>
                          </div>

                          {open && (
                            <div className="space-y-2 border-t border-line-soft bg-canvas/70/70 px-5 py-4">
                              {qs.map((q) => (
                                <div
                                  key={q.id}
                                  className="flex items-center justify-between gap-3 rounded-xl border border-line bg-white px-4 py-2.5"
                                >
                                  <div className="min-w-0">
                                    <span
                                      className={`mr-2 rounded-full px-2 py-0.5 text-[10px] font-semibold ${KIND_BADGE[q.kind]}`}
                                    >
                                      {q.kind}
                                    </span>
                                    <span className="truncate text-sm font-semibold">{q.prompt}</span>
                                    <BaseStatus ok={hasBase(q.content || q.prompt, baseLangCode)} />
                                  </div>
                                  <div className="shrink-0 whitespace-nowrap">
                                    <button
                                      onClick={() => setQuestionCtx({ lessonId: lesson.id, row: q })}
                                      className="mr-2 font-bold text-et-blue hover:underline"
                                    >
                                      Edit
                                    </button>
                                    <button onClick={() => removeQuestion(q)} className="font-bold text-et-red hover:underline">
                                      Delete
                                    </button>
                                  </div>
                                </div>
                              ))}
                              {!qs.length && (
                                <p className="py-2 text-center text-xs font-semibold text-muted">
                                  No questions yet — add the first one.
                                </p>
                              )}
                              <button
                                onClick={() => setQuestionCtx({ lessonId: lesson.id, row: null })}
                                className="w-full rounded-xl border border-dashed border-line py-2 text-xs font-bold uppercase tracking-wide text-muted hover:bg-white"
                              >
                                + Add question
                              </button>
                            </div>
                          )}
                        </li>
                      );
                    })}
                    {!unitLessons.length && (
                      <li className="px-5 py-6 text-center text-xs font-semibold text-muted">No lessons yet</li>
                    )}
                  </ul>

                  <div className="border-t border-line-soft px-5 py-3">
                    <button
                      onClick={() => {
                        setLessonEditingId(null);
                        setLessonCtx({ unitId: unit.id, ...emptyLesson(unitLessons.length) });
                      }}
                      className="text-xs font-semibold uppercase tracking-wide text-et-green-dark hover:underline"
                    >
                      + Add lesson
                    </button>
                  </div>
                </div>
              );
            })}

            <div className="mt-4 rounded-xl border border-et-green/25 bg-et-green-soft/50 px-4 py-3 text-[12px] leading-relaxed text-et-green-dark">
              <strong>Tip:</strong> Put shared chapter words on <em>Unit vocabulary</em>.
              Use <em>Lesson extra teach</em> only when one lesson needs unique words.
              In the app, learners see unit vocab first, then any extras.
            </div>
            {!units.length && (
              <p className="rounded-2xl border border-line bg-white px-5 py-8 text-center text-sm font-semibold text-muted shadow-sm">
                No units yet — click “+ New unit” to start building the course.
              </p>
            )}
          </div>
        </>
      )}

      {unitForm && (
        <div className="fixed inset-0 z-40 flex items-center justify-center bg-black/40 p-4">
          <form onSubmit={saveUnit} className="max-h-[85vh] w-full max-w-lg overflow-y-auto rounded-2xl bg-white p-7 shadow-2xl">
            <h2 className="text-xl font-semibold">{unitEditingId ? 'Edit unit' : 'New unit'}</h2>
            <div className="mt-5 grid grid-cols-2 gap-4">
              <Field label="Title *" value={unitForm.title} onChange={(v) => setUnitForm({ ...unitForm, title: v })} placeholder="Greetings" required />
              <Field label="Subtitle" value={unitForm.subtitle} onChange={(v) => setUnitForm({ ...unitForm, subtitle: v })} placeholder="First words & hellos" />
              <ColorField label="Color" value={unitForm.color_hex} onChange={(v) => setUnitForm({ ...unitForm, color_hex: v })} />
              <ColorField label="Dark color" value={unitForm.dark_hex} onChange={(v) => setUnitForm({ ...unitForm, dark_hex: v })} />
              <Field label="Sort order" type="number" value={unitForm.sort_order} onChange={(v) => setUnitForm({ ...unitForm, sort_order: Number(v) })} />
            </div>
            <div className="mt-4">
              <span className="mb-1.5 block text-xs font-semibold uppercase tracking-wider text-muted">Icon</span>
              <div className="flex flex-wrap gap-1.5">
                {Object.entries(ICONS).map(([name, emoji]) => (
                  <button
                    type="button"
                    key={name}
                    title={name.replaceAll('_', ' ')}
                    onClick={() => setUnitForm({ ...unitForm, icon: name })}
                    className={`h-10 w-10 rounded-xl border text-lg transition ${
                      unitForm.icon === name ? 'border-et-green bg-green-50' : 'border-line hover:bg-canvas/70'
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
          <form onSubmit={saveLesson} className="w-full max-w-md rounded-2xl bg-white p-7 shadow-2xl">
            <h2 className="text-xl font-semibold">{lessonEditingId ? 'Edit lesson' : 'New lesson'}</h2>
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
        <div className="fixed inset-0 z-50 flex items-start justify-center overflow-y-auto bg-ink/45 p-4 pt-8 backdrop-blur-[2px]">
          <div className="w-full max-w-2xl rounded-2xl border border-line-soft bg-panel shadow-2xl">
            <header className="flex items-start justify-between gap-4 border-b border-line-soft px-6 py-4">
              <div>
                <h2 className="text-[17px] font-bold text-ink">
                  {questionCtx.row ? 'Edit question' : 'New question'}
                </h2>
                <p className="mt-1 text-[13px] text-muted">
                  {lang?.native_name || lang?.name} · explain in <strong>{activeBaseLabel}</strong>
                  {' · '}Lesson #{questionCtx.lessonId}
                </p>
              </div>
              <button
                type="button"
                onClick={() => setQuestionCtx(null)}
                className="rounded-lg p-1.5 text-muted hover:bg-canvas hover:text-ink"
                aria-label="Close"
              >
                ✕
              </button>
            </header>
            <div className="max-h-[75vh] overflow-y-auto px-6 py-5">
              <QuestionEditor
                initial={questionCtx.row}
                onSave={saveQuestion}
                onClose={() => setQuestionCtx(null)}
                baseLanguages={baseLangs}
                focusBaseLang={baseLangCode}
                targetLanguageName={lang?.native_name || lang?.name}
              />
            </div>
          </div>
        </div>
      )}

      {resourceCtx && (
        <LessonResourcesEditor
          lesson={resourceCtx.lesson}
          initial={resourceCtx.initial}
          onSave={(items) => saveLessonResources(resourceCtx.lessonId, items)}
          onClose={() => setResourceCtx(null)}
        />
      )}

      {unitTeachCtx && (
        <TeachContentEditor
          title="Unit vocabulary"
          description={`Chapter words for ${lang?.native_name || lang?.name}, explained in ${activeBaseLabel}. Author once — every lesson in this unit reuses them.`}
          initial={unitTeachItemsOf(unitTeachCtx.unit)}
          onSave={(items) => saveUnitTeachContent(unitTeachCtx.unitId, items)}
          onClose={() => setUnitTeachCtx(null)}
          baseLanguages={baseLangs}
          focusBaseLang={baseLangCode}
        />
      )}

      {teachCtx && (
        <TeachContentEditor
          title="Lesson extra teach words"
          description={`Optional words only this lesson adds · focus language ${activeBaseLabel}. Chapter vocabulary lives on the unit.`}
          lessonId={teachCtx.lessonId}
          initial={teachItemsOf(teachCtx.lesson)}
          onSave={(items) => saveTeachContent(teachCtx.lessonId, items)}
          onClose={() => setTeachCtx(null)}
          baseLanguages={baseLangs}
          focusBaseLang={baseLangCode}
        />
      )}
    </div>
  );
}

function Field({ label, value, onChange, type = 'text', required, placeholder }) {
  return (
    <label className="block">
      <span className="mb-1 block text-xs font-semibold uppercase tracking-wider text-muted">{label}</span>
      <input
        type={type}
        value={value ?? ''}
        required={required}
        placeholder={placeholder}
        onChange={(e) => onChange(e.target.value)}
        className="w-full rounded-xl border border-line px-3 py-2.5 text-sm outline-none focus:border-et-green"
      />
    </label>
  );
}

function ColorField({ label, value, onChange }) {
  return (
    <label className="block">
      <span className="mb-1 block text-xs font-semibold uppercase tracking-wider text-muted">{label}</span>
      <div className="flex items-center gap-2">
        <input
          type="color"
          value={value}
          onChange={(e) => onChange(e.target.value)}
          className="h-10 w-12 cursor-pointer rounded-lg border border-line"
        />
        <code className="text-xs font-bold text-muted">{value}</code>
      </div>
    </label>
  );
}

function ModalActions({ onCancel, label }) {
  return (
    <div className="mt-6 flex gap-3">
      <button type="submit" className="flex-1 rounded-xl bg-et-green py-3 text-sm font-semibold text-white hover:bg-et-green-dark">
        {label}
      </button>
      <button type="button" onClick={onCancel} className="flex-1 rounded-xl border border-line py-3 text-sm font-semibold uppercase tracking-wide text-muted hover:bg-canvas/70">
        Cancel
      </button>
    </div>
  );
}

function LessonResourcesEditor({ lesson, initial, onSave, onClose }) {
  const [items, setItems] = useState(() => (Array.isArray(initial) ? [...initial] : []));
  const [title, setTitle] = useState('');
  const [url, setUrl] = useState('');
  const [kind, setKind] = useState('pdf');

  const add = () => {
    if (!url.trim()) return;
    const k =
      kind ||
      (/\.pdf(\?|$)/i.test(url) ? 'pdf' : /\.(mp3|m4a|wav|ogg|webm)(\?|$)/i.test(url) ? 'audio' : 'file');
    setItems([
      ...items,
      {
        kind: k,
        url: url.trim(),
        title: title.trim() || (k === 'pdf' ? 'PDF resource' : 'Audio resource'),
      },
    ]);
    setTitle('');
    setUrl('');
    setKind('pdf');
  };

  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center overflow-y-auto bg-ink/45 p-4 pt-8">
      <div className="w-full max-w-xl rounded-2xl border border-line-soft bg-panel p-6 shadow-2xl">
        <h2 className="text-[18px] font-bold text-ink">Lesson files</h2>
        <p className="mt-1 text-[13px] text-muted">
          Audio clips and PDFs for <strong>{lesson?.title}</strong>. Files are stored on S3; only the
          link is saved in the database. Learners open them from the teach/lesson screen.
        </p>

        {items.length > 0 && (
          <div className="mt-4 space-y-2">
            {items.map((item, i) => (
              <div
                key={`${item.url}-${i}`}
                className="flex items-center gap-3 rounded-xl border border-line-soft bg-canvas/50 px-4 py-2.5"
              >
                <span className="rounded-full bg-et-blue/10 px-2 py-0.5 text-[10px] font-bold text-et-blue uppercase">
                  {item.kind}
                </span>
                <div className="min-w-0 flex-1">
                  <div className="truncate text-[13px] font-semibold">{item.title}</div>
                  <div className="truncate text-[11px] text-muted" title={item.url}>
                    {item.url}
                  </div>
                </div>
                <a
                  href={item.url}
                  target="_blank"
                  rel="noreferrer"
                  className="text-[12px] font-semibold text-et-blue hover:underline"
                >
                  Open
                </a>
                <button
                  onClick={() => setItems(items.filter((_, idx) => idx !== i))}
                  className="text-[12px] font-semibold text-et-red hover:underline"
                >
                  Del
                </button>
              </div>
            ))}
          </div>
        )}

        <div className="mt-4 space-y-3 rounded-xl border border-dashed border-line p-4">
          <p className="text-[12px] font-semibold text-muted">Add a file (uploads to S3)</p>
          <div className="grid gap-3 sm:grid-cols-[120px_1fr]">
            <select
              value={kind}
              onChange={(e) => setKind(e.target.value)}
              className="rounded-xl border border-line px-3 py-2.5 text-sm outline-none focus:border-et-green"
            >
              <option value="pdf">PDF</option>
              <option value="audio">Audio</option>
              <option value="image">Image</option>
            </select>
            <input
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder="Title (e.g. Greetings worksheet)"
              className="rounded-xl border border-line px-3 py-2.5 text-sm outline-none focus:border-et-green"
            />
          </div>
          <MediaField
            label="File"
            value={url}
            onChange={setUrl}
            endpoint="/admin/media"
            hint={kind === 'pdf' ? 'Upload a PDF — the S3 link is saved automatically.' : 'Record or upload audio — S3 link saved automatically.'}
            accept={kind === 'pdf' ? 'application/pdf' : kind === 'audio' ? 'audio/*' : 'audio/*,application/pdf,image/*'}
          />
          <Button type="button" variant="primary" onClick={add} disabled={!url.trim()}>
            Add to lesson
          </Button>
        </div>

        <div className="mt-6 flex gap-3">
          <Button type="button" variant="primary" onClick={() => onSave(items)} className="flex-1">
            Save files
          </Button>
          <Button type="button" variant="secondary" onClick={onClose} className="flex-1">
            Cancel
          </Button>
        </div>
      </div>
    </div>
  );
}

function TeachContentEditor({
  lessonId,
  initial,
  onSave,
  onClose,
  baseLanguages,
  title = 'Teach content',
  description,
  focusBaseLang,
}) {
  const langs = baseLanguages?.length
    ? baseLanguages
    : [
        { code: 'en', name: 'English', native_name: 'English', nativeName: 'English' },
        { code: 'am', name: 'Amharic', native_name: 'አማርኛ', nativeName: 'አማርኛ' },
      ];
  const sortedLangs = [...langs].sort((a, b) => {
    if (a.code === focusBaseLang) return -1;
    if (b.code === focusBaseLang) return 1;
    return 0;
  });
  const labelOf = (l) => l.native_name || l.nativeName || l.name;
  const [items, setItems] = useState(() => (Array.isArray(initial) ? [...initial] : []));
  const [form, setForm] = useState({
    target: '',
    translit: '',
    meaning: '',
    meanings: {},
    audioUrl: '',
    pdfUrl: '',
  });
  const [editIdx, setEditIdx] = useState(null);
  const [activeMeaningLang, setActiveMeaningLang] = useState(
    focusBaseLang || sortedLangs[0]?.code || 'en',
  );

  const emptyForm = {
    target: '',
    translit: '',
    meaning: '',
    meanings: {},
    audioUrl: '',
    pdfUrl: '',
  };

  const addItem = () => {
    if (!form.target.trim()) return;
    const meanings = { ...(form.meanings || {}) };
    const fallback = form.meaning || meanings.en || meanings[langs[0]?.code] || '';
    if (fallback && !meanings.en) meanings.en = fallback;
    const payload = {
      target: form.target.trim(),
      translit: form.translit,
      meaning: fallback,
      meanings,
      audioUrl: form.audioUrl || '',
      pdfUrl: form.pdfUrl || '',
    };
    if (editIdx !== null) {
      const next = [...items];
      next[editIdx] = payload;
      setItems(next);
      setEditIdx(null);
    } else {
      setItems([...items, payload]);
    }
    setForm(emptyForm);
  };

  const removeItem = (i) => {
    setItems(items.filter((_, idx) => idx !== i));
    if (editIdx === i) {
      setEditIdx(null);
      setForm(emptyForm);
    }
  };

  const startEdit = (i) => {
    setEditIdx(i);
    const item = items[i];
    setForm({
      target: item.target || '',
      translit: item.translit || '',
      meaning: item.meaning || '',
      meanings: { ...(item.meanings || {}) },
      audioUrl: item.audioUrl || item.audio_url || '',
      pdfUrl: item.pdfUrl || item.pdf_url || '',
    });
  };

  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center overflow-y-auto bg-ink/45 p-4 pt-8">
      <div className="max-h-[85vh] w-full max-w-2xl overflow-y-auto rounded-2xl border border-line-soft bg-panel p-7 shadow-2xl">
        <h2 className="text-[18px] font-bold text-ink">{title}</h2>
        <p className="mt-1 text-[13px] text-muted">
          {description ||
            'Add words learners see before the quiz. Audio and PDF attachments are stored on S3.'}
        </p>

        {items.length > 0 && (
          <div className="mt-4 space-y-2">
            {items.map((item, i) => {
              const audio = item.audioUrl || item.audio_url || '';
              const pdf = item.pdfUrl || item.pdf_url || '';
              return (
                <div
                  key={i}
                  className="rounded-xl border border-line-soft bg-canvas/50 px-4 py-3"
                >
                  <div className="flex items-center gap-3">
                    <span className="text-[15px] font-semibold text-et-green">{i + 1}</span>
                    <div className="min-w-0 flex-1">
                      <span className="font-ethiopic block text-[15px] font-semibold">
                        {item.target}
                      </span>
                      <span className="block text-[12px] text-muted">
                        {item.translit}
                        {item.meaning ? ` · ${item.meaning}` : ''}
                        {item.meanings && Object.keys(item.meanings).length > 1
                          ? ` · ${Object.keys(item.meanings).join('/')}`
                          : ''}
                      </span>
                    </div>
                    <button
                      onClick={() => startEdit(i)}
                      className="text-[12px] font-semibold text-et-blue hover:underline"
                    >
                      Edit
                    </button>
                    <button
                      onClick={() => removeItem(i)}
                      className="text-[12px] font-semibold text-et-red hover:underline"
                    >
                      Del
                    </button>
                  </div>
                  {(audio || pdf) && (
                    <div className="mt-2 flex flex-wrap items-center gap-2 pl-8">
                      {audio && (
                        <audio controls src={resolveAudioUrl(audio)} className="h-9 max-w-[240px]" />
                      )}
                      {pdf && (
                        <a
                          href={resolveAudioUrl(pdf)}
                          target="_blank"
                          rel="noreferrer"
                          className="rounded-lg border border-et-red/25 bg-et-red/5 px-3 py-1.5 text-[12px] font-semibold text-et-red hover:underline"
                        >
                          Open PDF
                        </a>
                      )}
                      <span className="max-w-[160px] truncate text-[10px] text-muted">
                        {audio || pdf}
                      </span>
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        )}

        <div className="mt-4 rounded-xl border border-dashed border-line p-4">
          <span className="mb-2 block text-[12px] font-semibold text-muted">
            {editIdx !== null ? `Edit item ${editIdx + 1}` : 'Add a word'}
          </span>
          <div className="space-y-3">
            <input
              type="text"
              value={form.target}
              onChange={(e) => setForm({ ...form, target: e.target.value })}
              placeholder="Target word (e.g. ሰላም)"
              className="w-full rounded-xl border border-line px-3 py-2.5 text-sm outline-none focus:border-et-green font-ethiopic"
            />
            <div className="grid grid-cols-2 gap-3">
              <input
                type="text"
                value={form.translit}
                onChange={(e) => setForm({ ...form, translit: e.target.value })}
                placeholder="Transliteration"
                className="rounded-xl border border-line px-3 py-2.5 text-sm outline-none focus:border-et-green"
              />
              <input
                type="text"
                value={form.meaning}
                onChange={(e) => {
                  const v = e.target.value;
                  setForm((prev) => ({
                    ...prev,
                    meaning: v,
                    meanings: { ...prev.meanings, [activeMeaningLang]: v },
                  }));
                }}
                placeholder={`Meaning in ${labelOf(langs.find((l) => l.code === activeMeaningLang) || {})}`}
                className="rounded-xl border border-line px-3 py-2.5 text-sm outline-none focus:border-et-green"
              />
            </div>
            <div className="flex flex-wrap gap-2">
              {sortedLangs.map((l) => (
                <button
                  key={l.code}
                  type="button"
                  onClick={() => {
                    setActiveMeaningLang(l.code);
                    setForm((prev) => ({
                      ...prev,
                      meaning:
                        prev.meanings?.[l.code] ??
                        (l.code === focusBaseLang || l.code === 'en' ? prev.meaning : ''),
                    }));
                  }}
                  className={`rounded-full px-3 py-1.5 text-[12px] font-semibold transition ${
                    activeMeaningLang === l.code
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
            <MediaField
              label="Pronunciation audio"
              value={form.audioUrl}
              onChange={(v) => setForm({ ...form, audioUrl: v })}
              endpoint="/admin/media"
              accept="audio/*"
              hint="Record or upload — saved to S3"
            />
            <MediaField
              label="PDF (optional)"
              value={form.pdfUrl}
              onChange={(v) => setForm({ ...form, pdfUrl: v })}
              endpoint="/admin/media"
              accept="application/pdf"
              hint="Worksheet / notes for this word"
            />
            <button
              type="button"
              onClick={addItem}
              disabled={!form.target.trim()}
              className="w-full rounded-xl bg-et-green-soft py-2.5 text-[13px] font-semibold text-et-green-dark hover:bg-et-green/15 disabled:opacity-40"
            >
              {editIdx !== null ? 'Update item' : 'Add word'}
            </button>
          </div>
        </div>

        <div className="mt-6 flex gap-3">
          <button
            onClick={() => onSave(items)}
            className="flex-1 rounded-xl bg-et-green py-3 text-sm font-semibold text-white hover:bg-et-green-dark"
          >
            Save teach content
          </button>
          <button
            onClick={onClose}
            className="flex-1 rounded-xl border border-line py-3 text-sm font-semibold text-muted hover:bg-canvas"
          >
            Cancel
          </button>
        </div>
      </div>
    </div>
  );
}
