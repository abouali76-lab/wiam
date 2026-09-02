const express = require("express");
const bcrypt = require("bcryptjs");
const { prisma } = require("../db");
const { signParentToken, requireParent, generatePairingCode } = require("../auth");
const { computeChildState } = require("../balance");
const { todayInTimezone } = require("../date");
const { rateLimit } = require("../rate_limit");

const router = express.Router();

// Slows password guessing without getting in a real parent's way — a
// mistyped password a few times in a row is normal, twenty is not.
const loginLimiter = rateLimit({ windowMs: 5 * 60_000, max: 10, name: "login" });

const MIN_PASSWORD_LENGTH = 6;

// --- Auth ---------------------------------------------------------------

// Email is required once, at signup, as the durable account identity.
// Username is optional here — if skipped, the parent just keeps logging in
// with email until they set one from account settings.
router.post("/register", loginLimiter, async (req, res) => {
  const { email, username, password, childName } = req.body;
  if (!email || !password || !childName) {
    return res.status(400).json({ error: "email, password and childName are required" });
  }
  if (String(password).length < MIN_PASSWORD_LENGTH) {
    return res.status(400).json({ error: "password_too_short", minLength: MIN_PASSWORD_LENGTH });
  }
  const existingEmail = await prisma.parent.findUnique({ where: { email } });
  if (existingEmail) return res.status(409).json({ error: "email_taken" });
  if (username) {
    const existingUsername = await prisma.parent.findUnique({ where: { username } });
    if (existingUsername) return res.status(409).json({ error: "username_taken" });
  }

  const passwordHash = await bcrypt.hash(password, 10);
  const parent = await prisma.parent.create({
    data: {
      email,
      username: username || null,
      passwordHash,
      children: { create: { name: childName } },
    },
    include: { children: true },
  });

  res.json({ token: signParentToken(parent), children: parent.children });
});

// `identifier` is whatever the parent typed — could be their email or their
// chosen username (which itself may be all digits, e.g. a phone number).
router.post("/login", loginLimiter, async (req, res) => {
  const { identifier, password } = req.body;
  if (!identifier || !password) return res.status(401).json({ error: "invalid_credentials" });

  const parent = await prisma.parent.findFirst({
    where: { OR: [{ email: identifier }, { username: identifier }] },
  });
  if (!parent) return res.status(401).json({ error: "invalid_credentials" });
  const ok = await bcrypt.compare(password, parent.passwordHash);
  if (!ok) return res.status(401).json({ error: "invalid_credentials" });
  res.json({ token: signParentToken(parent) });
});

router.post("/username", requireParent, async (req, res) => {
  const { username } = req.body;
  if (!username || username.trim().length < 3) {
    return res.status(400).json({ error: "username_too_short" });
  }
  const existing = await prisma.parent.findUnique({ where: { username } });
  if (existing && existing.id !== req.parentId) return res.status(409).json({ error: "username_taken" });
  await prisma.parent.update({ where: { id: req.parentId }, data: { username } });
  res.json({ username });
});

router.use(requireParent);

// --- Children -------------------------------------------------------------

router.get("/children", async (req, res) => {
  const children = await prisma.child.findMany({ where: { parentId: req.parentId } });
  const states = await Promise.all(children.map((c) => computeChildState(c.id)));
  res.json(states);
});

router.post("/children", async (req, res) => {
  const { name, timezone } = req.body;
  if (!name) return res.status(400).json({ error: "name is required" });
  const child = await prisma.child.create({
    data: { name, timezone: timezone || "Asia/Riyadh", parentId: req.parentId },
  });
  res.json(child);
});

async function requireOwnChild(req, res, next) {
  const child = await prisma.child.findUnique({ where: { id: req.params.childId } });
  if (!child || child.parentId !== req.parentId) return res.status(404).json({ error: "child_not_found" });
  req.targetChild = child;
  next();
}

// Issue a short-lived 6-digit code the child types into the iPad's pairing
// screen. The device exchanges it once for a real deviceToken (POST
// /api/child/pair) — the parent's own login credentials are never involved.
// Shorter than before (was 10 min) — a 3-digit code is a much smaller
// space (1000 combinations) than the previous 6-digit one, so it expires
// faster to keep a brute-force window impractically small.
const PAIRING_CODE_TTL_MS = 3 * 60 * 1000;

router.post("/children/:childId/pairing-code", requireOwnChild, async (req, res) => {
  let pairingCode;
  for (let attempt = 0; attempt < 5; attempt++) {
    const candidate = generatePairingCode();
    const clash = await prisma.child.findFirst({
      where: { pairingCode: candidate, pairingCodeExpiresAt: { gt: new Date() } },
    });
    if (!clash) {
      pairingCode = candidate;
      break;
    }
  }
  if (!pairingCode) return res.status(503).json({ error: "could_not_allocate_code" });

  const expiresAt = new Date(Date.now() + PAIRING_CODE_TTL_MS);
  await prisma.child.update({
    where: { id: req.targetChild.id },
    data: { pairingCode, pairingCodeExpiresAt: expiresAt },
  });
  res.json({ pairingCode, expiresAt });
});

// --- Tasks ------------------------------------------------------------

router.post("/children/:childId/tasks", requireOwnChild, async (req, res) => {
  const { title, type, rewardMinutes, proofAllowed } = req.body;
  if (!title || !["digital", "external"].includes(type) || !Number.isFinite(rewardMinutes)) {
    return res.status(400).json({ error: "title, type ('digital'|'external') and rewardMinutes are required" });
  }
  const task = await prisma.task.create({
    data: {
      childId: req.targetChild.id,
      title,
      type,
      rewardMinutes,
      proofAllowed: Boolean(proofAllowed),
    },
  });
  res.json(task);
});

router.get("/children/:childId/state", requireOwnChild, async (req, res) => {
  res.json(await computeChildState(req.targetChild.id));
});

// Soft-delete: the task stops appearing (and stops being asked of the
// child) but its past completion history is left alone rather than erased.
router.delete("/children/:childId/tasks/:taskId", requireOwnChild, async (req, res) => {
  const task = await prisma.task.findUnique({ where: { id: req.params.taskId } });
  if (!task || task.childId !== req.targetChild.id) return res.status(404).json({ error: "task_not_found" });
  await prisma.task.update({ where: { id: task.id }, data: { active: false } });
  res.json(await computeChildState(req.targetChild.id));
});

// Manual confirmation for an EXTERNAL task — the parent's half of the
// hybrid verification model (digital tasks self-verify from the child app).
router.post("/tasks/:taskId/confirm", async (req, res) => {
  const task = await prisma.task.findUnique({ where: { id: req.params.taskId }, include: { child: true } });
  if (!task || task.child.parentId !== req.parentId) return res.status(404).json({ error: "task_not_found" });
  if (task.type !== "external") return res.status(400).json({ error: "only_external_tasks_need_confirmation" });

  const date = todayInTimezone(task.child.timezone);
  const completion = await prisma.taskCompletion.upsert({
    where: { taskId_date: { taskId: task.id, date } },
    update: { status: "completed", verifiedBy: "parent", proofUrl: req.body.proofUrl || null, completedAt: new Date() },
    create: {
      taskId: task.id,
      date,
      status: "completed",
      verifiedBy: "parent",
      proofUrl: req.body.proofUrl || null,
      completedAt: new Date(),
    },
  });
  res.json(completion);
});

// --- Emergency "Time Freeze" -------------------------------------------

// Freezing sets a standing lock on the child (independent of any one
// PlaySession) and, if a session happens to be open right now, ends it
// immediately too. The child device discovers both on its next poll (GET
// /api/child/session, /api/child/state) — an offline iPad picks up the
// freeze automatically the moment it reconnects, no command queue needed.
// Because the lock is standing, it also blocks the child from starting a
// brand new session while frozen (see routes/child.js `/session/start`),
// not just cutting off one already in progress.
router.post("/children/:childId/freeze", requireOwnChild, async (req, res) => {
  await prisma.child.update({ where: { id: req.targetChild.id }, data: { frozen: true } });
  const session = await prisma.playSession.findFirst({
    where: { childId: req.targetChild.id, endedAt: null, frozenAt: null },
    orderBy: { startedAt: "desc" },
  });
  if (session) {
    await prisma.playSession.update({ where: { id: session.id }, data: { frozenAt: new Date() } });
  }
  res.json(await computeChildState(req.targetChild.id));
});

router.post("/children/:childId/unfreeze", requireOwnChild, async (req, res) => {
  await prisma.child.update({ where: { id: req.targetChild.id }, data: { frozen: false } });
  res.json(await computeChildState(req.targetChild.id));
});

module.exports = router;
