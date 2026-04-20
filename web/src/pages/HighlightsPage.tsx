import { type FormEvent, useState } from 'react';
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import { api } from '../api/client';
import { useAuth } from '../auth/useAuth';
import type { Highlight } from '../types';

const KINDS: Highlight['kind'][] = ['photo', 'achievement', 'testimonial', 'video'];

export default function HighlightsPage() {
  const { session } = useAuth();
  const isAdmin = session?.teacher.role === 'ADMIN';
  const qc = useQueryClient();

  const { data = [], isLoading } = useQuery({
    queryKey: ['highlights'],
    queryFn: async () => {
      const { data } = await api.get<{ highlights: Highlight[] }>('/school-highlights');
      return data.highlights;
    },
  });

  const createMut = useMutation({
    mutationFn: async (payload: Omit<Highlight, 'id' | 'createdAt' | 'updatedAt'>) => {
      const { data } = await api.post<{ highlight: Highlight }>('/school-highlights', payload);
      return data.highlight;
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['highlights'] }),
  });

  const deleteMut = useMutation({
    mutationFn: async (id: string) => {
      await api.delete(`/school-highlights/${id}`);
    },
    onSuccess: () => qc.invalidateQueries({ queryKey: ['highlights'] }),
  });

  return (
    <div className="page">
      <h2>School Highlights</h2>
      <p className="muted">
        Shown to parents via the mobile app's "School Highlights" tab. Admins can add or remove items.
      </p>

      {isLoading && <p>Loading…</p>}

      <div className="highlights-grid">
        {data.map((h) => (
          <div key={h.id} className="card">
            <div className="kind">{h.kind}</div>
            <h3>{h.title}</h3>
            {h.body && <p>{h.body}</p>}
            {h.mediaUrl && <p className="muted break">{h.mediaUrl}</p>}
            {isAdmin && (
              <button className="ghost" onClick={() => deleteMut.mutate(h.id)}>
                Remove
              </button>
            )}
          </div>
        ))}
        {data.length === 0 && !isLoading && <p className="muted">No highlights yet.</p>}
      </div>

      {isAdmin && <NewHighlightForm onSubmit={(p) => createMut.mutateAsync(p)} />}
    </div>
  );
}

function NewHighlightForm({
  onSubmit,
}: {
  onSubmit: (payload: Omit<Highlight, 'id' | 'createdAt' | 'updatedAt'>) => Promise<Highlight>;
}) {
  const [kind, setKind] = useState<Highlight['kind']>('achievement');
  const [title, setTitle] = useState('');
  const [body, setBody] = useState('');
  const [mediaUrl, setMediaUrl] = useState('');
  const [order, setOrder] = useState(0);
  const [busy, setBusy] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function submit(e: FormEvent) {
    e.preventDefault();
    setBusy(true);
    setError(null);
    try {
      await onSubmit({
        kind,
        title: title.trim(),
        body: body.trim() || null,
        mediaUrl: mediaUrl.trim() || null,
        order: Number.isFinite(order) ? order : 0,
      });
      setTitle('');
      setBody('');
      setMediaUrl('');
    } catch (err) {
      const e = err as { response?: { data?: { error?: string } }; message?: string };
      setError(e.response?.data?.error ?? e.message ?? 'Failed to save.');
    } finally {
      setBusy(false);
    }
  }

  return (
    <form className="card new-form" onSubmit={submit}>
      <h3>Add a highlight</h3>
      <div className="row">
        <label>
          Kind
          <select value={kind} onChange={(e) => setKind(e.target.value as Highlight['kind'])}>
            {KINDS.map((k) => (
              <option key={k} value={k}>
                {k}
              </option>
            ))}
          </select>
        </label>
        <label>
          Order
          <input
            type="number"
            value={order}
            onChange={(e) => setOrder(Number(e.target.value))}
          />
        </label>
      </div>
      <label>
        Title
        <input value={title} onChange={(e) => setTitle(e.target.value)} required />
      </label>
      <label>
        Body
        <textarea value={body} onChange={(e) => setBody(e.target.value)} rows={3} />
      </label>
      <label>
        Media URL
        <input
          value={mediaUrl}
          onChange={(e) => setMediaUrl(e.target.value)}
          placeholder="https://…"
        />
      </label>
      {error && <div className="error">{error}</div>}
      <button type="submit" disabled={busy}>
        {busy ? 'Saving…' : 'Add highlight'}
      </button>
    </form>
  );
}
