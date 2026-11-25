// Public: course catalogue and training calendar
const router = require('express').Router();
const db = require('../db');
const { wrap, httpError } = require('../util');

router.get('/categories', wrap(async (_req, res) => {
  const r = await db.query('SELECT id, name FROM categories ORDER BY sort, name');
  res.json({ categories: r.rows });
}));

// ?category=NEBOSH&q=fire&international=true
router.get('/courses', wrap(async (req, res) => {
  const r = await db.query(
    `SELECT c.id, c.slug, c.title, c.summary, c.duration_days AS "durationDays",
            c.price_kobo AS "priceKobo", c.delivery_mode AS "deliveryMode",
            c.is_international AS "isInternational", c.image_url AS "imageUrl", cat.name AS category
       FROM courses c JOIN categories cat ON cat.id = c.category_id
      WHERE c.is_active
        AND c.is_international = $3
        AND ($1::text IS NULL OR cat.name = $1)
        AND ($2::text IS NULL OR c.title ILIKE '%' || $2 || '%')
      ORDER BY cat.sort, c.title`,
    [req.query.category || null, req.query.q || null, req.query.international === 'true']);
  res.json({ courses: r.rows });
}));

router.get('/courses/:slug', wrap(async (req, res) => {
  const c = await db.query(
    `SELECT c.id, c.slug, c.title, c.summary, c.description, c.audience, c.requirements,
            c.duration_days AS "durationDays", c.price_kobo AS "priceKobo",
            c.delivery_mode AS "deliveryMode", c.image_url AS "imageUrl", cat.name AS category
       FROM courses c JOIN categories cat ON cat.id = c.category_id
      WHERE c.slug = $1 AND c.is_active`, [req.params.slug]);
  if (!c.rows[0]) throw httpError(404, 'Course not found');
  const s = await db.query(
    `SELECT id, start_date AS "startDate", end_date AS "endDate", exam_date AS "examDate",
            location, status, capacity
       FROM course_sessions WHERE course_id = $1 AND end_date >= CURRENT_DATE ORDER BY start_date`,
    [c.rows[0].id]);
  res.json({ course: c.rows[0], upcomingSessions: s.rows });
}));

// Training calendar: ?from=2026-12-01&to=2026-12-31&category=NEBOSH
router.get('/sessions', wrap(async (req, res) => {
  const r = await db.query(
    `SELECT cs.id, cs.start_date AS "startDate", cs.end_date AS "endDate", cs.exam_date AS "examDate",
            cs.location, cs.status, cs.capacity,
            cs.capacity - (SELECT count(*)::int FROM registrations r
                            WHERE r.session_id = cs.id AND r.status <> 'cancelled') AS "seatsLeft",
            c.id AS "courseId", c.title, c.slug, c.price_kobo AS "priceKobo", cat.name AS category
       FROM course_sessions cs
       JOIN courses c ON c.id = cs.course_id
       JOIN categories cat ON cat.id = c.category_id
      WHERE cs.status <> 'cancelled'
        AND cs.end_date >= COALESCE($1::date, CURRENT_DATE)
        AND ($2::date IS NULL OR cs.start_date <= $2::date)
        AND ($3::text IS NULL OR cat.name = $3)
      ORDER BY cs.start_date, c.title`,
    [req.query.from || null, req.query.to || null, req.query.category || null]);
  res.json({ sessions: r.rows });
}));

module.exports = router;
