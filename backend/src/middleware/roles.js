// ─────────────────────────────────────────────────────
// roles.js
// Role-based access control middleware
// ─────────────────────────────────────────────────────

const supabase = require('../config/supabase');

// Role hierarchy — higher number = more access
const ROLE_LEVELS = {
  viewer:     1,
  agent:      2,
  admin:      3,
  superadmin: 4,
};

/**
 * Fetch user role from DB and attach to request
 * Always use this before any role check
 */
async function attachUserRole(req, res, next) {
  try {
    const { data: user, error } = await supabase
      .from('users')
      .select('id, role, team_id_ref, manager_id, full_name, email')
      .eq('id', req.userId)
      .single();

    if (error || !user) {
      return res.status(401).json({
        success: false,
        message: 'User not found',
      });
    }

    req.user = user;
    req.userRole = user.role;
    next();
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
}

/**
 * Require minimum role level
 * Usage: requireRole('admin') — allows admin and superadmin
 */
function requireRole(...allowedRoles) {
  return (req, res, next) => {
    if (!req.userRole) {
      return res.status(403).json({
        success: false,
        message: 'Role not loaded. Use attachUserRole first.',
      });
    }

    if (!allowedRoles.includes(req.userRole)) {
      return res.status(403).json({
        success: false,
        message: `Access denied. Required role: ${allowedRoles.join(' or ')}. Your role: ${req.userRole}`,
      });
    }

    next();
  };
}

/**
 * Require minimum role level by hierarchy
 * Usage: requireMinRole('admin') — allows admin AND superadmin
 */
function requireMinRole(minRole) {
  return (req, res, next) => {
    const userLevel = ROLE_LEVELS[req.userRole] || 0;
    const requiredLevel = ROLE_LEVELS[minRole] || 99;

    if (userLevel < requiredLevel) {
      return res.status(403).json({
        success: false,
        message: `Access denied. Minimum role required: ${minRole}`,
      });
    }

    next();
  };
}

/**
 * Check if user can access a specific lead
 * - superadmin/admin: any lead
 * - agent: only their own leads
 * - viewer: only their own leads (read only)
 */
async function canAccessLead(req, res, next) {
  try {
    const { id } = req.params;
    const { data: lead, error } = await supabase
      .from('leads')
      .select('user_id, assigned_to')
      .eq('id', id)
      .single();

    if (error || !lead) {
      return res.status(404).json({
        success: false,
        message: 'Lead not found',
      });
    }

    const role = req.userRole;
    const userId = req.userId;

    // Superadmin and admin can access any lead
    if (role === 'superadmin' || role === 'admin') {
      req.lead = lead;
      return next();
    }

    // Agent and viewer can only access their own leads
    if (lead.user_id === userId || lead.assigned_to === userId) {
      req.lead = lead;
      return next();
    }

    return res.status(403).json({
      success: false,
      message: 'Access denied. This lead belongs to another agent.',
    });
  } catch (err) {
    res.status(500).json({ success: false, message: err.message });
  }
}

/**
 * Block viewers from write operations
 */
function denyViewers(req, res, next) {
  if (req.userRole === 'viewer') {
    return res.status(403).json({
      success: false,
      message: 'Viewers have read-only access.',
    });
  }
  next();
}

module.exports = {
  attachUserRole,
  requireRole,
  requireMinRole,
  canAccessLead,
  denyViewers,
  ROLE_LEVELS,
};