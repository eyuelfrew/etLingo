import mysql from 'mysql2/promise';
import dotenv from 'dotenv';
dotenv.config();

const c = await mysql.createConnection({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASS || '',
  database: process.env.DB_NAME || 'etlingo',
});

const alters = [
  ['unit_likes', 'uq_unit_like', 'user_id, unit_id'],
  ['language_likes', 'uq_lang_like', 'user_id, language_id'],
  ['culture_unit_likes', 'uq_culture_unit_like', 'user_id, culture_unit_id'],
];

for (const [table, key, cols] of alters) {
  try {
    await c.query(`ALTER TABLE \`${table}\` ADD UNIQUE KEY \`${key}\` (${cols})`);
    console.log('unique ok', table);
  } catch (e) {
    console.log(table, e.message);
  }
}

const [rows] = await c.query(
  'SELECT unit_id, user_id, COUNT(*) c FROM unit_likes GROUP BY unit_id, user_id HAVING c > 1',
);
console.log('duplicate likes', rows);
await c.end();
