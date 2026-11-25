// Safeguard staff tools: publish courses and dates, manage bookings, issue certificates
const router = require('express').Router();
const crypto = require('crypto');
const db = require('../db');
const { requireAuth, requireRole } = require('../middleware/auth');
const { wrap, httpError, buildUpdate } = require('../util');

router.use('/admin', requireAuth, requireRole('admin'));

// ---- Courses ----
router.post('/admin/courses', wrap(async (req, res) => {
  const b = req.body;
  if (!b.categoryId || !b.slug || !b.title) throw httpError(400, 'categoryId, slug and title are required');
  const r = await db.query(
    `INSERT INTO courses(category_id, slug, title, summary, description, audience, requirements,
                         duration_days, price_kobo, delivery_mode, is_international, image_url)
     VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,COALESCE($10,'classroom'),COALESCE($11,false),$12) RETURNING id, slug`,
    [b.categoryId, b.slug, b.title, b.summary, b.description, b.audience, b.requirements,
     b.durationDays, b.priceKobo, b.deliveryMode, b.isInternational, b.imageUrl]);
  res.status(201).json({ course: r.rows[0] });
}));

router.patch('/admin/courses/:id', wrap(async (req, res) => {
  const { sets, vals } = buildUpdate(req.body, {
    title: 'title', summary: 'summary', description: 'description', audience: 'audience',
    requirements: 'requirements', durationDays: 'duration_days', priceKobo: 'price_kobo',
    deliveryMode: 'delivery_mode', isActive: 'is_active', imageUrl: 'image_url',
  });
  if (!sets.length) throw httpError(400, 'Nothing to update');
  vals.push(req.params.id);
  const r = await db.query(`UPDATE courses SET ${sets.join(', ')} WHERE id=$${vals.length} RETURNING id`, vals);
  if (!r.rows[0]) throw httpError(404, 'Course not found');
  res.json({ ok: true });
}));

// ---- Training dates ----
router.post('/admin/sessions', wrap(async (req, res) => {
  const b = req.body;
  if (!b.courseId || !b.startDate || !b.endDate) throw httpError(400, 'courseId, startDate and endDate are required');
  const r = await db.query(
    `INSERT INTO course_sessions(course_id, start_date, end_date, exam_date, location, capacity)
     VALUES ($1,$2,$3,$4,$5,$6) RETURNING id`,
    [b.courseId, b.startDate, b.endDate, b.examDate || null, b.location || null, b.capacity || null]);
  res.status(201).json({ session: r.rows[0] });
}));

router.patch('/admin/sessions/:id', wrap(async (req, res) => {
  const { sets, vals } = buildUpdate(req.body, {
    startDate: 'start_date', endDate: 'end_date', examDate: 'exam_date',
    location: 'location', capacity: 'capacity', status: 'status',
  });
  if (!sets.length) throw httpError(400, 'Nothing to update');
  vals.push(req.params.id);
  const r = await db.query(`UPDATE course_sessions SET ${sets.join(', ')} WHERE id=$${vals.length} RETURNING id`, vals);
  if (!r.rows[0]) throw httpError(404, 'Session not found');
  res.json({ ok: true });
}));

// ---- Bookings ----
router.get('/admin/registrations', wrap(async (req, res) => {
  const r = await db.query(
    `SELECT r.id, r.status, r.payment_status AS "paymentStatus", r.amount_kobo AS "amountKobo",
            r.attendee_name AS "attendeeName", r.attendee_email AS "attendeeEmail", r.attendee_phone AS "attendeePhone",
            co.name AS company, c.title AS "courseTitle", cs.start_date AS "startDate", r.created_at AS "createdAt"
       FROM registrations r
       JOIN course_sessions cs ON cs.id = r.session_id
       JOIN courses c ON c.id = cs.course_id
       LEFT JOIN companies co ON co.id = r.company_id
      WHERE ($1::uuid IS NULL OR r.session_id = $1)
      ORDER BY r.created_at DESC LIMIT 500`, [req.query.sessionId || null]);
  res.json({ registrations: r.rows });
}));

router.patch('/admin/registrations/:id', wrap(async (req, res) => {
  const { sets, vals } = buildUpdate(req.body, { status: 'status', paymentStatus: 'payment_status', amountKobo: 'amount_kobo' });
  if (!sets.length) throw httpError(400, 'Nothing to update');
  vals.push(req.params.id);
  const r = await db.query(`UPDATE registrations SET ${sets.join(', ')} WHERE id=$${vals.length} RETURNING id`, vals);
  if (!r.rows[0]) throw httpError(404, 'Registration not found');
  res.json({ ok: true });
}));

// ---- Certificates ----
router.post('/admin/certificates', wrap(async (req, res) => {
  const b = req.body;
  if (!b.holderName || !b.courseTitle || !b.issuedOn) throw httpError(400, 'holderName, courseTitle and issuedOn are required');
  const year = new Date(b.issuedOn).getUTCFullYear();
  for (let attempt = 0; attempt < 5; attempt++) {
    const number = `SG-${year}-${crypto.randomInt(100000, 1000000)}`;
    try {
      const r = await db.query(
        `INSERT INTO certificates(certificate_number, verify_token, registration_id, holder_name,
                                  course_title, awarding_body, issued_on, expires_on)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8) RETURNING certificate_number AS "certificateNumber", verify_token AS "verifyToken"`,
        [number, crypto.randomBytes(16).toString('hex'), b.registrationId || null, b.holderName,
         b.courseTitle, b.awardingBody || null, b.issuedOn, b.expiresOn || null]);
      if (b.registrationId)
        await db.query(`UPDATE registrations SET status='completed' WHERE id=$1`, [b.registrationId]);
      return res.status(201).json({ certificate: r.rows[0] });
    } catch (e) { if (e.code !== '23505') throw e; }
  }
  throw httpError(500, 'Could not generate a unique certificate number, please retry');
}));

router.post('/admin/certificates/:number/revoke', wrap(async (req, res) => {
  const r = await db.query(`UPDATE certificates SET state='revoked' WHERE certificate_number=$1 RETURNING id`,
    [req.params.number.toUpperCase()]);
  if (!r.rows[0]) throw httpError(404, 'Certificate not found');
  res.json({ ok: true });
}));

// ---- Quote requests ----
router.get('/admin/quotes', wrap(async (_req, res) => {
  const r = await db.query(
    `SELECT q.id, q.status, q.headcount, q.preferred_dates AS "preferredDates", q.message,
            COALESCE(c.title, q.course_text) AS course, co.name AS company,
            co.contact_email AS "contactEmail", co.contact_phone AS "contactPhone", q.created_at AS "createdAt"
       FROM quote_requests q
       LEFT JOIN courses c ON c.id = q.course_id
       LEFT JOIN companies co ON co.id = q.company_id
      ORDER BY q.created_at DESC LIMIT 200`);
  res.json({ quotes: r.rows });
}));

router.patch('/admin/quotes/:id', wrap(async (req, res) => {
  const r = await db.query('UPDATE quote_requests SET status=$1 WHERE id=$2 RETURNING id', [req.body.status, req.params.id]);
  if (!r.rows[0]) throw httpError(404, 'Quote request not found');
  res.json({ ok: true });
}));

module.exports = router;
