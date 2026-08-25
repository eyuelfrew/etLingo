import { DataTypes } from 'sequelize';
import { sequelize } from '../../core/db.js';

// Owned tables: admins. In a microservice split this becomes the auth service DB.
export const Admin = sequelize.define('Admin', {
  id: { type: DataTypes.INTEGER.UNSIGNED, primaryKey: true, autoIncrement: true },
  name: { type: DataTypes.STRING(120), allowNull: false },
  email: { type: DataTypes.STRING(190), allowNull: false, unique: true },
  password_hash: { type: DataTypes.STRING(255), allowNull: false },
  role: { type: DataTypes.ENUM('super', 'editor'), defaultValue: 'editor' },
}, { tableName: 'admins' });