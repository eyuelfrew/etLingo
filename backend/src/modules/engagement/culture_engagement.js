/**
 * Culture unit likes/comments — same sticky-like pattern as language units.
 * Tables owned by the engagement module (plain culture_unit_id FK by convention).
 */
import { DataTypes } from 'sequelize';
import { sequelize } from '../../core/db.js';

export const CultureUnitLike = sequelize.define('CultureUnitLike', {
  id: { type: DataTypes.INTEGER.UNSIGNED, primaryKey: true, autoIncrement: true },
  user_id: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false },
  culture_unit_id: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false },
}, {
  tableName: 'culture_unit_likes',
  timestamps: false,
  indexes: [{ unique: true, fields: ['user_id', 'culture_unit_id'] }],
});

export const CultureUnitComment = sequelize.define('CultureUnitComment', {
  id: { type: DataTypes.INTEGER.UNSIGNED, primaryKey: true, autoIncrement: true },
  user_id: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false },
  culture_unit_id: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false },
  body: { type: DataTypes.STRING(500), allowNull: false },
}, {
  tableName: 'culture_unit_comments',
  createdAt: 'created_at',
  updatedAt: false,
});
