import { DataTypes } from 'sequelize';
import { sequelize } from '../../core/db.js';

// Culture Path — parallel track to language lessons (per course language).

export const CultureUnit = sequelize.define('CultureUnit', {
  id: { type: DataTypes.INTEGER.UNSIGNED, primaryKey: true, autoIncrement: true },
  language_id: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false },
  title: { type: DataTypes.STRING(160), allowNull: false },
  subtitle: { type: DataTypes.STRING(200), defaultValue: '' },
  theme: { type: DataTypes.STRING(40), defaultValue: 'fact' },
  color_hex: { type: DataTypes.CHAR(7), defaultValue: '#078930' },
  dark_hex: { type: DataTypes.CHAR(7), defaultValue: '#056B24' },
  icon: { type: DataTypes.STRING(64), defaultValue: 'menu_book_rounded' },
  sort_order: { type: DataTypes.INTEGER, defaultValue: 0 },
  is_active: { type: DataTypes.BOOLEAN, defaultValue: true },
}, { tableName: 'culture_units', timestamps: false });

export const CultureCard = sequelize.define('CultureCard', {
  id: { type: DataTypes.INTEGER.UNSIGNED, primaryKey: true, autoIncrement: true },
  culture_unit_id: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false },
  kind: {
    type: DataTypes.ENUM(
      'text', 'fact', 'proverb', 'steps', 'vocab', 'calendar', 'media', 'music',
    ),
    defaultValue: 'text',
  },
  title: { type: DataTypes.STRING(200), allowNull: false },
  body: { type: DataTypes.TEXT, defaultValue: '' },
  content: { type: DataTypes.JSON, allowNull: true },
  translit: { type: DataTypes.STRING(300), defaultValue: '' },
  audio_url: { type: DataTypes.STRING(255), defaultValue: '' },
  pdf_url: { type: DataTypes.STRING(255), defaultValue: '' },
  resources: { type: DataTypes.JSON, allowNull: true },
  vocab: { type: DataTypes.JSON, allowNull: true },
  meta: { type: DataTypes.JSON, allowNull: true },
  xp_reward: { type: DataTypes.INTEGER, defaultValue: 5 },
  sort_order: { type: DataTypes.INTEGER, defaultValue: 0 },
}, { tableName: 'culture_cards', timestamps: false });

export const CultureProgress = sequelize.define('CultureProgress', {
  id: { type: DataTypes.INTEGER.UNSIGNED, primaryKey: true, autoIncrement: true },
  user_id: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false },
  culture_card_id: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false },
  completed_at: { type: DataTypes.DATE, defaultValue: DataTypes.NOW },
}, {
  tableName: 'culture_progress',
  updatedAt: false,
  createdAt: 'completed_at',
  indexes: [{ unique: true, fields: ['user_id', 'culture_card_id'] }],
});
