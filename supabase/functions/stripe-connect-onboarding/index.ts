// Deployed to project iakggzyqbamynwxdfxxz via MCP.
//
// Called by the mobile app when a writer wants to receive payouts for
// marketplace sales. Creates (or reuses) a Stripe Express connected
// account for the signed-in user and returns a one-time Stripe-hosted
// onboarding link. Stripe-hosted onboarding only works in a real browser
// (not an embedded webview), so the client opens the returned URL with
// url_launcher in external-browser mode — see
// mobile-app/lib/services/stripe_service.dart.
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import Stripe from "npm:stripe@17";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY") ?? "", {
  apiVersion: "2024-06-20",
});

const RETURN_URL =
  `${Deno.env.get("SUPABASE_URL")}/functions/v1/stripe-connect-return`;

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
    const user = userData.user;

    const admin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: existing } = await admin
      .from("user_stripe_accounts")
      .select("stripe_connect_account_id")
      .eq("user_id", user.id)
      .maybeSingle();

    let accountId = existing?.stripe_connect_account_id as string | undefined;

    if (!accountId) {
      const account = await stripe.accounts.create({
        type: "express",
        email: user.email ?? undefined,
        capabilities: { transfers: { requested: true } },
      });
      accountId = account.id;

      await admin.from("user_stripe_accounts").upsert({
        user_id: user.id,
        stripe_connect_account_id: accountId,
        updated_at: new Date().toISOString(),
      });
    }

    const accountLink = await stripe.accountLinks.create({
      account: accountId,
      type: "account_onboarding",
      return_url: RETURN_URL,
      refresh_url: RETURN_URL,
    });

    return json({ url: accountLink.url });
  } catch (err) {
    console.error(err);
    return json({ error: String(err) }, 500);
  }
});
