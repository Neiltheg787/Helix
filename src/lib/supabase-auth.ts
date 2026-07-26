"use client";

import {
  createClient,
  type Provider,
  type Session,
  type SupabaseClient,
} from "@supabase/supabase-js";

const supabaseUrl = process.env.NEXT_PUBLIC_SUPABASE_URL;
const supabasePublishableKey = process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY;
const requireSupabaseAuth =
  process.env.NEXT_PUBLIC_REQUIRE_SUPABASE_AUTH === "true";

const DEMO_USER_ID = "helix-hackathon-demo";
const DEMO_AUTH_EVENT = "node0-demo-auth";
const DEMO_AUTH_KEY = "node0_demo_auth";
const DEMO_EMAIL = "demo@helix.local";

const supabase: SupabaseClient | null =
  supabaseUrl && supabasePublishableKey
    ? createClient(supabaseUrl, supabasePublishableKey)
    : null;

let cachedHasSession = !requireSupabaseAuth;
let cachedUserId: string | null = !requireSupabaseAuth ? DEMO_USER_ID : null;

function demoSession(): Session {
  const now = Math.floor(Date.now() / 1000);
  return {
    access_token: "helix-demo",
    refresh_token: "helix-demo",
    expires_in: 60 * 60 * 24 * 365,
    expires_at: now + 60 * 60 * 24 * 365,
    token_type: "bearer",
    user: {
      id: DEMO_USER_ID,
      app_metadata: { provider: "demo", providers: ["demo"] },
      user_metadata: { name: "Hackathon Demo", email: DEMO_EMAIL },
      aud: "authenticated",
      created_at: new Date(0).toISOString(),
      email: DEMO_EMAIL,
    },
  } as Session;
}

function notifyAuthChanged() {
  if (typeof window === "undefined") return;
  window.dispatchEvent(new Event(DEMO_AUTH_EVENT));
}

function writeDemoAuth() {
  if (typeof window === "undefined") return;
  sessionStorage.setItem(DEMO_AUTH_KEY, "1");
  cachedHasSession = true;
  cachedUserId = DEMO_USER_ID;
  notifyAuthChanged();
}

export async function hydrateAuthSession() {
  if (!requireSupabaseAuth) {
    writeDemoAuth();
    return demoSession();
  }
  if (!supabase) return null;
  const { data } = await supabase.auth.getSession();
  cachedHasSession = Boolean(data.session);
  cachedUserId = data.session?.user.id ?? null;
  return data.session;
}

export function hasAuthSession() {
  return cachedHasSession;
}

export function getCachedAuthUserId() {
  return cachedUserId;
}

export function subscribeAuthSession(onStoreChange: () => void) {
  if (!requireSupabaseAuth) {
    const handler = () => {
      cachedHasSession = true;
      cachedUserId = DEMO_USER_ID;
      onStoreChange();
    };
    if (typeof window !== "undefined") {
      window.addEventListener(DEMO_AUTH_EVENT, handler);
      queueMicrotask(handler);
    }
    return () => {
      if (typeof window !== "undefined") {
        window.removeEventListener(DEMO_AUTH_EVENT, handler);
      }
    };
  }

  if (!supabase) return () => {};
  const {
    data: { subscription },
  } = supabase.auth.onAuthStateChange((_event, session) => {
    cachedHasSession = Boolean(session);
    cachedUserId = session?.user.id ?? null;
    onStoreChange();
  });

  return () => subscription.unsubscribe();
}

export async function signInWithProvider(provider: Provider, next = "/dashboard") {
  if (!requireSupabaseAuth) {
    void provider;
    writeDemoAuth();
    window.location.assign(next);
    return;
  }
  if (!supabase) throw new Error("Supabase auth is not configured.");
  const redirectTo = `${window.location.origin}/auth/callback?next=${encodeURIComponent(next)}`;
  const { error } = await supabase.auth.signInWithOAuth({
    provider,
    options: { redirectTo },
  });

  if (error) throw error;
}

export async function signOutAuth() {
  if (!requireSupabaseAuth) {
    cachedHasSession = true;
    cachedUserId = DEMO_USER_ID;
    notifyAuthChanged();
    return;
  }
  if (supabase) await supabase.auth.signOut();
}

export async function getSession() {
  if (!requireSupabaseAuth) {
    cachedHasSession = true;
    cachedUserId = DEMO_USER_ID;
    return demoSession();
  }
  if (!supabase) return null;
  const { data } = await supabase.auth.getSession();
  cachedHasSession = Boolean(data.session);
  cachedUserId = data.session?.user.id ?? null;
  return data.session;
}

/** Refresh access token before server calls that validate JWT (e.g. AR handoff mint). */
export async function refreshAuthSession() {
  if (!requireSupabaseAuth) return demoSession();
  if (!supabase) return null;
  const { data, error } = await supabase.auth.refreshSession();
  if (error || !data.session) return null;
  cachedHasSession = true;
  cachedUserId = data.session.user.id;
  return data.session;
}
