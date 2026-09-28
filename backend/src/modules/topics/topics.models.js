import { DataTypes } from 'sequelize';
import { sequelize } from '../../core/db.js';

/** Thematic word packs — Animals, Food, Colors… per course language. */
export const TopicCategory = sequelize.define('TopicCategory', {
  id: { type: DataTypes.INTEGER.UNSIGNED, primaryKey: true, autoIncrement: true },
  language_id: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false },
  slug: { type: DataTypes.STRING(40), allowNull: false },
  title: { type: DataTypes.STRING(80), allowNull: false },
  native_title: { type: DataTypes.STRING(80), defaultValue: '' },
  emoji: { type: DataTypes.STRING(16), defaultValue: '' },
  color_hex: { type: DataTypes.CHAR(7), defaultValue: '#078930' },
  description: { type: DataTypes.STRING(300), defaultValue: '' },
  is_active: { type: DataTypes.BOOLEAN, defaultValue: true },
  sort_order: { type: DataTypes.INTEGER, defaultValue: 0 },
}, {
  tableName: 'topic_categories',
  timestamps: false,
  indexes: [{ unique: true, fields: ['language_id', 'slug'] }],
});

export const TopicWord = sequelize.define('TopicWord', {
  id: { type: DataTypes.INTEGER.UNSIGNED, primaryKey: true, autoIncrement: true },
  category_id: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false },
  target: { type: DataTypes.STRING(120), allowNull: false },
  translit: { type: DataTypes.STRING(120), defaultValue: '' },
  meaning: { type: DataTypes.STRING(200), defaultValue: '' },
  meanings: { type: DataTypes.JSON, allowNull: true },
  audio_url: { type: DataTypes.STRING(255), defaultValue: '' },
  image_url: { type: DataTypes.STRING(255), defaultValue: '' },
  notes: { type: DataTypes.STRING(300), defaultValue: '' },
  sort_order: { type: DataTypes.INTEGER, defaultValue: 0 },
}, { tableName: 'topic_words', timestamps: false });
