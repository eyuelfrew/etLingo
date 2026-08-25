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
  { table: 'app_users', column: 'status', clause: "status ENUM('active','banned') NOT NULL DEFAULT 'active'" },
  { table: 'questions', column: 'audio_url', clause: "audio_url VARCHAR(255) NOT NULL DEFAULT ''" },
  { table: 'phrases', column: 'audio_url', clause: "audio_url VARCHAR(255) NOT NULL DEFAULT ''" },
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