// Deployed to project iakggzyqbamynwxdfxxz via MCP.
//
// Stripe-hosted Connect onboarding requires an https return_url/refresh_url
// and only works in a real browser tab (not an embedded webview) — see
// stripe-connect-onboarding/index.ts. This is that landing page: it carries
// no app state (Stripe redirects here with no query params that identify
// the user), it just tells the writer to go back to the app, which then
// re-checks their onboarding status (user_stripe_accounts.charges_enabled,
// updated by stripe-webhook's account.updated handler) next time the Sales
// tab loads.
const html = `<!doctype html>
<html>
<head>
<meta charset="utf-8">
<title>Literature — Stripe setup</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>
  body {
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
    display: flex;
    align-items: center;
    justify-content: center;
    height: 100vh;
    margin: 0;
    background: #faf6f0;
    color: #2b2620;
    text-align: center;
    padding: 24px;
    box-sizing: border-box;
  }
  div { max-width: 360px; }
  h1 { font-size: 20px; margin-bottom: 8px; }
  p { font-size: 15px; color: #6b6257; line-height: 1.5; }
</style>
</head>
<body>
  <div>
    <h1>You're all set</h1>
    <p>Close this tab and return to the Literature app to continue.</p>
  </div>
</body>
</html>`;

Deno.serve(() => {
  return new Response(html, { headers: { "Content-Type": "text/html" } });
});
