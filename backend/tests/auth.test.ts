/**
 * Minimal unit test for the JWT helper. The full API tests require a live
 * Postgres instance and are intended to run in CI against a service container.
 */
import { signToken, verifyToken } from "../src/utils/jwt";

describe("jwt helper", () => {
  it("round-trips a payload", () => {
    const token = signToken({ sub: "user-1", role: "TEACHER", email: "a@b.co" });
    const decoded = verifyToken(token);
    expect(decoded.sub).toBe("user-1");
    expect(decoded.role).toBe("TEACHER");
    expect(decoded.email).toBe("a@b.co");
  });

  it("rejects tampered tokens", () => {
    const token = signToken({ sub: "user-1", role: "TEACHER", email: "a@b.co" });
    const tampered = token.slice(0, -2) + (token.endsWith("a") ? "bb" : "aa");
    expect(() => verifyToken(tampered)).toThrow();
  });
});
