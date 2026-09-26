import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const allowedHeaders =
  "authorization, apikey, x-client-info, content-type";

Deno.serve(async (request: Request) => {
  const origin = request.headers.get("Origin") ?? "";
  const isAllowedOrigin =
    origin === "https://sqeducaplay.github.io" ||
    /^http:\/\/localhost:\d+$/.test(origin);
  const corsHeaders = {
    "Access-Control-Allow-Headers": allowedHeaders,
    "Access-Control-Allow-Methods": "POST, OPTIONS",
    ...(isAllowedOrigin ? { "Access-Control-Allow-Origin": origin } : {}),
    Vary: "Origin",
  };

  if (request.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  if (request.method !== "POST") {
    return new Response("Method not allowed", {
      status: 405,
      headers: corsHeaders,
    });
  }

  const authorization = request.headers.get("Authorization");
  const accessToken = authorization?.match(/^Bearer\s+(.+)$/i)?.[1];
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!accessToken || !supabaseUrl || !serviceRoleKey) {
    return new Response("Unauthorized", { status: 401, headers: corsHeaders });
  }

  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { autoRefreshToken: false, persistSession: false },
  });

  const { data, error: authError } = await admin.auth.getUser(accessToken);
  if (authError || !data.user) {
    return new Response("Unauthorized", { status: 401, headers: corsHeaders });
  }

  const { error: deletionError } = await admin.auth.admin.deleteUser(
    data.user.id,
  );
  if (deletionError) {
    console.error("Account deletion failed:", deletionError.message);
    return new Response("Account deletion failed", {
      status: 500,
      headers: corsHeaders,
    });
  }

  return new Response(null, { status: 204, headers: corsHeaders });
});
