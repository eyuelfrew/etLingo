import { useCallback, useEffect, useState } from 'react';
import client, { apiError, apiOrigin } from '../api/client';
import {
  PageHeader,
  Card,
  Button,
  Banner,
  Badge,
  EmptyState,
  inputCls,
  tableShellCls,
  thCls,
  tdCls,
} from '../components/ui';

const PRESETS = [
  { label: 'All', prefix: '' },
  { label: 'Audio', prefix: 'etlingo/audio' },
  { label: 'PDF', prefix: 'etlingo/pdf' },
  { label: 'Images', prefix: 'etlingo/images' },
  { label: 'Media', prefix: 'etlingo/media' },
];

function resolveUrl(path) {
  if (!path) return '';
  if (/^https?:\/\//i.test(path)) return path;
  return `${apiOrigin}${path}`;
}

function kindBadge(kind) {
  if (kind === 'audio') return <Badge tone="success" dot>audio</Badge>;
  if (kind === 'pdf') return <Badge tone="danger">pdf</Badge>;
  if (kind === 'image') return <Badge tone="info">image</Badge>;
  return <Badge tone="neutral">{kind}</Badge>;
}

function formatSize(n) {
  if (!n && n !== 0) return '—';
  if (n < 1024) return `${n} B`;
  if (n < 1024 * 1024) return `${(n / 1024).toFixed(1)} KB`;
  return `${(n / (1024 * 1024)).toFixed(1)} MB`;
}

export default function Storage() {
  const [status, setStatus] = useState(null);
  const [objects, setObjects] = useState([]);
  const [prefix, setPrefix] = useState('');
  const [search, setSearch] = useState('');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [copied, setCopied] = useState('');
  const [preview, setPreview] = useState(null);

  const load = useCallback(async (p = prefix) => {
    setLoading(true);
    setError('');
    try {
      const [{ data: st }, { data }] = await Promise.all([
        client.get('/admin/storage'),
        client.get(`/admin/storage/objects?prefix=${encodeURIComponent(p)}`),
      ]);
      setStatus(st);
      setObjects(data.objects || []);
    } catch (e) {
      setError(apiError(e, 'Could not load S3 storage'));
      setObjects([]);
    } finally {
      setLoading(false);
    }
  }, [prefix]);

  useEffect(() => {
    load('');
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const filtered = objects.filter((o) => {
    if (!search.trim()) return true;
    const q = search.toLowerCase();
    return (
      o.name.toLowerCase().includes(q) ||
      o.path.toLowerCase().includes(q) ||
      o.folder.toLowerCase().includes(q)
    );
  });

  const copyUrl = async (url) => {
    try {
      await navigator.clipboard.writeText(url);
      setCopied(url);
      setTimeout(() => setCopied(''), 1500);
    } catch {
      setError('Could not copy to clipboard');
    }
  };

  return (
    <div>
      <PageHeader
        eyebrow="Storage"
        title="S3 media browser"
        subtitle="Fetch and inspect files uploaded to object storage. Audio and PDF links used in lessons live here."
        actions={
          <Button variant="primary" onClick={() => load(prefix)} disabled={loading}>
            Refresh
          </Button>
        }
      />

      {status && (
        <div className="mt-5 grid gap-3 sm:grid-cols-4">
          <div className="rounded-2xl border border-line-soft bg-panel px-4 py-3">
            <p className="text-[12px] font-semibold text-muted">Bucket</p>
            <p className="mt-1 truncate text-[14px] font-bold text-ink" title={status.bucket}>
              {status.bucket}
            </p>
          </div>
          <div className="rounded-2xl border border-line-soft bg-panel px-4 py-3">
            <p className="text-[12px] font-semibold text-muted">Endpoint</p>
            <p className="mt-1 truncate text-[14px] font-bold text-ink" title={status.endpoint}>
              {status.endpoint}
            </p>
          </div>
          <div className="rounded-2xl border border-line-soft bg-panel px-4 py-3">
            <p className="text-[12px] font-semibold text-muted">Region</p>
            <p className="mt-1 text-[14px] font-bold text-ink">{status.region}</p>
          </div>
          <div className="rounded-2xl border border-line-soft bg-panel px-4 py-3">
            <p className="text-[12px] font-semibold text-muted">Status</p>
            <p className="mt-1">
              <Badge tone={status.enabled ? 'success' : 'danger'} dot>
                {status.enabled ? 'Enabled' : 'Disabled'}
              </Badge>
            </p>
          </div>
        </div>
      )}

      {error && (
        <div className="mt-5">
          <Banner tone="warning">{error}</Banner>
        </div>
      )}

      <div className="mt-5">
        <Card title="Browse bucket" description="Filter by folder prefix or file name. Click a row to preview audio/PDF.">
          <div className="flex flex-wrap items-center gap-2">
            {PRESETS.map((p) => (
              <button
                key={p.label}
                type="button"
                onClick={() => {
                  setPrefix(p.prefix);
                  load(p.prefix);
                }}
                className={`rounded-full px-3.5 py-1.5 text-[12px] font-semibold transition ${
                  prefix === p.prefix
                    ? 'bg-et-green text-white'
                    : 'bg-canvas text-muted hover:text-ink'
                }`}
              >
                {p.label}
              </button>
            ))}
            <div className="ml-auto min-w-[200px] flex-1 sm:max-w-xs">
              <input
                value={search}
                onChange={(e) => setSearch(e.target.value)}
                placeholder="Search file name…"
                className={`${inputCls} mt-0`}
              />
            </div>
          </div>

          <div className="mt-4">
            {loading ? (
              <div className={`${tableShellCls} px-5 py-10 text-center text-sm text-muted`}>
                Loading from S3…
              </div>
            ) : filtered.length === 0 ? (
              <EmptyState
                icon="☁"
                title="No files found"
                hint="Upload audio or PDF from Lessons → Files, or Phrases audio. Files appear here after upload."
              />
            ) : (
              <div className={tableShellCls}>
                <table className="w-full">
                  <thead>
                    <tr className="border-b border-line-soft">
                      <th className={thCls}>File</th>
                      <th className={thCls}>Type</th>
                      <th className={thCls}>Folder</th>
                      <th className={thCls}>Size</th>
                      <th className={`${thCls} text-right`}>Actions</th>
                    </tr>
                  </thead>
                  <tbody>
                    {filtered.map((o) => (
                      <tr
                        key={o.key}
                        className="border-t border-line-soft hover:bg-canvas/60"
                      >
                        <td className={tdCls}>
                          <button
                            type="button"
                            onClick={() => setPreview(o)}
                            className="text-left font-semibold text-ink hover:underline"
                          >
                            {o.name}
                          </button>
                          <div className="truncate text-[11px] text-muted" title={o.path}>
                            {o.path}
                          </div>
                        </td>
                        <td className={tdCls}>{kindBadge(o.kind)}</td>
                        <td className={`${tdCls} text-[12px] text-muted`}>{o.folder}</td>
                        <td className={`${tdCls} tabular-nums text-[12px]`}>
                          {formatSize(o.size)}
                        </td>
                        <td className={`${tdCls} text-right whitespace-nowrap`}>
                          <button
                            onClick={() => setPreview(o)}
                            className="mr-3 text-[12px] font-semibold text-et-blue hover:underline"
                          >
                            Preview
                          </button>
                          <button
                            onClick={() => copyUrl(o.url)}
                            className="mr-3 text-[12px] font-semibold text-et-green-dark hover:underline"
                          >
                            {copied === o.url ? 'Copied ✓' : 'Copy URL'}
                          </button>
                          <a
                            href={o.url}
                            target="_blank"
                            rel="noreferrer"
                            className="text-[12px] font-semibold text-ink hover:underline"
                          >
                            Open
                          </a>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>
        </Card>
      </div>

      {preview && (
        <div
          className="fixed inset-0 z-50 flex items-start justify-center bg-ink/45 p-4 pt-10"
          onClick={() => setPreview(null)}
        >
          <div
            className="w-full max-w-2xl rounded-2xl border border-line-soft bg-panel p-6 shadow-2xl"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-start justify-between gap-4">
              <div className="min-w-0">
                <h2 className="truncate text-[17px] font-bold text-ink">{preview.name}</h2>
                <p className="truncate text-[12px] text-muted">{preview.path}</p>
              </div>
              <Badge tone="info">{preview.kind}</Badge>
            </div>

            <div className="mt-4 rounded-xl border border-line-soft bg-canvas/50 p-4">
              {preview.kind === 'audio' && (
                <audio controls src={resolveUrl(preview.url)} className="w-full" />
              )}
              {preview.kind === 'pdf' && (
                <iframe
                  title={preview.name}
                  src={resolveUrl(preview.url)}
                  className="h-[360px] w-full rounded-lg border border-line bg-white"
                />
              )}
              {preview.kind === 'image' && (
                <img
                  src={resolveUrl(preview.url)}
                  alt={preview.name}
                  className="mx-auto max-h-80 rounded-lg"
                />
              )}
              {preview.kind === 'file' && (
                <p className="text-[13px] text-muted">No inline preview — use Open.</p>
              )}
            </div>

            <div className="mt-3 break-all rounded-xl bg-canvas px-3 py-2 text-[11px] text-muted">
              {preview.url}
            </div>

            <div className="mt-4 flex justify-end gap-2">
              <Button variant="secondary" onClick={() => copyUrl(preview.url)}>
                Copy URL
              </Button>
              <a
                href={preview.url}
                target="_blank"
                rel="noreferrer"
                className="inline-flex min-h-10 items-center justify-center rounded-xl bg-et-green px-4 text-[13px] font-semibold text-white hover:bg-et-green-dark"
              >
                Open in new tab
              </a>
              <Button variant="ghost" onClick={() => setPreview(null)}>
                Close
              </Button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
