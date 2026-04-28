const router = require('express').Router();
const authMiddleware = require('../middleware/auth');
const { attachUserRole } = require('../middleware/roles');
const supabase = require('../config/supabase');

router.use(authMiddleware);
router.use(attachUserRole);

// ─────────────────────────────────────────────
// GET /api/analytics/dashboard
// Returns different data based on user role
// ─────────────────────────────────────────────
router.get('/dashboard', async (req, res) => {
  try {
    const role = req.userRole;

    // ── SUPERADMIN & ADMIN — see everything ──
    if (role === 'superadmin' || role === 'admin') {
      // Get all leads
      let leadsQuery = supabase.from('leads').select('*');
      
      // Admin only sees their team
      if (role === 'admin') {
        const { data: teamMembers } = await supabase
          .from('users')
          .select('id')
          .eq('manager_id', req.userId);
        const teamIds = [req.userId, ...(teamMembers || []).map(m => m.id)];
        leadsQuery = leadsQuery.in('user_id', teamIds);
      }

      const { data: leads } = await leadsQuery;

      // Get all team members
      let usersQuery = supabase
        .from('users')
        .select('id, full_name, email, role, created_at');
      
      if (role === 'admin') {
        usersQuery = usersQuery.eq('manager_id', req.userId);
      }
      
      const { data: users } = await usersQuery;

      // Calculate metrics
      const total = leads?.length || 0;
      const closed = leads?.filter(l => l.status === 'closed').length || 0;
      const pipeline = leads?.reduce((sum, l) => sum + (l.loan_amount || 0), 0) || 0;
      const conversionRate = total > 0
        ? parseFloat(((closed / total) * 100).toFixed(1)) : 0;

      // Per agent performance
      const agentPerformance = (users || []).map(user => {
        const agentLeads = leads?.filter(l => l.user_id === user.id) || [];
        return {
          userId: user.id,
          name: user.full_name,
          email: user.email,
          role: user.role,
          totalLeads: agentLeads.length,
          closedLeads: agentLeads.filter(l => l.status === 'closed').length,
          pipelineValue: agentLeads.reduce((sum, l) => sum + (l.loan_amount || 0), 0),
          conversionRate: agentLeads.length > 0
            ? parseFloat(((agentLeads.filter(l => l.status === 'closed').length / agentLeads.length) * 100).toFixed(1))
            : 0,
        };
      });

      // Status breakdown
      const byStatus = {
        new: leads?.filter(l => l.status === 'new').length || 0,
        contacted: leads?.filter(l => l.status === 'contacted').length || 0,
        qualified: leads?.filter(l => l.status === 'qualified').length || 0,
        closed,
        lost: leads?.filter(l => l.status === 'lost').length || 0,
      };

     return res.json({
  success: true,
  role,
  portal: 'admin',
  data: {
    totalLeads: total,
    totalPipelineValue: pipeline,
    closedValue: leads?.filter(l => l.status === 'closed')
      .reduce((sum, l) => sum + (l.loan_amount || 0), 0) || 0,
    avgLoanValue: total > 0
      ? parseFloat((pipeline / total).toFixed(2)) : 0,
    conversionRate,
    avgRiskScore: leads?.filter(l => l.risk_score).length > 0
      ? parseFloat((leads.reduce((sum, l) =>
          sum + (l.risk_score || 0), 0) /
          leads.filter(l => l.risk_score).length).toFixed(1))
      : null,
    byStatus,
    recentLeads: (leads || [])
      .sort((a, b) => new Date(b.date_added) - new Date(a.date_added))
      .slice(0, 5)
      .map(l => ({
        id: l.id,
        firstName: l.first_name,
        lastName: l.last_name,
        email: l.email,
        status: l.status,
        loanAmount: l.loan_amount || 0,
        riskScore: l.risk_score,
        riskLabel: l.risk_label,
        dateAdded: l.date_added,
      })),
    agentPerformance,
    totalTeamMembers: users?.length || 0,
  },
});
    }

    // ── AGENT — sees only their own leads ──
    if (role === 'agent') {
      const { data: leads } = await supabase
        .from('leads')
        .select('*')
        .eq('user_id', req.userId)
        .order('date_added', { ascending: false });

      const total = leads?.length || 0;
      const closed = leads?.filter(l => l.status === 'closed').length || 0;
      const pipeline = leads?.reduce((sum, l) => sum + (l.loan_amount || 0), 0) || 0;
      const avgRiskScore = leads?.filter(l => l.risk_score).length > 0
        ? parseFloat((leads.reduce((sum, l) => sum + (l.risk_score || 0), 0) /
            leads.filter(l => l.risk_score).length).toFixed(1))
        : null;

      const byStatus = {
        new: leads?.filter(l => l.status === 'new').length || 0,
        contacted: leads?.filter(l => l.status === 'contacted').length || 0,
        qualified: leads?.filter(l => l.status === 'qualified').length || 0,
        closed,
        lost: leads?.filter(l => l.status === 'lost').length || 0,
      };

     return res.json({
  success: true,
  role,
  portal: 'agent',
  data: {
    totalLeads: total,
    totalPipelineValue: pipeline,
    closedValue: leads?.filter(l => l.status === 'closed')
      .reduce((sum, l) => sum + (l.loan_amount || 0), 0) || 0,
    avgLoanValue: total > 0
      ? parseFloat((pipeline / total).toFixed(2)) : 0,
    conversionRate: total > 0
      ? parseFloat(((closed / total) * 100).toFixed(2)) : 0,
    avgRiskScore: leads?.filter(l => l.risk_score).length > 0
      ? parseFloat((leads.reduce((sum, l) =>
          sum + (l.risk_score || 0), 0) /
          leads.filter(l => l.risk_score).length).toFixed(1))
      : null,
    byStatus: {
      new: leads?.filter(l => l.status === 'new').length || 0,
      contacted: leads?.filter(l => l.status === 'contacted').length || 0,
      qualified: leads?.filter(l => l.status === 'qualified').length || 0,
      closed,
      lost: leads?.filter(l => l.status === 'lost').length || 0,
    },
    recentLeads: (leads || []).slice(0, 5).map(l => ({
      id: l.id,
      firstName: l.first_name,
      lastName: l.last_name,
      email: l.email,
      status: l.status,
      loanAmount: l.loan_amount || 0,
      riskScore: l.risk_score,
      riskLabel: l.risk_label,
      dateAdded: l.date_added,
    })),
  },
});
    }

    // ── VIEWER — read only summary ──
    if (role === 'viewer') {
      const { data: leads } = await supabase
        .from('leads')
        .select('id, first_name, last_name, status, loan_amount, date_added')
        .eq('user_id', req.userId)
        .order('date_added', { ascending: false });

     return res.json({
  success: true,
  role,
  portal: 'viewer',
  data: {
    totalLeads: leads?.length || 0,
    totalPipelineValue: 0,
    closedValue: 0,
    avgLoanValue: 0,
    conversionRate: 0,
    avgRiskScore: null,
    byStatus: {
      new: leads?.filter(l => l.status === 'new').length || 0,
      contacted: 0,
      qualified: 0,
      closed: leads?.filter(l => l.status === 'closed').length || 0,
      lost: 0,
    },
    recentLeads: (leads || []).slice(0, 5).map(l => ({
      id: l.id,
      firstName: l.first_name,
      lastName: l.last_name,
      email: l.email,
      status: l.status,
      loanAmount: l.loan_amount || 0,
      riskScore: null,
      riskLabel: null,
      dateAdded: l.date_added,
    })),
  },
});
    }

  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;