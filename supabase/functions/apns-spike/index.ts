// Throwaway spike: send one push straight to APNs (HTTP/2, ES256 JWT from a .p8 key).
// Secrets: APNS_KEY_P8 (PEM contents), APNS_KEY_ID, APNS_TEAM_ID, APNS_TOPIC (bundle id).
import { importPKCS8, SignJWT } from "npm:jose@5.9.6";

Deno.serve(async (req) => {
  const { token, sandbox = true, title = "KitchenMate", body = "Hello from an Edge Function" } = await req.json();
  const key = await importPKCS8(Deno.env.get("APNS_KEY_P8")!.replace(/\\n/g, "\n"), "ES256");
  const jwt = await new SignJWT({})
    .setProtectedHeader({ alg: "ES256", kid: Deno.env.get("APNS_KEY_ID")! })
    .setIssuer(Deno.env.get("APNS_TEAM_ID")!)
    .setIssuedAt()
    .sign(key);
  const host = sandbox ? "api.sandbox.push.apple.com" : "api.push.apple.com";
  const t0 = performance.now();
  const res = await fetch(`https://${host}/3/device/${token}`, {
    method: "POST",
    headers: {
      authorization: `bearer ${jwt}`,
      "apns-topic": Deno.env.get("APNS_TOPIC")!,
      "apns-push-type": "alert",
      "apns-priority": "10",
    },
    body: JSON.stringify({ aps: { alert: { title, body }, sound: "default" } }),
  });
  return Response.json({
    status: res.status,
    apnsId: res.headers.get("apns-id"),
    body: await res.text(),
    ms: Math.round(performance.now() - t0),
  });
});
