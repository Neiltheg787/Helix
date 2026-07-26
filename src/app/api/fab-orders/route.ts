import { NextResponse } from "next/server";
import { z } from "zod";

import { dbForApiUser, resolveApiUser } from "@/lib/demo-api-auth";
import { bearerFromRequest } from "@/lib/supabase-user";

const nextFabStatus = (s: string): string | null => {
  if (s === "placed") return "shipped";
  if (s === "shipped") return "delivered";
  return null;
};

export async function GET(request: Request) {
  const token = bearerFromRequest(request);
  const authUser = await resolveApiUser(token);
  if (!authUser) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  let supabase;
  try {
    supabase = dbForApiUser(token!, authUser.isDemo);
  } catch (e) {
    return NextResponse.json({ orders: [], degraded: true });
  }
  const user = { id: authUser.id };

  const project = new URL(request.url).searchParams.get("project") ?? "";

  let query = supabase
    .from("node0_fab_orders")
    .select(
      "id,created_at,stripe_checkout_session_id,label,qty,fulfillment_status,amount_total,currency,project_client_id",
    )
    .eq("user_id", user.id)
    .order("created_at", { ascending: false });

  if (project) {
    query = query.eq("project_client_id", project);
  }

  const { data, error } = await query.limit(200);

  if (error) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }

  return NextResponse.json({ orders: data ?? [] });
}

const patchSchema = z.object({
  id: z.string().uuid(),
});

export async function PATCH(request: Request) {
  const token = bearerFromRequest(request);
  const authUser = await resolveApiUser(token);
  if (!authUser) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  let supabase;
  try {
    supabase = dbForApiUser(token!, authUser.isDemo);
  } catch (e) {
    return NextResponse.json({ error: "Database not configured" }, { status: 503 });
  }
  const user = { id: authUser.id };

  let json: unknown;
  try {
    json = await request.json();
  } catch {
    return NextResponse.json({ error: "Invalid JSON" }, { status: 400 });
  }

  const parsed = patchSchema.safeParse(json);
  if (!parsed.success) {
    return NextResponse.json(
      { error: "Invalid body", details: parsed.error.flatten() },
      { status: 400 },
    );
  }

  const { id } = parsed.data;

  const { data: row, error: selErr } = await supabase
    .from("node0_fab_orders")
    .select("id,fulfillment_status")
    .eq("id", id)
    .eq("user_id", user.id)
    .maybeSingle();

  if (selErr) {
    return NextResponse.json({ error: selErr.message }, { status: 500 });
  }
  if (!row) {
    return NextResponse.json({ error: "Not found" }, { status: 404 });
  }

  const current = row.fulfillment_status;
  if (typeof current !== "string") {
    return NextResponse.json({ error: "Invalid row" }, { status: 500 });
  }

  const advanced = nextFabStatus(current);
  if (!advanced) {
    return NextResponse.json({ error: "Already final" }, { status: 400 });
  }

  const { data: updated, error: upErr } = await supabase
    .from("node0_fab_orders")
    .update({ fulfillment_status: advanced })
    .eq("id", id)
    .eq("user_id", user.id)
    .select(
      "id,created_at,stripe_checkout_session_id,label,qty,fulfillment_status,amount_total,currency",
    )
    .single();

  if (upErr) {
    return NextResponse.json({ error: upErr.message }, { status: 500 });
  }

  return NextResponse.json({ order: updated });
}
