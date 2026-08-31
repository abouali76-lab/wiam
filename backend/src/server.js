require("dotenv").config();
const express = require("express");
const cors = require("cors");

const parentRoutes = require("./routes/parent");
const childRoutes = require("./routes/child");

const app = express();
app.use(cors());
app.use(express.json());

app.get("/health", (req, res) => res.json({ ok: true }));

app.use("/api/parent", parentRoutes);
app.use("/api/child", childRoutes);

app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: "internal_error" });
});

const port = process.env.PORT || 4000;
app.listen(port, () => console.log(`Wiam backend listening on :${port}`));
