const router = require('express').Router();
const authMiddleware = require('../middleware/auth');
const supabase = require('../config/supabase');

router.use(authMiddleware);

// GET /api/activities/lead/:id
router.get('/lead/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const { data: lead, error: leadError } = await supabase
      .from('leads')
      .select('id')
      .eq('id', id)
      .eq('user_id', req.userId)
      .single();

    if (leadError || !lead) {
      return res.status(404).json({
        success: false,
        message: 'Lead not found',
      });
    }

    const { data, error } = await supabase
      .from('activities')
      .select('*')
      .eq('lead_id', id)
      .eq('user_id', req.userId)
      .order('created_at', { ascending: false });

    if (error) throw error;

    res.json({
      success: true,
      data: data || [],
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      message: err.message,
    });
  }
});

module.exports = router;
