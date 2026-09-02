// Tiny fixed-window rate limiter, held in memory.
//
// This backend runs as a single instance for one family, so a shared store
// (Redis et al) isn't warranted — the goal is to make online guessing
// impractical, not to survive a distributed attack.
//
// It matters most for POST /api/child/pair: the pairing code is only 3
// digits (1000 combinations) by design, so that endpoint is only safe while
// an attacker cannot simply enumerate the space inside the code's 3-minute
// lifetime.

const buckets = new Map();

function clientKey(req) {
  // Behind a proxy, trust the first X-Forwarded-For hop when one is set.
  const forwarded = req.headers["x-forwarded-for"];
  if (forwarded) return String(forwarded).split(",")[0].trim();
  return req.ip || req.socket?.remoteAddress || "unknown";
}

/// Express middleware allowing `max` requests per `windowMs` per client.
function rateLimit({ windowMs, max, name }) {
  return (req, res, next) => {
    const key = `${name}:${clientKey(req)}`;
    const now = Date.now();
    const entry = buckets.get(key);

    if (!entry || now >= entry.resetAt) {
      buckets.set(key, { count: 1, resetAt: now + windowMs });
      return next();
    }

    entry.count += 1;
    if (entry.count > max) {
      const retryAfter = Math.ceil((entry.resetAt - now) / 1000);
      res.set("Retry-After", String(retryAfter));
      return res.status(429).json({ error: "too_many_requests", retryAfterSec: retryAfter });
    }
    next();
  };
}

// Drop expired buckets periodically so the map can't grow without bound.
// unref() so this timer never holds the process open on its own.
const sweep = setInterval(() => {
  const now = Date.now();
  for (const [key, entry] of buckets) {
    if (now >= entry.resetAt) buckets.delete(key);
  }
}, 60_000);
if (typeof sweep.unref === "function") sweep.unref();

module.exports = { rateLimit };
