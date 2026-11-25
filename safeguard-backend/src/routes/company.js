const router = require('express').Router();
const db = require('../db');
const { requireAuth, requireRole } = require('../middleware/auth');
const { wrap } = require('../util');

const guard = [requireAuth, requireRole('corporate_admin')];

router.get('/company', guard, wrap(async (req, res) => {
  const r = await db.query(
    `SELECT id, name, rc_number AS "rcNumber", industry, address, contact_email AS "contactEmail",
            contact_phone AS "contactPhone", join_code AS "joinCode" FROM companies WHERE id=$1`, [req.user.companyId]);
  res.json({ company: r.rows[0] });
}));

router.get('/company/staff', guard, wrap(async (req, res) => {
  const r = await db.query(
    `SELECT u.id, u.full_name AS "fullName", u.email, u.phone, u.job_title AS "jobTitle",
            u.account_type AS "accountType",
            (SELECT count(*)::int FROM registrations r WHERE r.user_id = u.id AND r.status <> 'cancelled') AS "registrations"
       FROM users u WHERE u.company_id = $1 ORDER BY u.full_name`, [req.user.companyId]);
  res.json({ staff: r.rows });
}));

// Quote / in-company training request
router.post('/quotes', guard, wrap(async (req, res) => {
  const { courseId, courseText, headcount, preferredDates, message } = req.body;
  const r = await db.query(
    `INSERT INTO quote_requests(company_id, requested_by, course_id, course_text, headcount, preferred_dates, message)
     VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING id, status`,
    [req.user.companyId, req.user.id, courseId || null, courseText || null, headcount || null,
     preferredDates || null, message || null]);
  res.status(201).json({ quote: r.rows[0] });
}));

module.exports = router;
