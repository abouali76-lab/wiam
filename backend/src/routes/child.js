const express = require("express");
const { prisma } = require("../db");
const { requireChildDevice, generateDeviceToken } = require("../auth");
const { computeChildState } = require("../balance");
const { todayInTimezone } = require("../date");
const { rateLimit } = require("../rate_limit");

const router = express.Router();

// The pairing code is only 3 digits (1000 combinations) and this endpoint is
// unauthenticated, so without a limit an attacker could sweep the whole space
// in seconds and steal a pairing. At 8 tries/minute a full sweep takes ~2
// hours — far longer than the code's 3-minute lifetime.
const pairLimiter = rateLimit({ windowMs: 60_000, max: 8, name: "pair" });

// Unauthenticated on purpose — the device has no token yet at pairing time.
// Exchanges the parent-issued 3-digit code (POST /api/parent/children/:id/pairing-code)
// for a real, long-lived deviceToken, and burns the code so it can't be reused.
router.post("/pair", pairLimiter, async (req, res) => {
  const { pairingCode } = req.body;
  if (!pairingCode) return res.status(400).json({ error: "pairing_code_required" });

  const child = await prisma.child.findFirst({
    where: { pairingCode, pairingCodeExpiresAt: { gt: new Date() } },
  });
  if (!child) return res.status(400).json({ error: "invalid_or_expired_code" });

  const deviceToken = generateDeviceToken();
  await prisma.child.update({
    where: { id: child.id },
    data: { deviceToken, pairingCode: null, pairingCodeExpiresAt: null },
  });
  res.json({ deviceToken });
});

router.use(requireChildDevice);

// Everything the lock screen needs: today's tasks, minutes earned, and
// whatever's left of any session already in progress.
router.get("/state", async (req, res) => {
  res.json(await computeChildState(req.child.id));
});

// Digital, in-app lessons self-verify — no parent action involved. This is
// the automated half of the hybrid model; see routes/parent.js `/confirm`
// for the manually-confirmed external-task half.
router.post("/tasks/:taskId/complete-digital", async (req, res) => {
  const task = await prisma.task.findUnique({ where: { id: req.params.taskId } });
  if (!task || task.childId !== req.child.id) return res.status(404).json({ error: "task_not_found" });
  if (task.type !== "digital") return res.status(400).json({ error: "only_digital_tasks_self_verify" });

  const date = todayInTimezone(req.child.timezone);
  const completion = await prisma.taskCompletion.upsert({
    where: { taskId_date: { taskId: task.id, date } },
    update: { status: "completed", verifiedBy: "system", completedAt: new Date() },
    create: { taskId: task.id, date, status: "completed", verifiedBy: "system", completedAt: new Date() },
  });
  res.json(completion);
});

// Opens the play gate: fixes the session's duration from whatever minutes
// are earned-but-unspent right now. The countdown itself is derived purely
// from `startedAt` on every later read — the device clock is never trusted.
router.post("/session/start", async (req, res) => {
  const state = await computeChildState(req.child.id);
  if (state.frozen) {
    return res.status(403).json({ error: "frozen_by_parent" });
  }
  if (state.activeSession && !state.activeSession.ended) {
    return res.json(state.activeSession);
  }
  if (state.availableSeconds <= 0) {
    return res.status(400).json({ error: "no_time_available" });
  }
  const session = await prisma.playSession.create({
    data: { childId: req.child.id, durationSec: state.availableSeconds },
  });
  res.json({ id: session.id, startedAt: session.startedAt, durationSec: session.durationSec, remainingSec: session.durationSec, frozen: false, ended: false });
});

// Closes the current session and banks whatever is left of it.
//
// A session's countdown is wall-clock (it has to be: the device clock is
// never trusted, and a paused server-side timer could be gamed by going
// offline). That means time a child spends away from the game would burn
// their earned minutes — being called to dinner shouldn't cost them their
// reward. The child app ends the session whenever it leaves the play
// screen or is backgrounded, so only time actually spent playing counts;
// the remainder stays available for later today.
router.post("/session/end", async (req, res) => {
  const session = await prisma.playSession.findFirst({
    where: { childId: req.child.id, endedAt: null },
    orderBy: { startedAt: "desc" },
  });
  if (session) {
    await prisma.playSession.update({ where: { id: session.id }, data: { endedAt: new Date() } });
  }
  res.json(await computeChildState(req.child.id));
});

// Polled every few seconds by the child app while the play screen is open.
router.get("/session", async (req, res) => {
  const state = await computeChildState(req.child.id);
  res.json(state.activeSession);
});

module.exports = router;
