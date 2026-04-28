const router = require('express').Router();
const authMiddleware = require('../middleware/auth');
const supabase = require('../config/supabase');
const { generateLeadReport } = require('../services/pdfService');
const { calculateMortgage } = require('../services/mortgageService');
const { scoreLead } = require('../services/scoringService');

router.use(authMiddleware);

// ─────────────────────────────────────────────
// GET /api/pdf/lead/:id
// Generate and return PDF report for a lead
// ─────────────────────────────────────────────
router.get('/lead/:id', async (req, res) => {
  try {
    // Fetch lead
    const { data: lead, error } = await supabase
      .from('leads')
      .select('*')
      .eq('id', req.params.id)
      .eq('user_id', req.userId)
      .single();

    if (error || !lead) {
      return res.status(404).json({
        success: false,
        message: 'Lead not found',
      });
    }

    // Calculate mortgage if loan data exists
    let mortgageResult = null;
    if (lead.loan_amount && lead.loan_amount > 0) {
      mortgageResult = calculateMortgage({
        loanAmount: lead.loan_amount,
        downPayment: 0,
        interestRate: 6.5,
        termYears: 30,
      });
    }

    // Generate risk score if financial data exists
    let scoringResult = null;
    if (lead.income && lead.credit_score) {
      scoringResult = scoreLead({
        income: lead.income,
        debt: lead.debt || 0,
        creditScore: lead.credit_score,
        loanAmount: lead.loan_amount || 0,
        employmentStatus: lead.employment_status || 'employed',
      });
    }

    // Generate PDF
    const pdfBuffer = await generateLeadReport(lead, mortgageResult, scoringResult);

    // Send PDF
    const filename = `LoanTrack_${lead.first_name}_${lead.last_name}_Report.pdf`;
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename="${filename}"`);
    res.setHeader('Content-Length', pdfBuffer.length);
    res.send(pdfBuffer);

  } catch (err) {
    console.error('PDF generation error:', err);
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;