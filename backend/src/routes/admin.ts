import { Router } from "express";
import { prisma } from "../db";
import { requireAuth, requireRole } from "../middleware/auth";

export const adminRouter = Router();

adminRouter.use(requireAuth, requireRole("ADMIN"));

adminRouter.get("/teachers", async (_req, res, next) => {
  try {
    const teachers = await prisma.teacher.findMany({
      select: { id: true, email: true, phone: true, name: true, role: true },
      orderBy: { name: "asc" },
    });
    res.json({ teachers });
  } catch (err) {
    next(err);
  }
});

// Aggregate: leads per teacher, with conversion counts.
adminRouter.get("/analytics/leads-per-teacher", async (_req, res, next) => {
  try {
    const teachers = await prisma.teacher.findMany({
      where: { role: "TEACHER" },
      select: { id: true, name: true, email: true },
    });

    const grouped = await prisma.lead.groupBy({
      by: ["teacherId", "status"],
      _count: { _all: true },
    });

    const byTeacher = new Map<string, { total: number; enrolled: number; interested: number }>();
    for (const g of grouped) {
      const cur = byTeacher.get(g.teacherId) ?? { total: 0, enrolled: 0, interested: 0 };
      cur.total += g._count._all;
      if (g.status === "ENROLLED") cur.enrolled += g._count._all;
      if (g.status === "INTERESTED") cur.interested += g._count._all;
      byTeacher.set(g.teacherId, cur);
    }

    const rows = teachers.map((t) => {
      const c = byTeacher.get(t.id) ?? { total: 0, enrolled: 0, interested: 0 };
      return {
        teacherId: t.id,
        teacherName: t.name,
        teacherEmail: t.email,
        totalLeads: c.total,
        enrolledLeads: c.enrolled,
        interestedLeads: c.interested,
        conversionRate: c.total > 0 ? c.enrolled / c.total : 0,
      };
    });

    res.json({ teachers: rows });
  } catch (err) {
    next(err);
  }
});

// Aggregate: leads per class + leads over time (by day, last 30d).
adminRouter.get("/analytics/overview", async (_req, res, next) => {
  try {
    const byClass = await prisma.lead.groupBy({
      by: ["studentClass"],
      _count: { _all: true },
      orderBy: { studentClass: "asc" },
    });

    const since = new Date();
    since.setDate(since.getDate() - 30);
    const recent = await prisma.lead.findMany({
      where: { createdAt: { gte: since } },
      select: { createdAt: true, status: true },
    });

    const byDay = new Map<string, number>();
    for (const l of recent) {
      const key = l.createdAt.toISOString().slice(0, 10);
      byDay.set(key, (byDay.get(key) ?? 0) + 1);
    }
    const timeseries = Array.from(byDay.entries())
      .sort(([a], [b]) => a.localeCompare(b))
      .map(([day, count]) => ({ day, count }));

    res.json({
      byClass: byClass.map((r) => ({ studentClass: r.studentClass, total: r._count._all })),
      timeseries,
    });
  } catch (err) {
    next(err);
  }
});
