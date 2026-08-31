const express = require("express");
const bcrypt = require("bcryptjs");
const { prisma } = require("../db");
const { signParentToken, requireParent, generateDeviceToken } = require("../auth");
const { computeChildState } = require("../balance");
const { todayInTimezone } = require("../date");

const router = express.Router();

// --- Auth ---------------------------------------------------------------

router.post("/register", async (req, res) => {
  const { email, pin, childName } = req.body;
  if (!email || !pin || !childName) {
    return res.status(400).json({ error: "email, pin and childName are required" });
  }
  const existing = await prisma.parent.findUnique({ where: { email } });
  if (existing) return res.status(409).json({ error: "email_taken" });

  const pinHash = await bcrypt.hash(pin, 10);
  const parent = await prisma.parent.create({
    data: {
      email,
      pinHash,
      children: { create: { name: childName } },
    },
    include: { children: true },
  });

  res.json({ token: signParentToken(parent), children: parent.children });
});

router.post("/login", async (req, res) => {
  const { email, pin } = req.body;
  const parent = await prisma.parent.findUnique({ where: { email } });
  if (!parent) return res.status(401).json({ error: "invalid_credentials" });
  const ok = await bcrypt.compare(pin || "", parent.pinHash);
  if (!ok) return res.status(401).json({ error: "invalid_credentials" });
  res.json({ token: signParentToken(parent) });
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

// Issue a fresh pairing code for the child's iPad. The child device stores
// this token and never sees the parent's own login credentials.
router.post("/children/:childId/device-token", requireOwnChild, async (req, res) => {
  const deviceToken = generateDeviceToken();
  await prisma.child.update({ where: { id: req.targetChild.id }, data: { deviceToken } });
  res.json({ deviceToken });
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

// Freezing just writes server state; the child device discovers it on its
// next poll (GET /api/child/session). That means an offline iPad picks up
// the freeze automatically the moment it reconnects — no separate command
// queue needed.
router.post("/children/:childId/freeze", requireOwnChild, async (req, res) => {
  const session = await prisma.playSession.findFirst({
    where: { childId: req.targetChild.id, endedAt: null, frozenAt: null },
    orderBy: { startedAt: "desc" },
  });
  if (!session) return res.status(404).json({ error: "no_active_session" });
  const updated = await prisma.playSession.update({ where: { id: session.id }, data: { frozenAt: new Date() } });
  res.json(updated);
});

module.exports = router;
