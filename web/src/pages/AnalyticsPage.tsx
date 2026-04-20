import { useQuery } from '@tanstack/react-query';
import {
  Bar,
  BarChart,
  CartesianGrid,
  Legend,
  Line,
  LineChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';
import { api } from '../api/client';
import type { AnalyticsOverview, LeadsPerTeacher } from '../types';

export default function AnalyticsPage() {
  const perTeacherQuery = useQuery({
    queryKey: ['analytics', 'leads-per-teacher'],
    queryFn: async () => {
      const { data } = await api.get<{ teachers: LeadsPerTeacher[] }>(
        '/admin/analytics/leads-per-teacher',
      );
      return data.teachers;
    },
  });

  const overviewQuery = useQuery({
    queryKey: ['analytics', 'overview'],
    queryFn: async () => {
      const { data } = await api.get<AnalyticsOverview>('/admin/analytics/overview');
      return data;
    },
  });

  const perTeacher = perTeacherQuery.data ?? [];
  const overview = overviewQuery.data;

  return (
    <div className="page">
      <h2>Analytics</h2>

      <section className="card">
        <h3>Leads per teacher</h3>
        {perTeacherQuery.isLoading && <p>Loading…</p>}
        {perTeacherQuery.isError && <p className="error">Failed to load analytics.</p>}
        {perTeacher.length > 0 && (
          <>
            <div style={{ width: '100%', height: 320 }}>
              <ResponsiveContainer>
                <BarChart data={perTeacher}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="teacherName" />
                  <YAxis />
                  <Tooltip />
                  <Legend />
                  <Bar dataKey="totalLeads" fill="#6366f1" name="Total leads" />
                  <Bar dataKey="enrolledLeads" fill="#22c55e" name="Enrolled" />
                </BarChart>
              </ResponsiveContainer>
            </div>
            <table className="compact">
              <thead>
                <tr>
                  <th>Teacher</th>
                  <th>Total</th>
                  <th>Enrolled</th>
                  <th>Conversion</th>
                </tr>
              </thead>
              <tbody>
                {perTeacher.map((t) => (
                  <tr key={t.teacherId}>
                    <td>{t.teacherName}</td>
                    <td>{t.totalLeads}</td>
                    <td>{t.enrolledLeads}</td>
                    <td>{(t.conversionRate * 100).toFixed(1)}%</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </>
        )}
      </section>

      <section className="card">
        <h3>Leads by class</h3>
        {overview && overview.byClass.length > 0 && (
          <div style={{ width: '100%', height: 300 }}>
            <ResponsiveContainer>
              <BarChart data={overview.byClass}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="studentClass" />
                <YAxis allowDecimals={false} />
                <Tooltip />
                <Bar dataKey="total" fill="#0ea5e9" name="Leads" />
              </BarChart>
            </ResponsiveContainer>
          </div>
        )}
      </section>

      <section className="card">
        <h3>Leads captured (last 30 days)</h3>
        {overview && overview.timeseries.length > 0 && (
          <div style={{ width: '100%', height: 300 }}>
            <ResponsiveContainer>
              <LineChart data={overview.timeseries}>
                <CartesianGrid strokeDasharray="3 3" />
                <XAxis dataKey="day" />
                <YAxis allowDecimals={false} />
                <Tooltip />
                <Line type="monotone" dataKey="count" stroke="#6366f1" />
              </LineChart>
            </ResponsiveContainer>
          </div>
        )}
      </section>
    </div>
  );
}
