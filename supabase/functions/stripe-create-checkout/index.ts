// Deployed to project iakggzyqbamynwxdfxxz via MCP.
//
// Called by the mobile app's cart checkout and "Buy Now" — takes one or
// more listing IDs, validates them server-side (price, ownership, "not
// already bought", seller has finished Connect onboarding), creates the
// orders/order_items rows and a single PaymentIntent on the platform
// account, and returns its client secret for the Flutter Payment Sheet.
//
// Uses the "separate charges and transfers" Connect pattern: this
// PaymentIntent charges the platform account for the whole cart (so one
// cart can span multiple sellers); stripe-webhook's payment_intent.succeeded
// handler then creates a Transfer per seller once the charge succeeds. See
// https://docs.stripe.com/connect/separate-charges-and-transfers — a single
// PaymentIntent can't itself split across connected accounts the way
// destination charges can.
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

// Flat 10% platform fee, taken out of each seller's transfer (see
// stripe-webhook). Adjust here if the business terms change.
const PLATFORM_FEE_BPS = 1000;

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
    const buyer = userData.user;

    const body = await req.json().catch(() => ({}));
    const listingIds = body.listingIds;
    if (!Array.isArray(listingIds) || listingIds.length === 0) {
      return json({ error: "listingIds required" }, 400);
    }
    const uniqueIds = [...new Set(listingIds)] as string[];

    const admin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: listings, error: listingsError } = await admin
      .from("marketplace_listings")
      .select("id, seller_id, price_cents, title")
      .in("id", uniqueIds);
    if (listingsError) throw listingsError;
    if (!listings || listings.length !== uniqueIds.length) {
      return json({ error: "One or more listings could not be found" }, 400);
    }

    for (const listing of listings) {
      if (listing.seller_id === buyer.id) {
        return json({ error: `You can't buy your own listing: "${listing.title}"` }, 400);
      }
      if (!listing.price_cents || listing.price_cents <= 0) {
        return json({ error: `"${listing.title}" doesn't have a valid price yet` }, 400);
      }
    }

    const { data: alreadyOwned } = await admin
      .from("order_items")
      .select("listing_id, orders!inner(buyer_id, status)")
      .in("listing_id", uniqueIds)
      .eq("orders.buyer_id", buyer.id)
      .eq("orders.status", "paid");
    if (alreadyOwned && alreadyOwned.length > 0) {
      const ownedIds = new Set(alreadyOwned.map((o: { listing_id: string }) => o.listing_id));
      const titles = listings.filter((l) => ownedIds.has(l.id)).map((l) => l.title).join(", ");
      return json({ error: `Already purchased: ${titles}` }, 400);
    }

    const sellerIds = [...new Set(listings.map((l) => l.seller_id))];
    const { data: sellerAccounts, error: sellerError } = await admin
      .from("user_stripe_accounts")
      .select("user_id, stripe_connect_account_id, charges_enabled")
      .in("user_id", sellerIds);
    if (sellerError) throw sellerError;

    const sellerMap = new Map(
      (sellerAccounts ?? []).map((s) => [s.user_id, s]),
    );
    for (const sellerId of sellerIds) {
      const acct = sellerMap.get(sellerId);
      if (!acct?.stripe_connect_account_id || !acct.charges_enabled) {
        const title = listings.find((l) => l.seller_id === sellerId)?.title;
        return json({ error: `"${title}"'s seller hasn't finished payment setup yet` }, 400);
      }
    }

    const items = listings.map((l) => {
      const unitPriceCents = l.price_cents as number;
      const platformFeeCents = Math.round((unitPriceCents * PLATFORM_FEE_BPS) / 10000);
      return { listing: l, unitPriceCents, platformFeeCents };
    });
    const amountTotalCents = items.reduce((sum, i) => sum + i.unitPriceCents, 0);

    const { data: order, error: orderError } = await admin
      .from("orders")
      .insert({ buyer_id: buyer.id, amount_total_cents: amountTotalCents, currency: "usd" })
      .select()
      .single();
    if (orderError) throw orderError;

    const { error: itemsError } = await admin.from("order_items").insert(
      items.map((i) => ({
        order_id: order.id,
        listing_id: i.listing.id,
        seller_id: i.listing.seller_id,
        unit_price_cents: i.unitPriceCents,
        platform_fee_cents: i.platformFeeCents,
      })),
    );
    if (itemsError) throw itemsError;

    const { data: buyerAccount } = await admin
      .from("user_stripe_accounts")
      .select("stripe_customer_id")
      .eq("user_id", buyer.id)
      .maybeSingle();

    let customerId = buyerAccount?.stripe_customer_id as string | undefined;
    if (!customerId) {
      const customer = await stripe.customers.create({ email: buyer.email ?? undefined });
      customerId = customer.id;
      await admin.from("user_stripe_accounts").upsert({
        user_id: buyer.id,
        stripe_customer_id: customerId,
        updated_at: new Date().toISOString(),
      });
    }

    const paymentIntent = await stripe.paymentIntents.create({
      amount: amountTotalCents,
      currency: "usd",
      customer: customerId,
      automatic_payment_methods: { enabled: true },
      transfer_group: order.id,
      metadata: { order_id: order.id },
    });

    await admin
      .from("orders")
      .update({ stripe_payment_intent_id: paymentIntent.id })
      .eq("id", order.id);

    return json({
      clientSecret: paymentIntent.client_secret,
      orderId: order.id,
      amountTotalCents,
    });
  } catch (err) {
    console.error(err);
    return json({ error: String(err) }, 500);
  }
});
