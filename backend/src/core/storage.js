import {
  S3Client,
  PutObjectCommand,
  DeleteObjectCommand,
  HeadBucketCommand,
} from '@aws-sdk/client-s3';
import { randomUUID } from 'crypto';
import path from 'path';

const endpoint = process.env.S3_ENDPOINT || 'https://s3.aletcloud.com';
const region = process.env.S3_REGION || 'et-addis-1';
const bucket = process.env.S3_BUCKET || 't71-etlang';
const accessKeyId = process.env.S3_ACCESS_KEY_ID || '';
const secretAccessKey = process.env.S3_SECRET_ACCESS_KEY || '';
const publicBase =
  process.env.S3_PUBLIC_BASE_URL ||
  `${endpoint.replace(/\/$/, '')}/${bucket}`;
const keyPrefix = (process.env.S3_KEY_PREFIX || 'etlingo').replace(/^\/+|\/+$/g, '');

export const s3Enabled = Boolean(accessKeyId && secretAccessKey && bucket);

let client = null;

function getClient() {
  if (!s3Enabled) return null;
  if (!client) {
    client = new S3Client({
      region,
      endpoint,
      // AletCloud / MinIO-style endpoints usually need path-style.
      forcePathStyle: process.env.S3_FORCE_PATH_STYLE !== 'false',
      credentials: { accessKeyId, secretAccessKey },
    });
  }
  return client;
}

const EXT_BY_MIME = {
  'audio/mpeg': '.mp3',
  'audio/mp3': '.mp3',
  'audio/wav': '.wav',
  'audio/x-wav': '.wav',
  'audio/webm': '.webm',
  'audio/ogg': '.ogg',
  'audio/mp4': '.m4a',
  'audio/x-m4a': '.m4a',
  'audio/aac': '.aac',
  'application/pdf': '.pdf',
  'image/png': '.png',
  'image/jpeg': '.jpg',
  'image/webp': '.webp',
};

export const ALLOWED_MEDIA_MIMES = Object.keys(EXT_BY_MIME);

export function mediaKindFromMime(mime) {
  if (!mime) return 'file';
  if (mime.startsWith('audio/')) return 'audio';
  if (mime === 'application/pdf') return 'pdf';
  if (mime.startsWith('image/')) return 'image';
  return 'file';
}

export function publicUrlForKey(key) {
  return `${publicBase.replace(/\/$/, '')}/${key}`;
}

/**
 * Upload a buffer to S3. Returns { url, key, kind, contentType }.
 * Fallback path (no S3 creds) returns null so callers can use local disk.
 */
export async function uploadBufferToS3({
  buffer,
  contentType,
  originalName,
  folder = 'media',
}) {
  const c = getClient();
  if (!c) return null;

  const mime = (contentType || 'application/octet-stream').toLowerCase();
  const ext =
    EXT_BY_MIME[mime] ||
    path.extname(originalName || '').toLowerCase() ||
    '';
  const safeFolder = folder.replace(/^\/+|\/+$/g, '') || 'media';
  const key = `${keyPrefix}/${safeFolder}/${Date.now()}-${randomUUID().slice(0, 10)}${ext}`;

  await c.send(
    new PutObjectCommand({
      Bucket: bucket,
      Key: key,
      Body: buffer,
      ContentType: mime,
      // Public read so learners can stream audio / open PDFs without signed URLs.
      ACL: process.env.S3_ACL || 'public-read',
    }),
  );

  return {
    url: publicUrlForKey(key),
    key,
    kind: mediaKindFromMime(mime),
    contentType: mime,
  };
}

export async function deleteFromS3(key) {
  const c = getClient();
  if (!c || !key) return false;
  try {
    await c.send(new DeleteObjectCommand({ Bucket: bucket, Key: key }));
    return true;
  } catch {
    return false;
  }
}

export async function pingS3() {
  const c = getClient();
  if (!c) return 'disabled';
  try {
    await c.send(new HeadBucketCommand({ Bucket: bucket }));
    return 'up';
  } catch (e) {
    return `down (${e.name || e.message})`;
  }
}

export function getS3Status() {
  return {
    enabled: s3Enabled,
    endpoint,
    bucket,
    region,
    publicBase,
  };
}
