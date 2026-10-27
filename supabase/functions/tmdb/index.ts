// TMDb proxy for Lumora: the app never carries the TMDb key. The key lives in
// this function's TMDB_API_KEY secret; the app calls
//   <SUPABASE_URL>/functions/v1/tmdb/<v3 path>?<params>
// and gets TMDb's JSON back.
//
// Browsing needs no account in Lumora, so reads are open to anyone; only the
// read-only paths below are forwarded. Answers are kept for ten minutes in
// this instance, each address gets a fair share of requests per minute, and
// adult results are only for admins (app_metadata.role, checked with Auth).

const TMDB = "https://api.themoviedb.org/3";

// Read-only TMDb paths the app uses.
const ALLOWED = [
  /^\/find\/[\w-]+$/,
  /^\/search\/(multi|movie|tv|person|collection)$/,
  /^\/discover\/(movie|tv)$/,
  /^\/trending\/(all|movie|tv|person)\/(day|week)$/,
  /^\/(movie|tv)\/\d+(\/[\w/-]+)?$/,
  /^\/movie\/(now_playing|popular|top_rated|upcoming)$/,
  /^\/tv\/(airing_today|on_the_air|popular|top_rated)$/,
  /^\/genre\/(movie|tv)\/list$/,
  /^\/collection\/\d+(\/[\w-]+)?$/,
  /^\/person\/\d+(\/[\w-]+)?$/,
  /^\/configuration$/,
];

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info",
  "Access-Control-Allow-Methods": "GET, OPTIONS",
};

// Requests per address per minute, per running instance. Enough for a viewer
// scrolling fast; not enough to spend the project's quota for it.
const PER_MINUTE = 120;
const hits = new Map<string, { start: number; count: number }>();

function overLimit(req: Request): boolean {
  const ip =
    req.headers.get("x-forwarded-for")?.split(",")[0].trim() ||
    req.headers.get("cf-connecting-ip") ||
    "unknown";
  const now = Date.now();
  const entry = hits.get(ip);
  if (!entry || now - entry.start > 60_000) {
    if (hits.size > 10_000) hits.clear();
    hits.set(ip, { start: now, count: 1 });
    return false;
  }
  entry.count++;
  return entry.count > PER_MINUTE;
}

// Successful answers, ten minutes, newest last; the oldest go first.
const TTL = 600_000;
const MAX_CACHED = 500;
const cache = new Map<string, { at: number; status: number; body: string }>();

function cached(key: string) {
  const hit = cache.get(key);
  if (!hit) return null;
  if (Date.now() - hit.at > TTL) {
    cache.delete(key);
    return null;
  }
  return hit;
}

function remember(key: string, status: number, body: string) {
  cache.set(key, { at: Date.now(), status, body });
  while (cache.size > MAX_CACHED) {
    cache.delete(cache.keys().next().value!);
  }
}

// Whether the caller's Lumora session belongs to an admin.
async function isAdmin(req: Request): Promise<boolean> {
  const auth = req.headers.get("authorization");
  const base = Deno.env.get("SUPABASE_URL");
  const anon = Deno.env.get("SUPABASE_ANON_KEY");
  if (!auth?.startsWith("Bearer ") || !base || !anon) return false;
  try {
    const res = await fetch(`${base}/auth/v1/user`, {
      headers: { Authorization: auth, apikey: anon },
      signal: AbortSignal.timeout(5_000),
    });
    if (!res.ok) return false;
    const user = await res.json();
    return user?.app_metadata?.role === "admin";
  } catch {
    return false;
  }
}

const json = (body: unknown, status: number) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...cors, "Content-Type": "application/json" },
  });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "GET") return json({ error: "method not allowed" }, 405);

  const url = new URL(req.url);
  const path = url.pathname.replace(/^.*?\/tmdb(?=\/|$)/, "") || "/";
  if (!ALLOWED.some((r) => r.test(path))) {
    return json({ error: "path not allowed" }, 404);
  }

  if (overLimit(req)) return json({ error: "too many requests" }, 429);

  const key = Deno.env.get("TMDB_API_KEY");
  if (!key) return json({ error: "not configured" }, 503);

  const upstream = new URL(TMDB + path);
  for (const [k, v] of url.searchParams) {
    if (k !== "api_key") upstream.searchParams.set(k, v);
  }
  // Adult titles only for an admin's session; everyone else gets them off,
  // whatever they asked for.
  const wantsAdult = upstream.searchParams.get("include_adult") === "true";
  const adult = wantsAdult && (await isAdmin(req));
  upstream.searchParams.set("include_adult", adult ? "true" : "false");
  upstream.searchParams.sort();
  const cacheKey = path + "?" + upstream.searchParams.toString();
  const hit = cached(cacheKey);
  if (hit) {
    return new Response(hit.body, {
      status: hit.status,
      headers: {
        ...cors,
        "Content-Type": "application/json",
        "Cache-Control": "public, max-age=600",
      },
    });
  }
  // A v4 read access token (a JWT) goes in the header; a v3 key in the query.
  const bearer = key.startsWith("eyJ");
  if (!bearer) upstream.searchParams.set("api_key", key);

  try {
    const res = await fetch(upstream, {
      headers: {
        Accept: "application/json",
        ...(bearer ? { Authorization: `Bearer ${key}` } : {}),
      },
      signal: AbortSignal.timeout(10_000),
    });
    const body = await res.text();
    if (res.ok) remember(cacheKey, res.status, body);
    return new Response(body, {
      status: res.status,
      headers: {
        ...cors,
        "Content-Type": "application/json",
        "Cache-Control": res.ok ? "public, max-age=600" : "no-store",
      },
    });
  } catch {
    return json({ error: "upstream unreachable" }, 502);
  }
});
