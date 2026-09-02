require("dotenv").config();
const express = require("express");
const cors = require("cors");

const parentRoutes = require("./routes/parent");
const childRoutes = require("./routes/child");

// Fail fast rather than signing tokens with `undefined` — a missing secret
// would otherwise surface as a confusing 500 on the first login attempt.
if (!process.env.JWT_SECRET) {
  console.error("JWT_SECRET is not set. Copy .env.example to .env and set it before starting.");
  process.exit(1);
}

const app = express();
// CORS_ORIGIN restricts browser callers in production; unset (dev) keeps the
// permissive default so the Flutter web build can talk to a local server.
app.use(cors(process.env.CORS_ORIGIN ? { origin: process.env.CORS_ORIGIN.split(",") } : {}));
app.use(express.json());
// Needed for the rate limiter to see the real client address behind a proxy.
app.set("trust proxy", true);

app.get("/health", (req, res) => res.json({ ok: true }));

app.use("/api/parent", parentRoutes);
app.use("/api/child", childRoutes);

app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: "internal_error" });
});

const port = process.env.PORT || 4000;
app.listen(port, () => console.log(`Wiam backend listening on :${port}`));
