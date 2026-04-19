import { Router } from "express";
import { z } from "zod";
import { prisma } from "../db";
import { requireAuth, requireRole } from "../middleware/auth";
import { HttpError } from "../middleware/error";

export const highlightsRouter = Router();

// Read is allowed for any authenticated user (teacher presenting to a parent).
highlightsRouter.get("/", requireAuth, async (_req, res, next) => {
  try {
    const highlights = await prisma.highlight.findMany({
      orderBy: [{ order: "asc" }, { createdAt: "asc" }],
    });
    res.json({ highlights });
  } catch (err) {
    next(err);
  }
});

const highlightSchema = z.object({
  kind: z.enum(["photo", "achievement", "testimonial", "video"]),
  title: z.string().min(1),
  body: z.string().optional().nullable(),
  mediaUrl: z.string().url().optional().nullable(),
  order: z.number().int().optional(),
});

// Mutations are admin-only.
highlightsRouter.post("/", requireAuth, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const body = highlightSchema.parse(req.body);
    const h = await prisma.highlight.create({
      data: {
        kind: body.kind,
        title: body.title,
        body: body.body ?? null,
        mediaUrl: body.mediaUrl ?? null,
        order: body.order ?? 0,
      },
    });
    res.status(201).json({ highlight: h });
  } catch (err) {
    next(err);
  }
});

highlightsRouter.patch("/:id", requireAuth, requireRole("ADMIN"), async (req, res, next) => {
  try {
    const body = highlightSchema.partial().parse(req.body);
    const existing = await prisma.highlight.findUnique({ where: { id: req.params.id } });
    if (!existing) throw new HttpError(404, "Not found");
    const h = await prisma.highlight.update({
      where: { id: existing.id },
      data: {
        kind: body.kind,
        title: body.title,
        body: body.body ?? undefined,
        mediaUrl: body.mediaUrl ?? undefined,
        order: body.order ?? undefined,
      },
    });
    res.json({ highlight: h });
  } catch (err) {
    next(err);
  }
});

highlightsRouter.delete("/:id", requireAuth, requireRole("ADMIN"), async (req, res, next) => {
  try {
    await prisma.highlight.delete({ where: { id: req.params.id } });
    res.status(204).end();
  } catch (err) {
    next(err);
  }
});
