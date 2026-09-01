const bcrypt = require("bcryptjs");
const { prisma } = require("../src/db");

async function main() {
  const passwordHash = await bcrypt.hash("1234", 10);
  const parent = await prisma.parent.create({
    data: {
      email: "demo@wiam.app",
      username: "demo",
      passwordHash,
      children: { create: { name: "أحمد" } },
    },
    include: { children: true },
  });
  const child = parent.children[0];

  await prisma.task.createMany({
    data: [
      { childId: child.id, title: "درس التفاعل الاجتماعي", type: "digital", rewardMinutes: 15 },
      { childId: child.id, title: "نشاط المهارات اليومية", type: "digital", rewardMinutes: 10 },
      { childId: child.id, title: "ترتيب الغرفة", type: "external", rewardMinutes: 20, proofAllowed: true },
    ],
  });

  console.log("Seeded parent demo@wiam.app (username: demo) / password 1234, child:", child.id);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
