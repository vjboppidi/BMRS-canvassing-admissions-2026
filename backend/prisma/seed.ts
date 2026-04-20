import { PrismaClient } from "@prisma/client";
import bcrypt from "bcryptjs";
import { randomUUID } from "node:crypto";

const prisma = new PrismaClient();

async function main() {
  const adminPwd = await bcrypt.hash("admin12345", 10);
  const teacherPwd = await bcrypt.hash("teacher12345", 10);

  const admin = await prisma.teacher.upsert({
    where: { email: "admin@bmrs.local" },
    update: {},
    create: {
      email: "admin@bmrs.local",
      name: "BMRS Admin",
      passwordHash: adminPwd,
      role: "ADMIN",
    },
  });

  const teacher = await prisma.teacher.upsert({
    where: { email: "teacher@bmrs.local" },
    update: {},
    create: {
      email: "teacher@bmrs.local",
      name: "Priya Teacher",
      passwordHash: teacherPwd,
      role: "TEACHER",
    },
  });

  // A couple of demo leads
  await prisma.lead.upsert({
    where: { id: "11111111-1111-1111-1111-111111111111" },
    update: {},
    create: {
      id: "11111111-1111-1111-1111-111111111111",
      teacherId: teacher.id,
      studentName: "Arjun Kumar",
      studentClass: "Class 6",
      currentSchool: "Little Flower",
      parentName: "Rajesh Kumar",
      parentNumber: "+919000000001",
      address: "MG Road, Bengaluru",
      location: "Bengaluru",
      status: "INTERESTED",
    },
  });
  await prisma.lead.upsert({
    where: { id: "22222222-2222-2222-2222-222222222222" },
    update: {},
    create: {
      id: "22222222-2222-2222-2222-222222222222",
      teacherId: teacher.id,
      studentName: "Meera Iyer",
      studentClass: "Class 4",
      currentSchool: "Sunrise School",
      parentName: "Lakshmi Iyer",
      parentNumber: "+919000000002",
      address: "Whitefield, Bengaluru",
      location: "Bengaluru",
      status: "NEW",
    },
  });

  await prisma.highlight.upsert({
    where: { id: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa" },
    update: {},
    create: {
      id: "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
      kind: "achievement",
      title: "State topper 2025",
      body: "Our Class 12 student secured AIR 1 in state board exams.",
      order: 1,
    },
  });
  await prisma.highlight.upsert({
    where: { id: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb" },
    update: {},
    create: {
      id: "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb",
      kind: "testimonial",
      title: "A parent's note",
      body: "BMRS has been transformative for our daughter's confidence.",
      order: 2,
    },
  });

  // Reminder example
  const remindAt = new Date(Date.now() + 3 * 24 * 60 * 60 * 1000);
  await prisma.reminder.upsert({
    where: { id: "cccccccc-cccc-cccc-cccc-cccccccccccc" },
    update: {},
    create: {
      id: "cccccccc-cccc-cccc-cccc-cccccccccccc",
      leadId: "11111111-1111-1111-1111-111111111111",
      teacherId: teacher.id,
      remindAt,
      note: "Call parent about admissions form",
    },
  });

  // eslint-disable-next-line no-console
  console.log("Seed complete:", { adminId: admin.id, teacherId: teacher.id, demoReminder: randomUUID() });
}

main()
  .catch((e) => {
    // eslint-disable-next-line no-console
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
