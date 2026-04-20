import { Router } from "express";
import type { Prisma } from "@prisma/client";
import { prisma } from "../db";
import { requireAuth } from "../middleware/auth";
import { HttpError } from "../middleware/error";
import { reminderPatchSchema, reminderUpsertSchema } from "../schemas/reminder";

export const remindersRouter = Router();

remindersRouter.use(requireAuth);

remindersRouter.get("/", async (req, res, next) => {
  try {
    const where: Prisma.ReminderWhereInput =
      req.user!.role === "TEACHER" ? { teacherId: req.user!.sub } : {};
    const reminders = await prisma.reminder.findMany({
      where,
      orderBy: { remindAt: "asc" },
      include: { lead: { select: { id: true, studentName: true, parentName: true } } },
    });
    res.json({ reminders });
  } catch (err) {
    next(err);
  }
});

remindersRouter.post("/", async (req, res, next) => {
  try {
    const body = reminderUpsertSchema.parse(req.body);
    const lead = await prisma.lead.findUnique({ where: { id: body.leadId } });
    if (!lead) throw new HttpError(404, "Lead not found");
    if (lead.teacherId !== req.user!.sub) throw new HttpError(403, "Forbidden");

    const existing = await prisma.reminder.findUnique({ where: { id: body.id } });
    if (existing) {
      if (existing.teacherId !== req.user!.sub) throw new HttpError(403, "Forbidden");
      if (body.updatedAt) {
        const clientTs = new Date(body.updatedAt).getTime();
        if (clientTs <= existing.updatedAt.getTime()) {
          res.json({ reminder: existing, conflict: true });
          return;
        }
      }
    }

    const reminder = await prisma.reminder.upsert({
      where: { id: body.id },
      update: {
        remindAt: new Date(body.remindAt),
        note: body.note ?? null,
        status: body.status ?? undefined,
      },
      create: {
        id: body.id,
        leadId: body.leadId,
        teacherId: req.user!.sub,
        remindAt: new Date(body.remindAt),
        note: body.note ?? null,
        status: body.status ?? "PENDING",
      },
    });
    res.status(existing ? 200 : 201).json({ reminder, conflict: false });
  } catch (err) {
    next(err);
  }
});

remindersRouter.patch("/:id", async (req, res, next) => {
  try {
    const body = reminderPatchSchema.parse(req.body);
    const existing = await prisma.reminder.findUnique({ where: { id: req.params.id } });
    if (!existing) throw new HttpError(404, "Reminder not found");
    if (req.user!.role === "TEACHER" && existing.teacherId !== req.user!.sub) {
      throw new HttpError(403, "Forbidden");
    }

    const data: Prisma.ReminderUpdateInput = {};
    if (body.remindAt !== undefined) data.remindAt = new Date(body.remindAt);
    if (body.note !== undefined) data.note = body.note;
    if (body.status !== undefined) data.status = body.status;

    const reminder = await prisma.reminder.update({ where: { id: existing.id }, data });
    res.json({ reminder });
  } catch (err) {
    next(err);
  }
});

remindersRouter.delete("/:id", async (req, res, next) => {
  try {
    const existing = await prisma.reminder.findUnique({ where: { id: req.params.id } });
    if (!existing) throw new HttpError(404, "Reminder not found");
    if (req.user!.role === "TEACHER" && existing.teacherId !== req.user!.sub) {
      throw new HttpError(403, "Forbidden");
    }
    await prisma.reminder.delete({ where: { id: existing.id } });
    res.status(204).end();
  } catch (err) {
    next(err);
  }
});
