require('dotenv').config();
const app = require('./app');

const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`
  ╔═══════════════════════════════════╗
  ║   LoanTrack API Server            ║
  ║   Running on port ${PORT}            ║
  ║   Environment: ${process.env.NODE_ENV}      ║
  ╚═══════════════════════════════════╝
  `);
});