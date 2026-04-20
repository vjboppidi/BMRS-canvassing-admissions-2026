import { z } from "zod";

export const reminderStatusEnum = z.enum([
  "PENDING",
  "NOTIFIED",
  "COMPLETED",
  "CANCELLED",
]);

export const reminderUpsertSchema = z.object({
  id: z.string().uuid(),
  leadId: z.string().uuid(),
  remindAt: z.string().datetime(),
  note: z.string().optional().nullable(),
  status: reminderStatusEnum.optional(),
  updatedAt: z.string().datetime().optional(),
});
export type ReminderUpsertInput = z.infer<typeof reminderUpsertSchema>;

export const reminderPatchSchema = reminderUpsertSchema.partial().omit({ id: true });
export type ReminderPatchInput = z.infer<typeof reminderPatchSchema>;
