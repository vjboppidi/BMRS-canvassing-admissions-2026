import express from "express";
import cors from "cors";
import helmet from "helmet";
import morgan from "morgan";
import { config } from "./config";
import { authRouter } from "./routes/auth";
import { leadsRouter } from "./routes/leads";
import { remindersRouter } from "./routes/reminders";
import { highlightsRouter } from "./routes/highlights";
import { adminRouter } from "./routes/admin";
import { errorHandler } from "./middleware/error";

export function createApp(): express.Express {
  const app = express();

  app.use(helmet());
  app.use(
    cors({
      origin: (origin, cb) => {
        if (!origin) return cb(null, true);
        if (config.corsOrigins.includes("*") || config.corsOrigins.includes(origin)) {
          return cb(null, true);
        }
        return cb(new Error(`CORS: origin ${origin} not allowed`));
      },
      credentials: true,
    }),
  );
  app.use(express.json({ limit: "1mb" }));
  if (config.nodeEnv !== "test") app.use(morgan("tiny"));

  app.get("/healthz", (_req, res) => res.json({ ok: true }));

  app.use("/auth", authRouter);
  app.use("/leads", leadsRouter);
  app.use("/reminders", remindersRouter);
  app.use("/school-highlights", highlightsRouter);
  app.use("/admin", adminRouter);

  app.use(errorHandler);
  return app;
}
