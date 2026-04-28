const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');

const authRoutes = require('./routes/auth');
const leadRoutes = require('./routes/leads');
const mortgageRoutes = require('./routes/mortgage');
const analyticsRoutes = require('./routes/analytics');
const scoringRoutes = require('./routes/scoring');
const activitiesRoutes = require('./routes/activities');
const pdfRoutes = require('./routes/pdf');

const app = express();





// ── MIDDLEWARE ─────────────────────────────────────
app.use(helmet());
app.use(cors());
app.use(morgan('dev'));
app.use(express.json());

// ── ROUTES ─────────────────────────────────────────
app.use('/api/auth', authRoutes);
app.use('/api/leads', leadRoutes);
app.use('/api/mortgage', mortgageRoutes);
app.use('/api/analytics', analyticsRoutes);
app.use('/api/scoring', scoringRoutes);
app.use('/api/activities', activitiesRoutes);
app.use('/api/pdf', pdfRoutes);


// ── HEALTH CHECK ───────────────────────────────────
app.get('/api/health', (req, res) => {
  res.json({
    status: 'ok',
    message: 'LoanTrack API is running',
    version: '1.0.0',
    timestamp: new Date().toISOString()
  });
});

// ── 404 HANDLER ────────────────────────────────────
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: `Route ${req.originalUrl} not found`
  });
});

// ── ERROR HANDLER ──────────────────────────────────
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Internal server error'
  });
});

module.exports = app;