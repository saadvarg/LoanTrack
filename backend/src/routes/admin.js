const router = require('express').Router();
const bcrypt = require('bcryptjs');
const authMiddleware = require('../middleware/auth');
const { attachUserRole, requireMinRole } = require('../middleware/roles');
const supabase = require('../config/supabase');

// All admin routes require auth + role check
router.use(authMiddleware);
router.use(attachUserRole);
router.use(requireMinRole('admin'));

// GET /api/admin/users
router.get('/users', async (req, res) => {
  try {
    let query = supabase
      .from('users')
      .select('id, email, full_name, role, status, company, team_id_ref, manager_id, created_at')
      .order('created_at', { ascending: false });

    if (req.userRole === 'admin') {
      query = query.eq('manager_id', req.userId);
    }

    const { data, error } = await query;
    if (error) throw error;

    res.json({ success: true, count: data.length, data });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// POST /api/admin/users
router.post('/users', async (req, res) => {
  try {
    const { email, password, fullName, role, company } = req.body;

    const allowedRoles = req.userRole === 'superadmin'
      ? ['superadmin', 'admin', 'agent', 'viewer']
      : ['agent', 'viewer'];

    if (!allowedRoles.includes(role)) {
      return res.status(403).json({
        success: false,
        message: `You cannot create users with role: ${role}`,
      });
    }

    const { data: existingUsers, error: existingError } = await supabase
      .from('users')
      .select('id')
      .eq('email', email)
      .limit(1);

    if (existingError) throw existingError;

    if (existingUsers && existingUsers.length > 0) {
      return res.status(409).json({
        success: false,
        message: 'Email already registered',
      });
    }

    const passwordHash = await bcrypt.hash(password || 'LoanTrack123!', 12);

    const { data: newUser, error } = await supabase
      .from('users')
      .insert([{
        email,
        password_hash: passwordHash,
        full_name: fullName,
        role: role || 'agent',
        company: company || null,
        manager_id: req.userRole === 'admin' ? req.userId : null,
        status: 'pending',
      }])
      .select('id, email, full_name, role, status, company, created_at')
      .single();

    if (error) throw error;

    res.status(201).json({
      success: true,
      message: 'User created successfully',
      data: newUser,
      temporaryPassword: password || 'LoanTrack123!',
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// PUT /api/admin/users/:id/role
router.put('/users/:id/role', async (req, res) => {
  try {
    const { role } = req.body;
    const { id } = req.params;

    const allowedRoles = req.userRole === 'superadmin'
      ? ['superadmin', 'admin', 'agent', 'viewer']
      : ['agent', 'viewer'];

    if (!allowedRoles.includes(role)) {
      return res.status(403).json({
        success: false,
        message: `You cannot assign role: ${role}`,
      });
    }

    const { data, error } = await supabase
      .from('users')
      .update({ role })
      .eq('id', id)
      .select('id, email, full_name, role, status, company, created_at')
      .single();

    if (error) throw error;

    res.json({
      success: true,
      message: `Role updated to ${role}`,
      data,
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// DELETE /api/admin/users/:id
router.delete('/users/:id', requireMinRole('superadmin'), async (req, res) => {
  try {
    const { id } = req.params;

    if (id === req.userId) {
      return res.status(400).json({
        success: false,
        message: 'You cannot delete your own account',
      });
    }

    const { error } = await supabase
      .from('users')
      .delete()
      .eq('id', id);

    if (error) throw error;

    res.json({ success: true, message: 'User deleted successfully' });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET /api/admin/leads
router.get('/leads', async (req, res) => {
  try {
    let query = supabase
      .from('leads')
      .select(`
        *,
        users:user_id (id, full_name, email, role)
      `)
      .order('date_added', { ascending: false });

    if (req.userRole === 'admin') {
      const { data: teamMembers } = await supabase
        .from('users')
        .select('id')
        .eq('manager_id', req.userId);

      const teamIds = [req.userId, ...(teamMembers || []).map(m => m.id)];
      query = query.in('user_id', teamIds);
    }

    const { data, error } = await query;
    if (error) throw error;

    res.json({ success: true, count: data.length, data });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET /api/admin/stats
router.get('/stats', async (req, res) => {
  try {
    let usersQuery = supabase
      .from('users')
      .select('id, full_name, role');

    if (req.userRole === 'admin') {
      usersQuery = usersQuery.eq('manager_id', req.userId);
    }

    const { data: users } = await usersQuery;
    const userIds = (users || []).map(u => u.id);
    userIds.push(req.userId);

    const { data: leads } = await supabase
      .from('leads')
      .select('*')
      .in('user_id', userIds);

    const total = leads?.length || 0;
    const closed = leads?.filter(l => l.status === 'closed').length || 0;
    const pipeline = leads?.reduce((sum, l) => sum + (l.loan_amount || 0), 0) || 0;

    const agentStats = (users || []).map(user => {
      const agentLeads = leads?.filter(l => l.user_id === user.id) || [];
      return {
        userId: user.id,
        name: user.full_name,
        role: user.role,
        totalLeads: agentLeads.length,
        closedLeads: agentLeads.filter(l => l.status === 'closed').length,
        pipelineValue: agentLeads.reduce((sum, l) => sum + (l.loan_amount || 0), 0),
        conversionRate: agentLeads.length > 0
          ? parseFloat(((agentLeads.filter(l => l.status === 'closed').length / agentLeads.length) * 100).toFixed(1))
          : 0,
      };
    });

    res.json({
      success: true,
      data: {
        totalTeamMembers: users?.length || 0,
        totalLeads: total,
        closedLeads: closed,
        totalPipeline: pipeline,
        conversionRate: total > 0 ? parseFloat(((closed / total) * 100).toFixed(1)) : 0,
        agentStats,
      },
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET /api/admin/users/pending
router.get('/users/pending', async (req, res) => {
  try {
    const { data, error } = await supabase
      .from('users')
      .select('id, email, full_name, role, status, company, created_at')
      .eq('status', 'pending')
      .order('created_at', { ascending: false });

    if (error) throw error;

    res.json({
      success: true,
      count: data.length,
      data,
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// PUT /api/admin/users/:id/approve
router.put('/users/:id/approve', async (req, res) => {
  try {
    const { id } = req.params;
    const { role } = req.body;

    const allowedRoles = req.userRole === 'superadmin'
      ? ['superadmin', 'admin', 'agent', 'viewer']
      : ['agent', 'viewer'];

    const assignedRole = allowedRoles.includes(role) ? role : 'agent';

    const { data, error } = await supabase
      .from('users')
      .update({
        status: 'active',
        role: assignedRole,
      })
      .eq('id', id)
      .select('id, email, full_name, role, status, company, created_at')
      .single();

    if (error) throw error;

    const { error: activityError } = await supabase
      .from('activities')
      .insert([{
        lead_id: null,
        user_id: req.userId,
        action: 'User Approved',
        note: `${data.full_name} approved as ${assignedRole}`,
      }]);

    if (activityError) {
      console.log('Activity log insert failed:', activityError.message);
    }

    res.json({
      success: true,
      message: `${data.full_name} approved as ${assignedRole}`,
      data,
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// PUT /api/admin/users/:id/reject
router.put('/users/:id/reject', async (req, res) => {
  try {
    const { id } = req.params;

    if (id === req.userId) {
      return res.status(400).json({
        success: false,
        message: 'You cannot reject your own account',
      });
    }

    const { data, error } = await supabase
      .from('users')
      .update({ status: 'rejected' })
      .eq('id', id)
      .select('id, email, full_name, role, status, company, created_at')
      .single();

    if (error) throw error;

    res.json({
      success: true,
      message: `${data.full_name} has been rejected`,
      data,
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// PUT /api/admin/users/:id/suspend
router.put('/users/:id/suspend', async (req, res) => {
  try {
    const { id } = req.params;

    if (id === req.userId) {
      return res.status(400).json({
        success: false,
        message: 'You cannot suspend your own account',
      });
    }

    const { data, error } = await supabase
      .from('users')
      .update({ status: 'suspended' })
      .eq('id', id)
      .select('id, email, full_name, role, status, company, created_at')
      .single();

    if (error) throw error;

    res.json({
      success: true,
      message: `${data.full_name} has been suspended`,
      data,
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

// GET /api/admin/users/all
router.get('/users/all', async (req, res) => {
  try {
    let query = supabase
      .from('users')
      .select('id, email, full_name, role, status, company, created_at, manager_id')
      .order('created_at', { ascending: false });

    if (req.userRole === 'admin') {
      const { data: teamMembers } = await supabase
        .from('users')
        .select('id')
        .eq('manager_id', req.userId);

      const teamIds = [req.userId, ...(teamMembers || []).map(m => m.id)];
      query = query.in('id', teamIds);
    }

    const { data, error } = await query;
    if (error) throw error;

    const grouped = {
      superadmin: data.filter(u => u.role === 'superadmin'),
      admin: data.filter(u => u.role === 'admin'),
      agent: data.filter(u => u.role === 'agent'),
      viewer: data.filter(u => u.role === 'viewer'),
      pending: data.filter(u => u.status === 'pending'),
    };

    res.json({
      success: true,
      total: data.length,
      grouped,
      data,
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
});

module.exports = router;
