const router = require('express').Router();
const { body, validationResult } = require('express-validator');
const authMiddleware = require('../middleware/auth');
const supabase = require('../config/supabase');
const { scoreLead } = require('../services/scoringService');

router.use(authMiddleware);

// ─────────────────────────────────────────────
// POST /api/scoring/score
// Score any lead profile instantly
// ─────────────────────────────────────────────
router.post(
  '/score',
  [
    body('income').isNumeric().withMessage('Income must be a number'),
    body('debt').isNumeric().withMessage('Debt must be a number'),
    body('creditScore').isNumeric().withMessage('Credit score must be a number'),
    body('loanAmount').isNumeric().withMessage('Loan amount must be a number'),
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }

    try {
      const { income, debt, creditScore, loanAmount, employmentStatus } = req.body;

      const result = scoreLead({
        income: Number(income),
        debt: Number(debt),
        creditScore: Number(creditScore),
        loanAmount: Number(loanAmount),
        employmentStatus: employmentStatus || 'employed',
      });

      res.json({ success: true, data: result });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  }
);

// ─────────────────────────────────────────────
// POST /api/scoring/score-lead/:id
// Score a specific lead and save result to DB
// ─────────────────────────────────────────────
router.post('/score-lead/:id', async (req, res) => {
  try {
    const { id } = req.params;

    // Fetch lead from database
    const { data: lead, error: fetchError } = await supabase
      .from('leads')
      .select('*')
      .eq('id', id)
      .eq('user_id', req.userId)
      .single();

    if (fetchError || !lead) {
      return res.status(404).json({
        success: false,
        message: 'Lead not found',
      });
    }

    // Check lead has enough data to score
    if (!lead.income || !lead.credit_score) {
      return res.status(400).json({
        success: false,
        message: 'Lead requires income and credit_score to be scored',
      });
    }

    // Run scoring engine
    const result = scoreLead({
      income: lead.income,
      debt: lead.debt || 0,
      creditScore: lead.credit_score,
      loanAmount: lead.loan_amount,
      employmentStatus: lead.employment_status || 'employed',
    });

    // Save score back to lead
    const { error: updateError } = await supabase
      .from('leads')
      .update({
        risk_score: result.score,
        risk_label: result.riskLabel,
        updated_at: new Date().toISOString(),
      })
      .eq('id', id);

    if (updateError) throw updateError;

    // Log activity
    await supabase.from('activities').insert([{
      lead_id: id,
      user_id: req.userId,
      action: 'Risk Score Generated',
      note: `Score: ${result.score}/100 — ${result.riskLabel}`,
    }]);

    res.json({
      success: true,
      message: 'Lead scored successfully',
      data: {
        leadId: id,
        leadName: `${lead.first_name} ${lead.last_name}`,
        ...result,
      },
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;