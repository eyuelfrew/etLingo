import 'dotenv/config';
import mysql from 'mysql2/promise';
import { pathToFileURL } from 'url';

// Adds columns to `app_users` that newer models expect but existing dev
// databases predate. `sequelize.sync({ force: false })` only creates missing
// tables — it does NOT alter existing tables — so manual idempotent migrations
// are required when models evolve.
//
// Usage:  npm run db:migrate

const { DB_HOST, DB_USER, DB_PASS, DB_NAME } = process.env;

// Idempotent column additions: [{ table, column, clause }].
const COLUMNS = [
  { table: 'app_users', column: 'firebase_uid', clause: 'firebase_uid VARCHAR(128) UNIQUE NULL' },
  { table: 'app_users', column: 'fcm_token', clause: 'fcm_token VARCHAR(255) NULL' },
  { table: 'app_users', column: 'status', clause: "status ENUM('active','banned') NOT NULL DEFAULT 'active'" },
  { table: 'questions', column: 'audio_url', clause: "audio_url VARCHAR(255) NOT NULL DEFAULT ''" },
  { table: 'phrases', column: 'audio_url', clause: "audio_url VARCHAR(255) NOT NULL DEFAULT ''" },
  { table: 'lessons', column: 'teach_content', clause: 'teach_content JSON NULL' },
  { table: 'lessons', column: 'resources', clause: 'resources JSON NULL' },
  { table: 'units', column: 'teach_content', clause: 'teach_content JSON NULL' },
  { table: 'questions', column: 'content', clause: 'content JSON NULL' },
  { table: 'scripts', column: 'language_id', clause: 'language_id INT UNSIGNED NULL' },
];

// Idempotent enum widenings: [{ table, column, type, mustInclude }]
// Applied only when the current column definition lacks `mustInclude`.
const ENUMS = [
  {
    table: 'questions',
    column: 'kind',
    type: "ENUM('mcq','fill','match','listen') NOT NULL",
    mustInclude: "'listen'",
  },
  {
    table: 'culture_cards',
    column: 'kind',
    type: "ENUM('text','fact','proverb','steps','vocab','calendar','media','music') NOT NULL DEFAULT 'text'",
    mustInclude: "'music'",
  },
];

// Table name -> CREATE TABLE IF NOT EXISTS statement (idempotent at the DB level).
const TABLES = {
  notifications: `CREATE TABLE IF NOT EXISTS notifications (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    recipient_user_id INT UNSIGNED NULL,
    title VARCHAR(160) NOT NULL,
    body VARCHAR(500) DEFAULT '',
    type VARCHAR(40) DEFAULT 'general',
    read_at DATETIME NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_recipient_user (recipient_user_id),
    CONSTRAINT fk_notif_user FOREIGN KEY (recipient_user_id)
      REFERENCES app_users(id) ON DELETE CASCADE
  ) ENGINE=InnoDB;`,
  notification_campaigns: `CREATE TABLE IF NOT EXISTS notification_campaigns (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(160) NOT NULL,
    body VARCHAR(500) DEFAULT '',
    type VARCHAR(40) DEFAULT 'general',
    audience ENUM('all','active') NOT NULL DEFAULT 'active',
    batch_size INT NOT NULL DEFAULT 50,
    interval_seconds INT NOT NULL DEFAULT 3600,
    status ENUM('pending','running','completed','cancelled') NOT NULL DEFAULT 'pending',
    start_at DATETIME NULL,
    next_run_at DATETIME NULL,
    total_sent INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  ) ENGINE=InnoDB;`,
  notification_campaign_recipients: `CREATE TABLE IF NOT EXISTS notification_campaign_recipients (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    campaign_id INT UNSIGNED NOT NULL,
    user_id INT UNSIGNED NOT NULL,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_campaign_user (campaign_id, user_id),
    CONSTRAINT fk_cr_campaign FOREIGN KEY (campaign_id)
      REFERENCES notification_campaigns(id) ON DELETE CASCADE
  ) ENGINE=InnoDB;`,
  notification_preferences: `CREATE TABLE IF NOT EXISTS notification_preferences (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL UNIQUE,
    push_enabled TINYINT(1) NOT NULL DEFAULT 1,
    lesson_reminders TINYINT(1) NOT NULL DEFAULT 1,
    streak_milestones TINYINT(1) NOT NULL DEFAULT 1,
    achievements TINYINT(1) NOT NULL DEFAULT 1,
    new_content TINYINT(1) NOT NULL DEFAULT 1,
    app_updates TINYINT(1) NOT NULL DEFAULT 1,
    tips TINYINT(1) NOT NULL DEFAULT 1,
    promotions TINYINT(1) NOT NULL DEFAULT 0,
    CONSTRAINT fk_np_user FOREIGN KEY (user_id)
      REFERENCES app_users(id) ON DELETE CASCADE
  ) ENGINE=InnoDB;`,
  unit_likes: `CREATE TABLE IF NOT EXISTS unit_likes (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    unit_id INT UNSIGNED NOT NULL,
    UNIQUE KEY uq_unit_like (user_id, unit_id)
  ) ENGINE=InnoDB;`,
  unit_comments: `CREATE TABLE IF NOT EXISTS unit_comments (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    unit_id INT UNSIGNED NOT NULL,
    body VARCHAR(500) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_unit_comment (unit_id)
  ) ENGINE=InnoDB;`,
  language_likes: `CREATE TABLE IF NOT EXISTS language_likes (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    language_id INT UNSIGNED NOT NULL,
    UNIQUE KEY uq_lang_like (user_id, language_id)
  ) ENGINE=InnoDB;`,
  language_comments: `CREATE TABLE IF NOT EXISTS language_comments (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    language_id INT UNSIGNED NOT NULL,
    body VARCHAR(500) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_lang_comment (language_id)
  ) ENGINE=InnoDB;`,
  culture_units: `CREATE TABLE IF NOT EXISTS culture_units (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    language_id INT UNSIGNED NOT NULL,
    title VARCHAR(160) NOT NULL,
    subtitle VARCHAR(200) DEFAULT '',
    theme VARCHAR(40) DEFAULT 'fact',
    color_hex CHAR(7) NOT NULL DEFAULT '#078930',
    dark_hex CHAR(7) NOT NULL DEFAULT '#056B24',
    icon VARCHAR(64) DEFAULT 'menu_book_rounded',
    sort_order INT NOT NULL DEFAULT 0,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    INDEX idx_cu_lang (language_id)
  ) ENGINE=InnoDB;`,
  culture_cards: `CREATE TABLE IF NOT EXISTS culture_cards (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    culture_unit_id INT UNSIGNED NOT NULL,
    kind VARCHAR(20) NOT NULL DEFAULT 'text',
    title VARCHAR(200) NOT NULL,
    body TEXT,
    content JSON NULL,
    translit VARCHAR(300) DEFAULT '',
    audio_url VARCHAR(255) DEFAULT '',
    pdf_url VARCHAR(255) DEFAULT '',
    resources JSON NULL,
    vocab JSON NULL,
    meta JSON NULL,
    xp_reward INT NOT NULL DEFAULT 5,
    sort_order INT NOT NULL DEFAULT 0,
    INDEX idx_cc_unit (culture_unit_id)
  ) ENGINE=InnoDB;`,
  culture_progress: `CREATE TABLE IF NOT EXISTS culture_progress (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    culture_card_id INT UNSIGNED NOT NULL,
    completed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_culture_done (user_id, culture_card_id)
  ) ENGINE=InnoDB;`,
  culture_unit_likes: `CREATE TABLE IF NOT EXISTS culture_unit_likes (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    culture_unit_id INT UNSIGNED NOT NULL,
    UNIQUE KEY uq_culture_unit_like (user_id, culture_unit_id),
    INDEX idx_cu_like (culture_unit_id)
  ) ENGINE=InnoDB;`,
  culture_unit_comments: `CREATE TABLE IF NOT EXISTS culture_unit_comments (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    culture_unit_id INT UNSIGNED NOT NULL,
    body VARCHAR(500) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_cu_comment (culture_unit_id)
  ) ENGINE=InnoDB;`,
  community_stories: `CREATE TABLE IF NOT EXISTS community_stories (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    language_code VARCHAR(8) NOT NULL DEFAULT 'am',
    title VARCHAR(160) NOT NULL,
    body TEXT NOT NULL,
    audio_url VARCHAR(255) DEFAULT '',
    status ENUM('pending','approved','rejected') NOT NULL DEFAULT 'pending',
    moderator_note VARCHAR(255) DEFAULT '',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_story_status (status),
    INDEX idx_story_user (user_id)
  ) ENGINE=InnoDB;`,
  exchange_signups: `CREATE TABLE IF NOT EXISTS exchange_signups (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NOT NULL,
    speaks VARCHAR(8) NOT NULL,
    learning VARCHAR(8) NOT NULL,
    note VARCHAR(300) DEFAULT '',
    status ENUM('waiting','matched','closed') NOT NULL DEFAULT 'waiting',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE KEY uq_exchange_user (user_id)
  ) ENGINE=InnoDB;`,
  scripts: `CREATE TABLE IF NOT EXISTS scripts (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(16) NOT NULL UNIQUE,
    name VARCHAR(80) NOT NULL,
    native_name VARCHAR(120) DEFAULT '',
    direction ENUM('ltr','rtl') NOT NULL DEFAULT 'ltr',
    family VARCHAR(60) DEFAULT '',
    sample VARCHAR(40) DEFAULT '',
    description VARCHAR(500) DEFAULT '',
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    sort_order INT NOT NULL DEFAULT 0
  ) ENGINE=InnoDB;`,
  script_letters: `CREATE TABLE IF NOT EXISTS script_letters (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    script_id INT UNSIGNED NOT NULL,
    glyph VARCHAR(8) NOT NULL,
    name VARCHAR(80) DEFAULT '',
    roman VARCHAR(40) DEFAULT '',
    sound VARCHAR(40) DEFAULT '',
    order_name VARCHAR(20) DEFAULT '',
    form_index INT NOT NULL DEFAULT 0,
    audio_url VARCHAR(255) DEFAULT '',
    notes VARCHAR(300) DEFAULT '',
    meta JSON NULL,
    sort_order INT NOT NULL DEFAULT 0,
    INDEX idx_sl_script (script_id),
    UNIQUE KEY uq_script_glyph (script_id, glyph, form_index)
  ) ENGINE=InnoDB;`,
  language_scripts: `CREATE TABLE IF NOT EXISTS language_scripts (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    language_id INT UNSIGNED NOT NULL,
    script_id INT UNSIGNED NOT NULL,
    is_primary TINYINT(1) NOT NULL DEFAULT 0,
    role VARCHAR(40) DEFAULT 'primary',
    sort_order INT NOT NULL DEFAULT 0,
    UNIQUE KEY uq_lang_script (language_id, script_id),
    INDEX idx_ls_lang (language_id),
    INDEX idx_ls_script (script_id)
  ) ENGINE=InnoDB;`,
  topic_categories: `CREATE TABLE IF NOT EXISTS topic_categories (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    language_id INT UNSIGNED NOT NULL,
    slug VARCHAR(40) NOT NULL,
    title VARCHAR(80) NOT NULL,
    native_title VARCHAR(80) DEFAULT '',
    emoji VARCHAR(16) DEFAULT '',
    color_hex CHAR(7) DEFAULT '#078930',
    description VARCHAR(300) DEFAULT '',
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    sort_order INT NOT NULL DEFAULT 0,
    UNIQUE KEY uq_topic_slug (language_id, slug),
    INDEX idx_tc_lang (language_id)
  ) ENGINE=InnoDB;`,
  topic_words: `CREATE TABLE IF NOT EXISTS topic_words (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    category_id INT UNSIGNED NOT NULL,
    target VARCHAR(120) NOT NULL,
    translit VARCHAR(120) DEFAULT '',
    meaning VARCHAR(200) DEFAULT '',
    meanings JSON NULL,
    audio_url VARCHAR(255) DEFAULT '',
    image_url VARCHAR(255) DEFAULT '',
    notes VARCHAR(300) DEFAULT '',
    sort_order INT NOT NULL DEFAULT 0,
    INDEX idx_tw_cat (category_id)
  ) ENGINE=InnoDB;`,
  ads: `CREATE TABLE IF NOT EXISTS ads (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(120) NOT NULL,
    body VARCHAR(300) DEFAULT '',
    image_url VARCHAR(255) DEFAULT '',
    cta_label VARCHAR(40) DEFAULT 'Learn more',
    position VARCHAR(40) NOT NULL DEFAULT 'home_top',
    action_type ENUM('url','screen','topic','culture','none') NOT NULL DEFAULT 'url',
    action_value VARCHAR(255) DEFAULT '',
    language_code VARCHAR(8) DEFAULT '',
    priority INT NOT NULL DEFAULT 0,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    starts_at DATETIME NULL,
    ends_at DATETIME NULL,
    impressions INT NOT NULL DEFAULT 0,
    clicks INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_ad_pos (position, is_active),
    INDEX idx_ad_live (starts_at, ends_at)
  ) ENGINE=InnoDB;`,
  base_languages: `CREATE TABLE IF NOT EXISTS base_languages (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(8) NOT NULL UNIQUE,
    name VARCHAR(80) NOT NULL,
    native_name VARCHAR(120) NOT NULL,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    sort_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  ) ENGINE=InnoDB;`,
};

async function tableExists(conn, table) {
  const [rows] = await conn.query(
    `SELECT COUNT(*) AS n FROM information_schema.TABLES
     WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ?`,
    [DB_NAME || 'etlingo', table],
  );
  return rows[0].n > 0;
}

async function columnExists(conn, table, column) {
  const [rows] = await conn.query(
    `SELECT COUNT(*) AS n FROM information_schema.COLUMNS
     WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ? AND COLUMN_NAME = ?`,
    [DB_NAME || 'etlingo', table, column],
  );
  return rows[0].n > 0;
}

export async function migrateAppUsers(connection) {
  for (const { table, column, clause } of COLUMNS) {
    if (!(await tableExists(connection, table))) continue; // db:init creates the table
    if (await columnExists(connection, table, column)) {
      console.log(`[db:migrate] '${table}.${column}' already present — skipping`);
      continue;
    }
    console.log(`[db:migrate] adding column '${table}.${column}'...`);
    await connection.query(`ALTER TABLE \`${table}\` ADD COLUMN ${clause}`);
    console.log(`[db:migrate] ✓ '${table}.${column}' added`);
  }

  for (const { table, column, type, mustInclude } of ENUMS) {
    if (!(await tableExists(connection, table))) continue;
    const [rows] = await connection.query(
      `SELECT COLUMN_TYPE FROM information_schema.COLUMNS
       WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ? AND COLUMN_NAME = ?`,
      [DB_NAME || 'etlingo', table, column],
    );
    if (!rows.length) continue;
    if (rows[0].COLUMN_TYPE.includes(mustInclude)) {
      console.log(`[db:migrate] '${table}.${column}' already includes ${mustInclude} — skipping`);
      continue;
    }
    console.log(`[db:migrate] widening enum '${table}.${column}'...`);
    await connection.query(`ALTER TABLE \`${table}\` MODIFY COLUMN \`${column}\` ${type}`);
    console.log(`[db:migrate] ✓ '${table}.${column}' widened`);
  }

  for (const [name, ddl] of Object.entries(TABLES)) {
    if (await tableExists(connection, name)) {
      console.log(`[db:migrate] table '${name}' already present — skipping`);
      continue;
    }
    console.log(`[db:migrate] creating table '${name}'...`);
    await connection.query(ddl);
    console.log(`[db:migrate] ✓ '${name}' created`);
  }

  // Seed base_languages if empty (instruction languages learners already speak).
  if (await tableExists(connection, 'base_languages')) {
    const [countRows] = await connection.query('SELECT COUNT(*) AS n FROM base_languages');
    if (countRows[0].n === 0) {
      console.log('[db:migrate] seeding base_languages...');
      await connection.query(`INSERT INTO base_languages (code, name, native_name, is_active, sort_order) VALUES
        ('en', 'English', 'English', 1, 0),
        ('am', 'Amharic', 'አማርኛ', 1, 1),
        ('om', 'Afaan Oromoo', 'Afaan Oromoo', 1, 2),
        ('ti', 'Tigrinya', 'ትግርኛ', 1, 3),
        ('so', 'Somali', 'Soomaali', 1, 4)`);
      console.log('[db:migrate] ✓ base_languages seeded (en, am, om, ti, so)');
    } else {
      // Ensure Ethiopian instruction languages exist even if table was seeded earlier with en/am only.
      const ensure = [
        ['om', 'Afaan Oromoo', 'Afaan Oromoo', 2],
        ['ti', 'Tigrinya', 'ትግርኛ', 3],
        ['so', 'Somali', 'Soomaali', 4],
      ];
      for (const [code, name, native_name, sort_order] of ensure) {
        const [exists] = await connection.query(
          'SELECT id FROM base_languages WHERE code = ? LIMIT 1',
          [code],
        );
        if (!exists.length) {
          await connection.query(
            'INSERT INTO base_languages (code, name, native_name, is_active, sort_order) VALUES (?, ?, ?, 1, ?)',
            [code, name, native_name, sort_order],
          );
          console.log(`[db:migrate] ✓ base language ${code} added`);
        }
      }
    }
  }

  // Migrate existing questions: copy prompt/sub_prompt/hint into content JSON.
  if (await tableExists(connection, 'questions') && await columnExists(connection, 'questions', 'content')) {
    const [rows] = await connection.query(
      "SELECT id, prompt, sub_prompt, hint FROM questions WHERE content IS NULL"
    );
    if (rows.length) {
      console.log(`[db:migrate] migrating ${rows.length} questions to content JSON...`);
      for (const row of rows) {
        const content = JSON.stringify({
          en: {
            prompt: row.prompt || '',
            subPrompt: row.sub_prompt || '',
            hint: row.hint || '',
          },
        });
        await connection.query('UPDATE questions SET content = ? WHERE id = ?', [content, row.id]);
      }
      console.log(`[db:migrate] ✓ ${rows.length} questions migrated`);
    }
  }
}

export async function runMigration() {
  await import('../src/core/db.js').then(({ createDatabase }) => createDatabase());

  console.log('[db:migrate] connecting...');
  const connection = await mysql.createConnection({
    host: DB_HOST || 'localhost',
    user: DB_USER || 'root',
    password: DB_PASS || '',
    database: DB_NAME || 'etlingo',
    multipleStatements: true,
  });

  await migrateAppUsers(connection);

  await connection.end();
  console.log('[db:migrate] done ✓');
}

// CLI entry point.
if (import.meta.url === pathToFileURL(process.argv[1]).href) {
  runMigration().catch(e => {
    console.error('[db:migrate] failed:', e.message);
    process.exit(1);
  });
}