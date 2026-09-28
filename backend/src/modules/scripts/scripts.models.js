import { DataTypes } from 'sequelize';
import { sequelize } from '../../core/db.js';

/**
 * Writing systems (scripts) — Ge'ez, Latin, Arabic, Osmanya, …
 * Owned by the scripts module. Languages map via language_scripts.
 */
export const Script = sequelize.define('Script', {
  id: { type: DataTypes.INTEGER.UNSIGNED, primaryKey: true, autoIncrement: true },
  /** Home course language this writing system was created for. */
  language_id: { type: DataTypes.INTEGER.UNSIGNED, allowNull: true },
  code: { type: DataTypes.STRING(16), allowNull: false, unique: true },
  name: { type: DataTypes.STRING(80), allowNull: false },
  native_name: { type: DataTypes.STRING(120), defaultValue: '' },
  direction: {
    type: DataTypes.ENUM('ltr', 'rtl'),
    defaultValue: 'ltr',
  },
  family: { type: DataTypes.STRING(60), defaultValue: '' },
  sample: { type: DataTypes.STRING(40), defaultValue: '' },
  description: { type: DataTypes.STRING(500), defaultValue: '' },
  is_active: { type: DataTypes.BOOLEAN, defaultValue: true },
  sort_order: { type: DataTypes.INTEGER, defaultValue: 0 },
}, { tableName: 'scripts', timestamps: false });

/**
 * Alphabet letters / syllables of a script (e.g. Ge'ez fidel rows).
 * glyph is the visible character; roman/sound feed the trainer & phonetics.
 */
export const ScriptLetter = sequelize.define('ScriptLetter', {
  id: { type: DataTypes.INTEGER.UNSIGNED, primaryKey: true, autoIncrement: true },
  script_id: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false },
  glyph: { type: DataTypes.STRING(8), allowNull: false },
  name: { type: DataTypes.STRING(80), defaultValue: '' },
  roman: { type: DataTypes.STRING(40), defaultValue: '' },
  sound: { type: DataTypes.STRING(40), defaultValue: '' },
  order_name: { type: DataTypes.STRING(20), defaultValue: '' },
  form_index: { type: DataTypes.INTEGER, defaultValue: 0 },
  audio_url: { type: DataTypes.STRING(255), defaultValue: '' },
  notes: { type: DataTypes.STRING(300), defaultValue: '' },
  meta: { type: DataTypes.JSON, allowNull: true },
  sort_order: { type: DataTypes.INTEGER, defaultValue: 0 },
}, { tableName: 'script_letters', timestamps: false });

/** Which writing system(s) a course language uses. */
export const LanguageScript = sequelize.define('LanguageScript', {
  id: { type: DataTypes.INTEGER.UNSIGNED, primaryKey: true, autoIncrement: true },
  language_id: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false },
  script_id: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false },
  is_primary: { type: DataTypes.BOOLEAN, defaultValue: false },
  role: { type: DataTypes.STRING(40), defaultValue: 'primary' },
  sort_order: { type: DataTypes.INTEGER, defaultValue: 0 },
}, {
  tableName: 'language_scripts',
  timestamps: false,
  indexes: [{ unique: true, fields: ['language_id', 'script_id'] }],
});
