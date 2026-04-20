import jwt, { SignOptions } from "jsonwebtoken";
import { config } from "../config";

export interface JwtPayload {
  sub: string;
  role: "TEACHER" | "ADMIN";
  email: string;
}

export function signToken(payload: JwtPayload): string {
  const opts: SignOptions = { expiresIn: config.jwtExpiresIn as SignOptions["expiresIn"] };
  return jwt.sign(payload, config.jwtSecret, opts);
}

export function verifyToken(token: string): JwtPayload {
  const decoded = jwt.verify(token, config.jwtSecret);
  if (typeof decoded === "string") {
    throw new Error("Malformed JWT payload");
  }
  return decoded as unknown as JwtPayload;
}
