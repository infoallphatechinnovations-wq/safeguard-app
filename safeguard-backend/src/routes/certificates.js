const router = require('express').Router();
const rateLimit = require('express-rate-limit');
const db = require('../db');
const { requireAuth } = require('../middleware/auth');
const { wrap, httpError } = require('../util');

// State is computed so an expired certificate is reported correctly without a nightly job
const SELECT = `
  SELECT certificate_number AS "certificateNumber", holder_name AS "holderName",
         course_title AS "courseTitle", awarding_body AS "awardingBody",
         issued_on AS "issuedOn", expires_on AS "expiresOn",
         CASE WHEN state = 'revoked' THEN 'revoked'
              WHEN expires_on IS NOT NULL AND expires_on < CURRENT_DATE THEN 'expired'
              ELSE state::text END AS state
    FROM certificates`;

// Public lookups are rate limited to make number-guessing impractical
const limiter = rateLimit({ windowMs: 15 * 60 * 1000, limit: 30, standardHeaders: true, legacyHeaders: false });

const respond = (row, res) => {
  if (!row) return res.status(404).json({ valid: false, error: 'No certificate found. Check the number and try again.' });
  res.json({ valid: row.state === 'valid', certificate: row });
};

router.get('/certificates/verify/:number', limiter, wrap(async (req, res) => {
  const r = await db.query(`${SELECT} WHERE certificate_number = $1`, [req.params.number.trim().toUpperCase()]);
  respond(r.rows[0], res);
}));

// The QR code on a certificate encodes this token
router.get('/certificates/verify-token/:token', limiter, wrap(async (req, res) => {
  const r = await db.query(`${SELECT} WHERE verify_token = $1`, [req.params.token]);
  respond(r.rows[0], res);
}));

router.get('/certificates/mine', requireAuth, wrap(async (req, res) => {
  const r = await db.query(
    `SELECT ct.certificate_number AS "certificateNumber", ct.holder_name AS "holderName",
            ct.course_title AS "courseTitle", ct.awarding_body AS "awardingBody",
            ct.issued_on AS "issuedOn", ct.expires_on AS "expiresOn", ct.verify_token AS "verifyToken",
            CASE WHEN ct.state = 'revoked' THEN 'revoked'
                 WHEN ct.expires_on IS NOT NULL AND ct.expires_on < CURRENT_DATE THEN 'expired'
                 ELSE ct.state::text END AS state
       FROM certificates ct
       JOIN registrations r ON r.id = ct.registration_id
      WHERE r.user_id = $1 OR lower(r.attendee_email) = lower($2)
      ORDER BY ct.issued_on DESC`,
    [req.user.id, req.user.email]);
  res.json({ certificates: r.rows });
}));

module.exports = router;
