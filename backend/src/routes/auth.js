const router = require('express').Router();
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const supabase = require('../config/supabase');


router.post(
  '/register',
  [
    body('email').isEmail().withMessage('Valid email required'),
    body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
    body('fullName').notEmpty().withMessage('Full name is required'),
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }
    try {
      const { email, password, fullName, company, role } = req.body;
      const { data: existing } = await supabase
        .from('users')
        .select('id')
        .eq('email', email)
        .single();
      if (existing) {
        return res.status(409).json({ success: false, message: 'Email already registered' });
      }
      const allowedSelfRegisterRoles = ['agent', 'viewer'];
const assignedRole = allowedSelfRegisterRoles.includes(role) ? role : 'agent';

      const passwordHash = await bcrypt.hash(password, 12);
      const { data: user, error } = await supabase
  .from('users')
  .insert([{
    email,
    password_hash: passwordHash,
    full_name: fullName,
    company: company || null,
    role: assignedRole, 
    status: 'pending', // ← add this line
  }])
  .select('id, email, full_name, company, role, created_at')
  .single();
      if (error) throw error;
      const token = jwt.sign({ userId: user.id }, process.env.JWT_SECRET, { expiresIn: '7d' });
      res.status(201).json({
  success: true,
  message: 'Account created successfully',
  token,
  user: {
    id: user.id,
    email: user.email,
    fullName: user.full_name,
    company: user.company,
    role: user.role,  // ← add this
  },
});
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  }
);

router.post(
  '/login',
  [
    body('email').isEmail().withMessage('Valid email required'),
    body('password').notEmpty().withMessage('Password is required'),
  ],
  async (req, res) => {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ success: false, errors: errors.array() });
    }
    try {
      const { email, password } = req.body;
      const { data: user, error } = await supabase
        .from('users')
        .select('*')
        .eq('email', email)
        .single();
      if (error || !user) {
        return res.status(401).json({ success: false, message: 'Invalid email or password' });
      }
      const isValid = await bcrypt.compare(password, user.password_hash);
      if (!isValid) {
        return res.status(401).json({ success: false, message: 'Invalid email or password' });
      }
      if (user.status === 'pending') {
  return res.status(403).json({
    success: false,
    message: 'Your account is pending approval. Please wait for an admin to activate your account.',
    code: 'ACCOUNT_PENDING',
  });
}

if (user.status === 'suspended') {
  return res.status(403).json({
    success: false,
    message: 'Your account has been suspended. Contact your administrator.',
    code: 'ACCOUNT_SUSPENDED',
  });
}
      
      const token = jwt.sign({ userId: user.id }, process.env.JWT_SECRET, { expiresIn: '7d' });
      res.json({
        success: true,
        message: 'Login successful',
        token,
        user: { id: user.id, email: user.email, fullName: user.full_name, company: user.company },
      });
    } catch (err) {
      res.status(500).json({ success: false, message: err.message });
    }
  }
);

router.get('/me', require('../middleware/auth'), async (req, res) => {
  try {
    const { data: user, error } = await supabase
      .from('users')
      .select('id, email, full_name, company, role, created_at')
      .eq('id', req.userId)
      .single();
    if (error || !user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }
    res.json({
      success: true,
      user: { id: user.id, email: user.email, fullName: user.full_name, company: user.company, role: user.role },
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// ─────────────────────────────────────────────
// GET /api/auth/profile
// Full profile with stats
// ─────────────────────────────────────────────
router.get('/profile', require('../middleware/auth'), async (req, res) => {
  try {
    const authMiddleware = require('../middleware/auth');
    const { attachUserRole } = require('../middleware/roles');

    // Get user
    const { data: user, error } = await supabase
      .from('users')
      .select('id, email, full_name, company, role, created_at, manager_id')
      .eq('id', req.userId)
      .single();

    if (error || !user) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    // Get their lead stats
    const { data: leads } = await supabase
      .from('leads')
      .select('id, status, loan_amount')
      .eq('user_id', req.userId);

    const totalLeads = leads?.length || 0;
    const closedLeads = leads?.filter(l => l.status === 'closed').length || 0;
    const pipelineValue = leads?.reduce((sum, l) => sum + (l.loan_amount || 0), 0) || 0;

    // Get manager info if agent
    let manager = null;
    if (user.manager_id) {
      const { data: mgr } = await supabase
        .from('users')
        .select('id, full_name, email, role')
        .eq('id', user.manager_id)
        .single();
      manager = mgr;
    }

    // Get team size if admin
    let teamSize = 0;
    if (user.role === 'admin' || user.role === 'superadmin') {
      const { data: team } = await supabase
        .from('users')
        .select('id')
        .eq('manager_id', req.userId);
      teamSize = team?.length || 0;
    }

    // Role badge info
    const roleInfo = {
      superadmin: { label: 'Super Admin', color: 'purple', description: 'Full system access' },
      admin: { label: 'Admin', color: 'blue', description: 'Team management access' },
      agent: { label: 'Agent', color: 'green', description: 'Lead management access' },
      viewer: { label: 'Viewer', color: 'gray', description: 'Read-only access' },
    };

    res.json({
      success: true,
      data: {
        user: {
          id: user.id,
          email: user.email,
          fullName: user.full_name,
          company: user.company,
          role: user.role,
          roleInfo: roleInfo[user.role],
          createdAt: user.created_at,
          manager,
        },
        stats: {
          totalLeads,
          closedLeads,
          pipelineValue,
          conversionRate: totalLeads > 0
            ? parseFloat(((closedLeads / totalLeads) * 100).toFixed(1))
            : 0,
          teamSize,
        },
      },
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});
module.exports = router;
