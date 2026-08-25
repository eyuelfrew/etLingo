import 'dotenv/config';
import bcrypt from 'bcryptjs';
import mysql from 'mysql2/promise';
import { createDatabase, sequelize } from '../src/core/db.js';
import { initModels } from '../src/modules/index.js';
import { Admin } from '../src/modules/auth/auth.models.js';
import { Language } from '../src/modules/content/content.models.js';
import { migrateAppUsers } from './db-migrate.js';

const { DB_USER = 'root', DB_PASS = '' } = process.env;

const STARTER_LANGUAGES = [
  {
    code: 'am', name: 'Amharic', native_name: 'አማርኛ',
    script_preview: 'ሰላም እንዴት ነህ?',
    speakers: '~32M', region: 'Ethiopia', color_hex: '#078930', dark_hex: '#056B24',
    hello_target: 'ሰላም', hello_meaning: 'Hello', icon: 'waving_hand_rounded', sort_order: 0,
  },
  {
    code: 'om', name: 'Afaan Oromo', native_name: 'Afaan Oromoo',
    script_preview: 'Akkam jirta?',
    speakers: '~37M', region: 'Ethiopia', color_hex: '#D94F04', dark_hex: '#B03D03',
    hello_target: 'Akkam', hello_meaning: 'Hello', icon: 'waving_hand_rounded', sort_order: 1,
  },
  {
    code: 'ti', name: 'Tigrinya', native_name: 'ትግርኛ',
    script_preview: 'ሰላማлейකም ከምኻኽ传来? (sample)',
    speakers: '~7M', region: 'Eritrea/Ethiopia', color_hex: '#1155CC', dark_hex: '#0D44A0',
    hello_target: 'ሰላማлей', hello_meaning: 'Hello', icon: 'waving_hand_rounded', sort_order: 2,
  },
  {
    code: 'so', name: 'Somali', native_name: 'Soomaali',
    script_preview: 'Nabad? Sidee tahay?',
    speakers: '~22M', region: 'Somalia', color_hex: '#4C6EF5', dark_hex: '#3B5BDB',
    hello_target: 'Nabad', hello_meaning: 'Peace', icon: 'waving_hand_rounded', sort_order: 3,
  },
];

async function run() {
  console.log('[db:init] creating database if needed...');
  await createDatabase();

  console.log('[db:init] applying idempotent migrations...');
  const mgr = await mysql.createConnection({
    host: process.env.DB_HOST || 'localhost',
    user: DB_USER,
    password: DB_PASS,
    database: process.env.DB_NAME || 'etlingo',
    multipleStatements: true,
  });
  await migrateAppUsers(mgr);
  await mgr.end();

  console.log('[db:init] connecting via Sequelize...');
  await sequelize.authenticate();
  console.log('[db:init] syncing tables...');
  await initModels();

  // ── Seed admin ──────────────────────────────────────────────────────────────
  const adminEmail = 'admin@etlang.app';
  const [admin] = await Admin.findOrCreate({
    where: { email: adminEmail },
    defaults: {
      name: 'EtLingo Admin',
      email: adminEmail,
      password_hash: await bcrypt.hash('admin123', 12),
      role: 'super',
    },
  });
  if (admin.password_hash === 'admin123') {
    await admin.update({ password_hash: await bcrypt.hash('admin123', 12) });
  }
  console.log(`[db:init] admin → ${adminEmail} / admin123`);

  // ── Seed starter languages ──────────────────────────────────────────────────
  let created = 0;
  for (const attrs of STARTER_LANGUAGES) {
    const [, isNew] = await Language.findOrCreate({ where: { code: attrs.code }, defaults: attrs });
    if (isNew) created++;
  }
  console.log(`[db:init] languages → ${created} seeded, ${STARTER_LANGUAGES.length - created} existing`);

  console.log('[db:init] done ✓');
  await sequelize.close();
  process.exit(0);
}

run().catch(e => {
  console.error('[db:init] failed:', e.message);
  process.exit(1);
});
