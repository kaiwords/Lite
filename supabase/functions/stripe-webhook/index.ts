// Deployed to project iakggzyqbamynwxdfxxz via MCP. verify_jwt=false —
// Stripe calls this directly with no Supabase auth; the Stripe-Signature
// header is the only trust boundary. Two Stripe webhook endpoints point
// here with two different signing secrets, because payment_intent.* fires
// on the platform account (a regular, connect=false endpoint) while
// account.updated fires on *connected* accounts (a connect=true endpoint) —
// Stripe requires separate endpoints for those two event sources, each
// with its own secret. STRIPE_WEBHOOK_SECRET is tried first, then
// STRIPE_CONNECT_WEBHOOK_SECRET.
//
// Reconciles orders/order_items with what actually happened in Stripe:
//   - payment_intent.succeeded: marks the order paid, then creates one
//     Transfer per seller (separate-charges-and-transfers pattern — see
//     stripe-create-checkout). Idempotent: Stripe can redeliver the same
//     event, so this is a no-op if the order is already "paid", and each
//     Transfer uses an idempotency key derived from the order_item id so a
//     retried delivery can't double-pay a seller.
//   - payment_intent.payment_failed: marks the order failed.
//   - account.updated: keeps user_stripe_accounts.charges_enabled in sync
//     so the app knows when a seller's Connect onboarding actually cleared
//     (the onboarding return_url alone doesn't guarantee that — see
//     stripe-connect-return).
import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import Stripe from "npm:stripe@17";

const stripe = new Stripe(Deno.env.get("STRIPE_SECRET_KEY") ?? "", {
  apiVersion: "2024-06-20",
});
const webhookSecret = Deno.env.get("STRIPE_WEBHOOK_SECRET") ?? "";
const connectWebhookSecret = Deno.env.get("STRIPE_CONNECT_WEBHOOK_SECRET") ?? "";

const admin = createClient(
  Deno.env.get("SUPABASE_URL")!,
  Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
);

Deno.serve(async (req) => {
  const signature = req.headers.get("Stripe-Signature");
  const body = await req.text();

  let event: Stripe.Event;
  try {
    event = await stripe.webhooks.constructEventAsync(body, signature ?? "", webhookSecret);
  } catch (_platformErr) {
    try {
      event = await stripe.webhooks.constructEventAsync(body, signature ?? "", connectWebhookSecret);
    } catch (connectErr) {
      console.error("Webhook signature verification failed", connectErr);
      return new Response("Invalid signature", { status: 400 });
    }
  }

  try {
    switch (event.type) {
      case "payment_intent.succeeded":
        await handlePaymentSucceeded(event.data.object as Stripe.PaymentIntent);
        break;
      case "payment_intent.payment_failed":
        await handlePaymentFailed(event.data.object as Stripe.PaymentIntent);
        break;
      case "account.updated":
        await handleAccountUpdated(event.data.object as Stripe.Account);
        break;
      default:
        break;
    }
  } catch (err) {
    console.error(`Error handling ${event.type}`, err);
    return new Response("Handler error", { status: 500 });
  }

  return new Response(JSON.stringify({ received: true }), {
    headers: { "Content-Type": "application/json" },
  });
});

async function handlePaymentSucceeded(pi: Stripe.PaymentIntent) {
  const orderId = pi.metadata?.order_id;
  if (!orderId) return;

  const { data: order } = await admin.from("orders").select("*").eq("id", orderId).maybeSingle();
  if (!order || order.status === "paid") return;

  await admin
    .from("orders")
    .update({ status: "paid", updated_at: new Date().toISOString() })
    .eq("id", orderId);

  const { data: items } = await admin.from("order_items").select("*").eq("order_id", orderId);
  if (!items || items.length === 0) return;

  const sellerIds = [...new Set(items.map((i) => i.seller_id))];
  const { data: sellerAccounts } = await admin
    .from("user_stripe_accounts")
    .select("user_id, stripe_connect_account_id")
    .in("user_id", sellerIds);
  const sellerMap = new Map(
    (sellerAccounts ?? []).map((s) => [s.user_id, s.stripe_connect_account_id as string | null]),
  );

  for (const item of items) {
    const destination = sellerMap.get(item.seller_id);
    if (!destination) {
      await admin.from("order_items").update({ transfer_status: "failed" }).eq("id", item.id);
      continue;
    }
    try {
      const transfer = await stripe.transfers.create(
        {
          amount: item.unit_price_cents - item.platform_fee_cents,
          currency: order.currency,
          destination,
          transfer_group: orderId,
          source_transaction:
            typeof pi.latest_charge === "string" ? pi.latest_charge : undefined,
        },
        { idempotencyKey: `transfer_${item.id}` },
      );
      await admin
        .from("order_items")
        .update({ stripe_transfer_id: transfer.id, transfer_status: "transferred" })
        .eq("id", item.id);
    } catch (err) {
      console.error(`Transfer failed for order_item ${item.id}`, err);
      await admin.from("order_items").update({ transfer_status: "failed" }).eq("id", item.id);
    }
  }
}

async function handlePaymentFailed(pi: Stripe.PaymentIntent) {
  const orderId = pi.metadata?.order_id;
  if (!orderId) return;
  await admin
    .from("orders")
    .update({ status: "failed", updated_at: new Date().toISOString() })
    .eq("id", orderId);
}

async function handleAccountUpdated(account: Stripe.Account) {
  await admin
    .from("user_stripe_accounts")
    .update({
      charges_enabled: !!account.charges_enabled,
      details_submitted: !!account.details_submitted,
      updated_at: new Date().toISOString(),
    })
    .eq("stripe_connect_account_id", account.id);
}
