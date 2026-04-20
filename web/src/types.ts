export interface Teacher {
  id: string;
  email: string;
  phone: string | null;
  name: string;
  role: 'TEACHER' | 'ADMIN';
}

export interface Session {
  token: string;
  teacher: Teacher;
}

export type LeadStatus = 'NEW' | 'CONTACTED' | 'INTERESTED' | 'ENROLLED' | 'LOST';

export interface Lead {
  id: string;
  teacherId: string;
  teacher?: Pick<Teacher, 'id' | 'name' | 'email'>;
  studentName: string;
  studentClass: string;
  currentSchool: string | null;
  parentName: string;
  parentNumber: string;
  address: string | null;
  location: string | null;
  status: LeadStatus;
  notes: string | null;
  createdAt: string;
  updatedAt: string;
}

export interface Reminder {
  id: string;
  leadId: string;
  teacherId: string;
  remindAt: string;
  note: string | null;
  status: 'PENDING' | 'NOTIFIED' | 'COMPLETED' | 'CANCELLED';
  createdAt: string;
  updatedAt: string;
}

export interface Highlight {
  id: string;
  kind: 'photo' | 'achievement' | 'testimonial' | 'video';
  title: string;
  body: string | null;
  mediaUrl: string | null;
  order: number;
  createdAt: string;
  updatedAt: string;
}

export interface LeadsPerTeacher {
  teacherId: string;
  teacherName: string;
  totalLeads: number;
  enrolledLeads: number;
  conversionRate: number;
}

export interface AnalyticsOverview {
  byClass: { studentClass: string; total: number }[];
  timeseries: { day: string; count: number }[];
}
