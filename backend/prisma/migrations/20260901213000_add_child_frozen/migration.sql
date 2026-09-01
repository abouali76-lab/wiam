-- RedefineTables
PRAGMA defer_foreign_keys=ON;
PRAGMA foreign_keys=OFF;
CREATE TABLE "new_Child" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "parentId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "timezone" TEXT NOT NULL DEFAULT 'Asia/Riyadh',
    "deviceToken" TEXT,
    "frozen" BOOLEAN NOT NULL DEFAULT false,
    "pairingCode" TEXT,
    "pairingCodeExpiresAt" DATETIME,
    "createdAt" DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "Child_parentId_fkey" FOREIGN KEY ("parentId") REFERENCES "Parent" ("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
INSERT INTO "new_Child" ("createdAt", "deviceToken", "id", "name", "pairingCode", "pairingCodeExpiresAt", "parentId", "timezone") SELECT "createdAt", "deviceToken", "id", "name", "pairingCode", "pairingCodeExpiresAt", "parentId", "timezone" FROM "Child";
DROP TABLE "Child";
ALTER TABLE "new_Child" RENAME TO "Child";
CREATE UNIQUE INDEX "Child_deviceToken_key" ON "Child"("deviceToken");
CREATE UNIQUE INDEX "Child_pairingCode_key" ON "Child"("pairingCode");
PRAGMA foreign_keys=ON;
PRAGMA defer_foreign_keys=OFF;

