import { DataTypes } from 'sequelize';
import { sequelize } from '../../core/db.js';

// Engagement for units (chapters) and languages — not lessons.
// Cross-module: unit_id / language_id are plain ids (content module owns those rows).

export const UnitLike = sequelize.define('UnitLike', {
  id: { type: DataTypes.INTEGER.UNSIGNED, primaryKey: true, autoIncrement: true },
  user_id: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false },
  unit_id: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false },
}, {
  tableName: 'unit_likes',
  timestamps: false,
  indexes: [{ unique: true, fields: ['user_id', 'unit_id'] }],
});

export const UnitComment = sequelize.define('UnitComment', {
  id: { type: DataTypes.INTEGER.UNSIGNED, primaryKey: true, autoIncrement: true },
  user_id: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false },
  unit_id: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false },
  body: { type: DataTypes.STRING(500), allowNull: false },
}, {
  tableName: 'unit_comments',
  createdAt: 'created_at',
  updatedAt: false,
});

export const LanguageLike = sequelize.define('LanguageLike', {
  id: { type: DataTypes.INTEGER.UNSIGNED, primaryKey: true, autoIncrement: true },
  user_id: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false },
  language_id: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false },
}, {
  tableName: 'language_likes',
  timestamps: false,
  indexes: [{ unique: true, fields: ['user_id', 'language_id'] }],
});

export const LanguageComment = sequelize.define('LanguageComment', {
  id: { type: DataTypes.INTEGER.UNSIGNED, primaryKey: true, autoIncrement: true },
  user_id: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false },
  language_id: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false },
  body: { type: DataTypes.STRING(500), allowNull: false },
}, {
  tableName: 'language_comments',
  createdAt: 'created_at',
  updatedAt: false,
});
