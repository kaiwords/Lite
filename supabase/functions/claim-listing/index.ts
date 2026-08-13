// Deployed to project iakggzyqbamynwxdfxxz via MCP.
//
// Claims a Free or Swap Physical listing — no Stripe involved, since
// nothing is charged. Creates the same orders/order_items shape
// stripe-create-checkout does (so CommerceRepository.fetchPurchases/
// fetchSales, and the "already owned" checks elsewhere, all keep working
// unchanged) but with a $0 amount and status inserted straight to 'paid'
// rather than waiting on a PaymentIntent + webhook. Also marks the listing
// is_sold_out so it stops showing as claimable — Free/Swap are one-off,
// unlike a Sale listing that can be bought repeatedly.
//
// Runs as the service role for the same reason stripe-create-checkout
// does: orders/order_items have no direct INSERT policy for authenticated
// users (so a client can't forge unit_price_cents/seller_id/etc. by
// writing the tables directly).
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
    const buyer = userData.user;

    const body = await req.json().catch(() => ({}));
    const listingId = body.listingId;
    if (typeof listingId !== "string" || !listingId) {
      return json({ error: "listingId required" }, 400);
    }
    const shipping = (body.shipping ?? {}) as {
      method?: string;
      meetupPlace?: string;
    };

    const admin = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: listing, error: listingError } = await admin
      .from("marketplace_listings")
      .select("id, seller_id, title, type, offer, shipping_methods, is_sold_out")
      .eq("id", listingId)
      .maybeSingle();
    if (listingError) throw listingError;
    if (!listing) return json({ error: "Listing not found" }, 404);
    if (listing.offer !== "free" && listing.offer !== "swap") {
      return json({ error: "This listing isn't Free or Swap" }, 400);
    }
    if (listing.seller_id === buyer.id) {
      return json({ error: `You can't claim your own listing: "${listing.title}"` }, 400);
    }
    if (listing.is_sold_out) {
      return json({ error: `"${listing.title}" has already been claimed` }, 400);
    }

    const methods = (listing.shipping_methods ?? []) as string[];
    if (methods.length > 0) {
      if (!shipping.method || !methods.includes(shipping.method)) {
        return json({ error: `Choose a shipping method for "${listing.title}"` }, 400);
      }
      if (shipping.method === "meetup" && !shipping.meetupPlace?.trim()) {
        return json({ error: `Suggest a meetup place/time for "${listing.title}"` }, 400);
      }
    }

    const { data: order, error: orderError } = await admin
      .from("orders")
      .insert({
        buyer_id: buyer.id,
        amount_total_cents: 0,
        currency: "usd",
        status: "paid",
      })
      .select()
      .single();
    if (orderError) throw orderError;

    const { error: itemError } = await admin.from("order_items").insert({
      order_id: order.id,
      listing_id: listing.id,
      seller_id: listing.seller_id,
      unit_price_cents: 0,
      platform_fee_cents: 0,
      transfer_status: "transferred", // nothing to pay out
      shipping_method: shipping.method ?? null,
      meetup_place: shipping.method === "meetup" ? shipping.meetupPlace : null,
    });
    if (itemError) throw itemError;

    const { error: updateError } = await admin
      .from("marketplace_listings")
      .update({ is_sold_out: true })
      .eq("id", listing.id);
    if (updateError) throw updateError;

    return json({ success: true, orderId: order.id });
  } catch (err) {
    console.error(err);
    return json({ error: String(err) }, 500);
  }
});
