import { Sequelize } from 'sequelize';
import mysql from 'mysql2/promise';
import 'dotenv/config';

const { DB_HOST, DB_USER, DB_PASS, DB_NAME } = process.env;

export async function createDatabase() {
  const connection = await mysql.createConnection({
    host: DB_HOST || 'localhost',
    user: DB_USER || 'root',
    password: DB_PASS || '',
  });

  await connection.query(`CREATE DATABASE IF NOT EXISTS \`${DB_NAME || 'etlingo'}\`;`);
  console.log(`[db] database '${DB_NAME || 'etlingo'}' is ready`);
  await connection.end();
}

export const sequelize = new Sequelize(DB_NAME || 'etlingo', DB_USER || 'root', DB_PASS || '', {
  host: DB_HOST || 'localhost',
  dialect: 'mysql',
  logging: false,
  define: {
    underscored: true,
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: false,
  },
});

export default sequelize;