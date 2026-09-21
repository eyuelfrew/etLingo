/**
 * Rewrite stored media URLs from raw S3 public links to API proxy paths.
 * AletCloud blocks anonymous GetObject (AccessDenied XML) — playback must go
 * through /api/v1/media/<key>.
 *
 * Usage: node scripts/rewrite-media-urls.mjs
 */
import mysql from 'mysql2/promise';
import dotenv from 'dotenv';

dotenv.config();

const BUCKET_HOSTS = [
  'https://s3.aletcloud.com/t71-etlang/',
  'http://s3.aletcloud.com/t71-etlang/',
];

function toProxy(url) {
  if (!url || typeof url !== 'string') return url;
  for (const host of BUCKET_HOSTS) {
    if (url.startsWith(host)) {
      return `/api/v1/media/${url.slice(host.length)}`;
    }
  }
  // already absolute local path
  return url;
}

function rewriteJson(value) {
  if (value == null) return { value, changed: false };
  let obj = value;
  if (typeof obj === 'string') {
    try {
      obj = JSON.parse(obj);
    } catch {
      return { value, changed: false };
    }
  }
  if (Array.isArray(obj)) {
    let changed = false;
    const next = obj.map((item) => {
      if (item && typeof item === 'object') {
        const clone = { ...item };
        if (clone.url) {
          const u = toProxy(clone.url);
          if (u !== clone.url) {
            clone.url = u;
            changed = true;
          }
        }
        if (clone.audioUrl) {
          const u = toProxy(clone.audioUrl);
          if (u !== clone.audioUrl) {
            clone.audioUrl = u;
            changed = true;
          }
        }
        if (clone.audio_url) {
          const u = toProxy(clone.audio_url);
          if (u !== clone.audio_url) {
            clone.audio_url = u;
            changed = true;
          }
        }
        if (clone.pdfUrl) {
          const u = toProxy(clone.pdfUrl);
          if (u !== clone.pdfUrl) {
            clone.pdfUrl = u;
            changed = true;
          }
        }
        return clone;
      }
      return item;
    });
    return { value: changed ? next : value, changed };
  }
  return { value, changed: false };
}

const conn = await mysql.createConnection({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASS || '',
  database: process.env.DB_NAME || 'etlingo',
});

async function fixColumn(table, column, json = false) {
  const [rows] = await conn.query(`SELECT id, \`${column}\` AS v FROM \`${table}\``);
  let n = 0;
  for (const row of rows) {
    let next = row.v;
    if (json) {
      const r = rewriteJson(row.v);
      if (!r.changed) continue;
      next = JSON.stringify(r.value);
    } else {
      const u = toProxy(row.v);
      if (u === row.v) continue;
      next = u;
    }
    await conn.query(`UPDATE \`${table}\` SET \`${column}\` = ? WHERE id = ?`, [next, row.id]);
    n++;
    console.log(`[rewrite] ${table}.${column} #${row.id}`);
  }
  console.log(`[rewrite] ${table}.${column} → ${n} row(s)`);
}

await fixColumn('questions', 'audio_url');
await fixColumn('phrases', 'audio_url');
await fixColumn('lessons', 'resources', true);
await fixColumn('lessons', 'teach_content', true);
await fixColumn('units', 'teach_content', true);

await conn.end();
console.log('[rewrite] done — media now served via /api/v1/media/*');
