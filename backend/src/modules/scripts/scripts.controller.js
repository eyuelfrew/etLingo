import { Script, ScriptLetter, LanguageScript } from './scripts.models.js';
import { Language } from '../content/content.models.js';
import { Op } from 'sequelize';
import { asyncHandler, badRequest, notFound } from '../../core/http.js';

function pick(obj, fields) {
  const out = {};
  for (const f of fields) if (obj[f] !== undefined) out[f] = obj[f];
  return out;
}

const scriptFields = [
  'language_id', 'code', 'name', 'native_name', 'direction', 'family',
  'sample', 'description', 'is_active', 'sort_order',
];
const letterFields = [
  'script_id', 'glyph', 'name', 'roman', 'sound', 'order_name',
  'form_index', 'audio_url', 'notes', 'meta', 'sort_order',
];
const mapFields = ['language_id', 'script_id', 'is_primary', 'role', 'sort_order'];

function scriptOut(r) {
  const x = r.toJSON ? r.toJSON() : r;
  return {
    id: x.id,
    languageId: x.language_id ?? null,
    code: x.code,
    name: x.name,
    nativeName: x.native_name || '',
    direction: x.direction || 'ltr',
    family: x.family || '',
    sample: x.sample || '',
    description: x.description || '',
    isActive: !!x.is_active,
    sortOrder: x.sort_order ?? 0,
  };
}

function letterOut(r) {
  const x = r.toJSON ? r.toJSON() : r;
  return {
    id: x.id,
    scriptId: x.script_id,
    glyph: x.glyph,
    name: x.name || '',
    roman: x.roman || '',
    sound: x.sound || x.roman || x.name || '',
    orderName: x.order_name || '',
    formIndex: x.form_index ?? 0,
    audioUrl: x.audio_url || '',
    notes: x.notes || '',
    meta: x.meta || {},
    sortOrder: x.sort_order ?? 0,
  };
}

// ── Scripts CRUD ─────────────────────────────────────────────────────────────

export const listScripts = asyncHandler(async (req, res) => {
  const where = {};
  if (req.query.language_id) where.language_id = Number(req.query.language_id);
  if (req.query.is_active !== undefined) where.is_active = req.query.is_active === '1' || req.query.is_active === 'true';
  if (req.query.q) where.name = { [Op.like]: `%${req.query.q}%` };
  // Prefer language-owned scripts; also include ones mapped to this language.
  let rows = await Script.findAll({
    where,
    order: [['sort_order', 'ASC'], ['id', 'ASC']],
  });
  if (req.query.language_id) {
    const lid = Number(req.query.language_id);
    const maps = await LanguageScript.findAll({ where: { language_id: lid } });
    const mappedIds = maps.map((m) => m.script_id);
    const have = new Set(rows.map((r) => r.id));
    const extras = mappedIds.length
      ? await Script.findAll({
          where: { id: mappedIds.filter((id) => !have.has(id)) },
          order: [['sort_order', 'ASC'], ['id', 'ASC']],
        })
      : [];
    rows = [...rows, ...extras];
  }
  res.json(rows.map(scriptOut));
});

export const getScript = asyncHandler(async (req, res) => {
  const row = await Script.findByPk(req.params.id);
  if (!row) throw notFound('Script not found');
  res.json(scriptOut(row));
});

export const createScript = asyncHandler(async (req, res) => {
  const data = pick(req.body, scriptFields);
  if (!data.code) throw badRequest('code is required');
  if (!data.name) throw badRequest('name is required');
  const exists = await Script.findOne({ where: { code: data.code } });
  if (exists) throw badRequest(`Script code "${data.code}" already exists`);
  const row = await Script.create(data);
  // Language-first: auto-map as primary when created for a language.
  if (row.language_id) {
    await LanguageScript.update(
      { is_primary: false },
      { where: { language_id: row.language_id } },
    );
    await LanguageScript.findOrCreate({
      where: { language_id: row.language_id, script_id: row.id },
      defaults: {
        language_id: row.language_id,
        script_id: row.id,
        is_primary: true,
        role: 'primary',
        sort_order: Number(data.sort_order) || 0,
      },
    });
  }
  res.status(201).json(scriptOut(row));
});

export const updateScript = asyncHandler(async (req, res) => {
  const row = await Script.findByPk(req.params.id);
  if (!row) throw notFound('Script not found');
  await row.update(pick(req.body, scriptFields));
  res.json(scriptOut(row));
});

export const deleteScript = asyncHandler(async (req, res) => {
  const row = await Script.findByPk(req.params.id);
  if (!row) throw notFound('Script not found');
  await ScriptLetter.destroy({ where: { script_id: row.id } });
  await LanguageScript.destroy({ where: { script_id: row.id } });
  await row.destroy();
  res.status(204).end();
});

/**
 * GET /admin/languages/:id/scripts — scripts owned by / mapped to a language
 * with letter counts (language-first admin flow).
 */
export const languageScriptsBundle = asyncHandler(async (req, res) => {
  const languageId = Number(req.params.id);
  const lang = await Language.findByPk(languageId);
  if (!lang) throw notFound('Language not found');

  const maps = await LanguageScript.findAll({
    where: { language_id: languageId },
    order: [['is_primary', 'DESC'], ['sort_order', 'ASC'], ['id', 'ASC']],
  });
  const owned = await Script.findAll({
    where: { language_id: languageId },
    order: [['sort_order', 'ASC'], ['id', 'ASC']],
  });
  const mapIds = maps.map((m) => m.script_id);
  const ownedIds = owned.map((s) => s.id);
  const extraIds = mapIds.filter((id) => !ownedIds.includes(id));
  const extras = extraIds.length
    ? await Script.findAll({ where: { id: extraIds } })
    : [];
  const all = [...owned, ...extras];
  const ids = all.map((s) => s.id);
  const letters = ids.length
    ? await ScriptLetter.findAll({
        where: { script_id: ids },
        order: [
          ['sort_order', 'ASC'],
          ['form_index', 'ASC'],
          ['id', 'ASC'],
        ],
      })
    : [];

  const byScript = new Map();
  for (const l of letters) {
    const sid = l.script_id;
    if (!byScript.has(sid)) byScript.set(sid, []);
    byScript.get(sid).push(letterOut(l));
  }

  res.json({
    language: {
      id: lang.id,
      code: lang.code,
      name: lang.name,
      nativeName: lang.native_name,
    },
    scripts: all.map((s) => {
      const map = maps.find((m) => m.script_id === s.id);
      return {
        ...scriptOut(s),
        isPrimary: !!map?.is_primary || (owned.length === 1 && owned[0].id === s.id),
        role: map?.role || (s.language_id === languageId ? 'primary' : 'secondary'),
        letterCount: (byScript.get(s.id) || []).length,
        letters: byScript.get(s.id) || [],
      };
    }),
  });
});

/**
 * POST /admin/languages/:id/scripts — create a writing system for one language
 * and attach it as primary (the “create language → create its script” flow).
 */
export const createScriptForLanguage = asyncHandler(async (req, res) => {
  const languageId = Number(req.params.id);
  const lang = await Language.findByPk(languageId);
  if (!lang) throw notFound('Language not found');

  const data = pick(req.body, scriptFields);
  data.language_id = languageId;
  if (!data.code) throw badRequest('code is required');
  if (!data.name) throw badRequest('name is required');
  const exists = await Script.findOne({ where: { code: data.code } });
  if (exists) throw badRequest(`Script code "${data.code}" already exists`);

  const row = await Script.create(data);
  await LanguageScript.update(
    { is_primary: false },
    { where: { language_id: languageId } },
  );
  await LanguageScript.create({
    language_id: languageId,
    script_id: row.id,
    is_primary: true,
    role: String(req.body?.role || 'primary'),
    sort_order: Number(data.sort_order) || 0,
  });

  // Optional seed letters on create
  const items = Array.isArray(req.body?.letters) ? req.body.letters : [];
  const created = [];
  for (let i = 0; i < items.length; i++) {
    const item = items[i] || {};
    const glyph = String(item.glyph || '').trim();
    if (!glyph) continue;
    created.push(await ScriptLetter.create({
      script_id: row.id,
      glyph,
      name: String(item.name || '').trim(),
      roman: String(item.roman || '').trim(),
      sound: String(item.sound || item.roman || item.name || '').trim(),
      order_name: String(item.orderName || item.order_name || '').trim(),
      form_index: Number(item.formIndex ?? item.form_index ?? 0) || 0,
      sort_order: Number(item.sortOrder ?? item.sort_order ?? i) || 0,
    }));
  }

  res.status(201).json({
    ...scriptOut(row),
    isPrimary: true,
    role: 'primary',
    letterCount: created.length,
    letters: created.map(letterOut),
  });
});

// ── Letters ──────────────────────────────────────────────────────────────────

export const listLetters = asyncHandler(async (req, res) => {
  const where = {};
  if (req.query.script_id) where.script_id = Number(req.query.script_id);
  const rows = await ScriptLetter.findAll({
    where,
    order: [
      ['sort_order', 'ASC'],
      ['form_index', 'ASC'],
      ['id', 'ASC'],
    ],
  });
  res.json(rows.map(letterOut));
});

/** POST /admin/script-letters/reorder — persist drag-and-drop order. */
export const reorderLetters = asyncHandler(async (req, res) => {
  const items = Array.isArray(req.body?.items) ? req.body.items : [];
  if (!items.length) throw badRequest('items[] required');
  if (items.length > 2000) throw badRequest('Max 2000 items');
  let updated = 0;
  for (const item of items) {
    const id = Number(item.id);
    if (!id) continue;
    const row = await ScriptLetter.findByPk(id);
    if (!row) continue;
    await row.update({
      sort_order: Number(item.sortOrder ?? item.sort_order) || 0,
      form_index: Number(item.formIndex ?? item.form_index ?? row.form_index) || 0,
    });
    updated += 1;
  }
  res.json({ updated });
});

export const createLetter = asyncHandler(async (req, res) => {
  const data = pick(req.body, letterFields);
  if (!data.script_id) throw badRequest('script_id is required');
  if (!data.glyph) throw badRequest('glyph is required');
  const script = await Script.findByPk(data.script_id);
  if (!script) throw notFound('Script not found');
  const row = await ScriptLetter.create(data);
  res.status(201).json(letterOut(row));
});

export const updateLetter = asyncHandler(async (req, res) => {
  const row = await ScriptLetter.findByPk(req.params.id);
  if (!row) throw notFound('Letter not found');
  await row.update(pick(req.body, letterFields));
  res.json(letterOut(row));
});

export const deleteLetter = asyncHandler(async (req, res) => {
  const row = await ScriptLetter.findByPk(req.params.id);
  if (!row) throw notFound('Letter not found');
  await row.destroy();
  res.status(204).end();
});

/** Bulk replace letters for a script (admin paste / import). */
export const bulkUpsertLetters = asyncHandler(async (req, res) => {
  const scriptId = Number(req.params.id);
  const script = await Script.findByPk(scriptId);
  if (!script) throw notFound('Script not found');
  const items = Array.isArray(req.body?.letters) ? req.body.letters : [];
  if (items.length > 2000) throw badRequest('Max 2000 letters per import');

  if (req.body?.replace) {
    await ScriptLetter.destroy({ where: { script_id: scriptId } });
  }

  const out = [];
  for (let i = 0; i < items.length; i++) {
    const item = items[i] || {};
    const glyph = String(item.glyph || '').trim();
    if (!glyph) continue;
    const payload = {
      script_id: scriptId,
      glyph,
      name: String(item.name || '').trim(),
      roman: String(item.roman || '').trim(),
      sound: String(item.sound || item.roman || item.name || '').trim(),
      order_name: String(item.orderName || item.order_name || '').trim(),
      form_index: Number(item.formIndex ?? item.form_index ?? 0) || 0,
      audio_url: String(item.audioUrl || item.audio_url || '').trim(),
      notes: String(item.notes || '').trim(),
      meta: item.meta || null,
      sort_order: Number(item.sortOrder ?? item.sort_order ?? i) || 0,
    };
    const existing = await ScriptLetter.findOne({
      where: { script_id: scriptId, glyph: payload.glyph, form_index: payload.form_index },
    });
    if (existing) {
      await existing.update(payload);
      out.push(letterOut(existing));
    } else {
      const row = await ScriptLetter.create(payload);
      out.push(letterOut(row));
    }
  }
  res.json({ imported: out.length, letters: out });
});

// ── Language ↔ script mapping ────────────────────────────────────────────────

export const listLanguageScripts = asyncHandler(async (req, res) => {
  const where = {};
  if (req.query.language_id) where.language_id = Number(req.query.language_id);
  if (req.query.script_id) where.script_id = Number(req.query.script_id);
  const rows = await LanguageScript.findAll({
    where,
    order: [['sort_order', 'ASC'], ['id', 'ASC']],
  });
  res.json(rows.map((r) => {
    const x = r.toJSON();
    return {
      id: x.id,
      languageId: x.language_id,
      scriptId: x.script_id,
      isPrimary: !!x.is_primary,
      role: x.role || 'primary',
      sortOrder: x.sort_order ?? 0,
    };
  }));
});

export const mapLanguageScript = asyncHandler(async (req, res) => {
  const languageId = Number(req.body?.language_id);
  const scriptId = Number(req.body?.script_id);
  if (!languageId || !scriptId) throw badRequest('language_id and script_id are required');

  const lang = await Language.findByPk(languageId);
  if (!lang) throw notFound('Language not found');
  const script = await Script.findByPk(scriptId);
  if (!script) throw notFound('Script not found');

  const isPrimary = req.body?.is_primary === true || req.body?.is_primary === 1;
  if (isPrimary) {
    await LanguageScript.update(
      { is_primary: false },
      { where: { language_id: languageId } },
    );
  }

  const [row, created] = await LanguageScript.findOrCreate({
    where: { language_id: languageId, script_id: scriptId },
    defaults: {
      language_id: languageId,
      script_id: scriptId,
      is_primary: isPrimary,
      role: String(req.body?.role || (isPrimary ? 'primary' : 'secondary')),
      sort_order: Number(req.body?.sort_order) || 0,
    },
  });
  if (!created) {
    await row.update({
      is_primary: isPrimary ? true : row.is_primary,
      role: String(req.body?.role || row.role),
      sort_order: Number(req.body?.sort_order) || row.sort_order,
    });
  }
  res.status(created ? 201 : 200).json({
    id: row.id,
    languageId: row.language_id,
    scriptId: row.script_id,
    isPrimary: !!row.is_primary,
    role: row.role,
    sortOrder: row.sort_order,
  });
});

export const unmapLanguageScript = asyncHandler(async (req, res) => {
  const row = await LanguageScript.findByPk(req.params.id);
  if (!row) throw notFound('Mapping not found');
  await row.destroy();
  res.status(204).end();
});

// ── App-facing ───────────────────────────────────────────────────────────────

/**
 * GET /app/scripts          — all active scripts
 * GET /app/scripts?lang=am  — scripts used by a course language (with letters)
 */
export const appScripts = asyncHandler(async (req, res) => {
  const langCode = (req.query.lang || '').toString().trim();
  if (langCode) {
    const lang = await Language.findOne({ where: { code: langCode, is_active: true } });
    if (!lang) throw notFound('language not found');
    const maps = await LanguageScript.findAll({
      where: { language_id: lang.id },
      order: [['is_primary', 'DESC'], ['sort_order', 'ASC'], ['id', 'ASC']],
    });
    const ids = maps.map((m) => m.script_id);
    const scripts = ids.length
      ? await Script.findAll({
          where: { id: ids, is_active: true },
          order: [['sort_order', 'ASC'], ['id', 'ASC']],
        })
      : [];
    const letters = ids.length
      ? await ScriptLetter.findAll({
          where: { script_id: ids },
          order: [
            ['order_name', 'ASC'],
            ['form_index', 'ASC'],
            ['sort_order', 'ASC'],
            ['id', 'ASC'],
          ],
        })
      : [];

    const byScript = new Map();
    for (const l of letters) {
      const sid = l.script_id;
      if (!byScript.has(sid)) byScript.set(sid, []);
      byScript.get(sid).push(letterOut(l));
    }

    res.json({
      language: {
        code: lang.code,
        name: lang.name,
        nativeName: lang.native_name,
      },
      scripts: scripts.map((s) => {
        const map = maps.find((m) => m.script_id === s.id);
        return {
          ...scriptOut(s),
          isPrimary: !!map?.is_primary,
          role: map?.role || 'secondary',
          letters: byScript.get(s.id) || [],
        };
      }),
    });
    return;
  }

  const rows = await Script.findAll({
    where: { is_active: true },
    order: [['sort_order', 'ASC'], ['id', 'ASC']],
  });
  res.json(rows.map(scriptOut));
});

/** GET /app/scripts/:code/letters — full alphabet for the trainer. */
export const appScriptLetters = asyncHandler(async (req, res) => {
  const code = (req.params.code || '').toString().trim().toLowerCase();
  const script = await Script.findOne({ where: { code, is_active: true } });
  if (!script) throw notFound('script not found');
  const letters = await ScriptLetter.findAll({
    where: { script_id: script.id },
    order: [
      ['sort_order', 'ASC'],
      ['form_index', 'ASC'],
      ['id', 'ASC'],
    ],
  });
  res.json({
    ...scriptOut(script),
    letters: letters.map(letterOut),
  });
});
