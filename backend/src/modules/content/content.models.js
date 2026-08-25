import { DataTypes } from 'sequelize';
import { sequelize } from '../../core/db.js';

// Owned tables: languages, units, lessons, questions, phrases.
// In a microservice split this becomes the content service DB.
// Note: no cross-module Sequelize associations — modules only reference each
// other by plain id columns, so extraction later requires no query rewrites.

export const Language = sequelize.define('Language', {
  id: { type: DataTypes.INTEGER.UNSIGNED, primaryKey: true, autoIncrement: true },
  code: { type: DataTypes.STRING(8), allowNull: false, unique: true },
  name: { type: DataTypes.STRING(80), allowNull: false },
  native_name: { type: DataTypes.STRING(120), allowNull: false },
  script_preview: { type: DataTypes.STRING(160), defaultValue: '' },
  speakers: { type: DataTypes.STRING(24), defaultValue: '' },
  region: { type: DataTypes.STRING(120), defaultValue: '' },
  color_hex: { type: DataTypes.CHAR(7), defaultValue: '#078930' },
  dark_hex: { type: DataTypes.CHAR(7), defaultValue: '#056B24' },
  hello_target: { type: DataTypes.STRING(160), defaultValue: '' },
  hello_meaning: { type: DataTypes.STRING(240), defaultValue: '' },
  icon: { type: DataTypes.STRING(64), defaultValue: 'waving_hand_rounded' },
  sort_order: { type: DataTypes.INTEGER, defaultValue: 0 },
  is_active: { type: DataTypes.BOOLEAN, defaultValue: true },
}, { tableName: 'languages' });

export const Unit = sequelize.define('Unit', {
  id: { type: DataTypes.INTEGER.UNSIGNED, primaryKey: true, autoIncrement: true },
  language_id: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false },
  title: { type: DataTypes.STRING(160), allowNull: false },
  subtitle: { type: DataTypes.STRING(200), defaultValue: '' },
  color_hex: { type: DataTypes.CHAR(7), defaultValue: '#078930' },
  dark_hex: { type: DataTypes.CHAR(7), defaultValue: '#056B24' },
  icon: { type: DataTypes.STRING(64), defaultValue: 'waving_hand_rounded' },
  sort_order: { type: DataTypes.INTEGER, defaultValue: 0 },
}, { tableName: 'units' });

export const Lesson = sequelize.define('Lesson', {
  id: { type: DataTypes.INTEGER.UNSIGNED, primaryKey: true, autoIncrement: true },
  unit_id: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false },
  title: { type: DataTypes.STRING(160), allowNull: false },
  is_boss: { type: DataTypes.BOOLEAN, defaultValue: false },
  xp_reward: { type: DataTypes.INTEGER, defaultValue: 10 },
  sort_order: { type: DataTypes.INTEGER, defaultValue: 0 },
}, { tableName: 'lessons' });

export const Question = sequelize.define('Question', {
  id: { type: DataTypes.INTEGER.UNSIGNED, primaryKey: true, autoIncrement: true },
  lesson_id: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false },
  kind: { type: DataTypes.ENUM('mcq', 'fill', 'match', 'listen'), allowNull: false },
  prompt: { type: DataTypes.STRING(300), allowNull: false },
  sub_prompt: { type: DataTypes.STRING(300), defaultValue: '' },
  hint: { type: DataTypes.STRING(160), defaultValue: '' },
  options: { type: DataTypes.JSON, allowNull: true },
  answer_index: { type: DataTypes.INTEGER, defaultValue: -1 },
  match_left: { type: DataTypes.JSON, allowNull: true },
  match_right: { type: DataTypes.JSON, allowNull: true },
  audio_url: { type: DataTypes.STRING(255), defaultValue: '' },
  sort_order: { type: DataTypes.INTEGER, defaultValue: 0 },
}, { tableName: 'questions' });

export const Phrase = sequelize.define('Phrase', {
  id: { type: DataTypes.INTEGER.UNSIGNED, primaryKey: true, autoIncrement: true },
  language_id: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false },
  target: { type: DataTypes.STRING(200), allowNull: false },
  translit: { type: DataTypes.STRING(200), defaultValue: '' },
  meaning: { type: DataTypes.STRING(300), defaultValue: '' },
  category: { type: DataTypes.STRING(60), defaultValue: 'Basics' },
  audio_url: { type: DataTypes.STRING(255), defaultValue: '' },
  sort_order: { type: DataTypes.INTEGER, defaultValue: 0 },
}, { tableName: 'phrases' });