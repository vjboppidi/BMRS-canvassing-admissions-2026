import { Router } from "express";
import bcrypt from "bcryptjs";
import { prisma } from "../db";
import { signToken } from "../utils/jwt";
import { loginSchema, registerSchema } from "../schemas/auth";
import { HttpError } from "../middleware/error";
import { requireAuth } from "../middleware/auth";

export const authRouter = Router();

authRouter.post("/register", async (req, res, next) => {
  try {
    const body = registerSchema.parse(req.body);
    const existing = await prisma.teacher.findUnique({ where: { email: body.email } });
    if (existing) throw new HttpError(409, "Email already registered");

    const passwordHash = await bcrypt.hash(body.password, 10);
    const teacher = await prisma.teacher.create({
      data: {
        email: body.email,
        phone: body.phone,
        name: body.name,
        passwordHash,
        role: body.role ?? "TEACHER",
      },
    });

    const token = signToken({ sub: teacher.id, role: teacher.role, email: teacher.email });
    res.status(201).json({
      token,
      teacher: {
        id: teacher.id,
        email: teacher.email,
        name: teacher.name,
        role: teacher.role,
      },
    });
  } catch (err) {
    next(err);
  }
});

authRouter.post("/login", async (req, res, next) => {
  try {
    const body = loginSchema.parse(req.body);
    const teacher = await prisma.teacher.findUnique({ where: { email: body.email } });
    if (!teacher) throw new HttpError(401, "Invalid credentials");
    const ok = await bcrypt.compare(body.password, teacher.passwordHash);
    if (!ok) throw new HttpError(401, "Invalid credentials");

    const token = signToken({ sub: teacher.id, role: teacher.role, email: teacher.email });
    res.json({
      token,
      teacher: {
        id: teacher.id,
        email: teacher.email,
        name: teacher.name,
        role: teacher.role,
      },
    });
  } catch (err) {
    next(err);
  }
});

authRouter.get("/me", requireAuth, async (req, res, next) => {
  try {
    const teacher = await prisma.teacher.findUnique({
      where: { id: req.user!.sub },
      select: { id: true, email: true, name: true, phone: true, role: true, createdAt: true },
    });
    if (!teacher) throw new HttpError(404, "Not found");
    res.json({ teacher });
  } catch (err) {
    next(err);
  }
});
