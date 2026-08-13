// Deployed to project iakggzyqbamynwxdfxxz via MCP.
//
// Lets a seller mark a Meetup-fulfillment order_items row as confirmed
// (they've agreed on the buyer's suggested place/time). A narrow,
// service-role-only mutation: order_items has no direct UPDATE RLS policy
// for authenticated users (see stripe-create-checkout's comment) — letting
// sellers UPDATE their own rows directly would also let them rewrite
// unit_price_cents/platform_fee_cents/transfer_status, so this goes through
// an Edge Function that only ever flips meetup_confirmed, same pattern as
// every other order/commerce write in this app.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

function json(body: unknown, status = 200) {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) return json({ error: "Missing Authorization header" }, 401);

    const anon = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      { global: { headers: { Authorization: authHeader } } },
    );
    const { data: userData, error: userError } = await anon.auth.getUser();
    if (userError || !userData.user) return json({ error: "Not authenticated" }, 401);

    const body = await req.json().catch(() => ({}));
    const orderItemId = body.orderItemId;
    if (typeof orderItemId !== "string" || !orderItemId) {
      return json({ error: "orderItemId required" }, 400);
    }

    const admin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: item, error: itemError } = await admin
      .from("order_items")
      .select("id, seller_id, shipping_method, meetup_confirmed")
      .eq("id", orderItemId)
      .maybeSingle();
    if (itemError) throw itemError;
    if (!item) return json({ error: "Order item not found" }, 404);
    if (item.seller_id !== userData.user.id) {
      return json({ error: "Not your sale" }, 403);
    }
    if (item.shipping_method !== "meetup") {
      return json({ error: "This order isn't a meetup" }, 400);
    }

    const { error: updateError } = await admin
      .from("order_items")
      .update({ meetup_confirmed: true })
      .eq("id", orderItemId);
    if (updateError) throw updateError;

    return json({ success: true });
  } catch (err) {
    console.error(err);
    return json({ error: String(err) }, 500);
  }
});
