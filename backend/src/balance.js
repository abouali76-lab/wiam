const { prisma } = require("./db");
const { todayInTimezone } = require("./date");

// Ensures every active task has a (lazily-created) completion row for
// `date`. This is the whole "daily reset" mechanism: nothing is deleted or
// cleared overnight, a new day just has no row yet, so it reads as pending.
async function ensureTodayRows(childId, date) {
  const tasks = await prisma.task.findMany({ where: { childId, active: true } });
  for (const task of tasks) {
    await prisma.taskCompletion.upsert({
      where: { taskId_date: { taskId: task.id, date } },
      update: {},
      create: { taskId: task.id, date, status: "pending" },
    });
  }
  return tasks;
}

// Minutes already earned today (completed tasks only) — this is what backs
// "partial completion": a child who finished 1 of 3 tasks gets exactly that
// task's reward, not all-or-nothing.
async function earnedMinutesToday(childId, date) {
  const rows = await prisma.taskCompletion.findMany({
    where: { date, status: "completed", task: { childId } },
    include: { task: true },
  });
  return rows.reduce((sum, row) => sum + row.task.rewardMinutes, 0);
}

// Seconds already spent across today's play sessions. A session frozen or
// ended stops counting from that moment; an active session counts up to now.
function dateInTimezone(instant, timezone) {
  return new Intl.DateTimeFormat("en-CA", { timeZone: timezone }).format(instant);
}

async function consumedSecondsToday(childId, date, timezone) {
  // Only sessions that could possibly fall on `date` in the child's
  // timezone matter — a 48h window covers every offset without loading the
  // child's entire history on each poll.
  const since = new Date(Date.now() - 48 * 60 * 60 * 1000);
  const sessions = await prisma.playSession.findMany({
    where: { childId, startedAt: { gte: since } },
  });
  const now = new Date();
  let total = 0;
  for (const s of sessions) {
    if (dateInTimezone(new Date(s.startedAt), timezone) !== date) continue;
    const stopAt = s.frozenAt || s.endedAt || now;
    const elapsed = Math.max(0, Math.floor((new Date(stopAt).getTime() - new Date(s.startedAt).getTime()) / 1000));
    total += Math.min(elapsed, s.durationSec);
  }
  return total;
}

function activeSessionRemaining(session) {
  if (!session) return null;
  // A parent freeze locks the game NOW, regardless of how much time was
  // actually left — it is not just a stopping point for the countdown.
  if (session.frozenAt || session.endedAt) {
    return {
      id: session.id,
      startedAt: session.startedAt,
      durationSec: session.durationSec,
      remainingSec: 0,
      frozen: Boolean(session.frozenAt),
      ended: true,
    };
  }
  const elapsedMs = Date.now() - new Date(session.startedAt).getTime();
  const remainingSec = Math.max(0, session.durationSec - Math.floor(elapsedMs / 1000));
  return {
    id: session.id,
    startedAt: session.startedAt,
    durationSec: session.durationSec,
    remainingSec,
    frozen: false,
    ended: remainingSec === 0,
  };
}

async function computeChildState(childId) {
  const child = await prisma.child.findUnique({ where: { id: childId } });
  if (!child) return null;
  const date = todayInTimezone(child.timezone);
  await ensureTodayRows(childId, date);

  const completions = await prisma.taskCompletion.findMany({
    where: { date, task: { childId, active: true } },
    include: { task: true },
  });

  const earned = completions
    .filter((c) => c.status === "completed")
    .reduce((sum, c) => sum + c.task.rewardMinutes, 0);

  const consumedSec = await consumedSecondsToday(childId, date, child.timezone);
  const availableSec = Math.max(0, earned * 60 - consumedSec);

  let openSession = await prisma.playSession.findFirst({
    where: { childId, endedAt: null },
    orderBy: { startedAt: "desc" },
  });

  // A session that has run out (or was frozen) is finished, but nothing ever
  // wrote endedAt — so it would keep matching "the open session" forever,
  // including on later days. Close it here, on the next read that notices.
  if (openSession) {
    const finished = activeSessionRemaining(openSession);
    if (finished.ended) {
      // Record when it actually ended (freeze time, or the moment its
      // budget ran out) rather than when we happened to notice — this row
      // is the history of the child's play time.
      const expiredAt = new Date(new Date(openSession.startedAt).getTime() + openSession.durationSec * 1000);
      openSession = await prisma.playSession.update({
        where: { id: openSession.id },
        data: { endedAt: openSession.frozenAt || expiredAt },
      });
    }
  }

  return {
    childId,
    childName: child.name,
    date,
    paired: Boolean(child.deviceToken),
    frozen: child.frozen,
    tasks: completions.map((c) => ({
      taskId: c.taskId,
      title: c.task.title,
      type: c.task.type,
      rewardMinutes: c.task.rewardMinutes,
      gameId: c.task.gameId,
      proofAllowed: c.task.proofAllowed,
      status: c.status,
      verifiedBy: c.verifiedBy,
    })),
    earnedMinutesToday: earned,
    availableSeconds: availableSec,
    activeSession: activeSessionRemaining(openSession),
  };
}

module.exports = { ensureTodayRows, earnedMinutesToday, computeChildState, activeSessionRemaining };
