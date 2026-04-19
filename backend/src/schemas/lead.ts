import { z } from "zod";

export const leadStatusEnum = z.enum([
  "NEW",
  "CONTACTED",
  "INTERESTED",
  "ENROLLED",
  "LOST",
]);

/// Full lead payload used for create/upsert from the mobile client.
/// The mobile app generates the UUID locally so offline-created leads
/// keep a stable identity across sync.
export const leadUpsertSchema = z.object({
  id: z.string().uuid(),
  studentName: z.string().min(1),
  studentClass: z.string().min(1),
  currentSchool: z.string().optional().nullable(),
  parentName: z.string().min(1),
  parentNumber: z.string().min(5),
  address: z.string().optional().nullable(),
  location: z.string().optional().nullable(),
  status: leadStatusEnum.optional(),
  notes: z.string().optional().nullable(),
  // Client clock. Used for last-write-wins conflict resolution.
  updatedAt: z.string().datetime().optional(),
});
export type LeadUpsertInput = z.infer<typeof leadUpsertSchema>;

export const leadPatchSchema = leadUpsertSchema.partial().omit({ id: true });
export type LeadPatchInput = z.infer<typeof leadPatchSchema>;

export const leadSyncSchema = z.object({
  leads: z.array(leadUpsertSchema).max(500),
});
export type LeadSyncInput = z.infer<typeof leadSyncSchema>;

export const leadListQuerySchema = z.object({
  teacherId: z.string().uuid().optional(),
  studentClass: z.string().optional(),
  location: z.string().optional(),
  from: z.string().datetime().optional(),
  to: z.string().datetime().optional(),
  status: leadStatusEnum.optional(),
  q: z.string().optional(),
});
export type LeadListQuery = z.infer<typeof leadListQuerySchema>;
