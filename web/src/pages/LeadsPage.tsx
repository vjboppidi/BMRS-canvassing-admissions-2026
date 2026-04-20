import { useMemo, useState } from 'react';
import { useQuery } from '@tanstack/react-query';
import { format } from 'date-fns';
import { api } from '../api/client';
import { useAuth } from '../auth/useAuth';
import { downloadCsv, toCsv } from '../utils/csv';
import type { Lead, LeadStatus, Teacher } from '../types';

const CLASSES = [
  'Nursery', 'LKG', 'UKG',
  'Class 1', 'Class 2', 'Class 3', 'Class 4', 'Class 5',
  'Class 6', 'Class 7', 'Class 8', 'Class 9', 'Class 10',
  'Class 11', 'Class 12',
];

const STATUSES: LeadStatus[] = ['NEW', 'CONTACTED', 'INTERESTED', 'ENROLLED', 'LOST'];

interface Filters {
  teacherId: string;
  studentClass: string;
  location: string;
  status: string;
  from: string;
  to: string;
  q: string;
}

const EMPTY: Filters = {
  teacherId: '',
  studentClass: '',
  location: '',
  status: '',
  from: '',
  to: '',
  q: '',
};

export default function LeadsPage() {
  const { session } = useAuth();
  const isAdmin = session?.teacher.role === 'ADMIN';
  const [filters, setFilters] = useState<Filters>(EMPTY);

  const teachersQuery = useQuery({
    queryKey: ['teachers'],
    enabled: isAdmin,
    queryFn: async () => {
      const { data } = await api.get<{ teachers: Teacher[] }>('/admin/teachers');
      return data.teachers;
    },
  });

  const leadsQuery = useQuery({
    queryKey: ['leads', filters],
    queryFn: async () => {
      const params: Record<string, string> = {};
      if (filters.teacherId) params.teacherId = filters.teacherId;
      if (filters.studentClass) params.studentClass = filters.studentClass;
      if (filters.location) params.location = filters.location;
      if (filters.status) params.status = filters.status;
      if (filters.from) params.from = filters.from;
      if (filters.to) params.to = filters.to;
      if (filters.q) params.q = filters.q;
      const { data } = await api.get<{ leads: Lead[] }>('/leads', { params });
      return data.leads;
    },
  });

  const onChange = (key: keyof Filters) => (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement>) =>
    setFilters((f) => ({ ...f, [key]: e.target.value }));

  const exportCsv = () => {
    const rows = (leadsQuery.data ?? []).map((l) => ({
      id: l.id,
      teacher: l.teacher?.name ?? l.teacherId,
      studentName: l.studentName,
      studentClass: l.studentClass,
      currentSchool: l.currentSchool ?? '',
      parentName: l.parentName,
      parentNumber: l.parentNumber,
      address: l.address ?? '',
      location: l.location ?? '',
      status: l.status,
      notes: l.notes ?? '',
      createdAt: l.createdAt,
      updatedAt: l.updatedAt,
    }));
    const csv = toCsv(rows, [
      { key: 'id', label: 'Lead ID' },
      { key: 'teacher', label: 'Teacher' },
      { key: 'studentName', label: 'Student' },
      { key: 'studentClass', label: 'Class' },
      { key: 'currentSchool', label: 'Current school' },
      { key: 'parentName', label: 'Parent' },
      { key: 'parentNumber', label: 'Parent phone' },
      { key: 'address', label: 'Address' },
      { key: 'location', label: 'Location' },
      { key: 'status', label: 'Status' },
      { key: 'notes', label: 'Notes' },
      { key: 'createdAt', label: 'Created at' },
      { key: 'updatedAt', label: 'Updated at' },
    ]);
    downloadCsv(`bmrs-leads-${format(new Date(), 'yyyy-MM-dd')}.csv`, csv);
  };

  const teachers = teachersQuery.data ?? [];
  const leads = leadsQuery.data ?? [];
  const uniqueLocations = useMemo(() => {
    const s = new Set<string>();
    for (const l of leadsQuery.data ?? []) if (l.location) s.add(l.location);
    return Array.from(s).sort();
  }, [leadsQuery.data]);

  return (
    <div className="page">
      <div className="page-header">
        <h2>Leads</h2>
        <button onClick={exportCsv} disabled={leads.length === 0}>
          Export CSV
        </button>
      </div>

      <div className="filters">
        {isAdmin && (
          <label>
            Teacher
            <select value={filters.teacherId} onChange={onChange('teacherId')}>
              <option value="">All teachers</option>
              {teachers.map((t) => (
                <option key={t.id} value={t.id}>
                  {t.name}
                </option>
              ))}
            </select>
          </label>
        )}
        <label>
          Class
          <select value={filters.studentClass} onChange={onChange('studentClass')}>
            <option value="">Any class</option>
            {CLASSES.map((c) => (
              <option key={c} value={c}>
                {c}
              </option>
            ))}
          </select>
        </label>
        <label>
          Status
          <select value={filters.status} onChange={onChange('status')}>
            <option value="">Any status</option>
            {STATUSES.map((s) => (
              <option key={s} value={s}>
                {s}
              </option>
            ))}
          </select>
        </label>
        <label>
          Location
          <input
            list="locations"
            type="text"
            value={filters.location}
            onChange={onChange('location')}
            placeholder="e.g. Bengaluru"
          />
          <datalist id="locations">
            {uniqueLocations.map((l) => (
              <option key={l} value={l} />
            ))}
          </datalist>
        </label>
        <label>
          From
          <input type="date" value={filters.from} onChange={onChange('from')} />
        </label>
        <label>
          To
          <input type="date" value={filters.to} onChange={onChange('to')} />
        </label>
        <label>
          Search
          <input
            type="search"
            value={filters.q}
            onChange={onChange('q')}
            placeholder="Student / parent / phone"
          />
        </label>
        <button className="ghost" onClick={() => setFilters(EMPTY)}>
          Reset
        </button>
      </div>

      {leadsQuery.isLoading && <p>Loading…</p>}
      {leadsQuery.isError && <p className="error">Failed to load leads.</p>}

      {!leadsQuery.isLoading && (
        <div className="table-wrap">
          <table>
            <thead>
              <tr>
                <th>Student</th>
                <th>Class</th>
                {isAdmin && <th>Teacher</th>}
                <th>Parent</th>
                <th>Phone</th>
                <th>Location</th>
                <th>Status</th>
                <th>Captured</th>
              </tr>
            </thead>
            <tbody>
              {leads.map((l) => (
                <tr key={l.id}>
                  <td>{l.studentName}</td>
                  <td>{l.studentClass}</td>
                  {isAdmin && <td>{l.teacher?.name ?? '—'}</td>}
                  <td>{l.parentName}</td>
                  <td>{l.parentNumber}</td>
                  <td>{l.location ?? '—'}</td>
                  <td>
                    <span className={`status status-${l.status.toLowerCase()}`}>{l.status}</span>
                  </td>
                  <td>{format(new Date(l.createdAt), 'd MMM yyyy')}</td>
                </tr>
              ))}
              {leads.length === 0 && (
                <tr>
                  <td colSpan={isAdmin ? 8 : 7} className="muted center">
                    No leads match these filters.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}
