import { useCallback, useEffect, useState } from 'react';
import client, { apiError } from '../api/client';
import {
  PageHeader,
  Card,
  Button,
  Banner,
  Badge,
  inputCls,
  EmptyState,
  tableShellCls,
  thCls,
  tdCls,
} from '../components/ui';

const STATUS_BADGE = {
  pending: ['pending', 'warning'],
  approved: ['approved', 'success'],
  rejected: ['rejected', 'danger'],
  waiting: ['waiting', 'warning'],
  matched: ['matched', 'success'],
  closed: ['closed', 'neutral'],
};

function BadgeFor({ status }) {
  const [label, tone] = STATUS_BADGE[status] || [status, 'neutral'];
  return <Badge tone={tone}>{label}</Badge>;
}

export default function Community() {
  const [tab, setTab] = useState('stories');
  const [stories, setStories] = useState([]);
  const [exchange, setExchange] = useState([]);
  const [error, setError] = useState('');
  const [filter, setFilter] = useState('pending');

  const load = useCallback(async () => {
    setError('');
    try {
      if (tab === 'stories') {
        const q = filter ? `?status=${filter}` : '';
        const { data } = await client.get(`/admin/stories${q}`);
        setStories(Array.isArray(data) ? data : []);
      } else {
        const { data } = await client.get('/admin/exchange');
        setExchange(Array.isArray(data) ? data : []);
      }
    } catch (e) {
      setError(apiError(e));
    }
  }, [tab, filter]);

  useEffect(() => {
    load();
  }, [load]);

  async function moderate(id, status) {
    try {
      await client.put(`/admin/stories/${id}`, { status });
      await load();
    } catch (e) {
      setError(apiError(e));
    }
  }

  async function setExchangeStatus(id, status) {
    try {
      await client.put(`/admin/exchange/${id}`, { status });
      await load();
    } catch (e) {
      setError(apiError(e));
    }
  }

  return (
    <div>
      <PageHeader
        eyebrow="Community"
        title="Stories & exchange"
        subtitle="Moderate user stories and manage the language-exchange waitlist."
      />
      {error && <Banner tone="error">{error}</Banner>}

      <div className="my-4 flex gap-2">
        <Button
          variant={tab === 'stories' ? 'primary' : 'secondary'}
          onClick={() => setTab('stories')}
        >
          Stories
        </Button>
        <Button
          variant={tab === 'exchange' ? 'primary' : 'secondary'}
          onClick={() => setTab('exchange')}
        >
          Language exchange
        </Button>
      </div>

      {tab === 'stories' && (
        <Card>
          <div className="mb-3 flex items-center gap-2">
            <span className="text-sm font-semibold">Status</span>
            <select
              className={inputCls}
              value={filter}
              onChange={(e) => setFilter(e.target.value)}
            >
              <option value="pending">Pending</option>
              <option value="approved">Approved</option>
              <option value="rejected">Rejected</option>
              <option value="">All</option>
            </select>
            <Button onClick={load}>Refresh</Button>
          </div>
          {stories.length === 0 ? (
            <EmptyState title="No stories in this filter" />
          ) : (
            <div className={tableShellCls}>
              <table className="w-full text-sm">
                <thead>
                  <tr>
                    <th className={thCls}>Author</th>
                    <th className={thCls}>Title</th>
                    <th className={thCls}>Story</th>
                    <th className={thCls}>Status</th>
                    <th className={thCls}>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {stories.map((s) => (
                    <tr key={s.id}>
                      <td className={tdCls}>{s.author}</td>
                      <td className={tdCls}>{s.title}</td>
                      <td className={`${tdCls} max-w-md`}>
                        <span className="line-clamp-3">{s.body}</span>
                      </td>
                      <td className={tdCls}>
                        <BadgeFor status={s.status} />
                      </td>
                      <td className={tdCls}>
                        <div className="flex gap-1">
                          <Button
                            variant="primary"
                            onClick={() => moderate(s.id, 'approved')}
                          >
                            Approve
                          </Button>
                          <Button
                            variant="danger"
                            onClick={() => moderate(s.id, 'rejected')}
                          >
                            Reject
                          </Button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </Card>
      )}

      {tab === 'exchange' && (
        <Card>
          <div className="mb-3">
            <Button onClick={load}>Refresh</Button>
          </div>
          {exchange.length === 0 ? (
            <EmptyState title="No exchange signups yet" />
          ) : (
            <div className={tableShellCls}>
              <table className="w-full text-sm">
                <thead>
                  <tr>
                    <th className={thCls}>Learner</th>
                    <th className={thCls}>Speaks</th>
                    <th className={thCls}>Learning</th>
                    <th className={thCls}>Note</th>
                    <th className={thCls}>Status</th>
                    <th className={thCls}>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {exchange.map((e) => (
                    <tr key={e.id}>
                      <td className={tdCls}>{e.author}</td>
                      <td className={tdCls}>{e.speaks}</td>
                      <td className={tdCls}>{e.learning}</td>
                      <td className={`${tdCls} max-w-xs`}>{e.note}</td>
                      <td className={tdCls}>
                        <BadgeFor status={e.status} />
                      </td>
                      <td className={tdCls}>
                        <div className="flex gap-1">
                          <Button
                            variant="primary"
                            onClick={() => setExchangeStatus(e.id, 'matched')}
                          >
                            Match
                          </Button>
                          <Button
                            variant="secondary"
                            onClick={() => setExchangeStatus(e.id, 'waiting')}
                          >
                            Wait
                          </Button>
                          <Button
                            variant="danger"
                            onClick={() => setExchangeStatus(e.id, 'closed')}
                          >
                            Close
                          </Button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          )}
        </Card>
      )}
    </div>
  );
}
