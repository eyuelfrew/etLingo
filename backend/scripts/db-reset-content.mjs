import mysql from 'mysql2/promise';
import dotenv from 'dotenv';

dotenv.config();

const conn = await mysql.createConnection({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASS || '',
  database: process.env.DB_NAME || 'etlingo',
  multipleStatements: true,
});

const tables = [
  'notification_campaign_recipients',
  'notification_campaigns',
  'notifications',
  'notification_preferences',
  'lesson_progress',
  'questions',
  'lessons',
  'units',
  'phrases',
  'languages',
  'base_languages',
  'app_users',
];

console.log('[reset] wiping learning data (admin accounts kept)…');
await conn.query('SET FOREIGN_KEY_CHECKS=0');
for (const t of tables) {
  const [r] = await conn.query(`DELETE FROM \`${t}\``);
  console.log(`[reset] ${t} → ${r.affectedRows} row(s) removed`);
}
// Reset auto-increment so new content gets clean ids
for (const t of tables) {
  try {
    await conn.query(`ALTER TABLE \`${t}\` AUTO_INCREMENT = 1`);
  } catch {
    /* ignore */
  }
}
await conn.query('SET FOREIGN_KEY_CHECKS=1');

const [admins] = await conn.query('SELECT id, email, role FROM admins');
console.log(
  '[reset] admins kept:',
  admins.map((a) => `${a.email} (${a.role})`).join(', ') || '(none)',
);

const counts = [];
for (const t of ['languages', 'units', 'lessons', 'questions', 'phrases', 'base_languages', 'app_users']) {
  const [rows] = await conn.query(`SELECT COUNT(*) AS n FROM \`${t}\``);
  counts.push(`${t}=${rows[0].n}`);
}
console.log('[reset] remaining counts:', counts.join(' · '));

await conn.end();
console.log('[reset] done — clean slate for the new content model');
