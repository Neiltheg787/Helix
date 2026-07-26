import type { SupabaseClient } from "@supabase/supabase-js";

import { createSupabaseServiceClient } from "@/lib/supabase-service";
import { createSupabaseForAccessToken } from "@/lib/supabase-user";

export const DEMO_USER_ID = "helix-hackathon-demo";
export const DEMO_ACCESS_TOKEN = "helix-demo";

export function isDemoApiToken(token: string): boolean {
  return (
    process.env.NEXT_PUBLIC_REQUIRE_SUPABASE_AUTH !== "true" &&
    token === DEMO_ACCESS_TOKEN
  );
}

/** Auth for AR handoff + Stripe routes only (not workspace/team). */
export async function resolveApiUser(
  token: string | null,
): Promise<{ id: string; email: string | null; isDemo: boolean } | null> {
  if (!token) return null;
  if (isDemoApiToken(token)) {
    return { id: DEMO_USER_ID, email: "demo@helix.local", isDemo: true };
  }
  try {
    const supabase = createSupabaseForAccessToken(token);
    const {
      data: { user },
      error,
    } = await supabase.auth.getUser(token);
    if (error || !user) return null;
    const email =
      typeof user.email === "string" && user.email.includes("@")
        ? user.email.trim()
        : null;
    return { id: user.id, email, isDemo: false };
  } catch {
    return null;
  }
}

export function dbForApiUser(token: string, isDemo: boolean): SupabaseClient {
  if (isDemo) {
    const svc = createSupabaseServiceClient();
    if (!svc) throw new Error("SUPABASE_SERVICE_ROLE_KEY required for demo checkout/AR");
    return svc;
  }
  return createSupabaseForAccessToken(token);
}
