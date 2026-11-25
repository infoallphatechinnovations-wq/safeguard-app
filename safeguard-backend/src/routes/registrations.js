const router = require('express').Router();
const db = require('../db');
const { requireAuth, requireRole } = require('../middleware/auth');
const { wrap, httpError, validEmail } = require('../util');

// Creates registrations inside one transaction and locks the session row so
// two people cannot take the last seat at the same time.
async function createRegistrations({ sessionId, attendees, registeredBy, companyId }) {
  const client = await db.pool.connect();
  try {
    await client.query('BEGIN');
    const s = await client.query(
      `SELECT cs.id, cs.status, cs.capacity, (cs.start_date < CURRENT_DATE) AS started, c.price_kobo
         FROM course_sessions cs JOIN courses c ON c.id = cs.course_id
        WHERE cs.id = $1 FOR UPDATE OF cs`, [sessionId]);
    const session = s.rows[0];
    if (!session) throw httpError(404, 'Training session not found');
    if (session.status !== 'open' || session.started) throw httpError(409, 'This session is not open for registration');
    if (session.capacity != null) {
      const n = await client.query(
        `SELECT count(*)::int AS n FROM registrations WHERE session_id=$1 AND status <> 'cancelled'`, [sessionId]);
      if (n.rows[0].n + attendees.length > session.capacity) throw httpError(409, 'Not enough seats left on this session');
    }
    const created = [];
    for (const a of attendees) {
      try {
        const r = await client.query(
          `INSERT INTO registrations(session_id, registered_by, user_id, company_id,
                                     attendee_name, attendee_email, attendee_phone, amount_kobo)
           VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING id, status, payment_status AS "paymentStatus", amount_kobo AS "amountKobo"`,
          [sessionId, registeredBy, a.userId || null, companyId || null,
           a.name, a.email.toLowerCase(), a.phone || null, session.price_kobo]);
        created.push({ ...r.rows[0], attendeeName: a.name, attendeeEmail: a.email.toLowerCase() });
      } catch (e) {
        if (e.code === '23505') throw httpError(409, `${a.email} is already registered for this session`);
        throw e;
      }
    }
    await client.query('COMMIT');
    return created;
  } catch (e) {
    await client.query('ROLLBACK');
    throw e;
  } finally { client.release(); }
}

const LIST_SQL = `
  SELECT r.id, r.status, r.payment_status AS "paymentStatus", r.amount_kobo AS "amountKobo",
         r.attendee_name AS "attendeeName", r.attendee_email AS "attendeeEmail", r.created_at AS "createdAt",
         cs.id AS "sessionId", cs.start_date AS "startDate", cs.end_date AS "endDate",
         cs.exam_date AS "examDate", cs.location, c.title AS "courseTitle", c.slug
    FROM registrations r
    JOIN course_sessions cs ON cs.id = r.session_id
    JOIN courses c ON c.id = cs.course_id`;

// Individual (or any signed-in user) registers themselves
router.post('/registrations', requireAuth, wrap(async (req, res) => {
  const me = await db.query('SELECT id, full_name, email, phone, company_id FROM users WHERE id=$1', [req.user.id]);
  const u = me.rows[0];
  const created = await createRegistrations({
    sessionId: req.body.sessionId, registeredBy: u.id, companyId: u.company_id,
    attendees: [{ userId: u.id, name: u.full_name, email: u.email, phone: u.phone }],
  });
  res.status(201).json({ registration: created[0] });
}));

// Corporate admin registers several staff members at once
router.post('/registrations/bulk', requireAuth, requireRole('corporate_admin'), wrap(async (req, res) => {
  const { sessionId, attendees } = req.body;
  if (!Array.isArray(attendees) || attendees.length === 0 || attendees.length > 100)
    throw httpError(400, 'Provide between 1 and 100 attendees');
  for (const a of attendees)
    if (!a.name || !validEmail(a.email)) throw httpError(400, 'Every attendee needs a name and a valid email');
  const created = await createRegistrations({
    sessionId, attendees, registeredBy: req.user.id, companyId: req.user.companyId,
  });
  res.status(201).json({ registrations: created });
}));

router.get('/registrations/mine', requireAuth, wrap(async (req, res) => {
  const r = await db.query(`${LIST_SQL} WHERE r.user_id = $1 OR lower(r.attendee_email) = lower($2)
                            ORDER BY cs.start_date DESC`, [req.user.id, req.user.email]);
  res.json({ registrations: r.rows });
}));

// Everything the company has booked, optionally filtered by ?status=confirmed
router.get('/company/registrations', requireAuth, requireRole('corporate_admin'), wrap(async (req, res) => {
  const r = await db.query(`${LIST_SQL} WHERE r.company_id = $1 AND ($2::text IS NULL OR r.status::text = $2)
                            ORDER BY cs.start_date DESC`, [req.user.companyId, req.query.status || null]);
  res.json({ registrations: r.rows });
}));

router.delete('/registrations/:id', requireAuth, wrap(async (req, res) => {
  const r = await db.query(
    `UPDATE registrations SET status='cancelled'
      WHERE id = $1 AND status IN ('pending','confirmed')
        AND (registered_by = $2 OR ($3::uuid IS NOT NULL AND company_id = $3 AND $4 = 'corporate_admin'))
      RETURNING id`,
    [req.params.id, req.user.id, req.user.companyId || null, req.user.role]);
  if (!r.rows[0]) throw httpError(404, 'Registration not found or it can no longer be cancelled');
  res.json({ ok: true });
}));

module.exports = router;
