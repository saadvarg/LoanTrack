const router = require('express').Router();
const { body, validationResult } = require('express-validator');
const authMiddleware = require('../middleware/auth');
const supabase = require('../config/supabase');
const { attachUserRole, canAccessLead, denyViewers } = require('../middleware/roles');

router.use(authMiddleware);
router.use(attachUserRole);

router.get('/', async (req, res) => {
  try {
    let query = supabase
      .from('leads')
      .select('*')
      .order('date_added', { ascending: false });
    if (req.userRole === 'agent' || req.userRole === 'viewer') {
      query = query.eq('user_id', req.userId);
    }
    const { data, error } = await query;
    if (error) throw error;
    res.json({ success: true, count: data.length, data });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.get('/:id', canAccessLead, async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('leads')
      .select('*')
      .eq('id', req.params.id)
      .single();
    if (error || !data) {
      return res.status(404).json({ success: false, message: 'Lead not found' });
    }
    res.json({ success: true, data });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.post('/',
  denyViewers,
  [
    body('firstName').notEmpty().withMessage('First name is required'),
    body('lastName').notEmpty().withMessage('Last name is required'),
    body('email').isEmail().withMessage('Valid email required'),
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }
    try {
      const {
        firstName, lastName, email, phone,
        loanAmount, status, notes,
        income, debt, creditScore, employmentStatus
      } = req.body;
      const { data, error } = await supabase
        .from('leads')
        .insert([{
          user_id: req.userId,
          first_name: firstName,
          last_name: lastName,
          email,
          phone: phone || null,
          loan_amount: loanAmount || 0,
          status: status || 'new',
          notes: notes || null,
          income: income || null,
          debt: debt || null,
          credit_score: creditScore || null,
          employment_status: employmentStatus || 'employed',
        }])
        .select()
        .single();
      if (error) throw error;
      await supabase.from('activities').insert([{
        lead_id: data.id,
        user_id: req.userId,
        action: 'Lead Created',
        note: `${data.first_name} ${data.last_name} was added to the pipeline`,
      }]);
      res.status(201).json({ success: true, message: 'Lead created', data });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  }
);

router.put('/:id', denyViewers, canAccessLead, async (req, res) => {
  try {
    const {
      firstName, lastName, email, phone,
      loanAmount, status, notes,
      income, debt, creditScore, employmentStatus
    } = req.body;
    const { data, error } = await supabase
      .from('leads')
      .update({
        first_name: firstName,
        last_name: lastName,
        email,
        phone,
        loan_amount: loanAmount,
        status,
        notes,
        income,
        debt,
        credit_score: creditScore,
        employment_status: employmentStatus,
        updated_at: new Date().toISOString(),
      })
      .eq('id', req.params.id)
      .select()
      .single();
    if (error) throw error;
    await supabase.from('activities').insert([{
      lead_id: data.id,
      user_id: req.userId,
      action: 'Lead Updated',
      note: `Lead status changed to ${data.status}`,
    }]);
    res.json({ success: true, message: 'Lead updated', data });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

router.delete('/:id', denyViewers, canAccessLead, async (req, res) => {
  try {
    const { data: lead } = await supabase
      .from('leads')
      .select('id, first_name, last_name')
      .eq('id', req.params.id)
      .single();
    const { error } = await supabase
      .from('leads')
      .delete()
      .eq('id', req.params.id);
    if (error) throw error;
    if (lead) {
      await supabase.from('activities').insert([{
        lead_id: lead.id,
        user_id: req.userId,
        action: 'Lead Deleted',
        note: `${lead.first_name} ${lead.last_name} was removed from the pipeline`,
      }]);
    }
    res.json({ success: true, message: 'Lead deleted' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;