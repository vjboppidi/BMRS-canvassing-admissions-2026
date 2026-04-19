import { Router } from "express";
import type { Prisma } from "@prisma/client";
import { prisma } from "../db";
import { requireAuth } from "../middleware/auth";
import { HttpError } from "../middleware/error";
import {
  leadListQuerySchema,
  leadPatchSchema,
  leadSyncSchema,
  leadUpsertSchema,
} from "../schemas/lead";

export const leadsRouter = Router();

leadsRouter.use(requireAuth);

// GET /leads — list with filters.
// Teachers only see their own; admins can optionally filter by teacherId.
leadsRouter.get("/", async (req, res, next) => {
  try {
    const q = leadListQuerySchema.parse(req.query);
    const user = req.user!;

    const where: Prisma.LeadWhereInput = {};
    if (user.role === "TEACHER") {
      where.teacherId = user.sub;
    } else if (q.teacherId) {
      where.teacherId = q.teacherId;
    }
    if (q.studentClass) where.studentClass = q.studentClass;
    if (q.location) where.location = { contains: q.location, mode: "insensitive" };
    if (q.status) where.status = q.status;
    if (q.from || q.to) {
      where.createdAt = {};
      if (q.from) where.createdAt.gte = new Date(q.from);
      if (q.to) where.createdAt.lte = new Date(q.to);
    }
    if (q.q) {
      where.OR = [
        { studentName: { contains: q.q, mode: "insensitive" } },
        { parentName: { contains: q.q, mode: "insensitive" } },
        { parentNumber: { contains: q.q } },
      ];
    }

    const leads = await prisma.lead.findMany({
      where,
      orderBy: { updatedAt: "desc" },
      include: { teacher: { select: { id: true, name: true, email: true } } },
    });
    res.json({ leads });
  } catch (err) {
    next(err);
  }
});

// GET /leads/:id
leadsRouter.get("/:id", async (req, res, next) => {
  try {
    const lead = await prisma.lead.findUnique({ where: { id: req.params.id } });
    if (!lead) throw new HttpError(404, "Lead not found");
    if (req.user!.role === "TEACHER" && lead.teacherId !== req.user!.sub) {
      throw new HttpError(403, "Forbidden");
    }
    res.json({ lead });
  } catch (err) {
    next(err);
  }
});

// POST /leads — create (or upsert by id).
// Last-write-wins: if the client's updatedAt is older than the stored
// updatedAt, we keep the stored copy and return it with a 200.
leadsRouter.post("/", async (req, res, next) => {
  try {
    const body = leadUpsertSchema.parse(req.body);
    const teacherId = req.user!.sub;
    const result = await upsertLead(body, teacherId);
    res.status(result.created ? 201 : 200).json({ lead: result.lead, conflict: result.conflict });
  } catch (err) {
    next(err);
  }
});

// POST /leads/sync — bulk upsert from offline queue.
leadsRouter.post("/sync", async (req, res, next) => {
  try {
    const { leads } = leadSyncSchema.parse(req.body);
    const teacherId = req.user!.sub;
    const results = [];
    for (const l of leads) {
      const r = await upsertLead(l, teacherId);
      results.push({ id: l.id, created: r.created, conflict: r.conflict });
    }
    res.json({ results });
  } catch (err) {
    next(err);
  }
});

// PATCH /leads/:id
leadsRouter.patch("/:id", async (req, res, next) => {
  try {
    const body = leadPatchSchema.parse(req.body);
    const existing = await prisma.lead.findUnique({ where: { id: req.params.id } });
    if (!existing) throw new HttpError(404, "Lead not found");
    if (req.user!.role === "TEACHER" && existing.teacherId !== req.user!.sub) {
      throw new HttpError(403, "Forbidden");
    }

    const data: Prisma.LeadUpdateInput = {};
    if (body.studentName !== undefined) data.studentName = body.studentName;
    if (body.studentClass !== undefined) data.studentClass = body.studentClass;
    if (body.currentSchool !== undefined) data.currentSchool = body.currentSchool;
    if (body.parentName !== undefined) data.parentName = body.parentName;
    if (body.parentNumber !== undefined) data.parentNumber = body.parentNumber;
    if (body.address !== undefined) data.address = body.address;
    if (body.location !== undefined) data.location = body.location;
    if (body.status !== undefined) data.status = body.status;
    if (body.notes !== undefined) data.notes = body.notes;

    const lead = await prisma.lead.update({ where: { id: existing.id }, data });
    res.json({ lead });
  } catch (err) {
    next(err);
  }
});

// DELETE /leads/:id
leadsRouter.delete("/:id", async (req, res, next) => {
  try {
    const existing = await prisma.lead.findUnique({ where: { id: req.params.id } });
    if (!existing) throw new HttpError(404, "Lead not found");
    if (req.user!.role === "TEACHER" && existing.teacherId !== req.user!.sub) {
      throw new HttpError(403, "Forbidden");
    }
    await prisma.lead.delete({ where: { id: existing.id } });
    res.status(204).end();
  } catch (err) {
    next(err);
  }
});

async function upsertLead(
  body: import("../schemas/lead").LeadUpsertInput,
  teacherId: string,
): Promise<{ lead: import("@prisma/client").Lead; created: boolean; conflict: boolean }> {
  const existing = await prisma.lead.findUnique({ where: { id: body.id } });

  if (existing && existing.teacherId !== teacherId) {
    // Another teacher owns this id — refuse.
    throw new HttpError(409, "Lead belongs to another teacher");
  }

  // Last-write-wins: if client timestamp is older, keep server copy.
  if (existing && body.updatedAt) {
    const clientTs = new Date(body.updatedAt).getTime();
    if (clientTs <= existing.updatedAt.getTime()) {
      return { lead: existing, created: false, conflict: true };
    }
  }

  const lead = await prisma.lead.upsert({
    where: { id: body.id },
    update: {
      studentName: body.studentName,
      studentClass: body.studentClass,
      currentSchool: body.currentSchool ?? null,
      parentName: body.parentName,
      parentNumber: body.parentNumber,
      address: body.address ?? null,
      location: body.location ?? null,
      status: body.status ?? undefined,
      notes: body.notes ?? null,
    },
    create: {
      id: body.id,
      teacherId,
      studentName: body.studentName,
      studentClass: body.studentClass,
      currentSchool: body.currentSchool ?? null,
      parentName: body.parentName,
      parentNumber: body.parentNumber,
      address: body.address ?? null,
      location: body.location ?? null,
      status: body.status ?? "NEW",
      notes: body.notes ?? null,
    },
  });
  return { lead, created: !existing, conflict: false };
}
