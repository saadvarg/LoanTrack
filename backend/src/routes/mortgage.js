const router = require('express').Router();
router.get('/', (req, res) => res.json({ message: 'Mortgage routes ready' }));
module.exports = router;