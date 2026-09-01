const jwt = require("jsonwebtoken");
const crypto = require("crypto");
const { prisma } = require("./db");

const JWT_SECRET = process.env.JWT_SECRET;

function signParentToken(parent) {
  return jwt.sign({ parentId: parent.id }, JWT_SECRET, { expiresIn: "30d" });
}

// Parent-facing routes: Authorization: Bearer <jwt>
async function requireParent(req, res, next) {
  const header = req.headers.authorization || "";
  const token = header.startsWith("Bearer ") ? header.slice(7) : null;
  if (!token) return res.status(401).json({ error: "missing_token" });
  try {
    const payload = jwt.verify(token, JWT_SECRET);
    req.parentId = payload.parentId;
    next();
  } catch {
    return res.status(401).json({ error: "invalid_token" });
  }
}

// Child-device routes: X-Device-Token: <token issued at pairing time>
// A device token (not a parent login) is deliberate: the iPad should be
// usable by the child without ever holding the parent's credentials.
async function requireChildDevice(req, res, next) {
  const token = req.headers["x-device-token"];
  if (!token) return res.status(401).json({ error: "missing_device_token" });
  const child = await prisma.child.findUnique({ where: { deviceToken: token } });
  if (!child) return res.status(401).json({ error: "invalid_device_token" });
  req.child = child;
  next();
}

function generateDeviceToken() {
  return crypto.randomBytes(24).toString("hex");
}

// 3 digits, human-typeable — this is a one-time pairing code, never the
// long-term auth credential (see the schema comment on Child.pairingCode).
// Deliberately short-lived (see PAIRING_CODE_TTL_MS) since a 3-digit space
// is small (1000 combinations).
function generatePairingCode() {
  return String(crypto.randomInt(0, 1_000)).padStart(3, "0");
}

module.exports = { signParentToken, requireParent, requireChildDevice, generateDeviceToken, generatePairingCode };
