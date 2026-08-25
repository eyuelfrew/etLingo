import { DataTypes } from 'sequelize';
import { sequelize } from '../../core/db.js';

// Owned tables: app_users, lesson_progress.
// In a microservice split this becomes the user service DB.
// lesson_progress.lesson_id references the content module's table by plain id
// only — no cross-module joins, so extraction later needs no query rewrites.

export const AppUser = sequelize.define('AppUser', {
  id: { type: DataTypes.INTEGER.UNSIGNED, primaryKey: true, autoIncrement: true },
  firebase_uid: { type: DataTypes.STRING(128), unique: true, allowNull: true },
  device_id: { type: DataTypes.STRING(64), unique: true, allowNull: true },
  email: { type: DataTypes.STRING(190), unique: true, allowNull: true },
  display_name: { type: DataTypes.STRING(120), defaultValue: '' },
  password_hash: { type: DataTypes.STRING(255), allowNull: true },
  provider: { type: DataTypes.ENUM('guest', 'email', 'google'), defaultValue: 'guest' },
  status: { type: DataTypes.ENUM('active', 'banned'), defaultValue: 'active' },
  xp: { type: DataTypes.INTEGER, defaultValue: 0 },
  hearts: { type: DataTypes.INTEGER, defaultValue: 5 },
  streak: { type: DataTypes.INTEGER, defaultValue: 0 },
  last_active_date: { type: DataTypes.DATEONLY, allowNull: true },
}, { tableName: 'app_users', updatedAt: false });

export const LessonProgress = sequelize.define('LessonProgress', {
  id: { type: DataTypes.INTEGER.UNSIGNED, primaryKey: true, autoIncrement: true },
  app_user_id: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false },
  lesson_id: { type: DataTypes.INTEGER.UNSIGNED, allowNull: false },
  mistakes: { type: DataTypes.INTEGER, defaultValue: 0 },
  xp_earned: { type: DataTypes.INTEGER, defaultValue: 0 },
}, {
  tableName: 'lesson_progress',
  createdAt: 'completed_at',
  updatedAt: false,
});